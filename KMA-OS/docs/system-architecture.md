# System Architecture

## 1. Host-Guest Topology

```
macOS Host (Apple Silicon)
  └── UTM (QEMU userspace)
        └── Ubuntu Guest VM (ARM64)
              ├── /mnt/shared  ← 9p virtio shared folder (macOS source tree)
              ├── /swapfile    ← 8 GB swap
              └── kernel build tooling
                    ├── scripts/build-kernel.sh
                    ├── scripts/measure-boot.sh
                    ├── kernel-modules/kma-branding/
                    └── kernel-modules/kma-vfs-guard/
```

**Network:** NAT via virtio-net; guest SSH reachable at `10.0.2.15` from host.
**Shared folder:** 9p virtio FS, mount command in `vm/kma-os-utm.toml`.
**Sync:** rsync over SSH (`scripts/sync-to-vm.sh`).

---

## 2. Kernel Build Pipeline

```
scripts/build-kernel.sh
  ├── git clone/pull  git://kernel.ubuntu.com/ubuntu/oracular.git  tag Ubuntu-7.0.0-22.22
  ├── LOCALVERSION=-kma-os-minimal  →  .config
  ├── make localmodconfig          (scrapes ~15 000 → ~200 config items)
  ├── make -j$(nproc)              (parallel build on all host cores)
  ├── make modules_install
  ├── make install
  └── update-grub
```

Result: `/boot/config-$(uname -r)` reflects a stripped-down config; `uname -r` returns `7.0.0-22-generic-kma-os-minimal`.

---

## 3. Branding Architecture

Two complementary mechanisms — the kernel patch is always present; the loadable module is optional and hot-pluggable.

### 3a. Boot Banner Patch (`init/main.c`)

- `patches/0002-kma-boot-banner.patch` adds `pr_info("╔══ ... ══╗ ...")`
- Prints the box immediately after `start_kernel()`, before TTY init
- Always active when kernel boots; cannot be unloaded

### 3b. ASCII Logo Module (`kma-branding`)

- `kernel-modules/kma-branding/kma-branding.c`
- GPL 2.0 loadable module
- Prints ASCII wordmark via `pr_info()` on `module_init`; prints unload message on `module_exit`
- Can be added to `/etc/modules` for auto-load, or omitted to suppress the logo

---

## 4. VFS Guard Architecture

**Module:** `kernel-modules/kma-vfs-guard/kma-vfs-guard.c` (GPL 2.0)

### 4a. LSM Hooks

Three `security_` hooks are registered:

| Hook | Blocks | Return |
|---|---|---|
| `inode_unlink` | `unlink()` / `rm` | `-EPERM` |
| `inode_rmdir` | `rmdir()` | `-EPERM` |
| `path_rename` | `rename()` / `mv` | `-EPERM` |

### 4b. Inode Tracking

- **Key:** `(inode->i_ino, sb->s_dev)` — stable across renames, correct for hardlinks
- **Hash table:** `DEFINE_HASHTABLE(prot_ht, 12)` — 4 096 buckets
- **Concurrency:**
  - Lookup: `rcu_read_lock()` → O(1) lockless
  - Insert/Remove: `spin_lock()` + `synchronize_rcu()`

### 4c. Sysfs Interface

Path: `/sys/kernel/kma-vfs-guard/`

| File | Direction | Effect |
|---|---|---|
| `add_path` | write-only | Resolves path → inode → adds to hash table |
| `remove_path` | write-only | Resolves path → removes from hash table |
| `stats` | read-only | Shows `hits` and `misses` counters |

### 4d. Module Parameter

```bash
insmod kma-vfs-guard.ko protected_paths=/home/kma/src
```

Colon-separated list parsed at load time; each path is resolved and its inode pair inserted.

---

## 5. Test Suite

```
tests/
  test-branding.sh    T3.1 – T3.3   uname suffix, dmesg banner, dmesg logo
  test-boot.sh        T1.1, T2.1–3  uname suffix, config count, boot time
  test-vfs-guard.sh   T4.1–5       module load, rm block, mv block, stats
```

All three scripts return exit code 0 on success, non-zero on failure.

---

## 6. Configuration Files

| File | Purpose |
|---|---|
| `vm/kma-os-utm.toml` | UTM VM hardware config (CPU, RAM, disk, network, shared folder) |
| `scripts/setup-vm.sh` | Guest bootstrap (apt, SSH, swap, mount) |
| `scripts/sync-to-vm.sh` | rsync source from host to guest |
| `scripts/build-kernel.sh` | Full kernel build pipeline |
| `scripts/measure-boot.sh` | Boot-time profiling |
| `kernel-modules/*/Makefile` | Out-of-tree module build |
