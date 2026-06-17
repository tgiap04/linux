'use strict'

const router = require('express').Router()
const { run, runShell, runSudo, stream, streamSudo, validate, badRequest } = require('../shell')

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

// Build install/remove/update/autoremove args per manager.
// Returns { cmd, args, env?, shell? } — caller passes to runSudo(password, cmd, args).
// cmd is the real binary (no 'sudo' prefix); shell is used for pipeline commands.
function buildCmd(manager, action, packages = [], purge = false) {
  const env = { ...process.env, DEBIAN_FRONTEND: 'noninteractive' }

  switch (manager) {
    case 'apt-get': {
      if (action === 'install') return { cmd: 'apt-get', args: ['install', '-y', ...packages], env }
      if (action === 'remove') return { cmd: 'apt-get', args: [purge ? 'purge' : 'remove', '-y', ...packages], env }
      if (action === 'update') return { cmd: 'apt-get', args: ['upgrade', '-y'], env }
      if (action === 'autoremove') return { cmd: 'apt-get', args: ['autoremove', '-y'], env }
      break
    }
    case 'dnf':
    case 'yum': {
      if (action === 'install') return { cmd: manager, args: ['install', '-y', ...packages] }
      if (action === 'remove') return { cmd: manager, args: ['remove', '-y', ...packages] }
      if (action === 'update') return { cmd: manager, args: ['upgrade', '-y'] }
      if (action === 'autoremove') return { cmd: manager, args: ['autoremove', '-y'] }
      break
    }
    case 'pacman': {
      if (action === 'install') return { cmd: 'pacman', args: ['-S', '--noconfirm', ...packages] }
      if (action === 'remove') return { cmd: 'pacman', args: [purge ? '-Rns' : '-R', '--noconfirm', ...packages] }
      if (action === 'update') return { cmd: 'pacman', args: ['-Su', '--noconfirm'] }
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

// GET /list — list installed packages
router.get('/list', async (req, res) => {
  const manager = await detectManager()
  if (manager === 'unknown') throw Object.assign(new Error('No supported package manager found'), { status: 500 })

  let pkgs = []

  if (manager === 'apt-get') {
    const { stdout } = await run('dpkg-query', ['-W', '-f=${Package}\t${Version}\t${db:Status-Status}\n'])
    pkgs = stdout.split('\n').filter(Boolean).reduce((acc, line) => {
      const [name, version, status] = line.split('\t')
      if (status && status.trim() === 'installed') acc.push({ name: name.trim(), version: version.trim() })
      return acc
    }, [])
  } else if (manager === 'dnf' || manager === 'yum') {
    const { stdout } = await run('rpm', ['-qa', '--queryformat', '%{NAME}\t%{VERSION}-%{RELEASE}\n'])
    pkgs = stdout.split('\n').filter(Boolean).map(line => {
      const [name, version] = line.split('\t')
      return { name: name.trim(), version: version.trim() }
    })
  } else if (manager === 'pacman') {
    const { stdout } = await run('pacman', ['-Q'])
    pkgs = stdout.split('\n').filter(Boolean).map(line => {
      const parts = line.trim().split(/\s+/)
      return { name: parts[0] || '', version: parts[1] || '' }
    })
  }

  res.json({ data: pkgs })
})

// POST /install — body: {packages: []}
router.post('/install', async (req, res) => {
  const { packages } = req.body
  validate('pkgList', packages, 'packages')
  const password = req.sudoPassword

  const data = await withLock(async () => {
    const manager = await detectManager()
    if (manager === 'unknown') throw Object.assign(new Error('No supported package manager found'), { status: 500 })
    const { cmd, args, env } = buildCmd(manager, 'install', packages)
    const { stdout } = await runSudo(password, cmd, args, env ? { env } : undefined)
    return { ok: true, output: stdout }
  })

  res.json({ data })
})

// POST /remove — body: {pkg, purge:bool}
router.post('/remove', async (req, res) => {
  const { pkg, purge = false } = req.body
  if (!pkg) throw badRequest('pkg is required')
  validate('pkg', pkg, 'pkg')
  const password = req.sudoPassword

  const data = await withLock(async () => {
    const manager = await detectManager()
    if (manager === 'unknown') throw Object.assign(new Error('No supported package manager found'), { status: 500 })
    const { cmd, args, env } = buildCmd(manager, 'remove', [pkg], purge)
    const { stdout } = await runSudo(password, cmd, args, env ? { env } : undefined)
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

    const sudoPassword = req.sudoPassword
    if (!sudoPassword) {
      res.write(`data: ${JSON.stringify({ error: 'sudo_required' })}\n\n`)
      res.write(`data: ${JSON.stringify({ done: true, code: 1 })}\n\n`)
      res.end()
      pkgLock = false
      return
    }
    const { cmd, args } = buildCmd(manager, 'update')
    const child = streamSudo(
      sudoPassword,
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
  const password = req.sudoPassword

  const data = await withLock(async () => {
    const manager = await detectManager()
    if (manager === 'unknown') throw Object.assign(new Error('No supported package manager found'), { status: 500 })
    const built = buildCmd(manager, 'autoremove')
    const { stdout } = built.shell
      ? await runShell(built.shell)
      : await runSudo(password, built.cmd, built.args, built.env ? { env: built.env } : undefined)
    return { ok: true, output: stdout }
  })

  res.json({ data })
})

module.exports = router
