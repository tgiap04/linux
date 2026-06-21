// SPDX-License-Identifier: GPL-2.0
/*
 * vfs_guard.c — Built-in LSM for Linux 7.0: block unlink/rmdir/rename
 * on protected directories.
 *
 * Uses hash table + RCU for O(1) lockless lookup of protected inodes.
 * sysfs interface at /sys/kernel/kma-vfs-guard/ for runtime management.
 * Boot-time paths: kma_vfs_guard.protected_paths="/path1:/path2"
 *
 * Registered as a built-in LSM via DEFINE_LSM(), not a loadable module
 * (security_add_hooks is not exported in Linux 7.0).
 */
#include <linux/kernel.h>
#include <linux/security.h>
#include <linux/lsm_hooks.h>
#include <linux/fs.h>
#include <linux/namei.h>
#include <linux/slab.h>
#include <linux/hashtable.h>
#include <linux/rculist.h>
#include <linux/kobject.h>
#include <linux/string.h>
#include <linux/spinlock.h>

/* Must match the token in CONFIG_LSM (underscores, not dashes) because the
 * LSM framework does strcmp(lsm_info->id->name, token) against CONFIG_LSM. */
#define KMA_NAME "kma_vfs_guard"
#define HT_BITS 12  /* 4096 buckets */
/* Sysfs/kobject name — can use dashes (different from the LSM match name) */
#define KMA_SYSFS_NAME "kma-vfs-guard"

/* --- Hash table for protected inodes --- */

struct prot_entry {
	struct hlist_node node;
	struct rcu_head rcu;
	unsigned long ino;
	dev_t dev;
};

static inline u32 prot_hash(unsigned long ino, dev_t dev)
{
	return hash_32(hash_long(ino ^ dev, 32), HT_BITS);
}

static DEFINE_HASHTABLE(prot_ht, HT_BITS);
static DEFINE_SPINLOCK(prot_lock);
static atomic64_t stat_hits;
static atomic64_t stat_misses;

static bool prot_lookup(struct inode *inode)
{
	struct prot_entry *e;
	int bkt;
	bool found = false;

	rcu_read_lock();
	hash_for_each_rcu(prot_ht, bkt, e, node) {
		if (e->ino == inode->i_ino && e->dev == inode->i_sb->s_dev) {
			found = true;
			break;
		}
	}
	rcu_read_unlock();

	if (found)
		atomic64_inc(&stat_hits);
	else
		atomic64_inc(&stat_misses);

	return found;
}

static void prot_add_entry(struct inode *inode)
{
	struct prot_entry *e;
	u32 key = prot_hash(inode->i_ino, inode->i_sb->s_dev);

	spin_lock(&prot_lock);
	hash_for_each_possible_rcu(prot_ht, e, node, key) {
		if (e->ino == inode->i_ino && e->dev == inode->i_sb->s_dev) {
			spin_unlock(&prot_lock);
			return; /* already protected */
		}
	}

	e = kmalloc(sizeof(*e), GFP_KERNEL);
	if (!e) {
		spin_unlock(&prot_lock);
		return;
	}

	e->ino = inode->i_ino;
	e->dev = inode->i_sb->s_dev;
	hash_add_rcu(prot_ht, &e->node, key);
	spin_unlock(&prot_lock);

	pr_info("%s: protected ino=%lu dev=%u\n", KMA_NAME, e->ino, e->dev);
}

static void prot_remove_entry(struct inode *inode)
{
	struct prot_entry *e;
	u32 key = prot_hash(inode->i_ino, inode->i_sb->s_dev);

	spin_lock(&prot_lock);
	hash_for_each_possible_rcu(prot_ht, e, node, key) {
		if (e->ino == inode->i_ino && e->dev == inode->i_sb->s_dev) {
			hash_del_rcu(&e->node);
			spin_unlock(&prot_lock);
			synchronize_rcu();
			kfree(e);
			pr_info("%s: unprotected ino=%lu dev=%u\n",
				KMA_NAME, inode->i_ino, inode->i_sb->s_dev);
			return;
		}
	}
	spin_unlock(&prot_lock);
}

/* --- LSM hooks --- */

static int prot_inode_unlink(struct inode *dir, struct dentry *dentry)
{
	/* Protecting a directory means files INSIDE it can't be unlinked.
	 * Check if the parent directory (dir) is in the protected set. */
	if (!dir)
		return 0;

	if (prot_lookup(dir)) {
		pr_warn("%s: blocked unlink in dir ino=%lu dev=%u\n",
			KMA_NAME, dir->i_ino, dir->i_sb->s_dev);
		return -EPERM;
	}

	return 0;
}

static int prot_inode_rmdir(struct inode *dir, struct dentry *dentry)
{
	return prot_inode_unlink(dir, dentry);
}

static int prot_path_rename(const struct path *old_dir, struct dentry *old_dentry,
			     const struct path *new_dir, struct dentry *new_dentry,
			     unsigned int flags)
{
	struct inode *src_dir;

	/* Block renaming anything OUT OF a protected directory.
	 * old_dir is the source parent directory of the rename. */
	if (!old_dir || !old_dir->dentry)
		return 0;

	src_dir = d_inode(old_dir->dentry);
	if (!src_dir)
		return 0;

	if (prot_lookup(src_dir)) {
		pr_warn("%s: blocked rename-out of dir ino=%lu dev=%u\n",
			KMA_NAME, src_dir->i_ino, src_dir->i_sb->s_dev);
		return -EPERM;
	}

	return 0;
}

