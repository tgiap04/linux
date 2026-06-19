#ifndef COVERT_UDP_EMBED_H
#define COVERT_UDP_EMBED_H

#include <linux/skbuff.h>

/**
 * covert_udp_embed_byte - Embed one byte into IP Identification field.
 * @skb:    network packet (must be UDP)
 * @byte:   the byte to embed
 *
 * Embeds the byte into the lower 8 bits of the IP ID field.
 * Recalculates IP checksum after modification.
 *
 * Returns 0 on success, -1 on failure.
 */
int covert_udp_embed_byte(struct sk_buff *skb, u8 byte);

/**
 * covert_udp_extract_byte - Extract one byte from IP Identification field.
 * @skb:    network packet (must be UDP)
 * @out:    output byte
 *
 * Returns 0 on success, -1 on failure.
 */
int covert_udp_extract_byte(struct sk_buff *skb, u8 *out);

#endif /* COVERT_UDP_EMBED_H */
