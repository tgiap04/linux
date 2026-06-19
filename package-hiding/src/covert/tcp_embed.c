#include "tcp_embed.h"
#include "error_handler.h"
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/checksum.h>
#include <net/checksum.h>

int covert_tcp_embed_byte(struct sk_buff *skb, u8 byte)
{
	struct iphdr *iph;
	struct tcphdr *tcph;
	int ip_hdr_len;
	u32 orig_seq, new_seq;

	if (covert_skb_linearize(skb) < 0)
		return -1;

	iph = covert_skb_header(skb, 0, sizeof(struct iphdr));
	if (!iph)
		return -1;

	ip_hdr_len = iph->ihl * 4;
	tcph = covert_skb_header(skb, ip_hdr_len, sizeof(struct tcphdr));
	if (!tcph)
		return -1;

	/* Embed byte into lower 8 bits of TCP sequence number */
	orig_seq = ntohl(tcph->seq);
	new_seq  = (orig_seq & 0xFFFFFF00) | (u32)byte;
	tcph->seq = htonl(new_seq);

	/* Recalculate checksums */
	covert_tcp_recalc_checksum(skb);

	pr_debug("covert: TCP seq embedded 0x%02x (0x%08x -> 0x%08x)\n",
		 byte, orig_seq, new_seq);
	return 0;
}

int covert_tcp_extract_byte(struct sk_buff *skb, u8 *out)
{
	struct iphdr *iph;
	struct tcphdr *tcph;
	int ip_hdr_len;

	if (covert_skb_linearize(skb) < 0)
		return -1;

	iph = covert_skb_header(skb, 0, sizeof(struct iphdr));
	if (!iph)
		return -1;

	ip_hdr_len = iph->ihl * 4;
	tcph = covert_skb_header(skb, ip_hdr_len, sizeof(struct tcphdr));
	if (!tcph)
		return -1;

	*out = (u8)(ntohl(tcph->seq) & 0xFF);
	return 0;
}

void covert_tcp_recalc_checksum(struct sk_buff *skb)
{
	struct iphdr *iph;
	struct tcphdr *tcph;
	int ip_hdr_len;

	iph = (struct iphdr *)skb->data;
	ip_hdr_len = iph->ihl * 4;
	tcph = (struct tcphdr *)(skb->data + ip_hdr_len);

	/* Recalculate TCP checksum */
	tcph->check = 0;
	tcph->check = tcp_v4_check(skb->len - ip_hdr_len,
				   iph->saddr, iph->daddr,
				   csum_partial((char *)tcph,
						skb->len - ip_hdr_len, 0));

	/* Recalculate IP checksum */
	iph->check = 0;
	iph->check = ip_fast_csum((unsigned char *)iph, iph->ihl);
}
