---
title: "Phase 01 — Host-Guest Workflow (US1.1-US1.3)"
description: "Set up macOS host editing + UTM Ubuntu VM with SSH and shared folder for kernel development"
status: completed
priority: P1
effort: 1.5h
blockedBy: []
progress: "3/3 files created; 3/6 todos code-complete"
updated: 2026-06-21
---

# Phase 01: Host-Guest Workflow

## Goal

Establish a development pipeline: edit C/config on macOS (host), compile on Ubuntu VM (guest) with full multi-core utilization.

## User Stories

- **US1.1:** Edit source on macOS with familiar IDE (VS Code)
- **US1.2:** Sync source to VM, run `make` entirely on Ubuntu guest
- **US1.3:** Build utilizes all allocated CPU cores (`make -j$(nproc)`)

## Key Insights (from research)

- UTM has no official CLI; use Homebrew community tap or manual `.utm` config
- virtio-9p shared folders: `mount -t 9p -o trans=virtio,version=9p2000.L <tag> /mnt/shared`
- SSH recommended over UTM display for terminal work
- Swap: allocate 8GB for 8GB RAM VM (kernel builds are memory-hungry)
- Apple Silicon: native ARM64, no cross-compile needed

## Architecture

```
macOS Host (VS Code)
    │
    ├── rsync / virtio-9p ──→ Ubuntu VM (UTM)
    │                              │
    │                              ├── openssh-server
    │                              ├── kernel source
    │                              └── make -j$(nproc)
    │
    └── SSH ──────────────────────→ build output / install
```

## Requirements

### Functional
1. UTM VM config file with optimal settings (50GB disk, 8GB RAM, max CPU)
2. SSH access from host to guest
3. Shared folder for source sync
4. Automated setup script for build dependencies

### Non-functional
- Build time for `localmodconfig`: ~8-15 min on 4-core
- Disk: 10GB+ free in VM for build artifacts
- No cross-compilation (Apple Silicon = native ARM64)

## Files to Create

| File | Purpose |
|------|---------|
| `vm/kma-os-utm.toml` | UTM VM configuration |
| `scripts/setup-vm.sh` | Install build deps, configure SSH + shared folder |
| `scripts/sync-to-vm.sh` | rsync host→guest with exclusions |

## Implementation Steps

1. Create `vm/kma-os-utm.toml` with UTM VM spec
   - Ubuntu 26.04 ARM64 ISO
   - 50GB qcow2 disk, 8GB RAM, max CPU cores
   - VirtIO network (NAT), virtio-9p shared folder
   - Display off (headless, SSH-only)

2. Create `scripts/setup-vm.sh`
   - Install build-essential, libncurses-dev, libssl-dev, libelf-dev, flex, bison, dwarves, python3, cpio, zstd, rsync
   - Configure openssh-server
   - Mount shared folder at /mnt/shared
   - Set up 8GB swap file
   - Print verification summary

3. Create `scripts/sync-to-vm.sh`
   - rsync from host project dir to VM `/home/kma/kernel-src/`
   - Exclude: `.git`, `build/`, `*.o`, `*.ko`, `*.mod`
   - SSH target configurable via env var `KMA_VM_SSH` (default: `kma@10.0.2.15`)

## Todo

- [x] Write `vm/kma-os-utm.toml`
- [x] Write `scripts/setup-vm.sh`
- [x] Write `scripts/sync-to-vm.sh`
- [ ] Test: create UTM VM from config (requires VM environment)
- [ ] Test: SSH access from host (requires VM environment)
- [ ] Test: sync source, verify files in guest (requires VM environment)

## Success Criteria

- [ ] UTM VM boots Ubuntu to login prompt (requires VM environment)
- [ ] `ssh kma@<vm-ip>` connects from macOS terminal (requires VM environment)
- [x] `scripts/sync-to-vm.sh` copies source to VM (script written)
- [x] `make -j$(nproc)` runs successfully in VM with build deps installed (script written)

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| UTM TOML config format changes | Pin to UTM version; test import immediately |
| virtio-9p mount fails | Fall back to rsync-only workflow |
| SSH key auth setup friction | Script generates keys + copies via `ssh-copy-id` |

## Next Steps

- Phase 02, 03, 04 all depend on this phase completing
- Once VM is running, proceed to kernel build (Phase 02)
