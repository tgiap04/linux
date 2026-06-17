# Research Report: Node.js + Express Web UI for sys-cli

**Date:** 2026-06-17  
**Sources:** Node.js official docs, OWASP OS Command Injection Cheat Sheet, MDN SSE docs, htmx docs, Alpine.js docs — 5 authoritative sources.

---

## Summary

Building a web dashboard over the existing bash modules is well-supported by Node.js. The safe, idiomatic pattern is: `execFile()` or `spawn()` with argument arrays (never `exec()` with user input), SSE for streaming long-running commands, htmx as the frontend (no build step, server-rendered HTML), and `sudoers NOPASSWD` targeted to specific scripts for privilege escalation. Wholesale use of `exec()` + shell strings is the single highest-risk mistake.

---

## Q1: child_process — Which API to Use

**Decision matrix:**

| API | Shell? | I/O | Block event loop | Use case in this project |
|---|---|---|---|---|
| `execFile()` | No | Buffered | No | Most commands: list files, kill PID, set timezone |
| `spawn()` | No | Streamed | No | Long-running: `apt upgrade`, `apt update`, process monitor |
| `exec()` | **Yes** | Buffered | No | AVOID with user input — only for internal, no-user-input commands |
| `execSync()` | Yes | Buffered | **Yes** | Startup checks only, never in request handlers |

**Ruling:** Use `execFile(scriptPath, argsArray)` as the default. Only switch to `spawn()` when you need to stream output to the browser. Never use `exec()` or `execSync()` in request handlers — they either open shell injection or block the event loop.

The existing bash modules already encapsulate the logic: the Node layer calls `execFile('./lib/pkg-mgmt.sh', ['install', 'nginx'])`, not raw `apt-get`.

---

## Q2: Streaming Long-Running Commands — SSE vs WebSocket

**Verdict: SSE wins for this use case.**

| Factor | SSE | WebSocket |
|---|---|---|
| Direction | Server → client only | Bidirectional |
| Protocol | Plain HTTP | Upgraded `ws://` |
| Auto-reconnect | Built-in | Manual |
| Proxy/load-balancer compat | Excellent | Requires config |
| Implementation effort | ~15 LOC | ~50 LOC + library |
| Binary support | No (text only) | Yes |

Command output (`apt upgrade`, `journalctl -f`) is pure server→client text. SSE is the right tool. WebSocket is overkill unless a future requirement needs bidirectional communication (e.g., interactive shell in browser — explicitly out of scope for this dashboard).

**Node.js SSE pattern (Express):**
```js
app.get('/stream/pkg-upgrade', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  const child = spawn('./sys-cli.sh', ['pkg', 'upgrade'], { stdio: ['ignore', 'pipe', 'pipe'] });

  child.stdout.on('data', chunk => res.write(`data: ${chunk.toString().trim()}\n\n`));
  child.stderr.on('data', chunk => res.write(`data: [stderr] ${chunk.toString().trim()}\n\n`));
  child.on('close', code => {
    res.write(`data: [done] exit ${code}\n\n`);
    res.end();
  });

  req.on('close', () => child.kill());
});
```

---

## Q3: Shell Injection Prevention

**Hierarchy (apply all layers, in order):**

