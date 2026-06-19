#include "udp_embed.h"
#include "error_handler.h"
#include <linux/ip.h>
#include <linux/udp.h>
#include <net/ip.h>

int covert_udp_embed_byte(struct sk_buff *skb, u8 byte)
{
	struct iphdr *iph;
	u16 orig_id, new_id;

	if (covert_skb_linearize(skb) < 0)
		return -1;

	/* Use skb->data directly (not skb_header_pointer which copies) */
	iph = (struct iphdr *)skb->data;

	/* Embed byte into lower 8 bits of IP Identification field */
	orig_id = ntohs(iph->id);
	new_id  = (orig_id & 0xFF00) | (u16)byte;
	iph->id  = htons(new_id);

	/* Recalculate IP checksum */
	iph->check = 0;
	iph->check = ip_fast_csum((unsigned char *)iph, iph->ihl);

	pr_debug("covert: UDP/IP ID embedded 0x%02x (0x%04x -> 0x%04x)\n",
		 byte, orig_id, new_id);
	return 0;
}

int covert_udp_extract_byte(struct sk_buff *skb, u8 *out)
{
	struct iphdr *iph;

	if (covert_skb_linearize(skb) < 0)
		return -1;

	iph = covert_skb_header(skb, 0, sizeof(struct iphdr));
	if (!iph)
		return -1;

	*out = (u8)(ntohs(iph->id) & 0xFF);
	return 0;
}
