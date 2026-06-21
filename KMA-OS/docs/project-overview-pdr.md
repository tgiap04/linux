# KMA OS Project Overview

## 1. Vision

KMA OS is a research and learning project that produces a **purpose-built, minimal Linux kernel** running in a UTM/QEMU virtual machine on macOS Apple Silicon. Every component is built from source, configured from scratch, and shipped with security hardening (VFS guard) and brand identity baked in.

## 2. What Gets Built

| Component | Status |
|---|---|
| Custom Linux 7.0 kernel (`Ubuntu-7.0.0-22.22`) with `LOCALVERSION=-kma-os-minimal` | Implemented |
| UTM VM configuration (virtio, headless, 8 GB RAM) | Implemented |
| Host → Guest sync workflow (rsync over SSH) | Implemented |
| Minimal kernel config (`make localmodconfig`, < 300 items) | Implemented |
| Boot banner (`init/main.c` patch) | Implemented |
| ASCII logo (loadable `kma-branding` module, GPL) | Implemented |
| LSM VFS guard (`inode_unlink`, `inode_rmdir`, `path_rename` hooks) | Implemented |
| Sysfs control interface (`add_path`, `remove_path`, `stats`) | Implemented |
| Full test suite (branding, boot, VFS guard) | Implemented |

## 3. Key Non-Goals

- This is not a general-purpose distribution kernel.
- No out-of-tree filesystems (NFS, FUSE, network mounts).
- No user-space utilities beyond what's needed to build and test.
- Module auto-load uses `/etc/modules`, not `initramfs` tooling.

## 4. User Stories (Source of Truth)

See `user_stories.md` for the full Vietnamese-language user story map. Summary:

| Area | Story |
|---|---|
| Host-Guest | Edit on macOS, build inside VM, rsync source automatically |
| Minimalism | `make localmodconfig` → < 300 modules; boot < 10 s |
| Branding | `uname -r` returns `-kma-os-minimal`; boot prints "Welcome to KMA OS" |
| VFS Guard | `rm`/`mv` blocked on protected paths even as root; < 1 ms overhead |

## 5. Phase Overview

| Phase | Name | Status |
|---|---|---|
| 01 | Host-Guest Workflow | Complete |
| 02 | Minimalist Kernel | Complete |
| 03 | Branding & Custom Boot | Complete |
| 04 | VFS Protection (LSM) | Complete |
| 05 | Integration Testing | Pending |

Full details in `plans/260621-1430-kma-os-kernel/`.

## 6. Assumptions & Constraints

- **macOS host** (Apple Silicon) with UTM installed.
- **ARM64** kernel build (matching Apple Silicon).
- Guest runs Ubuntu 24.10 (Oracular) from the official installer ISO.
- No cross-compilation — native build inside the VM.
- `root` access available inside the guest VM.