1. **Never use `exec()` / `execSync()` with user input.** These always spawn a shell.
2. **Use `execFile()` or `spawn()` with argument arrays.** Shell metacharacters (`&`, `|`, `;`, `$`, `` ` ``) are passed as literals, not interpreted.
3. **Allowlist all user input before use.** Per OWASP:
   - Package names: `/^[a-z0-9][a-z0-9\-\+\.]+$/i`
   - PIDs: `/^\d+$/`
   - File paths: resolve with `path.resolve()`, then verify prefix is within allowed base dir
   - Timezones: match against a fixed list (`fs.readFileSync('/usr/share/zoneinfo/...', 'utf8')`)
4. **Pass `--` before user-controlled arguments** to signal end-of-options to POSIX commands.
5. **Run the web process as a non-root user.** Privilege escalation only via targeted `sudoers` (see Q5).

**NEVER do:**
```js
exec(`apt-get install ${req.body.pkg}`);         // shell injection
exec(`kill ${req.body.pid}`);                     // shell injection
```

**DO:**
```js
const pkg = req.body.pkg;
if (!/^[a-z0-9][a-z0-9\-\+\.]+$/.test(pkg)) return res.status(400).send('Invalid package name');
execFile('sudo', ['apt-get', 'install', '-y', '--', pkg], callback);
```

---

## Q4: Frontend Approach

**Ranked choice: htmx (first), Alpine.js (complementary, not an alternative)**

**htmx:**
- No build step — single `<script>` tag from CDN
- `hx-get/post` on any element — buttons trigger API calls, server returns HTML fragments
- `hx-swap="innerHTML"` replaces table content, `hx-swap="beforeend"` appends log lines
- Built-in polling (`hx-trigger="every 2s"`) for live process/network status
- SSE extension (`hx-ext="sse"`) handles streaming output with zero JS
- ~14 KB minified. No npm, no Webpack, no JSX.

**Alpine.js (additive):**
- Use alongside htmx for in-page interactivity: modal toggles, conditional rendering (`x-show`), form state
- `x-model` for reactive inputs, `$store` for shared state (selected PID, active tab)
- ~7-10 KB minified. Same no-build-step story.

**Rejected options:**
- React/Vue/Svelte: require build toolchain, SPA mental model, overkill for a sysadmin tool that runs server-rendered HTML
- Plain vanilla JS: viable but creates custom event-binding boilerplate that htmx solves declaratively

**Recommended stack:** Express renders EJS/plain HTML templates → htmx handles AJAX + SSE → Alpine.js for UI state. Zero build step.

---

## Q5: sudo from a Web Process — Patterns and Security

**Context:** The existing scripts already use `sudo` (e.g., `sudo apt-get install -y "${pkgs[@]}"`). The web process must replicate this.

**Safe pattern: targeted `sudoers NOPASSWD` entries**

```sudoers
# /etc/sudoers.d/sys-cli-web
www-data ALL=(ALL) NOPASSWD: /path/to/sys-cli/lib/pkg-mgmt.sh *
www-data ALL=(ALL) NOPASSWD: /path/to/sys-cli/lib/process-mgmt.sh *
www-data ALL=(ALL) NOPASSWD: /path/to/sys-cli/lib/network-mgmt.sh *
```

Rules:
- Grant `NOPASSWD` only for the specific scripts, not `/bin/bash` or `ALL`
- Scripts must not be world-writable (`chmod 750`, owned by root)
- Do NOT use `NOPASSWD: ALL` — that grants full root to any request

**What to avoid:**
- `process.env.SUDO_PASSWORD` stored in env and piped to stdin — any code execution = full root
- Running the entire Node.js web process as root — all injection becomes root injection
- `shell: true` + `sudo` + user input — worst possible combination

**Adoption risk:** This pattern is standard for web-managed system tools (Cockpit, Webmin use similar mechanisms). Risk is low if script ownership/permissions are locked down.

---

## Q6: Project Structure

Co-locate the web UI in the same repo under a `web/` directory. The bash modules stay untouched — the Node layer is a thin adapter.

```
sys-cli/
├── sys-cli.sh              # existing entry point (unchanged)
├── lib/                    # existing bash modules (unchanged)
│   ├── pkg-mgmt.sh
│   ├── process-mgmt.sh
│   └── ...
├── web/
│   ├── server.js           # Express app entry point
│   ├── routes/
│   │   ├── files.js        # wraps lib/file-mgmt.sh
│   │   ├── cron.js         # wraps lib/cron-mgmt.sh
│   │   ├── time.js
│   │   ├── packages.js
│   │   ├── processes.js
│   │   └── network.js
│   ├── views/              # EJS/plain HTML templates
│   │   ├── layout.html
│   │   ├── packages.html
│   │   └── ...
│   ├── public/
│   │   ├── htmx.min.js     # vendored, no CDN dependency in prod
│   │   └── alpine.min.js
│   ├── lib/
│   │   ├── shell.js        # execFile/spawn wrappers + allowlist validators
│   │   └── sanitize.js     # input validation helpers
│   └── package.json
└── docs/
```

**Key principle:** `web/lib/shell.js` is the only file that calls `child_process`. All routes import from it. This centralizes the security boundary.

---

## Q7: Essential npm Packages (Minimal)

| Package | Purpose | Alternative |
|---|---|---|
| `express` | HTTP server + routing | None — baseline |
| `express-async-errors` | Catches async errors without try/catch boilerplate | Manual try/catch everywhere |
| `helmet` | HTTP security headers (XSS, CSRF, etc.) | Manual header setting |
| `express-rate-limit` | Prevent abuse of command endpoints | None if internal-only |
| `ejs` | Server-side templating (if not using plain HTML) | `pug`, plain string templates |

**Do NOT add:**
- `socket.io` — SSE is sufficient; socket.io adds 40 KB + complexity
- `shelljs` — abstraction over child_process; you want direct control for security
- Any body parser beyond `express.json()` + `express.urlencoded()` (built into Express 4.16+)

**Total production deps: 3–5 packages.** This is intentional — each additional package is an attack surface.

---

## Trade-Off Summary

| Decision | Chosen | Rejected | Reason |
|---|---|---|---|
| Shell API | `execFile()` + arg arrays | `exec()` + shell strings | Shell injection prevention |
| Streaming | SSE | WebSocket | Simpler, auto-reconnect, server→client only |
| Frontend | htmx + Alpine.js | React/Vue | No build step, server-rendered model, lower complexity |
| Privilege | Targeted sudoers NOPASSWD | Run as root | Least-privilege principle |
| Structure | `web/` subdir in same repo | Separate repo | Co-location, single deploy unit |

---

## Adoption Risk

- **htmx:** v2.0 released 2024, stable, 39k+ GitHub stars, OWASP uses it in their tools, MIT license. Low abandonment risk.
- **Alpine.js:** v3.x stable since 2021, 29k+ stars, actively maintained. Low risk.
- **Express:** Still the de-facto Node.js server (Fastify is faster but Express has more ecosystem). Low risk for internal tool.
- **SSE:** Browser baseline "Widely Available" since 2020. No library dependency. Zero adoption risk.

---

## Unresolved Questions

1. **Auth:** No authentication layer researched. If the dashboard is exposed beyond localhost, session-based auth (e.g., `express-session` + password) or mTLS is required. This is a blocking security gap.
2. **Multi-distro sudo paths:** The `sudoers` entries use absolute script paths. If deployed on multiple distros where install paths differ, a deployment script must generate correct entries.
3. **Concurrent command safety:** What happens if two browser sessions run `apt upgrade` simultaneously? Locking/queue mechanism not researched.
4. **CSRF protection:** POST endpoints that trigger system commands need CSRF tokens if accessed from a browser. `helmet` sets some headers but a CSRF token library may be needed.
