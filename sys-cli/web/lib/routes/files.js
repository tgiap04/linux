'use strict'

const router = require('express').Router()
const { run, runShell, runSudo, validate, badRequest } = require('../shell')

// Convert bytes to human-readable string
function humanBytes(bytes) {
  const n = parseInt(bytes, 10)
  if (isNaN(n)) return bytes
  if (n >= 1073741824) return (n / 1073741824).toFixed(1) + 'G'
  if (n >= 1048576) return (n / 1048576).toFixed(1) + 'M'
  if (n >= 1024) return (n / 1024).toFixed(1) + 'K'
  return n + 'B'
}

// GET /tree?path=&depth=
// Returns flat list [{name, path, relPath, type, depth}] sorted dirs-first
router.get('/tree', async (req, res) => {
  const { path: dirPath = '/', depth = '3' } = req.query
  validate('path', dirPath, 'path')
  const maxDepth = Math.min(Math.max(parseInt(depth, 10) || 3, 1), 5)

  // -printf '%d\t%y\t%P\n': depth, type (d/f/l), relative path
  const { stdout } = await runShell(
    `find "${dirPath}" -maxdepth ${maxDepth} -printf '%d\\t%y\\t%P\\n' 2>/dev/null | sort -t$'\\t' -k3`
  )

  const items = stdout.split('\n').filter(Boolean).reduce((acc, line) => {
    const tab1 = line.indexOf('\t')
    const tab2 = line.indexOf('\t', tab1 + 1)
    const d = parseInt(line.slice(0, tab1), 10)
    const t = line.slice(tab1 + 1, tab2)
    const rel = line.slice(tab2 + 1)
    if (!rel || d === 0) return acc // skip root entry itself
    const name = rel.includes('/') ? rel.slice(rel.lastIndexOf('/') + 1) : rel
    const fullPath = dirPath.replace(/\/$/, '') + '/' + rel
    acc.push({ name, path: fullPath, relPath: rel, type: t === 'd' ? 'dir' : 'file', depth: d })
    return acc
  }, [])

  // Sort into proper tree order: each item sorts under its parent,
  // dirs before files within same parent.
  // Build a sort key per item: for each path segment, prefix with '0' (dir) or '1' (file)
  // so the full key encodes ancestry + type + name in one comparable string.
  function treeSortKey(item) {
    const parts = item.relPath.split('/')
    // All ancestor segments are dirs, so prefix with '0'; final segment uses item type
    return parts.map((seg, i) => {
      const isLast = i === parts.length - 1
      const typePrefix = isLast ? (item.type === 'dir' ? '0' : '1') : '0'
      return typePrefix + seg.toLowerCase()
    }).join('/')
  }
  items.sort((a, b) => treeSortKey(a).localeCompare(treeSortKey(b)))

  res.json({ data: items })
})

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

  // Single pass: print matched paths then delete them.
  // Exit code 1 is normal when find hits permission-denied dirs — treat it as success.
  let deleted = 0
  try {
    const { stdout } = await runShell(
      `find "${dir}" -name "${pattern}" -type f -printf '.' -delete 2>/dev/null`
    )
    deleted = stdout.length // one '.' printed per deleted file
  } catch (err) {
    // find exits 1 on permission errors even with 2>/dev/null — count from dots printed before exit
    deleted = err.stdout ? err.stdout.length : 0
  }

  res.json({ data: { deleted } })
})

// POST /delete-path — body: {path}
// Deletes a single file or directory (rm -rf)
router.post('/delete-path', async (req, res) => {
  const { path: targetPath } = req.body
  if (!targetPath) throw badRequest('path is required')
  validate('path', targetPath, 'path')

  // Check existence first — rm -rf on a missing path exits 0 on most systems but 1 on some
  const { stdout: testOut } = await runShell(`test -e "${targetPath}" && echo exists || echo missing`)
  if (testOut.trim() === 'missing') return res.json({ data: { ok: true } })

  await runSudo(req.sudoPassword, 'rm', ['-rf', '--', targetPath])
  res.json({ data: { ok: true } })
})

// POST /rename — body: {path, newName}
// Renames a file or directory in place (mv)
router.post('/rename', async (req, res) => {
  const { path: targetPath, newName } = req.body
  if (!targetPath) throw badRequest('path is required')
  if (!newName) throw badRequest('newName is required')
  validate('path', targetPath, 'path')
  validate('filename', newName, 'newName')

  const dir = targetPath.includes('/') ? targetPath.slice(0, targetPath.lastIndexOf('/')) || '/' : '.'
  const dest = dir.replace(/\/$/, '') + '/' + newName
  await runSudo(req.sudoPassword, 'mv', [targetPath, dest])
  res.json({ data: { ok: true, dest } })
})

// POST /create — body: {path, name, type: 'file'|'dir'}
// Creates a new file (touch) or directory (mkdir -p) inside path
router.post('/create', async (req, res) => {
  const { path: parentPath, name, type } = req.body
  if (!parentPath) throw badRequest('path is required')
  if (!name) throw badRequest('name is required')
  if (type !== 'file' && type !== 'dir') throw badRequest('type must be "file" or "dir"')
  validate('path', parentPath, 'path')
  validate('filename', name, 'name')

  const dest = parentPath.replace(/\/$/, '') + '/' + name
  if (type === 'dir') {
    await runSudo(req.sudoPassword, 'mkdir', ['-p', dest])
  } else {
    await runSudo(req.sudoPassword, 'touch', [dest])
  }
  res.json({ data: { ok: true, dest } })
})


module.exports = router
