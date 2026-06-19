#ifndef COVERT_ERROR_HANDLER_H
#define COVERT_ERROR_HANDLER_H

#include <linux/skbuff.h>
#include <linux/kernel.h>

/*
 * Safe wrapper for sk_buff header parsing.
 * Returns NULL and logs error if header is inaccessible.
 */
static inline void *covert_skb_header(struct sk_buff *skb, int offset, int len)
{
	void *hdr = skb_header_pointer(skb, offset, len, NULL);

	if (!hdr)
		pr_warn("covert: failed to get header at offset %d (len=%d)\n", offset, len);

	return hdr;
}

/*
 * Ensure the skb has enough linear data for header extraction.
 * Returns 0 on success, -1 on failure (caller should NF_ACCEPT).
 */
static inline int covert_skb_pull(struct sk_buff *skb, unsigned int len)
{
	if (!pskb_may_pull(skb, len)) {
		pr_warn("covert: pskb_may_pull failed for %u bytes\n", len);
		return -1;
	}
	return 0;
}

/*
 * Linearize skb if it's non-linear (fragmented).
 * Returns 0 on success, -1 on failure.
 */
static inline int covert_skb_linearize(struct sk_buff *skb)
{
	if (skb_is_nonlinear(skb)) {
		if (skb_linearize(skb)) {
			pr_warn("covert: skb_linearize failed\n");
			return -1;
		}
	}
	return 0;
}

#endif /* COVERT_ERROR_HANDLER_H */