/* Kernel 7.0 LSM API: hook arrays use __ro_after_init, and
 * security_add_hooks() takes a const struct lsm_id *. LSM_ID_UNDEF is used
 * because we are an out-of-tree LSM with no official ID. */
static const struct lsm_id kma_lsmid = {
	.name = KMA_NAME,
	.id   = LSM_ID_UNDEF,
};

static struct security_hook_list kma_hooks[] __ro_after_init = {
	LSM_HOOK_INIT(inode_unlink, prot_inode_unlink),
	LSM_HOOK_INIT(inode_rmdir, prot_inode_rmdir),
	LSM_HOOK_INIT(path_rename, prot_path_rename),
};

/* --- sysfs interface --- */

static struct kobject *kma_kobj;

static ssize_t add_path_store(struct kobject *kobj, struct kobj_attribute *attr,
			      const char *buf, size_t count)
{
	struct path path;
	char *trimmed;
	int ret;

	trimmed = strim(kstrdup(buf, GFP_KERNEL));
	if (!trimmed)
		return -ENOMEM;

	ret = kern_path(trimmed, LOOKUP_FOLLOW, &path);
	if (ret) {
		pr_warn("%s: path '%s' not found (%d)\n", KMA_NAME, trimmed, ret);
		kfree(trimmed);
		return ret;
	}

	prot_add_entry(path.dentry->d_inode);
	path_put(&path);
	kfree(trimmed);
	return count;
}

static ssize_t remove_path_store(struct kobject *kobj, struct kobj_attribute *attr,
				 const char *buf, size_t count)
{
	struct path path;
	char *trimmed;
	int ret;

	trimmed = strim(kstrdup(buf, GFP_KERNEL));
	if (!trimmed)
		return -ENOMEM;

	ret = kern_path(trimmed, LOOKUP_FOLLOW, &path);
	if (ret) {
		pr_warn("%s: path '%s' not found (%d)\n", KMA_NAME, trimmed, ret);
		kfree(trimmed);
		return ret;
	}

	prot_remove_entry(path.dentry->d_inode);
	path_put(&path);
	kfree(trimmed);
	return count;
}

static ssize_t stats_show(struct kobject *kobj, struct kobj_attribute *attr,
			   char *buf)
{
	return sysfs_emit(buf,
			  "hits:   %lld\n"
			  "misses: %lld\n",
			  atomic64_read(&stat_hits),
			  atomic64_read(&stat_misses));
}

static struct kobj_attribute add_path_attr = __ATTR_WO(add_path);
static struct kobj_attribute remove_path_attr = __ATTR_WO(remove_path);
static struct kobj_attribute stats_attr = __ATTR_RO(stats);

static struct attribute *kma_attrs[] = {
	&add_path_attr.attr,
	&remove_path_attr.attr,
	&stats_attr.attr,
	NULL,
};

static struct attribute_group kma_attr_group = {
	.attrs = kma_attrs,
};

/* --- Boot-time protected paths (kernel cmdline) --- */

static char *protected_paths_param;
/* __setup + early_param for builtin; module_param is only for loadable modules. */
static int __init kma_vfs_guard_setup(char *str)
{
	protected_paths_param = str;
	return 1;
}
__setup(KMA_NAME ".protected_paths=", kma_vfs_guard_setup);

/* --- LSM init (called from security_init() inside start_kernel()) --- */

static int __init kma_vfs_guard_init(void)
{
	/* Phase 1: register LSM hooks — this MUST happen at boot.
	 * security_add_hooks() is available early; the hooks themselves
	 * just store pointers — they don't need sysfs or VFS to be ready. */
	security_add_hooks(kma_hooks, ARRAY_SIZE(kma_hooks), &kma_lsmid);

	pr_info("%s: hooks registered\n", KMA_NAME);
	return 0;
}

DEFINE_LSM(kma_vfs_guard) = {
	.id   = &kma_lsmid,
	.init = kma_vfs_guard_init,
};

/* --- Late init: sysfs + cmdline paths (after VFS + kobject ready) --- */

static int __init kma_vfs_guard_late_init(void)
{
	int ret;

	/* Create sysfs interface — kernel_kobj is ready by late_initcall */
	kma_kobj = kobject_create_and_add(KMA_SYSFS_NAME, kernel_kobj);
	if (!kma_kobj) {
		pr_warn("%s: sysfs not available (hooks still active)\n", KMA_NAME);
	} else {
		ret = sysfs_create_group(kma_kobj, &kma_attr_group);
		if (ret) {
			pr_warn("%s: sysfs_create_group failed (%d)\n", KMA_NAME, ret);
			kobject_put(kma_kobj);
			kma_kobj = NULL;
		}
	}

	/* Process protected paths from kernel cmdline */
	if (protected_paths_param && *protected_paths_param) {
		char *path_str, *token;

		path_str = kstrdup(protected_paths_param, GFP_KERNEL);
		if (path_str) {
			for (token = strsep(&path_str, ":"); token; token = strsep(&path_str, ":")) {
				struct path path;
				if (kern_path(token, LOOKUP_FOLLOW, &path) == 0) {
					prot_add_entry(path.dentry->d_inode);
					path_put(&path);
				} else {
					pr_warn("%s: initial path '%s' not found\n",
						KMA_NAME, token);
				}
			}
			kfree(path_str);
		}
	}

	pr_info("%s: ready\n", KMA_NAME);
	return 0;
}

late_initcall(kma_vfs_guard_late_init);
