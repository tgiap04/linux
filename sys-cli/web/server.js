'use strict'
require('express-async-errors')

const express = require('express')
const helmet = require('helmet')
const rateLimit = require('express-rate-limit')
const path = require('path')

const app = express()
const PORT = process.env.PORT || 3000

// --- Security middleware ---
app.use(helmet({ contentSecurityPolicy: false })) // CSP off — inline scripts in views
app.use(rateLimit({ windowMs: 60_000, max: 120, standardHeaders: true, legacyHeaders: false }))

// --- Body parsing ---
app.use(express.json())
app.use(express.urlencoded({ extended: false }))

// --- Sudo password — extract from header so routes can call runSudo(req.sudoPassword, ...) ---
// Password lives only in the request, never logged or stored.
app.use((req, _res, next) => {
  req.sudoPassword = req.headers['x-sudo-password'] || null
  next()
})

// --- Audit log — print every user action (non-static API calls) to stdout ---
app.use((req, _res, next) => {
  if (req.path.startsWith('/api/')) {
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '-'
    const body = req.method !== 'GET' && req.body && Object.keys(req.body).length
      ? ' ' + JSON.stringify(req.body)
      : ''
    console.log(`[AUDIT] ${new Date().toISOString()} ${ip} ${req.method} ${req.path}${body}`)
  }
  next()
})

// --- Static assets ---
app.use(express.static(path.join(__dirname, 'public')))

// --- Sudo token store — short-lived tokens for EventSource (can't set headers) ---
const sudoTokens = new Map() // token -> { password, expires }
function createSudoToken(password) {
  const token = require('crypto').randomBytes(16).toString('hex')
  sudoTokens.set(token, { password, expires: Date.now() + 30_000 }) // 30s TTL
  setTimeout(() => sudoTokens.delete(token), 30_000)
  return token
}
function consumeSudoToken(token) {
  const entry = sudoTokens.get(token)
  if (!entry || entry.expires < Date.now()) return null
  sudoTokens.delete(token) // one-time use
  return entry.password
}

// --- Sudo verify — test password and optionally issue a one-time token for SSE ---
app.post('/api/sudo/verify', async (req, res) => {
  const password = req.sudoPassword
  if (!password) return res.status(400).json({ error: 'sudo_required' })
  const { runSudo } = require('./lib/shell')
  try {
    await runSudo(password, 'true', [])
    const token = createSudoToken(password)
    res.json({ data: { ok: true, token } })
  } catch (e) {
    if (e.sudoIncorrect) return res.status(401).json({ error: 'incorrect_password' })
    res.status(500).json({ error: e.message })
  }
})

// Attach sudo password from token query param (for EventSource) or header
app.use((req, _res, next) => {
  if (!req.sudoPassword && req.query._sudo_token) {
    req.sudoPassword = consumeSudoToken(req.query._sudo_token) || null
  }
  next()
})

// --- API routes ---
app.use('/api/files',     require('./lib/routes/files'))
app.use('/api/cron',      require('./lib/routes/cron'))
app.use('/api/time',      require('./lib/routes/time'))
app.use('/api/packages',  require('./lib/routes/packages'))
app.use('/api/processes', require('./lib/routes/processes'))
app.use('/api/network',   require('./lib/routes/network'))
app.use('/api/firewall',  require('./lib/routes/firewall'))

// --- SPA fallback — serve index.html for non-API routes ---
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'))
})

// --- Global error handler ---
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, _next) => {
  const status = err.status || 500
  const message = err.message || 'Internal server error'
  if (status >= 500) console.error('[ERROR]', err)
  res.status(status).json({ error: message })
})

app.listen(PORT, '0.0.0.0', () => {
  console.log(`sys-cli web UI running at http://0.0.0.0:${PORT}`)
  console.log('Access from any device on your network via http://<server-ip>:' + PORT)
})
