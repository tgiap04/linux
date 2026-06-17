# Code Review: sys-cli Web UI

**Date:** 2026-06-17
**Score:** 7.5 / 10
**Verdict:** APPROVED_WITH_NOTES

---

## Scope
- `server.js`, `lib/shell.js`
- `lib/routes/files.js`, `cron.js`, `time.js`, `packages.js`, `processes.js`, `network.js`
- `public/js/app.js`
- `public/views/processes.html`, `network.html`, `packages.html`, `files.html`, `cron.html`, `time.html`

---

## Overall Assessment

Architecture is solid. Shell execution is correctly funnelled through a single choke point (`lib/shell.js`) using `execFile`/`spawn` with array arguments. Validators cover all input types. Route files are clean and consistent. Frontend uses Alpine.js text-binding (`x-text`) throughout — no raw `innerHTML`/`x-html` injections. Destructive actions (kill, file delete, cron delete) are modal-gated. Several correctness bugs and one meaningful security gap need fixing before production confidence is high.

---

## Critical Issues

### C1 — DNS endpoint: frontend uses GET query param; backend expects POST body (broken feature)
**Severity: Critical (functional breakage)**

`network.html` line 344 calls:
```
GET /api/network/dns?query=<value>
```
`network.js` line 122–123 defines:
```js
router.post('/dns', async (req, res) => {
  const { target } = req.body
```
The method is `POST` and reads `req.body.target`, but the frontend does `GET` with `query=`. Result: `target` is always `undefined` → `badRequest('target is required')` on every DNS lookup. DNS tab is completely non-functional.

**Fix:** Either change frontend to `POST { target: this.dnsQuery }`, or change the route to `GET` and read `req.query.target`. Backend validator name (`target`) must also align with whatever key is sent.

---

### C2 — Cron add: frontend sends `{ entry }` (full string); backend destructures `{ min, hour, day, month, wday, cmd }`
**Severity: Critical (functional breakage)**

`cron.html` line 217:
```js
body: JSON.stringify({ entry })
```
`cron.js` line 35:
```js
const { min, hour, day, month, wday, cmd } = req.body
```
All six fields will be `undefined`. The `for` loop on line 36 throws `badRequest('min is required')` immediately. Add cron job feature is completely non-functional.

**Fix:** Frontend must send `{ min, hour, day, month, wday, cmd }` as separate fields, not a pre-assembled string. Or backend must accept `{ entry }` and split/validate it.

---

### C3 — files.js: single-file delete endpoint accepts `{ path }` but route only handles `{ dir, pattern }`
**Severity: Critical (data loss path)**

`files.html` `executeDelete()` (line 192) sends:
```js
{ path }
```
`files.js` `POST /delete` (line 45) reads:
```js
const { dir, pattern } = req.body
```
`dir` is `undefined` → `badRequest('dir is required')`. Single-file delete is non-functional. However if `dir` were somehow present but `pattern` missing, the route would silently fail in the count step and delete nothing. The path is never used as an individual file delete target. This is a **missing code path** — there is no route that deletes a single file by path.

**Fix:** Add a separate endpoint `POST /delete/single` that accepts `{ path }`, validates `path` validator, and runs `run('rm', ['-f', '--', path])` — no shell template needed. Or extend the existing route to branch on whether `pattern` is present.

---

### C4 — packages.js: `remove` route expects `{ pkg }` (singular); frontend sends `{ packages: [...], purge }`
**Severity: Critical (functional breakage)**

`packages.html` line 152:
```js
body: JSON.stringify({ packages: names, purge: this.purge })
```
`packages.js` line 84:
```js
const { pkg, purge = false } = req.body
```
`pkg` is `undefined` → `badRequest('pkg is required')`. Remove Package card is non-functional.

**Fix:** Either change the backend to `const { packages, purge } = req.body` + `validate('pkgList', packages)` + `buildCmd(manager, 'remove', packages, purge)`, or change the frontend to send `{ pkg: names[0], purge }` (single-package only).

---

## Important Issues

### H1 — time.js: frontend sends `{ timezone }` key; backend reads `{ tz }`
**Severity: High (broken feature)**

