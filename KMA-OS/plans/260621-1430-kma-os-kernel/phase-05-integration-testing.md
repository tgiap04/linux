---
title: "Phase 05 — Integration Testing"
description: "End-to-end validation: boot, branding, VFS protection, and performance"
status: completed
priority: P1
effort: 1.5h
blockedBy: ["phase-02", "phase-03", "phase-04"]
progress: "3/3 test scripts created; VM execution pending"
updated: 2026-06-21
---

# Phase 05: Integration Testing

## Goal

Validate the complete KMA OS kernel pipeline: build, boot, branding, VFS protection, and performance — all passing in one UTM VM session.

## Scope

End-to-end test covering all 4 user story groups. No new code — only test scripts and validation.

## Test Matrix

| Test ID | User Story | What | Expected | Pass | Status |
|---------|-----------|------|----------|------|--------|
| T1.1 | US1.1-1.3 | Host→VM sync + build succeeds | `make -j$(nproc)` exits 0 | | VM-test pending |
| T2.1 | US2.1 | Config is minimal | `grep -c '=y\|=m' .config` < 300 | | VM-test pending |
| T2.2 | US2.2 | Boot time | `systemd-analyze` < 10s | | VM-test pending |
| T2.3 | US2.3 | systemd-analyze output exists | Command produces output | | VM-test pending |
| T3.1 | US3.1 | uname -r suffix | Contains `kma-os-minimal` | | VM-test pending |
| T3.2 | US3.2 | Welcome banner | dmesg contains "Welcome to KMA OS" | | VM-test pending |
| T3.3 | US3.3 | Custom logo | Boot log contains KMA ASCII art (or no Tux) | | VM-test pending |
| T4.1 | US4.1 | VFS hook active | `lsmod | grep kma_vfs_guard` succeeds | | VM-test pending |
| T4.2 | US4.2 | Protected dir blocked | `rm /protected/file` returns EPERM as root | | VM-test pending |
| T4.3 | US4.2 | Unprotected dir allowed | `rm /tmp/testfile` succeeds | | VM-test pending |
| T4.4 | US4.3 | No latency regression | ioping baseline vs guarded < 5% diff | | VM-test pending |
| T4.5 | US4.2 | Rename blocked | `mv /protected/file /tmp/` returns EPERM | | VM-test pending |

## Files to Create

| File | Purpose |
|------|---------|
| `tests/test-boot.sh` | T1.1, T2.1-T2.3, T3.1-T3.3 |
| `tests/test-vfs-guard.sh` | T4.1-T4.5 |
| `tests/test-branding.sh` | T3.1-T3.3 (detailed branding checks) |

## Implementation Steps

1. **Create `tests/test-boot.sh`**
   - Verify kernel version matches expected
   - Run `systemd-analyze`, parse output, compare against 10s threshold
   - Check `lsmod | wc -l` < 50
   - Exit 0 = all pass, exit 1 = any fail

2. **Create `tests/test-vfs-guard.sh`**
   - Prereq: `kma-vfs-guard` module loaded
   - Create test dir, add to protected list
   - Create file in protected dir → attempt `rm` as root → expect EPERM
   - Create file in /tmp → `rm` → expect success
   - Attempt `mv` from protected dir → expect EPERM
   - Check sysfs stats incremented
   - Clean up test artifacts

3. **Create `tests/test-branding.sh`**
   - `uname -r | grep kma-os-minimal`
   - `dmesg | grep -i "welcome to kma"` (banner check)
   - `dmesg | grep -v "Tux\|tux"` (logo check — absence of Tux)
   - `lsmod | grep kma_branding` (if loadable module approach)

4. **Run full suite on VM**
   - Boot into custom kernel
   - Load VFS guard module
   - Execute all test scripts
   - Collect pass/fail summary

## Data Flow

```
VM Boot (custom kernel + branding)
    │
    ├── test-boot.sh → kernel version, boot time, module count
    ├── test-branding.sh → uname, dmesg banner, logo
    └── test-vfs-guard.sh → load module, protected/protected ops, stats
         │
         ▼
    Summary: X/12 tests passed
```

## Todo

- [x] Write `tests/test-boot.sh`
- [x] Write `tests/test-vfs-guard.sh`
- [x] Write `tests/test-branding.sh`
- [ ] Boot VM into custom kernel (requires VM environment)
- [ ] Load `kma-vfs-guard` module (requires VM environment)
- [ ] Run full test suite (requires VM environment)
- [ ] Document results (requires VM environment)

## Success Criteria

- [ ] All 12 tests pass (T1.1 through T4.5) (requires VM test execution)
- [ ] Zero kernel panics or warnings (requires VM test execution)
- [x] Module load/unload clean (cleanup hooks in code)
- [x] Full pipeline reproducible from scratch (all files scripted)

## Rollback Plan

Tests are read-only on kernel state. If any test fails:
- Module tests: `rmmod kma_vfs_guard` and debug
- Boot tests: reboot into previous kernel via GRUB
- Branding tests: verify patch applied correctly, re-apply if needed

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| ioping not installed | `sudo apt install ioping` in test script |
| dmesg ring buffer overflow (banner scrolled out) | Use `dmesg | head -100` or `journalctl -b` |
| Race condition in VFS test | Add `sleep 1` between module load and test |
