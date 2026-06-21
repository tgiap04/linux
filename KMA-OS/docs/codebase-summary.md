# Codebase Summary

## Directory Layout

```
kma-os/
├── vm/
│   └── kma-os-utm.toml           UTM VM configuration (hardware, network, shared folder)
├── scripts/
│   ├── setup-vm.sh                Guest bootstrap (dependencies, SSH, swap, mount)
│   ├── sync-to-vm.sh              Rsync source from host to guest
│   ├── build-kernel.sh            Clone Ubuntu kernel + configure + build + install
│   └── measure-boot.sh            Boot-time profiling (systemd-analyze, lsmod)
├── patches/
│   ├── 0002-kma-boot-banner.patch init/main.c: pr_info() welcome box
│   └── 0003-kma-boot-logo.patch   init/main.c: ASCII KMA OS wordmark
├── kernel-modules/
│   ├── kma-branding/              Loadable module: ASCII boot banner
│   │   ├── kma-branding.c
│   │   └── Makefile
│   └── kma-vfs-guard/             LSM module: VFS unlink/rename protection
│       ├── kma-vfs-guard.c
│       └── Makefile
├── tests/
│   ├── test-branding.sh           T3.1–T3.3: uname, dmesg banner/logo
│   ├── test-boot.sh               T1.1, T2.1–3: uname, config count, boot time
│   └── test-vfs-guard.sh          T4.1–5: module load, rm/mv block, stats
├── docs/                          This documentation
├── plans/                         Implementation plan and phases
└── user_stories.md                User story map (Vietnamese)
```

## Key Source Files

### `kernel-modules/kma-vfs-guard/kma-vfs-guard.c`
- **Lines:** ~280
- **Purpose:** LSM hook blocking `unlink`/`rmdir`/`rename` on protected inodes
- **Key functions:**
  - `vfs_guard_hash_inode()` — insert `(i_ino, s_dev)` into hash table
  - `vfs_guard_unhash_inode()` — remove entry, call `synchronize_rcu()`
  - `vfs_guard_inode_unlink()` / `vfs_guard_inode_rmdir()` / `vfs_guard_path_rename()` — LSM hooks
  - `add_path_store()` / `remove_path_store()` / `stats_show()` — sysfs callbacks
- **Concurrency:** RCU lockless reads; `spin_lock` + `synchronize_rcu()` for writes
- **Module param:** `protected_paths` (colon-separated path list)

### `kernel-modules/kma-branding/kma-branding.c`
- **Lines:** ~60
- **Purpose:** Print boxed ASCII "Welcome to KMA OS" on load
- **Key functions:** `kma_branding_init()`, `kma_branding_exit()`

### `scripts/build-kernel.sh`
- **Purpose:** Full pipeline — clone, configure (`LOCALVERSION=-kma-os-minimal`, `localmodconfig`), build, install, update-grub

### `scripts/sync-to-vm.sh`
- **Purpose:** rsync with excludes for `.git/`, build artifacts, `node_modules/`
- **SSH target:** `kma@10.0.2.15`

## Code Not Present

This codebase does not include:
- Kernel source tree (cloned at build time inside VM)
- Built kernel image / modules (produced by VM build run)
- Test results / boot logs (generated during test execution)
