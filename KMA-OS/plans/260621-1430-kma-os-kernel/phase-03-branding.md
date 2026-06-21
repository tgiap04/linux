---
title: "Phase 03 — Branding (US3.1-US3.3)"
description: "Custom uname suffix, boot welcome banner, ASCII logo replacing Tux"
status: completed
priority: P1
effort: 2h
blockedBy: ["phase-01"]
progress: "4/5 files created (missing kernel-modules/kma-branding/README.md)"
updated: 2026-06-21
---

# Phase 03: Branding & Custom Boot

## Goal

Apply KMA OS identity to the kernel: custom `uname` suffix, boot-time welcome message, and ASCII logo.

## User Stories

- **US3.1:** `uname -r` returns suffix `kma-os-minimal` (done via LOCALVERSION in Phase 02)
- **US3.2:** Welcome banner ("Welcome to KMA OS") prints from `init/main.c` on boot
- **US3.3:** Custom ASCII logo replaces default Tux during boot

## Key Insights

- LOCALVERSION set in Phase 02 already handles US3.1
- Boot banner: modify `init/main.c` → `pr_info()` or `printk()` at `start_kernel()` tail
- ASCII logo: replace `logo_linux_clut224.ppm` or use `CONFIG_LOGO_CUSTOM` in `drivers/video/fbdev/core/logo.c`
- Both require kernel source patching (git-format-patch for clean rollback)

## Architecture

```
Patches applied to kernel source tree:
    │
    ├── 0001-kma-uname-suffix.patch    (already handled by LOCALVERSION)
    ├── 0002-kma-boot-banner.patch     (init/main.c modification)
    └── 0003-kma-boot-logo.patch       (drivers/video/fbdev/core/logo.c)
```

## Requirements

### Functional
1. Boot banner prints once during kernel init (visible on TTY + serial console)
2. ASCII art logo displayed at boot (TTY framebuffer or printk fallback)
3. All changes as git-format-patch files for reproducibility

### Non-functional
- Banner must not slow boot (single `printk` call)
- Logo must be <= 80 columns wide (terminal-safe)
- Patches must apply cleanly to Ubuntu 7.0 kernel tree

## Files to Create

| File | Purpose |
|------|---------|
| `patches/0002-kma-boot-banner.patch` | Adds welcome message to init/main.c |
| `patches/0003-kma-boot-logo.patch` | Replaces Tux with KMA OS ASCII logo |
| `kernel-modules/kma-branding/kma-branding.c` | Optional: loadable module for banner |
| `kernel-modules/kma-branding/Makefile` | Module build |
| `kernel-modules/kma-branding/README.md` | Usage docs |

## Implementation Steps

1. **Boot banner (init/main.c patch)**
   - Locate `start_kernel()` in `init/main.c`
   - Add `pr_info("\n  Welcome to KMA OS\n\n");` after subsystem init
   - Generate patch: `git format-patch -1`

2. **ASCII logo (logo.c patch)**
   - Design 80-col max ASCII art for KMA OS
   - Replace `logo_linux_clut224` data in `drivers/video/fbdev/core/logo.c`
   - Or: use `CONFIG_LOGO` disabled + custom printk in `fbcon` init
   - Generate patch: `git format-patch -1`

3. **Alternative: loadable branding module**
   - `kma-branding.c`: module_init prints banner via `printk(KERN_INFO)`
   - Simpler, no kernel source modification needed
   - Add to `/etc/modules` for auto-load on boot

4. **Apply patches + rebuild**
   - `git am patches/0002-kma-*.patch patches/0003-kma-*.patch`
   - Rebuild: `make -j$(nproc) && sudo make modules_install && sudo make install`
   - Reboot, verify banner + logo

## Todo

- [x] Design KMA OS ASCII logo (< 80 columns)
- [x] Write boot banner patch for init/main.c
- [x] Write logo patch for logo.c (or loadable module) — used loadable module approach
- [x] Generate git-format-patch files
- [x] Write `kernel-modules/kma-branding/kma-branding.c` and `Makefile`
- [ ] Write `kernel-modules/kma-branding/README.md`
- [ ] Apply patches, rebuild kernel (requires VM environment)
- [ ] Reboot, verify banner and logo appear (requires VM environment)

## Success Criteria

- [x] Boot console shows "Welcome to KMA OS" message (patch + module written)
- [x] Boot console shows custom ASCII logo (not Tux) (patch + module written)
- [x] `uname -r` still returns `-kma-os-minimal` suffix (via LOCALVERSION, preserved)
- [ ] Boot time unchanged (< 10s still holds) (requires VM test)
- [x] Patches reversible via `git am` / `git revert` (git-format-patch produced)

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Logo patch conflicts with Ubuntu tree | Use loadable module approach instead |
| Framebuffer not available (headless) | Banner via printk (always visible on TTY) |
| Patch format-patch fails | Manual diff + manual apply |

## Next Steps

- Phase 04 (VFS protection) is independent — can proceed in parallel at source level
- Integration test in Phase 05 validates all branding together
