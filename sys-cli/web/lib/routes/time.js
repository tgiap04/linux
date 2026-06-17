'use strict'

const router = require('express').Router()
const { run, runSudo, badRequest, validate } = require('../shell')

// Try timedatectl; if ENOENT fall back to `date`
async function getTimedatectl() {
  try {
    const { stdout } = await run('timedatectl', ['status'])
    return { tool: 'timedatectl', output: stdout }
  } catch (err) {
    if (err.code === 'ENOENT') {
      const { stdout } = await run('date')
      return { tool: 'date', output: stdout }
    }
    throw err
  }
}

// Parse timedatectl status output into structured object
function parseTimedatectl(output) {
  const get = key => {
    const m = output.match(new RegExp(`${key}:\\s*(.+)`))
    return m ? m[1].trim() : null
  }
  return {
    datetime: get('Local time') || get('Universal time') || output.split('\n')[0] || '',
    timezone: get('Time zone'),
    ntpSync: /synchronized: yes/i.test(output) || /NTP synchronized: yes/i.test(output),
  }
}

// GET /status
router.get('/status', async (req, res) => {
  const { tool, output } = await getTimedatectl()

  let data
  if (tool === 'timedatectl') {
    data = parseTimedatectl(output)
  } else {
    data = { datetime: output, timezone: null, ntpSync: null }
  }

  res.json({ data })
})

// GET /timezones?filter=
router.get('/timezones', async (req, res) => {
  const { filter = '' } = req.query

  try {
    const { stdout } = await run('timedatectl', ['list-timezones'])
    let zones = stdout.split('\n').filter(Boolean)
    if (filter) {
      const lc = filter.toLowerCase()
      zones = zones.filter(z => z.toLowerCase().includes(lc))
    }
    res.json({ data: zones })
  } catch (err) {
    if (err.code === 'ENOENT') {
      // Fallback: list from zoneinfo directory
      const { stdout } = await run('find', ['/usr/share/zoneinfo', '-type', 'f'])
      let zones = stdout
        .split('\n')
        .filter(Boolean)
        .map(p => p.replace('/usr/share/zoneinfo/', ''))
        .filter(z => !z.includes('posix/') && !z.includes('right/') && z.includes('/'))
      if (filter) {
        const lc = filter.toLowerCase()
        zones = zones.filter(z => z.toLowerCase().includes(lc))
      }
      res.json({ data: zones })
    } else {
      throw err
    }
  }
})

// POST /timezone — body: {tz}
router.post('/timezone', async (req, res) => {
  const { tz } = req.body
  if (!tz) throw badRequest('tz is required')
  validate('tz', tz, 'tz')

  // Verify zone file exists
  try {
    await run('test', ['-f', `/usr/share/zoneinfo/${tz}`])
  } catch {
    throw badRequest(`Unknown timezone: "${tz}"`)
  }

  await runSudo(req.sudoPassword, 'timedatectl', ['set-timezone', tz])

  // Return the new time after setting
  const { stdout } = await run('date')
  res.json({ data: { ok: true, newTime: stdout } })
})

// POST /ntp — enable NTP sync
router.post('/ntp', async (req, res) => {
  await runSudo(req.sudoPassword, 'timedatectl', ['set-ntp', 'true'])
  res.json({ data: { ok: true } })
})

// GET /ntp-status
router.get('/ntp-status', async (req, res) => {
  try {
    const { stdout } = await run('timedatectl', ['timesync-status'])
    res.json({ data: { raw: stdout } })
  } catch (err) {
    if (err.code === 'ENOENT' || err.stderr?.includes('Unknown command')) {
      // Fallback: parse from timedatectl status
      const { stdout } = await run('timedatectl', ['status'])
      res.json({ data: { raw: stdout } })
    } else {
      throw err
    }
  }
})

module.exports = router
