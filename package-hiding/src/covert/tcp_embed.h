#ifndef COVERT_TCP_EMBED_H
#define COVERT_TCP_EMBED_H

#include <linux/skbuff.h>

/**
 * covert_tcp_embed_byte - Embed one byte into TCP sequence number.
 * @skb:    network packet (must be TCP)
 * @byte:   the byte to embed
 *
 * Embeds the byte into the lower 8 bits of the TCP sequence number.
 * Recalculates TCP checksum after modification.
 *
 * Returns 0 on success, -1 on failure.
 */
int covert_tcp_embed_byte(struct sk_buff *skb, u8 byte);

/**
 * covert_tcp_extract_byte - Extract one byte from TCP sequence number.
 * @skb:    network packet (must be TCP)
 * @out:    output byte
 *
 * Returns 0 on success, -1 on failure.
 */
int covert_tcp_extract_byte(struct sk_buff *skb, u8 *out);

/**
 * covert_tcp_recalc_checksum - Recalculate IP and TCP checksums.
 * @skb:    network packet
 *
 * Must be called after any header modification.
 */
void covert_tcp_recalc_checksum(struct sk_buff *skb);

#endif /* COVERT_TCP_EMBED_H */
