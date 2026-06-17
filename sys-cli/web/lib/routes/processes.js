'use strict'

const router = require('express').Router()
const { run, validate, badRequest } = require('../shell')

const VALID_SIGNALS = new Set(['TERM', 'KILL', 'HUP', 'INT', 'USR1', 'USR2'])

// Parse `ps aux` stdout into structured array
// Header: USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
function parsePsAux(stdout) {
  const lines = stdout.split('\n').filter(Boolean)
  // Skip header line
  return lines.slice(1).map(line => {
    const parts = line.trim().split(/\s+/)
    const [user, pid, cpu, mem] = parts
    // COMMAND is everything from index 10 onward
    const command = parts.slice(10).join(' ')
    return { pid, user, cpu, mem, command }
  })
}

// GET /list?sort=cpu|mem
router.get('/list', async (req, res) => {
  const { sort = 'cpu' } = req.query
  const sortFlag = sort === 'mem' ? '-%mem' : '-%cpu'

  const { stdout } = await run('ps', ['aux', `--sort=${sortFlag}`])
  const data = parsePsAux(stdout)

  res.json({ data })
})

// POST /kill — body: {pid, signal}
router.post('/kill', async (req, res) => {
  const { pid, signal = 'TERM' } = req.body
  if (!pid) throw badRequest('pid is required')

  validate('pid', String(pid), 'pid')

  const sig = String(signal).toUpperCase()
  if (!VALID_SIGNALS.has(sig)) {
    throw badRequest(`signal must be one of: ${[...VALID_SIGNALS].join(', ')}`)
  }

  await run('kill', [`-${sig}`, String(pid)])

  res.json({ data: { ok: true, pid: String(pid), signal: sig } })
})

// GET /port/:port — find process listening on port
router.get('/port/:port', async (req, res) => {
  const { port } = req.params
  validate('port', String(port), 'port')

  const { stdout } = await run('ss', ['-tulpn'])

  // Parse ss -tulpn output
  // Format: Netid State Recv-Q Send-Q Local Address:Port Peer Address:Port Process
  const lines = stdout.split('\n').filter(Boolean)
  const portPattern = `:${port}`

  const matched = lines
    .slice(1) // skip header
    .filter(line => line.includes(portPattern))
    .map(line => {
      const parts = line.trim().split(/\s+/)
      const proto = parts[0] || ''
      const state = parts[1] || ''
      const local = parts[4] || ''
      const peer = parts[5] || ''
      const process = parts.slice(6).join(' ') || ''
      return { proto, state, local, peer, process }
    })

  res.json({ data: matched })
})

module.exports = router
