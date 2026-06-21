# Project Roadmap

## Overview

KMA OS kernel development is organized into 5 sequential/parallel phases. Phase 01 must complete before any other begins; phases 02, 03, and 04 are independent and can run concurrently.

## Phase Status

| Phase | Name | Status | Notes |
|---|---|---|---|
| 01 | Host-Guest Workflow | **Complete** | VM config, sync scripts, setup script |
| 02 | Minimalist Kernel | **Complete** | Build script, LOCALVERSION, localmodconfig |
| 03 | Branding & Custom Boot | **Complete** | init/main.c patches, kma-branding module |
| 04 | VFS Protection (LSM) | **Complete** | kma-vfs-guard module + sysfs interface |
| 05 | Integration Testing | **Pending** | Full test suite run, results documentation |

## Milestones

| Milestone | Phase | Criterion |
|---|---|---|
| VM boots and SSH connects | 01 | `ssh kma@10.0.2.15` succeeds |
| Kernel builds and installs | 02 | `uname -r` contains `kma-os-minimal` |
| Boot < 10 s | 02 | `systemd-analyze` first time ≤ 10 000 ms |
| Config ≤ 300 items | 02 | `grep -c '=y\|=m' /boot/config-$(uname -r)` < 300 |
| Welcome banner in dmesg | 03 | `dmesg \| grep -qi "Welcome to KMA OS"` |
| ASCII logo in dmesg | 03 | `dmesg \| grep -qi "KMA"` |
| VFS guard loads | 04 | `insmod kma-vfs-guard.ko` exits 0 |
| rm/mv blocked as root | 04 | `rm` on protected path returns exit code 1 |
| Stats counter increments | 04 | `cat /sys/kernel/kma-vfs-guard/stats` hits > 0 |

## Timeline (Estimated)

| Phase | Effort | Dependencies |
|---|---|---|
| 01 Host-Guest Workflow | 1.5 h | None |
| 02 Minimalist Kernel | 2 h | Phase 01 |
| 03 Branding & Custom Boot | 2 h | Phase 01 |
| 04 VFS Protection | 3 h | Phase 01 |
| 05 Integration Testing | 1.5 h | Phases 02, 03, 04 |
| **Total** | **~10 h** | |

## Next Steps

1. Run `scripts/setup-vm.sh` inside the Ubuntu VM.
2. Run `scripts/sync-to-vm.sh` from the macOS host.
3. Run `scripts/build-kernel.sh` inside the VM.
4. Reboot into the new kernel.
5. Run `tests/test-boot.sh`, `tests/test-branding.sh`, `tests/test-vfs-guard.sh`.
6. Document results; update this roadmap with actual measured values (boot time, module count).

Full details in `plans/260621-1430-kma-os-kernel/`.
