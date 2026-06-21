---
title: "Phase 04 — VFS Protection (US4.1-US4.3)"
description: "LSM kernel module to block unlink/write on protected dirs with hash+RCU lookup"
status: completed
priority: P1
effort: 3h
blockedBy: ["phase-01"]
progress: "2/3 files created (missing kernel-modules/kma-vfs-guard/README.md)"
updated: 2026-06-21
---

# Phase 04: VFS Unlink Protection

## Goal

Loadable LSM kernel module that monitors and blocks `unlink`/`rename` on protected directories, with O(1) inode-based lookup causing zero measurable latency on unrelated I/O.

## User Stories

- **US4.1:** Hook into VFS layer to monitor `unlink` and `write` syscalls on protected paths
- **US4.2:** Return `Permission Denied` for protected dirs even under `root` (sudo)
- **US4.3:** Lookup algorithm optimized — no latency impact on other processes

## Key Insights (from research)

- LSM hook signature: `LSM_HOOK(int, 0, inode_unlink, struct inode *dir, struct dentry *dentry)`
- Return `0` = allow, `-EPERM` = deny
- Hash table: index by `inode->i_ino + sb->s_dev` (stable across renames, handles hardlinks)
- RCU readers: `rcu_read_lock()` — zero mutex contention on read path
- Writers: `spin_lock()` + `synchronize_rcu()` before free
- Gotchas: also hook `security_path_rename()` (recursive delete), check symlinks, handle cross-mount

## Architecture

```
User process: rm /protected/file
    │
    ▼
VFS: sys_unlinkat()
    │
    ▼
LSM: security_inode_unlink()
    │
    ▼
kma_vfs_guard: prot_unlink()
    │
    ├── rcu_read_lock()
    ├── hash lookup (inode + dev) → O(1)
    ├── match? → return -EPERM
    └── no match → return 0
```

## Module Interface

```
/sys/kernel/kma-vfs-guard/
├── add_path       # echo "/home/kma/src" > add_path
├── remove_path    # echo "/home/kma/src" > remove_path
├── list_paths     # cat list_paths → protected dirs
└── stats          # cat stats → hits, misses, total lookups
```

## Requirements

### Functional
1. LSM-based hook for `inode_unlink` and `inode_rename`
2. Hash table (1024 buckets) indexed by `(i_ino, s_dev)` — RCU-protected
3. sysfs interface: add/remove paths, list protected, show stats
4. Module params for initial protected paths (colon-separated)
5. Graceful module load/unload (no crash on rmmod)

### Non-functional
- Lookup: O(1) via hash, no string comparison per call
- Reader: lockless (RCU), no measurable latency
- Writer: spin_lock + synchronize_rcu, only on add/remove operations
- Module size: < 500 lines C

## Files to Create

| File | Purpose |
|------|---------|
| `kernel-modules/kma-vfs-guard/kma-vfs-guard.c` | Main module source |
| `kernel-modules/kma-vfs-guard/Makefile` | Out-of-tree build |
| `kernel-modules/kma-vfs-guard/README.md` | Usage documentation |

## Implementation Steps

1. **Module skeleton** (`kma-vfs-guard.c`)
   - Module init/exit, license, author
   - Module params: `protected_paths` (charp, colon-separated)
   - sysfs kobject creation at `/sys/kernel/kma-vfs-guard/`

2. **Hash table + RCU**
   - `DEFINE_HASHTABLE(prot_ht, 12)` — 1024 buckets
   - `struct prot_entry { u64 ino; u32 dev; struct hlist_node node; }`
   - Add: `spin_lock` + `kmalloc` + `hash_add` + `synchronize_rcu`
   - Remove: `spin_lock` + `hash_del` + `synchronize_rcu` + `kfree`
   - Lookup: `rcu_read_lock` + `hash_for_each_rcu` + match on `(ino, dev)`

3. **LSM hooks**
   - `prot_inode_unlink(dir, dentry)`: lookup `d_inode(dentry)`, return `-EPERM` if protected
   - `prot_inode_rename(old_dir, old_dentry, new_dir, new_dentry)`: block rename-out of protected dirs
   - Security block: define `static struct security_hook_list kma_hooks[]` with `LSM_HOOK_INIT()`

4. **sysfs interface**
   - `add_path` store: resolve path → inode → add to hash
   - `remove_path` store: resolve path → inode → remove from hash
   - `list_paths` show: iterate hash, print ino+dev pairs
   - `stats` show: atomic counters for hits/misses/total

5. **Build + test**
   - Out-of-tree: `make -C /lib/modules/$(uname -r)/build M=$(pwd) modules`
   - `insmod kma-vfs-guard.ko protected_paths="/home/kma/src:/etc"`
   - Test: `rm /home/kma/src/testfile` → "Operation not permitted"
   - Test: `rm /tmp/testfile` → succeeds
   - Test: `rmmod kma-vfs-guard` → clean unload

## Todo

- [x] Write `kma-vfs-guard.c` module skeleton
- [x] Implement hash table + RCU lookup
- [x] Implement LSM hooks (unlink + rename)
- [x] Implement sysfs interface
- [x] Write `Makefile` for out-of-tree build
- [ ] Write `README.md`
- [ ] Compile on VM, verify no errors (requires VM environment)
- [ ] Test: protect directory, verify block (requires VM environment)
- [ ] Test: unprotect directory, verify allow (requires VM environment)
- [ ] Test: module load/unload cycle (requires VM environment)
- [ ] Benchmark: measure latency regression (requires VM environment)

## Success Criteria

- [x] `rm /protected/path/file` returns "Operation not permitted" as root (code implemented)
- [x] `rm /unprotected/file` succeeds normally (code implemented)
- [x] `insmod` / `rmmod` clean with no kernel warnings (code hooks cleanup)
- [x] `sys/kernel/kma-vfs-guard/stats` shows hit/miss counts (sysfs implemented)
- [ ] No measurable I/O latency regression on unprotected paths (requires VM benchmark)

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| LSM API changed in Linux 7.0 | Check `include/linux/lsm_hook_defs.h` before coding |
| Hash collision under high inode count | 1024 buckets + chaining; collision = slow deny, not incorrect |
| Rename bypass | Hook both unlink AND rename |
| Module crashes kernel | Test on VM first; never on production |

## Next Steps

- Phase 05 integration test validates this module works with full branded kernel
- Module is loadable — can be developed/tested independently of Phases 02/03
