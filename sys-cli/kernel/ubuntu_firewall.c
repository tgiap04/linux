// SPDX-License-Identifier: GPL-2.0
/*
 * ubuntu_firewall.c - Mini netfilter firewall for sys-cli
 *
 * Hooks NF_INET_PRE_ROUTING to drop ICMP and reject TCP on configured ports.
 * Sysfs at /sys/firewall/{enabled,drop_icmp,reject_ports,status}.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/skbuff.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/netfilter.h>
#include <linux/netfilter_ipv4.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/string.h>
#include <linux/atomic.h>
#include <linux/slab.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Tobi");
MODULE_DESCRIPTION("Mini netfilter firewall for sys-cli");

#define MAX_PORTS 64

/* ── Globals ─────────────────────────────────────────────────────────────── */
static struct kobject *firewall_kobj;

/* ── Counters ───────────────────────────────────────────────────────────── */
static atomic_t dropped_count  = ATOMIC_INIT(0);
static atomic_t rejected_count = ATOMIC_INIT(0);

/* ── Runtime config ─────────────────────────────────────────────────────── */
static atomic_t enabled      = ATOMIC_INIT(1);
static atomic_t drop_icmp    = ATOMIC_INIT(1);
static int     *reject_ports;
static atomic_t reject_ports_cnt = ATOMIC_INIT(0);
static DEFINE_MUTEX(reject_ports_lock);

static int port_array_contains(int port)
{
	int i, cnt;
	mutex_lock(&reject_ports_lock);
	cnt = atomic_read(&reject_ports_cnt);
	for (i = 0; i < cnt; i++) {
		if (reject_ports[i] == port) {
			mutex_unlock(&reject_ports_lock);
			return 1;
		}
	}
	mutex_unlock(&reject_ports_lock);
	return 0;
}

static void free_reject_ports(void)
{
	mutex_lock(&reject_ports_lock);
	kfree(reject_ports);
	reject_ports = NULL;
	atomic_set(&reject_ports_cnt, 0);
	mutex_unlock(&reject_ports_lock);
}

static int parse_reject_ports(const char *buf, size_t count)
{
	int *new_ports, new_cnt = 0;
	char *copy, *tok;
	int ret = -EINVAL;

	new_ports = kcalloc(MAX_PORTS, sizeof(*new_ports), GFP_KERNEL);
	if (!new_ports)
		return -ENOMEM;

	copy = kstrndup(buf, count, GFP_KERNEL);
	if (!copy)
		goto out;

	tok = strim(copy);
	/* Empty string clears the port list */
	if (!*tok) {
		ret = 0;
		mutex_lock(&reject_ports_lock);
		swap(reject_ports, new_ports);
		atomic_set(&reject_ports_cnt, 0);
		mutex_unlock(&reject_ports_lock);
		goto out_copy;
	}
	while (tok && new_cnt < MAX_PORTS) {
		char *comma = strchr(tok, ',');
		int port;
		if (comma)
			*comma = '\0';
		if (kstrtoint(strim(tok), 10, &port) != 0 ||
		    port < 1 || port > 65535) {
			pr_err("[ubuntu_firewall] invalid port: %s\n",
			       strim(tok));
			goto out_copy;
		}
		new_ports[new_cnt++] = port;
		tok = comma ? comma + 1 : NULL;
	}

	ret = new_cnt;

	mutex_lock(&reject_ports_lock);
	swap(reject_ports, new_ports);
	atomic_set(&reject_ports_cnt, new_cnt);
	mutex_unlock(&reject_ports_lock);

out_copy:
	kfree(copy);
out:
	kfree(new_ports);
	return ret;
}

/* ── Sysfs attributes ───────────────────────────────────────────────────── */
static ssize_t enabled_show(struct kobject *kobj, struct kobj_attribute *attr,
			    char *buf)
{
	return sysfs_emit(buf, "%d\n", atomic_read(&enabled));
}

static ssize_t enabled_store(struct kobject *kobj, struct kobj_attribute *attr,
			     const char *buf, size_t count)
{
	int val;
	if (kstrtoint(buf, 10, &val) != 0 || val < 0 || val > 1)
		return -EINVAL;
	atomic_set(&enabled, val);
	return count;
}

static ssize_t drop_icmp_show(struct kobject *kobj, struct kobj_attribute *attr,
			      char *buf)
{
	return sysfs_emit(buf, "%d\n", atomic_read(&drop_icmp));
}

static ssize_t drop_icmp_store(struct kobject *kobj, struct kobj_attribute *attr,
			       const char *buf, size_t count)
{
	int val;
	if (kstrtoint(buf, 10, &val) != 0 || val < 0 || val > 1)
		return -EINVAL;
	atomic_set(&drop_icmp, val);
	return count;
}

static ssize_t reject_ports_show(struct kobject *kobj,
				 struct kobj_attribute *attr, char *buf)
{
	int i, cnt;
	ssize_t off = 0;
	mutex_lock(&reject_ports_lock);
	cnt = atomic_read(&reject_ports_cnt);
	for (i = 0; i < cnt; i++) {
		if (i)
			buf[off++] = ',';
		off += scnprintf(buf + off, PAGE_SIZE - off, "%d",
				 reject_ports[i]);
	}
	mutex_unlock(&reject_ports_lock);
	off += scnprintf(buf + off, PAGE_SIZE - off, "\n");
	return off;
}

