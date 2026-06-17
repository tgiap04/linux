# Phase 02: API Routes

**Priority:** High
**Status:** Pending
**Blocked by:** Phase 01

## Files to Create

- `web/lib/routes/files.js`
- `web/lib/routes/cron.js`
- `web/lib/routes/time.js`
- `web/lib/routes/packages.js`
- `web/lib/routes/processes.js`
- `web/lib/routes/network.js`

## Pattern for every route file

```js
const router = require('express').Router()
const { run, stream, validate } = require('../shell')
// ... routes ...
module.exports = router
```

Each route returns JSON `{ data: ... }` on success, throws on error (caught by global handler).

---

## files.js

| Route | Shell cmd | Validate |
|-------|-----------|----------|
| `GET /large?dir=&size=` | `find "$dir" -type f -size "+$size" -printf '%s\t%p\n' \| sort -rn \| head -20` | path, size (e.g. 100M) |
| `POST /delete` body: `{dir, pattern}` | `find "$dir" -name "$pattern" -delete` | path, pattern (glob chars only) |
| `POST /chmod` body: `{dir, fmode, dmode, owner}` | sequential: find+chmod for dirs, files, then chown | path, mode, owner |

All use `execFile('bash', ['-c', cmd])` — wrap in shell only where pipelines are needed. Validate all inputs first.

---

## cron.js

| Route | Action |
|-------|--------|
| `GET /list` | `crontab -l 2>/dev/null`, parse into array of `{index, entry}` |
| `POST /add` body: `{min,hour,day,month,wday,cmd}` | validate each cron field, assemble entry, idempotency check, add |
| `DELETE /:index` | snapshot crontab, remove line by index (awk), rewrite |
| `POST /backup` body: `{src, dest, schedule}` | assemble tar entry, add to crontab |

Cron field validation: each field must match `/^[\d*,\/-]+$/` or be `*`.

---

## time.js

| Route | Action |
|-------|--------|
| `GET /status` | `timedatectl status` or `date` fallback, return parsed object |
| `GET /timezones?filter=` | `timedatectl list-timezones`, return array |
| `POST /timezone` body: `{tz}` | validate tz format, check `/usr/share/zoneinfo/$tz` exists, `sudo timedatectl set-timezone "$tz"` |
| `POST /ntp` | `sudo timedatectl set-ntp true` |
| `GET /ntp-status` | `timedatectl timesync-status` |

---

## packages.js

In-memory mutex to prevent concurrent installs:
```js
let pkgLock = false
function withLock(fn) {
  if (pkgLock) throw Object.assign(new Error('A package operation is already running'), { status: 409 })
  pkgLock = true
  return fn().finally(() => { pkgLock = false })
}
```

| Route | Action |
|-------|--------|
| `GET /detect` | detect pkg manager, return `{ manager }` |
| `POST /install` body: `{packages: []}` | validate each pkg name, install via detected manager |
| `POST /remove` body: `{pkg, purge}` | validate pkg name, remove/purge + autoremove |
| `GET /update/stream` | SSE stream of `apt-get upgrade -y` output (or dnf/yum/pacman) |
| `POST /autoremove` | run autoremove for detected manager |

SSE pattern:
```js
res.setHeader('Content-Type', 'text/event-stream')
res.setHeader('Cache-Control', 'no-cache')
stream('sudo', ['apt-get', 'upgrade', '-y'],
  data => res.write(`data: ${JSON.stringify({ line: data })}\n\n`),
  code => { res.write(`data: ${JSON.stringify({ done: true, code })}\n\n`); res.end() }
)
```

---

## processes.js

| Route | Action |
|-------|--------|
| `GET /list?sort=cpu\|mem` | `ps aux --sort=-%cpu` or `--sort=-%mem`, parse into array of objects |
| `POST /kill` body: `{pid, signal}` | validate numeric pid, send TERM first, return `{ sent: 'TERM' }` |
| `POST /kill-force` body: `{pid}` | validate pid, SIGKILL |
| `GET /port/:port` | `ss -tulpn \| grep ":$port"`, return matches |

Parse `ps aux` output into structured JSON:
```js
// Fields: USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
lines.slice(1).map(line => {
  const [user, pid, cpu, mem, ...rest] = line.trim().split(/\s+/)
  return { user, pid, cpu, mem, command: rest.slice(6).join(' ') }
})
```

---

## network.js

| Route | Action |
|-------|--------|
| `GET /sockets` | `ss -tulpn`, parse into structured array |
| `GET /interfaces` | `ip addr show`, parse interfaces |
| `GET /routes` | `ip route show`, parse routes, flag default |
| `POST /ping` body: `{host}` | validate host, `ping -c 3 -W 2 "$host"`, return parsed stats |
| `POST /dns` body: `{target}` | validate host, try `dig +short` then `getent hosts` fallback |
| `GET /firewall` | detect ufw/firewall-cmd/iptables/nft, return status |

## Success Criteria

- All routes return `{ data: ... }` JSON
- Invalid input (bad path, bad PID, bad pkg name) returns 400 before any shell call
- Package install/update rejects concurrent calls with 409
- SSE stream ends with `{ done: true, code: N }`
