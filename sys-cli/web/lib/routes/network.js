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

// POST /ping — body: {host, port?}
// Returns { reachable, ping, tcp } to match frontend expectations
router.post('/ping', async (req, res) => {
  const { host, port } = req.body
  if (!host) throw badRequest('host is required')
  validate('host', host, 'host')
  const tcpPort = parseInt(port, 10) || 80

  // Run ICMP ping and TCP check concurrently
  const [icmpResult, tcpResult] = await Promise.allSettled([
    run('ping', ['-c', '3', '-W', '2', '--', host]),
    run('bash', ['-c', `bash -c 'echo >/dev/tcp/${host}/${tcpPort}' 2>/dev/null && echo open || echo closed`]),
  ])

  // ICMP
  let pingStr = null
  let icmpOk = false
  if (icmpResult.status === 'fulfilled') {
    const output = icmpResult.value.stdout
    const rttMatch = output.match(/rtt[^=]+=\s*([\d.]+)\/([\d.]+)\/([\d.]+)/)
    if (rttMatch) {
      pingStr = rttMatch[2] + ' ms'
      icmpOk = true
    }
  }

  // TCP
  let tcpOk = false
  if (tcpResult.status === 'fulfilled') {
    tcpOk = tcpResult.value.stdout.trim() === 'open'
  }

  res.json({ data: { reachable: icmpOk || tcpOk, ping: pingStr, tcp: tcpOk } })
})

// POST /dns — body: {target}
// Returns { query, records } to match frontend expectations
router.post('/dns', async (req, res) => {
  const { target } = req.body
  if (!target) throw badRequest('target is required')
  validate('host', target, 'target')

  let records = []

  // Try dig first
  try {
    const { stdout } = await run('dig', ['+short', target])
    records = stdout.split('\n').filter(Boolean)
    return res.json({ data: { query: target, records } })
  } catch (digErr) {
    if (digErr.code !== 'ENOENT') {
      // dig found but returned error — still try fallback
    }
  }

  // Fallback to getent hosts
  try {
    const { stdout } = await run('getent', ['hosts', target])
    records = stdout.split('\n').filter(Boolean).map(line => line.trim().split(/\s+/)[0])
    return res.json({ data: { query: target, records } })
  } catch (getentErr) {
    throw Object.assign(new Error(`DNS lookup failed for "${target}"`), { status: 502 })
  }
})

module.exports = router
