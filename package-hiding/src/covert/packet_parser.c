#include "packet_parser.h"
#include "error_handler.h"
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>

int covert_parse_packet(struct sk_buff *skb, struct covert_packet_info *info)
{
	int ip_hdr_len;

	memset(info, 0, sizeof(*info));

	/* Linearize if fragmented */
	if (covert_skb_linearize(skb) < 0)
		return -1;

	/* Parse IP header */
	info->iph = covert_skb_header(skb, 0, sizeof(struct iphdr));
	if (!info->iph)
		return -1;

	ip_hdr_len = info->iph->ihl * 4;
	if (ip_hdr_len < sizeof(struct iphdr)) {
		pr_warn("covert: invalid IP header length %d\n", ip_hdr_len);
		return -1;
	}

	info->src_ip   = info->iph->saddr;
	info->dst_ip   = info->iph->daddr;
	info->protocol = info->iph->protocol;

	/* Parse transport header */
	if (info->protocol == IPPROTO_TCP) {
		info->tcph = covert_skb_header(skb, ip_hdr_len, sizeof(struct tcphdr));
		if (!info->tcph)
			return -1;
		info->src_port = info->tcph->source;
		info->dst_port = info->tcph->dest;

	} else if (info->protocol == IPPROTO_UDP) {
		info->udph = covert_skb_header(skb, ip_hdr_len, sizeof(struct udphdr));
		if (!info->udph)
			return -1;
		info->src_port = info->udph->source;
		info->dst_port = info->udph->dest;

	} else {
		return -1; /* Not TCP/UDP */
	}

	return 0;
}

int covert_is_target_packet(const struct covert_packet_info *info,
			    __be32 target_ip, __be16 target_port)
{
	if (!info->iph)
		return 0;

	/* Match destination IP (if target_ip != 0 means any IP) */
	if (target_ip != 0 && info->dst_ip != target_ip)
		return 0;

	/* Match destination port */
	if (info->dst_port != target_port)
		return 0;

	return 1;
}
