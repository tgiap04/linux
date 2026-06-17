'use strict'

const router = require('express').Router()
const { run, runShell, validate, badRequest } = require('../shell')

// Read current crontab, return [] if none exists
async function getCrontab() {
  try {
    const { stdout } = await run('crontab', ['-l'])
    return stdout
  } catch (err) {
    // Exit code 1 = no crontab for user — not an error
    if (err.code === 1 || (err.stderr && err.stderr.includes('no crontab'))) {
      return ''
    }
    throw err
  }
}

// GET /list — parse crontab -l, return [{index, entry}]
router.get('/list', async (req, res) => {
  const raw = await getCrontab()

  const data = raw
    .split('\n')
    .filter(line => line.trim() && !line.startsWith('#'))
    .map((entry, i) => ({ index: i + 1, entry: entry.trim() }))

  res.json({ data })
})

// POST /add — body: {min, hour, day, month, wday, cmd}
// Adds cron job idempotently
router.post('/add', async (req, res) => {
  const { min, hour, day, month, wday, cmd } = req.body
  for (const [field, val] of [['min', min], ['hour', hour], ['day', day], ['month', month], ['wday', wday]]) {
    if (val === undefined || val === null) throw badRequest(`${field} is required`)
    validate('cronField', String(val), field)
  }
  if (!cmd || typeof cmd !== 'string' || !cmd.trim()) throw badRequest('cmd is required')

  const entry = `${min} ${hour} ${day} ${month} ${wday} ${cmd.trim()}`

  const current = await getCrontab()
  const lines = current ? current.split('\n') : []

  // Idempotency check
  if (lines.some(l => l.trim() === entry)) {
    return res.json({ data: { ok: true, added: false, reason: 'already exists' } })
  }

  const newCrontab = [...lines.filter(Boolean), entry, ''].join('\n')
  await runShell(`echo ${JSON.stringify(newCrontab)} | crontab -`)

  res.json({ data: { ok: true, added: true, entry } })
})

// DELETE /:index — remove cron job at 1-based index (non-comment lines)
router.delete('/:index', async (req, res) => {
  const idx = parseInt(req.params.index, 10)
  if (isNaN(idx) || idx < 1) throw badRequest('index must be a positive integer')

  const current = await getCrontab()
  const allLines = current ? current.split('\n') : []

  // Filter to non-comment, non-empty lines and track original indices
  const jobLines = []
  for (let i = 0; i < allLines.length; i++) {
    const trimmed = allLines[i].trim()
    if (trimmed && !trimmed.startsWith('#')) {
      jobLines.push({ lineIdx: i, entry: allLines[i] })
    }
  }

  if (idx > jobLines.length) {
    throw badRequest(`index ${idx} out of range (${jobLines.length} jobs)`)
  }

  const toRemove = jobLines[idx - 1].lineIdx
  const remaining = allLines.filter((_, i) => i !== toRemove)
  const newCrontab = remaining.join('\n')

  if (newCrontab.trim()) {
    await runShell(`echo ${JSON.stringify(newCrontab)} | crontab -`)
  } else {
    await run('crontab', ['-r'])
  }

  res.json({ data: { ok: true, removed: jobLines[idx - 1].entry.trim() } })
})

// POST /backup — body: {src, dest, schedule}
// schedule: {min, hour, day, month, wday} — adds tar backup cron entry
router.post('/backup', async (req, res) => {
  const { src, dest, schedule } = req.body
  if (!src) throw badRequest('src is required')
  if (!dest) throw badRequest('dest is required')
  if (!schedule || typeof schedule !== 'object') throw badRequest('schedule is required')

  validate('path', src, 'src')
  validate('path', dest, 'dest')

  const { min = '0', hour = '2', day = '*', month = '*', wday = '*' } = schedule
  for (const [field, val] of [['min', min], ['hour', hour], ['day', day], ['month', month], ['wday', wday]]) {
    validate('cronField', String(val), field)
  }

  const tarCmd = `tar -czf "${dest}/backup-$(date +\\%Y\\%m\\%d-\\%H\\%M\\%S).tar.gz" "${src}"`
  const entry = `${min} ${hour} ${day} ${month} ${wday} ${tarCmd}`

  const current = await getCrontab()
  const lines = current ? current.split('\n') : []

  if (lines.some(l => l.trim() === entry)) {
    return res.json({ data: { ok: true, added: false, reason: 'already exists' } })
  }

  const newCrontab = [...lines.filter(Boolean), entry, ''].join('\n')
  await runShell(`echo ${JSON.stringify(newCrontab)} | crontab -`)

  res.json({ data: { ok: true, added: true, entry } })
})

module.exports = router
