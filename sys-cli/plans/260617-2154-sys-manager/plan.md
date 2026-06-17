# Plan: sys-manager — Linux System Management Shell Script

**Date:** 2026-06-17
**Status:** Complete

## Overview

A modular bash script suite (`sys-cli`) for Linux system management covering 6 domains:
1. File & Directory Management
2. Cron Job Scheduling
3. System Time Management
4. Package Management (apt/dnf/yum/pacman)
5. Process Management
6. File Descriptors, Sockets & Network Management

## Architecture

```
sys-cli/
├── sys-cli.sh          # entry point & main menu
└── lib/
    ├── common.sh       # shared: die(), confirm(), color vars, require_root()
    ├── file-mgmt.sh    # US1.x — file operations
    ├── cron-mgmt.sh    # US2.x — cron job management
    ├── time-mgmt.sh    # US3.x — timezone & NTP
    ├── pkg-mgmt.sh     # US4.x — package manager
    ├── process-mgmt.sh # process list/kill/monitor/tree/port lookup
    └── network-mgmt.sh # sockets, interfaces, routing, DNS, firewall
```

## Phases

| Phase | File | Status |
|-------|------|--------|
| 01 | [common.sh + entry point](phase-01-common-entrypoint.md) | Complete |
| 02 | [file-mgmt.sh](phase-02-file-mgmt.md) | Complete |
| 03 | [cron-mgmt.sh](phase-03-cron-mgmt.md) | Complete |
| 04 | [time-mgmt.sh](phase-04-time-mgmt.md) | Complete |
| 05 | [pkg-mgmt.sh](phase-05-pkg-mgmt.md) | Complete |
| 06 | [process-mgmt.sh](phase-06-process-mgmt.md) | Complete |
| 07 | [network-mgmt.sh](phase-07-network-mgmt.md) | Complete |

## Design Decisions

- **Menus:** `select` builtin (zero-dep), `whiptail` as optional enhancement
- **Privilege:** per-command `sudo` (Pattern B) — script runs as normal user
- **Distros:** Debian/Ubuntu (apt), RHEL/CentOS/Fedora (dnf/yum), Arch (pacman)
- **Timezone:** `timedatectl` primary, `/etc/localtime` symlink fallback
- **Error handling:** `set -euo pipefail` + `trap cleanup EXIT INT TERM`
- **Safety:** `confirm()` gates before all destructive ops
- **Fallbacks:** every network/process op has `/proc` fallback — zero mandatory new deps
- **Kill pattern:** SIGTERM → 5s grace → SIGKILL (never silent force-kill)
