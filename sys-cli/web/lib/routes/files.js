'use strict'

const router = require('express').Router()
const { run, runShell, validate, badRequest } = require('../shell')

// Convert bytes to human-readable string
function humanBytes(bytes) {
  const n = parseInt(bytes, 10)
  if (isNaN(n)) return bytes
  if (n >= 1073741824) return (n / 1073741824).toFixed(1) + 'G'
  if (n >= 1048576) return (n / 1048576).toFixed(1) + 'M'
  if (n >= 1024) return (n / 1024).toFixed(1) + 'K'
  return n + 'B'
}

// GET /large?dir=&size=
// Returns [{bytes, human, path}] for files larger than `size`
router.get('/large', async (req, res) => {
  const { dir, size } = req.query
  if (!dir) throw badRequest('dir is required')
  if (!size) throw badRequest('size is required')

  validate('path', dir, 'dir')
  validate('size', size, 'size')

  const { stdout } = await runShell(
    `find "${dir}" -type f -size "+${size}" -printf '%s\t%p\n' 2>/dev/null | sort -rn | head -30`
  )

  const data = stdout
    .split('\n')
    .filter(Boolean)
    .map(line => {
      const tab = line.indexOf('\t')
      const bytes = line.slice(0, tab)
      const path = line.slice(tab + 1)
      return { bytes: parseInt(bytes, 10), human: humanBytes(bytes), path }
    })

  res.json({ data })
})

// POST /delete — body: {dir, pattern}
// Deletes files matching pattern under dir, returns {deleted: count}
router.post('/delete', async (req, res) => {
  const { dir, pattern } = req.body
  if (!dir) throw badRequest('dir is required')
  if (!pattern) throw badRequest('pattern is required')

  validate('path', dir, 'dir')
  validate('glob', pattern, 'pattern')

  // Count first, then delete
  const { stdout: countOut } = await runShell(
    `find "${dir}" -name "${pattern}" -type f 2>/dev/null | wc -l`
  )
  const deleted = parseInt(countOut.trim(), 10) || 0

  await runShell(`find "${dir}" -name "${pattern}" -type f -delete 2>/dev/null`)

  res.json({ data: { deleted } })
})

// POST /chmod — body: {dir, fmode?, dmode?, owner?}
// Applies file/directory permissions and ownership
router.post('/chmod', async (req, res) => {
  const { dir, fmode = '', dmode = '', owner = '' } = req.body
  if (!dir) throw badRequest('dir is required')

  validate('path', dir, 'dir')
  if (fmode) validate('mode', fmode, 'fmode')
  if (dmode) validate('mode', dmode, 'dmode')
  if (owner) validate('owner', owner, 'owner')

  if (!fmode && !dmode && !owner) {
    throw badRequest('At least one of fmode, dmode, or owner is required')
  }

  if (dmode) {
    await run('sudo', ['find', dir, '-type', 'd', '-exec', 'chmod', dmode, '{}', '+'])
  }
  if (fmode) {
    await run('sudo', ['find', dir, '-type', 'f', '-exec', 'chmod', fmode, '{}', '+'])
  }
  if (owner) {
    await run('sudo', ['chown', '-R', owner, dir])
  }

  res.json({ data: { ok: true } })
})

module.exports = router
