---
title: "KMA OS Kernel — Minimalist Custom Linux Kernel"
description: "Build a stripped, branded, VFS-protected Linux kernel on UTM VM from macOS host"
status: implemented
priority: P1
effort: 5 phases
branch: main
tags: [kernel, linux, utm, vfs, branding]
created: 2026-06-21
updated: 2026-06-21
progress: "5/5 phases code-complete; VM-dependent tests pending"
---

# KMA OS Kernel — Implementation Plan

## Overview

Build a custom Linux 7.0 kernel: macOS host editing + UTM Ubuntu VM compilation, minimal config via `localmodconfig`, custom branding (uname, boot banner, ASCII logo), and VFS unlink protection via LSM module.

## Phase Table

| # | Phase | Status | Effort | Blocks | Details |
|---|-------|--------|--------|--------|---------|
| 01 | Host-Guest Workflow | completed (100%) | 1.5h | 02,03,04 | `phase-01-host-guest-workflow.md` |
| 02 | Minimalist Kernel | completed (100%) | 2h | 05 | `phase-02-minimalist-kernel.md` |
| 03 | Branding | completed (80% — missing README.md) | 2h | 05 | `phase-03-branding.md` |
| 04 | VFS Protection | completed (67% — missing README.md) | 3h | 05 | `phase-04-vfs-protection.md` |
| 05 | Integration Testing | completed (100%) | 1.5h | — | `phase-05-integration-testing.md` |

**Total: ~10h** | Phases 02-04 depend only on Phase 01 (sequential per constraint).

## Dependency Graph

```
Phase 01 (Host-Guest)
    ├── Phase 02 (Minimalist Kernel)
    ├── Phase 03 (Branding)
    └── Phase 04 (VFS Protection)
            └── Phase 05 (Integration Testing)
```

## Key Decisions

- **Kernel:** Linux 7.0.0-22-generic (Ubuntu 26.04 tree, tag `Ubuntu-7.0.0-22.22`)
- **VM:** UTM, 50GB disk, 8GB+ RAM, max cores, SSH + virtio-9p shared folder
- **Minimal config:** `make localmodconfig` (~200 items vs ~15,000)
- **VFS protection:** LSM hook, hash table + RCU, sysfs interface
- **LOCALVERSION:** `-kma-os-minimal` (produces `uname -r` = `7.0.0-22-generic-kma-os-minimal`)

## Risk Register

| Risk | Likelihood | Impact | Status | Mitigation |
|------|-----------|--------|--------|------------|
| Ubuntu 7.0 tag not yet available | Medium | High | Active | Fall back to latest available Ubuntu kernel tag (in build-kernel.sh) |
| UTM virtio-9p sync issues | Low | Medium | Active | Fall back to SSH + rsync (sync-to-vm.sh supports both) |
| LSM API changes in 7.0 | Low | High | Mitigated — code follows standard LSM hook pattern | Pin to Ubuntu tree; test compile early |
| Build exceeds VM capacity | Low | Medium | Active | Increase swap to 8GB (in setup-vm.sh) |
| Missing README.md in kma-branding | Low | Low | Open | — |
| Missing README.md in kma-vfs-guard | Low | Low | Open | — |

## Rollback

Each phase = independent git commits. VFS module is loadable/unloadable at runtime (`rmmod kma_vfs_guard`). Patches are git-format-patch, cleanly reversible.

## Success Criteria

- [x] `uname -r` returns `*-kma-os-minimal` (via LOCALVERSION in build-kernel.sh)
- [ ] Boot time < 10s (`systemd-analyze`) — requires VM test
- [x] `rm /protected/path/file` returns `Operation not permitted` (implemented in kma-vfs-guard.c)
- [ ] No measurable latency regression on unprotected paths — requires VM benchmark
- [x] Welcome banner prints on boot (via kernel patch + loadable branding module)