static ssize_t reject_ports_store(struct kobject *kobj,
				  struct kobj_attribute *attr,
				  const char *buf, size_t count)
{
	if (!count)
		return -EINVAL;
	if (parse_reject_ports(buf, count) < 0)
		return -EINVAL;
	return count;
}

static ssize_t status_show(struct kobject *kobj, struct kobj_attribute *attr,
			   char *buf)
{
	int i, cnt;
	ssize_t off = 0;
	off += scnprintf(buf + off, PAGE_SIZE - off,
			 "enabled=%d drop_icmp=%d rejected_count=%d dropped_count=%d\nreject_ports=",
			 atomic_read(&enabled), atomic_read(&drop_icmp),
			 atomic_read(&rejected_count),
			 atomic_read(&dropped_count));
	mutex_lock(&reject_ports_lock);
	cnt = atomic_read(&reject_ports_cnt);
	for (i = 0; i < cnt; i++)
		off += scnprintf(buf + off, PAGE_SIZE - off,
				 "%s%d", i ? "," : "", reject_ports[i]);
	mutex_unlock(&reject_ports_lock);
	off += scnprintf(buf + off, PAGE_SIZE - off, "\n");
	return off;
}

static struct kobj_attribute enabled_attr      = __ATTR_RW(enabled);
static struct kobj_attribute drop_icmp_attr    = __ATTR_RW(drop_icmp);
static struct kobj_attribute reject_ports_attr  = __ATTR_RW(reject_ports);
static struct kobj_attribute status_attr        = __ATTR_RO(status);

static struct attribute *firewall_attrs[] = {
	&enabled_attr.attr, &drop_icmp_attr.attr,
	&reject_ports_attr.attr, &status_attr.attr, NULL,
};

/* Root group — attrs appear directly under /sys/firewall/ */

static struct attribute_group firewall_attr_group = {
	.attrs = firewall_attrs,
};

/* ── Netfilter hook ─────────────────────────────────────────────────────── */
static struct nf_hook_ops *nf_ops;

static unsigned int firewall_hook(void *priv, struct sk_buff *skb,
				 const struct nf_hook_state *state)
{
	struct iphdr *iph;
	struct tcphdr *tcph;
	int proto, dport;

	if (!atomic_read(&enabled))
		return NF_ACCEPT;

	if (state->hook != NF_INET_PRE_ROUTING)
		return NF_ACCEPT;

	if (!skb || !(iph = ip_hdr(skb)))
		return NF_ACCEPT;

	proto = iph->protocol;

	if (proto == IPPROTO_ICMP && atomic_read(&drop_icmp)) {
		atomic_inc(&dropped_count);
		pr_info("[ubuntu_firewall] DROP ICMP\n");
		return NF_DROP;
	}

	if (proto == IPPROTO_TCP && (tcph = tcp_hdr(skb))) {
		dport = ntohs(tcph->dest);
		if (port_array_contains(dport)) {
			atomic_inc(&rejected_count);
			pr_info("[ubuntu_firewall] REJECT TCP port %d\n",
				dport);
			return NF_DROP;
		}
	}

	return NF_ACCEPT;
}

/* ── Module init / exit ──────────────────────────────────────────────────── */
static int ubuntu_firewall_init(void)
{
	struct nf_hook_ops *ops;
	int ret;

	reject_ports = kcalloc(MAX_PORTS, sizeof(*reject_ports), GFP_KERNEL);
	if (!reject_ports)
		return -ENOMEM;

	firewall_kobj = kobject_create_and_add("firewall", NULL);
	if (!firewall_kobj) {
		ret = -ENOMEM;
		goto out_free;
	}

	ret = sysfs_create_group(firewall_kobj, &firewall_attr_group);
	if (ret) {
		pr_err("[ubuntu_firewall] sysfs group failed: %d\n", ret);
		goto out_kobj;
	}

	ops = kcalloc(1, sizeof(*ops), GFP_KERNEL);
	if (!ops) {
		ret = -ENOMEM;
		goto out_sysfs;
	}
	ops->hook     = firewall_hook;
	ops->pf       = NFPROTO_IPV4;
	ops->hooknum  = NF_INET_PRE_ROUTING;
	ops->priority = NF_IP_PRI_FIRST + 1;

	ret = nf_register_net_hook(&init_net, ops);
	if (ret) {
		pr_err("[ubuntu_firewall] hook registration failed: %d\n",
		       ret);
		goto out_ops;
	}

	nf_ops = ops;
	pr_info("[ubuntu_firewall] firewall activated\n");
	return 0;

out_ops:
	kfree(ops);
out_sysfs:
	sysfs_remove_group(firewall_kobj, &firewall_attr_group);
out_kobj:
	kobject_put(firewall_kobj);
out_free:
	kfree(reject_ports);
	return ret;
}

static void ubuntu_firewall_exit(void)
{
	if (nf_ops) {
		nf_unregister_net_hook(&init_net, nf_ops);
		kfree(nf_ops);
		nf_ops = NULL;
	}

	if (firewall_kobj) {
		sysfs_remove_group(firewall_kobj, &firewall_attr_group);
		kobject_put(firewall_kobj);
		firewall_kobj = NULL;
	}

	free_reject_ports();
	pr_info("[ubuntu_firewall] firewall deactivated\n");
}

module_init(ubuntu_firewall_init);
module_exit(ubuntu_firewall_exit);
