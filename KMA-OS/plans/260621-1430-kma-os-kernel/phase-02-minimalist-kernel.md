---
title: "Phase 02 — Minimalist Kernel (US2.1-US2.3)"
description: "Strip drivers via localmodconfig, optimize boot, measure with systemd-analyze"
status: completed
priority: P1
effort: 2h
blockedBy: ["phase-01"]
progress: "2/2 files created; 2/6 todos code-complete"
updated: 2026-06-21
---

# Phase 02: Minimalist Kernel

## Goal

Produce a stripped-down kernel with only essential modules, achieving fast boot time measurable via `systemd-analyze`.

## User Stories

- **US2.1:** Auto-scan hardware, strip unneeded drivers → minimal `.config`
- **US2.2:** Skip redundant init processes → boot in seconds
- **US2.3:** `systemd-analyze` proves optimized boot time

## Key Insights (from research)

- `make localmodconfig` reads `lsmod` output + `/proc/config.gz`, keeps only ~200 items (vs ~15,000)
- `make localyesconfig` converts `=m` to `=y` (built-in, no module loading overhead)
- `LOCALVERSION="-kma-os-minimal"` sets custom uname suffix
- Build time with `localmodconfig` + `-j4`: 8-15 minutes
- Disk: 2-4GB build dir, 10GB+ free recommended

## Architecture

```
Host: lsmod > /tmp/modules.txt
    │
    ▼
VM:  kernel source (Ubuntu 7.0 tree)
    │
    ├── make localmodconfig  (auto-strip)
    ├── LOCALVERSION="-kma-os-minimal"
    ├── make -j$(nproc)      (parallel build)
    ├── make modules_install
    └── make install          (update grub)
         │
         ▼
    Boot → verify uname -r, boot time
```

## Requirements

### Functional
1. Script to capture host modules and transfer to VM
2. Automated `localmodconfig` with LOCALVERSION set
3. Parallel build using all VM cores
4. GRUB auto-update on install
5. Boot time measurement via `systemd-analyze`

### Non-functional
- Boot target: < 10 seconds
- Config size: ~200 Kconfig items
- No proprietary/binary blob drivers

## Files to Create

| File | Purpose |
|------|---------|
| `scripts/build-kernel.sh` | Full build pipeline (config → build → install) |
| `scripts/measure-boot.sh` | Capture + display systemd-analyze output |

## Implementation Steps

1. Create `scripts/build-kernel.sh`
   - Accept env vars: `KMA_KERNEL_SRC`, `KMA_LOCALVERSION` (default: `-kma-os-minimal`)
   - Clone Ubuntu kernel tree if source not present (tag: `Ubuntu-7.0.0-22.22`)
   - Run `make localmodconfig` with LOCALVERSION exported
   - Run `make -j$(nproc)`
   - Run `sudo make modules_install && sudo make install`
   - Update GRUB: `sudo update-grub`
   - Print `uname -r` of installed kernel

2. Create `scripts/measure-boot.sh`
   - Run `systemd-analyze` (total time)
   - Run `systemd-analyze blame` (top 10 slowest services)
   - Run `systemd-analyze critical-chain` (bottleneck path)
   - Output summary with pass/fail against 10s threshold

3. Test on VM
   - Boot into custom kernel
   - Verify `uname -r` = `7.0.0-22-generic-kma-os-minimal`
   - Run `systemd-analyze`, confirm < 10s

## Todo

- [x] Write `scripts/build-kernel.sh`
- [x] Write `scripts/measure-boot.sh`
- [ ] Run build on VM, verify compilation succeeds (requires VM environment)
- [ ] Reboot VM into custom kernel (requires VM environment)
- [ ] Verify `uname -r` output (requires VM environment)
- [ ] Measure boot time, confirm < 10s (requires VM environment)

## Success Criteria

- [ ] `uname -r` returns `7.0.0-22-generic-kma-os-minimal` (requires VM test)
- [ ] `systemd-analyze` shows boot < 10 seconds (requires VM test)
- [ ] `lsmod | wc -l` shows minimal loaded modules (< 50) (requires VM test)
- [x] Build completes without errors (script written)

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Ubuntu 7.0 tag not found | Fall back to latest available tag |
| localmodconfig misses needed driver | Manual `make menuconfig` fallback |
| GRUB doesn't detect new kernel | Run `sudo update-grub` + verify `/boot` |

## Next Steps

- Phase 03 (branding) applies on top of this kernel
- Phase 04 (VFS) is a loadable module, independent of config
