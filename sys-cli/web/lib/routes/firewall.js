'use strict'

const router = require('express').Router()
const { runSudo, badRequest } = require('../shell')

// Map of sysfs attribute name to its file path
const SYSFS_ATTRS = {
  enabled: '/sys/firewall/enabled',
  drop_icmp: '/sys/firewall/drop_icmp',
  reject_ports: '/sys/firewall/reject_ports',
}

// Read a single sysfs attribute; returns null if the file doesn't exist.
// Re-throws sudo_required so the frontend can show the password modal.
async function readAttr(password, name) {
  const path = SYSFS_ATTRS[name]
  if (!path) return null
  try {
    const { stdout } = await runSudo(password, 'cat', [path])
    return stdout.trim()
  } catch (err) {
    if (err.sudoRequired) throw err
    // Module not loaded — path doesn't exist
    return null
  }
}

// Validate port numbers: each must be 1-65535, comma-separated.
function validatePorts(ports) {
  if (typeof ports !== 'string') throw badRequest('ports must be a string')
  const trimmed = ports.trim()
  if (!trimmed) throw badRequest('ports cannot be empty')
  const parts = trimmed.split(',')
  for (const p of parts) {
    const n = parseInt(p.trim(), 10)
    if (isNaN(n) || n < 1 || n > 65535) {
      throw badRequest(`Invalid port "${p.trim()}": must be 1-65535`)
    }
  }
  return trimmed
}

// Parse a dmesg line into {time, message}.
// Format: "[  1234.567890] text here" or "[1234.567890] text here"
function parseDmesgLine(line) {
  const match = line.match(/^\[\s*([\d.]+)\]\s*(.*)/)
  if (!match) return { time: line, message: '' }
  return { time: match[1], message: match[2] }
}

// GET /status — read all 3 sysfs attributes
router.get('/status', async (req, res) => {
  const pw = req.sudoPassword

  try {
    const [enabled, drop_icmp, reject_ports] = await Promise.all([
      readAttr(pw, 'enabled'),
      readAttr(pw, 'drop_icmp'),
      readAttr(pw, 'reject_ports'),
    ])

    // If none of the attrs exist, the module is not loaded
    if (enabled === null && drop_icmp === null && reject_ports === null) {
      return res.status(503).json({
        error: 'ubuntu_firewall kernel module is not loaded (sysfs path /sys/firewall not found)',
      })
    }

    res.json({
      data: {
        enabled: enabled !== null ? enabled : '0',
        drop_icmp: drop_icmp !== null ? drop_icmp : '0',
        reject_ports: reject_ports !== null ? reject_ports : '',
        status_raw: { enabled, drop_icmp, reject_ports },
      },
    })
  } catch (err) {
    if (err.sudoRequired) throw err
    throw err
  }
})

// GET /logs — fetch dmesg, filter for ubuntu_firewall entries, parse timestamps
router.get('/logs', async (req, res) => {
  const pw = req.sudoPassword
  const { stdout } = await runSudo(pw, 'dmesg', [])

  const logs = stdout
    .split('\n')
    .filter(line => line.includes('ubuntu_firewall'))
    .map(parseDmesgLine)
    .reverse() // newest first
    .slice(0, 50)

  res.json({ data: { logs } })
})

// POST /toggle — write 0 or 1 to a sysfs attribute
router.post('/toggle', async (req, res) => {
  const pw = req.sudoPassword
  const { field, value } = req.body

  if (!field) throw badRequest('field is required')
  if (!['enabled', 'drop_icmp'].includes(field)) {
    throw badRequest('field must be "enabled" or "drop_icmp"')
  }
  if (value === undefined || value === null) throw badRequest('value is required')
  if (value !== 0 && value !== 1 && value !== '0' && value !== '1') {
    throw badRequest('value must be 0 or 1')
  }

  const path = SYSFS_ATTRS[field]
  const strVal = String(value)

  await runSudo(pw, 'bash', ['-c', `echo ${strVal} > ${path}`])

  res.json({ data: { ok: true, field, value: strVal } })
})

// POST /ports — validate and write comma-separated port list
router.post('/ports', async (req, res) => {
  const pw = req.sudoPassword
  const { ports } = req.body

  const validPorts = validatePorts(ports)
  const path = SYSFS_ATTRS.reject_ports

  await runSudo(pw, 'bash', ['-c', `echo "${validPorts}" > ${path}`])

  res.json({ data: { ok: true, ports: validPorts } })
})

// POST /ports/clear — remove all rejected ports
router.post('/ports/clear', async (req, res) => {
  const pw = req.sudoPassword
  const path = SYSFS_ATTRS.reject_ports
  await runSudo(pw, 'bash', ['-c', `echo -n "" > ${path}`])
  res.json({ data: { ok: true, ports: '' } })
})

module.exports = router
