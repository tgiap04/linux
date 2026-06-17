'use strict'

const router = require('express').Router()
const { run, runShell, stream, validate, badRequest } = require('../shell')

// --- Mutex to prevent concurrent package operations ---
let pkgLock = false
function withLock(fn) {
  if (pkgLock) throw Object.assign(new Error('A package operation is already running'), { status: 409 })
  pkgLock = true
  return Promise.resolve().then(fn).finally(() => { pkgLock = false })
}

// Detect which package manager is available
async function detectManager() {
  const managers = ['apt-get', 'dnf', 'yum', 'pacman']
  for (const mgr of managers) {
    try {
      await run('which', [mgr])
      return mgr
    } catch {
      // Not found, try next
    }
  }
  return 'unknown'
}

// Build install/remove/update/autoremove args per manager
function buildCmd(manager, action, packages = [], purge = false) {
  const env = { ...process.env, DEBIAN_FRONTEND: 'noninteractive' }

  switch (manager) {
    case 'apt-get': {
      if (action === 'install') return { cmd: 'sudo', args: ['apt-get', 'install', '-y', ...packages], env }
      if (action === 'remove') return { cmd: 'sudo', args: ['apt-get', purge ? 'purge' : 'remove', '-y', ...packages], env }
      if (action === 'update') return { cmd: 'sudo', args: ['apt-get', 'upgrade', '-y'], env }
      if (action === 'autoremove') return { cmd: 'sudo', args: ['apt-get', 'autoremove', '-y'], env }
      break
    }
    case 'dnf':
    case 'yum': {
      if (action === 'install') return { cmd: 'sudo', args: [manager, 'install', '-y', ...packages] }
      if (action === 'remove') return { cmd: 'sudo', args: [manager, 'remove', '-y', ...packages] }
      if (action === 'update') return { cmd: 'sudo', args: [manager, 'upgrade', '-y'] }
      if (action === 'autoremove') return { cmd: 'sudo', args: [manager, 'autoremove', '-y'] }
      break
    }
    case 'pacman': {
      if (action === 'install') return { cmd: 'sudo', args: ['pacman', '-S', '--noconfirm', ...packages] }
      if (action === 'remove') return { cmd: 'sudo', args: ['pacman', purge ? '-Rns' : '-R', '--noconfirm', ...packages] }
      if (action === 'update') return { cmd: 'sudo', args: ['pacman', '-Su', '--noconfirm'] }
      if (action === 'autoremove') return { cmd: null, shell: 'pacman -Qtdq | xargs -r sudo pacman -Rns --noconfirm' }
      break
    }
  }
  throw Object.assign(new Error(`Unsupported package manager: ${manager}`), { status: 500 })
}

// GET /detect
router.get('/detect', async (req, res) => {
  const manager = await detectManager()
  res.json({ data: manager })
})

// POST /install — body: {packages: []}
router.post('/install', async (req, res) => {
  const { packages } = req.body
  validate('pkgList', packages, 'packages')

  const data = await withLock(async () => {
    const manager = await detectManager()
    if (manager === 'unknown') throw Object.assign(new Error('No supported package manager found'), { status: 500 })
    const { cmd, args, env } = buildCmd(manager, 'install', packages)
    const { stdout } = await run(cmd, args, env ? { env } : undefined)
    return { ok: true, output: stdout }
  })

  res.json({ data })
})

// POST /remove — body: {pkg, purge:bool}
router.post('/remove', async (req, res) => {
  const { pkg, purge = false } = req.body
  if (!pkg) throw badRequest('pkg is required')
  validate('pkg', pkg, 'pkg')

  const data = await withLock(async () => {
    const manager = await detectManager()
    if (manager === 'unknown') throw Object.assign(new Error('No supported package manager found'), { status: 500 })
    const { cmd, args, env } = buildCmd(manager, 'remove', [pkg], purge)
    const { stdout } = await run(cmd, args, env ? { env } : undefined)
    return { ok: true, output: stdout }
  })

  res.json({ data })
})

// GET /update/stream — SSE stream of system update output
router.get('/update/stream', (req, res) => {
  if (pkgLock) {
    res.status(409).json({ error: 'A package operation is already running' })
    return
  }
  pkgLock = true

  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Connection', 'keep-alive')
  res.flushHeaders()

  detectManager().then(manager => {
    if (manager === 'unknown') {
      res.write(`data: ${JSON.stringify({ error: 'No supported package manager found' })}\n\n`)
      res.write(`data: ${JSON.stringify({ done: true, code: 1 })}\n\n`)
      res.end()
      pkgLock = false
      return
    }

    const { cmd, args, env } = buildCmd(manager, 'update')
    const child = stream(
      cmd,
      args,
      chunk => res.write(`data: ${JSON.stringify({ line: chunk })}\n\n`),
      code => {
        res.write(`data: ${JSON.stringify({ done: true, code })}\n\n`)
        res.end()
        pkgLock = false
      }
    )

    // Cleanup on client disconnect
    req.on('close', () => {
      child.kill()
      pkgLock = false
    })
  }).catch(err => {
    res.write(`data: ${JSON.stringify({ error: err.message })}\n\n`)
    res.write(`data: ${JSON.stringify({ done: true, code: 1 })}\n\n`)
    res.end()
    pkgLock = false
  })
})

// POST /autoremove
router.post('/autoremove', async (req, res) => {
  const data = await withLock(async () => {
    const manager = await detectManager()
    if (manager === 'unknown') throw Object.assign(new Error('No supported package manager found'), { status: 500 })
    const built = buildCmd(manager, 'autoremove')
    const { stdout } = built.shell
      ? await runShell(built.shell)
      : await run(built.cmd, built.args, built.env ? { env: built.env } : {})
    return { ok: true, output: stdout }
  })

  res.json({ data })
})

module.exports = router
