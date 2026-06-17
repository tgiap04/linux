# Phase 01: Server Setup — server.js + shell.js + package.json

**Priority:** Critical (blocks all phases)
**Status:** Pending

## Files to Create

- `web/package.json`
- `web/server.js`
- `web/lib/shell.js`

## package.json

```json
{
  "name": "sys-cli-web",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": { "start": "node server.js" },
  "dependencies": {
    "express": "^4.18.0",
    "helmet": "^7.0.0",
    "express-rate-limit": "^7.0.0",
    "express-async-errors": "^3.1.0"
  }
}
```

## server.js

- `require('express-async-errors')` first line
- `helmet()` middleware
- `express-rate-limit`: 30 req/min per IP
- `express.json()` body parser
- `express.static('public')` for frontend assets
- Mount all route modules under `/api/*`
- Global error handler: `(err, req, res, next)` → JSON `{ error: err.message }`
- Listen on `0.0.0.0:PORT` (PORT from env, default 3000)
- Log startup: `Listening on http://0.0.0.0:${PORT}`

## lib/shell.js — THE security choke point

All `child_process` calls live here. No other file may spawn processes.

```js
const { execFile } = require('child_process')

// Allowlist validators — throw on invalid input
const validators = {
  path:    v => /^[\w./ -]+$/.test(v),
  pkg:     v => /^[\w.+-]+$/.test(v),
  pid:     v => /^\d+$/.test(v),
  port:    v => /^\d{1,5}$/.test(v) && +v <= 65535,
  tz:     v => /^[A-Za-z_/]+$/.test(v),
  mode:    v => /^[0-7]{3,4}$/.test(v),
  owner:   v => /^[\w.-]+(:([\w.-]+))?$/.test(v),
  host:    v => /^[\w.-]+$/.test(v),
  cronField: v => /^[\d*,/-]+$/.test(v),
}

function validate(type, value) {
  if (!validators[type]?.(value)) throw Object.assign(new Error(`Invalid ${type}: ${value}`), { status: 400 })
}

// Run a command, resolve with { stdout, stderr }
function run(cmd, args = []) {
  return new Promise((resolve, reject) => {
    execFile(cmd, args, { timeout: 30_000 }, (err, stdout, stderr) => {
      if (err) reject(Object.assign(err, { stderr }))
      else resolve({ stdout: stdout.trim(), stderr: stderr.trim() })
    })
  })
}

// Stream command output via SSE — calls write(data) per line, then done()
function stream(cmd, args, write, done) {
  const { spawn } = require('child_process')
  const child = spawn(cmd, args)
  child.stdout.on('data', d => write(d.toString()))
  child.stderr.on('data', d => write(d.toString()))
  child.on('close', code => done(code))
  return child
}

module.exports = { run, stream, validate }
```

## Success Criteria

- `node web/server.js` starts without error
- `GET /` serves `public/index.html`
- `GET /api/nonexistent` returns JSON `{ error: "..." }` not HTML stack trace
- Rate limiter responds 429 after 31 rapid requests
