# Code Standards

## 1. Kernel Module Standards

### Licensing
All kernel modules must use `MODULE_LICENSE("GPL")`. Non-GPL modules cannot use many exported symbols.

### Formatting
- Linux kernel style: tabs for indentation, max 80 columns.
- No tabs after opening bracket on the same line.
- Functions: `type name(args)` — no K&R style.
- `if`/`for`/`while`/`switch`: always braces around single-statement bodies.

### Naming
| Object | Convention |
|---|---|
| Source file | `kma-<feature>.c` (kebab-case, descriptive) |
| Makefile | `Makefile` (in same directory) |
| Module name | `kma-<feature>` (matches directory name) |
| Sysfs group | `/sys/kernel/kma-<feature>/` |

### Required Headers
```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
/* feature-specific headers */
```

### Module Info Block
```c
MODULE_AUTHOR("KMA OS Team");
MODULE_DESCRIPTION("...");
MODULE_VERSION("1.0");
MODULE_LICENSE("GPL");
```

---

## 2. Out-of-Tree Makefile

Every module directory contains a `Makefile` with at minimum:

```make
obj-m := kma-<feature>.o
KDIR ?= /lib/modules/$(shell uname -r)/build

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
```

Always use `$(MAKE)` rather than `make` inside recursive invocations.

---

## 3. Hash Table (RCU)

For lockless-read, copy-on-write data structures:

```c
DEFINE_HASHTABLE(name, order);          /* 2^order buckets */
hash_init(name);

rcu_read_lock();
/* read-only traversal */
rcu_read_unlock();

spin_lock(&lock);
/* write: add or remove */
spin_unlock(&lock);
synchronize_rcu();                      /* before freeing */
```

Key with `(inode->i_ino, sb->s_dev)` — do not use `dentry->d_name.name` as a key (unstable under rename).

---

## 4. Sysfs Interface

- Group under `/sys/kernel/kma-<feature>/`.
- Use `sysfs_create_group` / `sysfs_remove_group`.
- Use `DEVICE_ATTR_RO` / `DEVICE_ATTR_WO` for individual files.
- Do not block in sysfs callbacks (no `mutex_lock` across `store()` return).

---

## 5. Shell Scripts

- Shebang: `#!/usr/bin/env bash`
- Exit early on error: `set -e`
- Variable names: `UPPER_SNAKE_CASE`
- Check for required tools before use.
- Quote all variable expansions: `"$VAR"`, not `$VAR`.

---

## 6. Test Scripts

- Shebang: `#!/usr/bin/env bash`, `set -e`
- Test functions prefixed with `test_`; main flow logs each step with `echo`.
- Pass: exit 0. Fail: exit 1 (no silent failures).
- Clean up any created files/directories on exit or error.
- Diagnostic output to stdout, not stderr.

---

## 7. Patch Format

Kernel patches are generated with `git format-patch`:

```bash
git format-patch -1 --stdout <commit> > patches/NNNN-description.patch
```

Patches apply to `init/main.c` in the Ubuntu kernel tree. Always verify patch applies cleanly with `git apply --check`.