`time.html` line 158:
```js
body: JSON.stringify({ timezone: tz })
```
`time.js` line 81:
```js
const { tz } = req.body
```
`tz` is `undefined` → `badRequest('tz is required')`. Change Timezone is non-functional.

**Fix:** Align the key — either send `{ tz }` from the frontend or read `req.body.timezone` in the backend.

---

### H2 — `runShell` used with interpolated user-controlled values in files.js
**Severity: High (injection surface)**

`files.js` lines 26–28, 54–55, 59:
```js
`find "${dir}" -type f -size "+${size}" ...`
`find "${dir}" -name "${pattern}" ...`
```
Both `dir` and `size`/`pattern` pass through validators before reaching these calls, so the immediate risk is mitigated. However the `path` validator regex `^[\w./\s~-]+$` permits whitespace (`\s`). A path value like `/tmp /etc` passes validation and would be interpreted by `bash -c` as two separate arguments to `find`. This bypasses `execFile`'s argument array boundary.

**Fix:** Remove `\s` from the `path` validator regex, or use `execFile` with an array instead of `runShell` for the `find` calls. The `size` validator `^\d+[KMGkmg]$` is clean; no issue there.

---

### H3 — pacman autoremove uses shell subshell inside args array (dead code but wrong pattern)
**Severity: High (if ever reached)**

`packages.js` line 52:
```js
args: ['pacman', '-Rns', '--noconfirm', '$(pacman -Qtdq)']
```
This passes `$(pacman -Qtdq)` as a literal string argument to `sudo`. With `execFile`, shell expansion is suppressed, so the command will fail silently or error — but it documents a misunderstanding of how `execFile` works. The correct pattern is to capture the output of `pacman -Qtdq` first (via `run`), then pass the packages list as an array.

**Fix:** Replace with:
```js
const { stdout } = await run('pacman', ['-Qtdq'])
const orphans = stdout.split('\n').filter(Boolean)
if (orphans.length) return { cmd: 'sudo', args: ['pacman', '-Rns', '--noconfirm', ...orphans] }
```

---

### H4 — CSP disabled for inline scripts in views
**Severity: High (defense-in-depth gap)**

`server.js` line 13:
```js
app.use(helmet({ contentSecurityPolicy: false }))
```
The comment acknowledges inline scripts in views. This is an accepted trade-off for the current architecture, but it means XSS via a reflected error message or future template interpolation has no browser-level backstop.

**Note:** No current `x-html` or `innerHTML` usage was found. Recommend moving view `<script>` tags to separate `.js` files so CSP can be re-enabled with a strict policy.

---

### H5 — Rate limiter too loose for a privileged system manager
**Severity: High**

120 requests per 60 seconds (2 req/s) is trivially bypassable for brute-force or abuse. A local sys-cli UI running as root-equivalent (via `sudo` calls) should apply a much stricter limit, or apply authentication middleware. No authentication is present at all.

**Note:** If this is LAN-only and behind a firewall, the risk is reduced but not eliminated (SSRF from browser extensions, malicious LAN devices, etc.).

---

## Minor Issues

### M1 — `cron.html`: jobs array stores full entry strings but table renders `x-text="job"` instead of `x-text="job.entry"`
The backend `/api/cron/list` returns `[{index, entry}]` objects. The frontend stores `json.data` directly into `this.jobs`, then renders `x-text="job"` — this would display `[object Object]`. If the backend is ever fixed to return what its comment says, this will silently break.

**Fix:** Either flatten to strings on receipt `this.jobs = (json.data || []).map(j => j.entry)`, or use `x-text="job.entry"` in the template. Both are fine; pick one and be consistent.

---

### M2 — `/api/processes/port/:port` returns an array; frontend treats it as a single object
`processes.js` returns `json.data` as an array of matched socket rows. `processes.html` line 80 renders:
```js
`PID ${portResult.pid} — ...`
```
`portResult.pid` will be `undefined` because the response is an array. The first match should be extracted: `this.portResult = json.data[0] || null`.

---

