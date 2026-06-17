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

// --- Static assets ---
app.use(express.static(path.join(__dirname, 'public')))

// --- API routes ---
app.use('/api/files',     require('./lib/routes/files'))
app.use('/api/cron',      require('./lib/routes/cron'))
app.use('/api/time',      require('./lib/routes/time'))
app.use('/api/packages',  require('./lib/routes/packages'))
app.use('/api/processes', require('./lib/routes/processes'))
app.use('/api/network',   require('./lib/routes/network'))

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
