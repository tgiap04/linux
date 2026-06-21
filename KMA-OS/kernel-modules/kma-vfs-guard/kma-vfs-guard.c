// SPDX-License-Identifier: GPL-2.0
/*
 * kma-vfs-guard.c — LSM module to block unlink on protected directories
 *
 * Uses hash table + RCU for O(1) lockless lookup of protected inodes.
 * sysfs interface at /sys/kernel/kma-vfs-guard/ for runtime management.
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/security.h>
#include <linux/lsm_hooks.h>
#include <linux/fs.h>
#include <linux/namei.h>
#include <linux/slab.h>
#include <linux/hash.h>
#include <linux/rculist.h>
#include <linux/kobject.h>
#include <linux/string.h>
#include <linux/spinlock.h>
#include <linux/rhashtable.h>

#define MODULE_NAME "kma-vfs-guard"
#define HT_BITS 12  /* 4096 buckets */

/* --- Hash table for protected inodes --- */

struct prot_entry {
	struct hlist_node node;
	struct rcu_head rcu;
	unsigned long ino;
	dev_t dev;
};

/* Combined hash key: both ino and dev */
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
	u32 key = prot_hash(inode->i_ino, inode->i_sb->s_dev);

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

	/* Atomic: check + insert under single lock, no TOCTOU */
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

	pr_info("%s: protected ino=%lu dev=%u\n", MODULE_NAME, e->ino, e->dev);
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
				MODULE_NAME, inode->i_ino, inode->i_sb->s_dev);
			return;
		}
	}
	spin_unlock(&prot_lock);
}

/* --- LSM hooks --- */

static int prot_inode_unlink(struct inode *dir, struct dentry *dentry)
{
	struct inode *inode;

	if (!dentry)
		return 0;

	inode = d_inode(dentry);
	if (!inode)
		return 0;

	if (prot_lookup(inode)) {
		pr_warn("%s: blocked unlink on ino=%lu dev=%u\n",
			MODULE_NAME, inode->i_ino, inode->i_sb->s_dev);
		return -EPERM;
	}

	return 0;
}

static int prot_inode_rmdir(struct inode *dir, struct dentry *dentry)
{
	return prot_inode_unlink(dir, dentry);
}

static int prot_path_rename(const struct path *old_dir, struct dentry *old_dentry,
			     const struct path *new_dir, struct dentry *new_dentry)
{
	struct inode *inode;

	if (!old_dentry)
		return 0;

	inode = d_inode(old_dentry);
	if (!inode)
		return 0;

	/* Block rename-out of protected dirs */
	if (prot_lookup(inode)) {
		pr_warn("%s: blocked rename-out on ino=%lu dev=%u\n",
			MODULE_NAME, inode->i_ino, inode->i_sb->s_dev);
		return -EPERM;
	}

	return 0;
}

static struct security_hook_list kma_hooks[] __lsm_ro_after_init = {
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
		pr_warn("%s: path '%s' not found (%d)\n", MODULE_NAME, trimmed, ret);
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
		pr_warn("%s: path '%s' not found (%d)\n", MODULE_NAME, trimmed, ret);
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

/* --- Module params --- */

static char *protected_paths;
module_param(protected_paths, charp, 0644);
MODULE_PARM_DESC(protected_paths, "Colon-separated list of paths to protect at load");

/* --- Module init/exit --- */

static int __init kma_vfs_guard_init(void)
{
	int ret;

	ret = security_add_hooks(kma_hooks, ARRAY_SIZE(kma_hooks), MODULE_NAME);
	if (ret) {
		pr_err("%s: security_add_hooks failed (%d)\n", MODULE_NAME, ret);
		return ret;
	}

	kma_kobj = kobject_create_and_add(MODULE_NAME, kernel_kobj);
	if (!kma_kobj) {
		pr_err("%s: kobject_create_and_add failed\n", MODULE_NAME);
		return -ENOMEM;
	}

	ret = sysfs_create_group(kma_kobj, &kma_attr_group);
	if (ret) {
		pr_err("%s: sysfs_create_group failed (%d)\n", MODULE_NAME, ret);
		kobject_put(kma_kobj);
		return ret;
	}

	/* Process initial protected paths from module param */
	if (protected_paths && *protected_paths) {
		char *path_str, *token;

		path_str = kstrdup(protected_paths, GFP_KERNEL);
		if (path_str) {
			for (token = strsep(&path_str, ":"); token; token = strsep(&path_str, ":")) {
				struct path path;
				if (kern_path(token, LOOKUP_FOLLOW, &path) == 0) {
					prot_add_entry(path.dentry->d_inode);
					path_put(&path);
				} else {
					pr_warn("%s: initial path '%s' not found\n",
						MODULE_NAME, token);
				}
			}
			kfree(path_str);
		}
	}

	pr_info("%s: loaded\n", MODULE_NAME);
	return 0;
}

static void __exit kma_vfs_guard_exit(void)
{
	struct prot_entry *e;
	struct hlist_node *tmp;
	int bkt;

	/* Remove all entries */
	spin_lock(&prot_lock);
	hash_for_each_safe(prot_ht, bkt, tmp, e, node) {
		hash_del_rcu(&e->node);
		kfree(e);
	}
	spin_unlock(&prot_lock);

	sysfs_remove_group(kma_kobj, &kma_attr_group);
	kobject_put(kma_kobj);

	pr_info("%s: unloaded — hits=%lld misses=%lld\n",
		MODULE_NAME,
		atomic64_read(&stat_hits),
		atomic64_read(&stat_misses));
}

module_init(kma_vfs_guard_init);
module_exit(kma_vfs_guard_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("KMA OS");
MODULE_DESCRIPTION("LSM module to block unlink on protected directories");
MODULE_VERSION("1.0.0");
