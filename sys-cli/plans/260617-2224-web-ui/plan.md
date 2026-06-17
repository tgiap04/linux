# Plan: sys-cli Web UI

**Date:** 2026-06-17
**Status:** Draft — awaiting approval

## Overview

A Node.js + Express web dashboard for sys-cli. Users access it via browser at `http://<IP>:<PORT>`.
Each module (file, cron, time, pkg, process, network) becomes a page with forms and formatted result cards.
No auth (local network), no build step, no terminal — pure web UI.

## Architecture

```
sys-cli/
├── web/
│   ├── server.js              # Express entry point
│   ├── package.json
│   ├── lib/
│   │   ├── shell.js           # All child_process calls (choke point)
│   │   ├── routes/
│   │   │   ├── files.js       # /api/files/*
│   │   │   ├── cron.js        # /api/cron/*
│   │   │   ├── time.js        # /api/time/*
│   │   │   ├── packages.js    # /api/packages/*
│   │   │   ├── processes.js   # /api/processes/*
│   │   │   └── network.js     # /api/network/*
│   └── public/
│       ├── index.html         # SPA shell + navigation
│       ├── css/
│       │   └── style.css      # Dashboard styling
│       ├── js/
│       │   ├── app.js         # Alpine.js app state + routing
│       │   ├── alpine.min.js  # Alpine.js (vendored)
│       │   └── htmx.min.js    # htmx (vendored)
│       └── views/             # HTML fragments per module
│           ├── files.html
│           ├── cron.html
│           ├── time.html
│           ├── packages.html
│           ├── processes.html
│           └── network.html
```

## Tech Stack

| Layer | Choice | Reason |
|-------|--------|--------|
| Backend | Node.js + Express | Per user preference |
| Frontend | Plain HTML + Alpine.js + htmx | No build step, zero npm frontend deps |
| Shell calls | `child_process.execFile` | No shell spawned → injection-safe |
| Streaming | SSE (Server-Sent Events) | apt upgrade, process monitor — server→client only |
| Security | `helmet`, input allowlisting, `--` separator | Defense-in-depth, no auth |

## Phases

| Phase | File | Status |
|-------|------|--------|
| 01 | [server + shell.js + package.json](phase-01-server-setup.md) | Pending |
| 02 | [API routes](phase-02-api-routes.md) | Pending |
| 03 | [Frontend — index.html + CSS + Alpine](phase-03-frontend.md) | Pending |
| 04 | [Module views (6 HTML fragments)](phase-04-module-views.md) | Pending |

## API Surface

| Method | Endpoint | Action |
|--------|----------|--------|
| GET | `/api/files/large` | Find large files |
| POST | `/api/files/delete` | Delete files by pattern |
| POST | `/api/files/chmod` | Set permissions |
| GET | `/api/cron/list` | List cron jobs |
| POST | `/api/cron/add` | Add cron job |
| DELETE | `/api/cron/:index` | Delete cron job by index |
| POST | `/api/cron/backup` | Setup backup cron |
| GET | `/api/time/status` | Show time/timezone |
| POST | `/api/time/timezone` | Set timezone |
| POST | `/api/time/ntp` | Enable NTP |
| GET | `/api/packages/detect` | Detect package manager |
| POST | `/api/packages/install` | Install packages |
| POST | `/api/packages/remove` | Remove/purge package |
| GET | `/api/packages/update/stream` | System update (SSE stream) |
| GET | `/api/processes/list` | List top processes |
| POST | `/api/processes/kill` | Kill process |
| GET | `/api/processes/port/:port` | Find process by port |
| GET | `/api/network/sockets` | List sockets |
| GET | `/api/network/interfaces` | Show interfaces |
| GET | `/api/network/routes` | Show routes |
| POST | `/api/network/ping` | Test connectivity |
| POST | `/api/network/dns` | DNS lookup |
| GET | `/api/network/firewall` | Firewall status |

## Security Model

- `execFile` only — never `exec()` with string interpolation
- All user input allowlisted with regex before touching shell
- `helmet` middleware on all responses
- `express-rate-limit` — max 30 req/min per IP
- No auth (per user choice) — bind `0.0.0.0`, document "use on trusted LAN only"
- Concurrent-unsafe operations (pkg install/update) serialized via in-memory lock flag
