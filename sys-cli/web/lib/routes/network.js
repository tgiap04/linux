'use strict'

const router = require('express').Router()
const { run, validate, badRequest } = require('../shell')

// Parse `ss -tulpn` output into structured array
function parseSockets(stdout) {
  const lines = stdout.split('\n').filter(Boolean)
  return lines.slice(1).map(line => {
    const parts = line.trim().split(/\s+/)
    return {
      proto: parts[0] || '',
      state: parts[1] || '',
      local: parts[4] || '',
      peer: parts[5] || '',
      process: parts.slice(6).join(' ') || '',
    }
  })
}

// Parse `ip addr show` output — group lines by interface
function parseInterfaces(stdout) {
  const interfaces = []
  let current = null

  for (const line of stdout.split('\n')) {
    // Interface header: "2: eth0: <BROADCAST,...> mtu 1500 ..."
    const ifaceMatch = line.match(/^\d+:\s+([\w@.-]+):\s+<([^>]*)>/)
    if (ifaceMatch) {
      if (current) interfaces.push(current)
      const flags = ifaceMatch[2]
      current = {
        name: ifaceMatch[1].split('@')[0], // strip @ifname for veth
        ipv4: [],
        ipv6: [],
        state: flags.includes('UP') ? 'UP' : 'DOWN',
      }
      continue
    }

    if (!current) continue

    // IPv4: "    inet 192.168.1.1/24 brd ..."
    const inet4 = line.match(/^\s+inet\s+([\d./]+)/)
    if (inet4) { current.ipv4.push(inet4[1]); continue }

    // IPv6: "    inet6 fe80::1/64 scope ..."
    const inet6 = line.match(/^\s+inet6\s+([a-f0-9:./]+)/i)
    if (inet6) { current.ipv6.push(inet6[1]); continue }
  }
  if (current) interfaces.push(current)

  return interfaces
}

// Parse `ip route show` output
function parseRoutes(stdout) {
  return stdout
    .split('\n')
    .filter(Boolean)
    .map(line => {
      const isDefault = line.startsWith('default')
      const viaMatch = line.match(/via\s+([\d.a-f:]+)/i)
      const devMatch = line.match(/dev\s+(\S+)/)
      const destMatch = line.match(/^(\S+)/)
      return {
        dest: isDefault ? 'default' : (destMatch ? destMatch[1] : ''),
        gateway: viaMatch ? viaMatch[1] : null,
        iface: devMatch ? devMatch[1] : null,
        isDefault,
      }
    })
}

// GET /sockets
router.get('/sockets', async (req, res) => {
  const { stdout } = await run('ss', ['-tulpn'])
  res.json({ data: parseSockets(stdout) })
})

// GET /interfaces
router.get('/interfaces', async (req, res) => {
  const { stdout } = await run('ip', ['addr', 'show'])
  res.json({ data: parseInterfaces(stdout) })
})

// GET /routes
router.get('/routes', async (req, res) => {
  const { stdout } = await run('ip', ['route', 'show'])
  res.json({ data: parseRoutes(stdout) })
})

// POST /ping — body: {host}
router.post('/ping', async (req, res) => {
  const { host } = req.body
  if (!host) throw badRequest('host is required')
  validate('host', host, 'host')

  let success = false
  let rtt = null
  let output = ''

  try {
    const result = await run('ping', ['-c', '3', '-W', '2', '--', host])
    output = result.stdout

    // Parse RTT from summary: "rtt min/avg/max/mdev = 0.1/0.2/0.3/0.0 ms"
    const rttMatch = output.match(/rtt[^=]+=\s*([\d.]+)\/([\d.]+)\/([\d.]+)/)
    if (rttMatch) {
      rtt = { min: rttMatch[1], avg: rttMatch[2], max: rttMatch[3], unit: 'ms' }
    }
    success = true
  } catch (err) {
    output = err.stderr || err.message || ''
    success = false
  }

  res.json({ data: { success, rtt, output } })
})

// POST /dns — body: {target}
router.post('/dns', async (req, res) => {
  const { target } = req.body
  if (!target) throw badRequest('target is required')
  validate('host', target, 'target')

  let results = []

  // Try dig first
  try {
    const { stdout } = await run('dig', ['+short', target])
    results = stdout.split('\n').filter(Boolean)
    return res.json({ data: { tool: 'dig', results } })
  } catch (digErr) {
    if (digErr.code !== 'ENOENT') {
      // dig found but returned error — still try fallback
    }
  }

  // Fallback to getent hosts
  try {
    const { stdout } = await run('getent', ['hosts', target])
    results = stdout.split('\n').filter(Boolean).map(line => line.trim().split(/\s+/)[0])
    return res.json({ data: { tool: 'getent', results } })
  } catch (getentErr) {
    throw Object.assign(new Error(`DNS lookup failed for "${target}"`), { status: 502 })
  }
})

// GET /firewall — detect and query firewall tool
router.get('/firewall', async (req, res) => {
  const tools = [
    { name: 'ufw', check: ['ufw', ['status']] },
    { name: 'firewall-cmd', check: ['firewall-cmd', ['--state']] },
    { name: 'iptables', check: ['iptables', ['-L', '-n', '--line-numbers']] },
    { name: 'nft', check: ['nft', ['list', 'ruleset']] },
  ]

  for (const { name, check } of tools) {
    try {
      const { stdout } = await run(check[0], check[1])
      return res.json({ data: { tool: name, output: stdout } })
    } catch (err) {
      // ENOENT = not installed, permission error = installed but no access
      if (err.code !== 'ENOENT') {
        // Tool exists but errored — report partial result
        return res.json({ data: { tool: name, output: err.stderr || err.message || '' } })
      }
    }
  }

  res.json({ data: { tool: null, output: 'No firewall tool detected' } })
})

module.exports = router
