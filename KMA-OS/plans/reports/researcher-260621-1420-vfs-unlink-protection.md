---
name: researcher-260621-1420-vfs-unlink-protection
description: VFS unlink protection hook - LSM vs kprobes comparison with code
metadata:
  type: report
---

# Study Report: VFS Unlink Protection Hook

## Approach: LSM Framework (Recommended)

LSM hooks into security framework — stable, stackable, near-zero overhead.

### Hook Signature

```c
// include/linux/lsm_hook_defs.h
LSM_HOOK(int, 0, inode_unlink, struct inode *dir, struct dentry *dentry)
```

- Return `0` = allow, `-EPERM` = deny
- `dir`: parent directory inode; `dentry`: target file being unlinked

### Performance Strategy

**Hash table + RCU** — production standard:
- Index by `inode->i_ino + sb->s_dev` (stable across renames)
- Readers: `rcu_read_lock()` — no mutex contention
- Writers: `spin_lock()` + `synchronize_rcu()` before freeing
- O(1) lookup, no path string comparison per call

### Module Structure

```c
// Module params: protected paths as colon-separated string
// sysfs: /sys/kernel/kma_protected/{add_path,remove_path,stats}

static DEFINE_HASHTABLE(prot_ht, 12);  // 1024 buckets
static int prot_unlink(struct inode *dir, struct dentry *dentry)
{
    struct inode *inode = d_inode(dentry);
    rcu_read_lock();
    hash_for_each_rcu(prot_ht, i, e, node) {
        if (e->ino == inode->i_ino && e->dev == inode->i_sb->s_dev) {
            rcu_read_unlock();
            return -EPERM;
        }
    }
    rcu_read_unlock();
    return 0;
}
```

### Gotchas

1. Recursive delete via `rename` + `rmdir` — also hook `security_path_rename()`
2. Symlinks — check `d_inode(dentry)->i_mode & S_IFLNK`
3. Hardlinks — inode-based lookup handles all hardlinks automatically
4. Cross-mount protection — use `security_path_unlink(struct path *)` instead
