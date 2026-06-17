'use strict'

const router = require('express').Router()
const { run, runSudo, validate, badRequest } = require('../shell')

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

  await runSudo(req.sudoPassword, 'kill', [`-${sig}`, String(pid)])

  res.json({ data: { ok: true, pid: String(pid), signal: sig } })
})

// GET /port/:port — find process listening on port
// Returns { pid, user, command } by parsing ss output then cross-referencing ps
router.get('/port/:port', async (req, res) => {
  const { port } = req.params
  validate('port', String(port), 'port')

  const { stdout } = await run('ss', ['-tulpn'])
  const portPattern = `:${port}`

  // Extract pid from ss process column: users:(("node",pid=1234,fd=5))
  let pid = null
  for (const line of stdout.split('\n')) {
    if (!line.includes(portPattern)) continue
    const m = line.match(/pid=(\d+)/)
    if (m) { pid = m[1]; break }
  }

  if (!pid) {
    return res.status(404).json({ error: `No process found on port ${port}` })
  }

  // Look up user + command from ps for that pid
  const { stdout: psOut } = await run('ps', ['-p', pid, '-o', 'user=,comm='])
  const parts = psOut.trim().split(/\s+/)
  const user = parts[0] || '?'
  const command = parts.slice(1).join(' ') || '?'

  res.json({ data: { pid, user, command } })
})

module.exports = router