### M3 — `network.html`: `firewallOutput` assigned `json.data` which is `{tool, output}` object, not a string
`network.js` returns `{ data: { tool, output } }`. Frontend line 363:
```js
this.firewallOutput = json.data || '(no output)'
```
This sets `firewallOutput` to the whole object. `x-text="firewallOutput"` renders `[object Object]`.

**Fix:** `this.firewallOutput = json.data?.output || '(no output)'`

---

### M4 — SSE `done` event uses `d.exitCode` but server sends `code`
`packages.html` line 185:
```js
d.exitCode === 0 ? 'success' : 'warning'
```
`packages.js` line 127 sends `{ done: true, code }`. The field is `code`, not `exitCode`. The toast will always show "warning" because `undefined === 0` is false.

**Fix:** Use `d.code` on the frontend.

---

### M5 — `time.html` displays `status.localTime` / `status.utcTime` but backend returns `status.datetime`
`time.js` `parseTimedatectl` returns `{ datetime, timezone, ntpSync }`. Frontend references `status.localTime` and `status.utcTime` — both will be `undefined` (empty cards).

**Fix:** Either rename backend key to match, or update frontend to use `status.datetime`.

---

### M6 — `/api/time/ntp-status` returns `{ raw }` but frontend reads `json.data` directly as a string
`time.js` line 108: `res.json({ data: { raw: stdout } })`.
`time.html` line 197: `this.ntpStatus = json.data || '(no output)'`.
`x-text="ntpStatus"` will render `[object Object]`.

**Fix:** `this.ntpStatus = json.data?.raw || '(no output)'`

---

### M7 — Batch delete in `files.html` uses browser `confirm()` instead of the modal pattern used everywhere else
Inconsistent UX. Minor, but the modal pattern is better for a dark-theme sys-cli UI and avoids browser dialog styling quirks. Low priority.

---

### M8 — `glob` validator `^[\w.*?[\]-]+$` permits `]` without a matching `[`
Not exploitable through `execFile` array args or the `find -name` pattern, but an odd edge in the validator.

---

## Positive Observations

- Shell choke-point pattern is excellent — `lib/shell.js` is clean, single responsibility
- `execFile` used everywhere except the two `runShell` cases, which are explicitly labelled
- `express-async-errors` ensures unhandled promise rejections propagate to the error handler
- Global error handler returns structured JSON and logs 5xx server-side only
- Packages mutex correctly prevents concurrent `apt-get` races
- Cron delete uses line-index snapshot (not grep -vF) — correctly avoids duplicate-line hazard
- Cron gracefully handles empty crontab (exit code 1 check on line 12-17)
- SSE stream ends with `{done:true,code}` and handles client disconnect (`req.on('close')`)
- All views use `x-data` isolation, no `<html>/<head>/<body>` wrapper tags
- Kill and file delete both gate behind confirm modals; cron delete likewise
- No `x-html` or `innerHTML` usage — XSS surface is minimal
- Timezone change verifies zone file exists before applying (`run('test', ['-f', ...])`)

---

## Recommended Actions (Priority Order)

1. **[Critical]** Fix cron add frontend → send `{min,hour,day,month,wday,cmd}` not `{entry}` (C2)
2. **[Critical]** Fix DNS: align method + field name (C1)
3. **[Critical]** Add single-file delete endpoint or extend existing route to handle `{path}` (C3)
4. **[Critical]** Fix packages remove: align `{packages}` vs `{pkg}` (C4)
5. **[High]** Fix timezone set: align `{timezone}` vs `{tz}` (H1)
6. **[High]** Fix M1 (cron jobs array rendering), M2 (portResult), M3 (firewallOutput), M4 (SSE exitCode), M5 (status.datetime), M6 (ntpStatus.raw)
7. **[High]** Remove `\s` from `path` validator to prevent whitespace injection (H2)
8. **[High]** Fix pacman autoremove to capture `pacman -Qtdq` output first (H3)
9. **[Medium]** Add authentication — even HTTP Basic Auth would reduce risk surface for a root-capable tool (H5)

---

## Unresolved Questions

- Is this intended to run as the same user as the process, or does it require passwordless `sudo`? If passwordless sudo is required, the attack surface of the unauthenticated HTTP API is much larger.
- Is the `path` validator's `\s` intentional (to support paths with spaces)?
