'use strict'
// shell.js — single choke point for all child_process calls
// No other file may call execFile/spawn/exec directly.

const { execFile, spawn } = require('child_process')

// --- Input validators — throw 400 on invalid input ---
const VALIDATORS = {
  path:      v => /^[\w./~-]+$/.test(v) && !v.includes('..'),
  pkg:       v => /^[\w.+:-]+$/.test(v),
  pkgList:   v => Array.isArray(v) && v.length > 0 && v.every(p => /^[\w.+:-]+$/.test(p)),
  pid:       v => /^\d+$/.test(String(v)),
  port:      v => /^\d{1,5}$/.test(String(v)) && Number(v) >= 1 && Number(v) <= 65535,
  tz:        v => /^[A-Za-z_/+-]+$/.test(v) && !v.includes('..'),
  mode:      v => v === '' || /^[0-7]{3,4}$/.test(v),
  owner:     v => v === '' || /^[\w.-]+(:([\w.-]+))?$/.test(v),
  host:      v => /^[\w.-]+$/.test(v),
  cronField: v => /^(\*|[\d*,/-]+)$/.test(v),
  glob:      v => /^[\w.*?[\]-]+$/.test(v),
  size:      v => /^\d+[KMGkmg]$/.test(v),
}

function validate(type, value, label) {
  const fn = VALIDATORS[type]
  if (!fn) throw badRequest(`Unknown validator type: ${type}`)
  if (!fn(value)) throw badRequest(`Invalid ${label || type}: "${value}"`)
}

function badRequest(msg) {
  return Object.assign(new Error(msg), { status: 400 })
}

// --- run — execFile wrapper, resolves {stdout, stderr} ---
function run(cmd, args = [], opts = {}) {
  return new Promise((resolve, reject) => {
    execFile(cmd, args, { timeout: 30_000, ...opts }, (err, stdout, stderr) => {
      if (err) {
        const e = Object.assign(err, { stderr: stderr?.trim() })
        reject(e)
      } else {
        resolve({ stdout: stdout.trim(), stderr: stderr.trim() })
      }
    })
  })
}

// --- runShell — bash -c for pipeline commands; all args must be pre-validated ---
function runShell(script, opts = {}) {
  return run('bash', ['-c', script], opts)
}

// --- stream — spawn + SSE callbacks ---
// write(chunk: string) called per stdout/stderr chunk
// done(exitCode: number) called on close
function stream(cmd, args, write, done) {
  const child = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] })
  child.stdout.on('data', d => write(d.toString()))
  child.stderr.on('data', d => write(d.toString()))
  child.on('close', code => done(code ?? 0))
  child.on('error', err => { write(`Error: ${err.message}\n`); done(1) })
  return child
}

module.exports = { run, runShell, stream, validate, badRequest }
