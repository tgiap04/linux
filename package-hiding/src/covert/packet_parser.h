#ifndef COVERT_PACKET_PARSER_H
#define COVERT_PACKET_PARSER_H

#include <linux/skbuff.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>

/*
 * Parsed packet information extracted from sk_buff.
 */
struct covert_packet_info {
	struct iphdr  *iph;
	struct tcphdr *tcph;  /* NULL if UDP */
	struct udphdr *udph;  /* NULL if TCP */
	__be32         src_ip;
	__be32         dst_ip;
	__be16         src_port;
	__be16         dst_port;
	__u8           protocol;  /* IPPROTO_TCP or IPPROTO_UDP */
};

/**
 * covert_parse_packet - Parse headers from sk_buff.
 * @skb:    network packet
 * @info:   output: parsed packet info
 *
 * Returns 0 on success, -1 on parse failure.
 */
int covert_parse_packet(struct sk_buff *skb, struct covert_packet_info *info);

/**
 * covert_is_target_packet - Check if packet matches target IP/port.
 * @info:      parsed packet info
 * @target_ip: target IP in network byte order
 * @target_port: target port in network byte order
 *
 * Returns 1 if target, 0 otherwise.
 */
int covert_is_target_packet(const struct covert_packet_info *info,
			    __be32 target_ip, __be16 target_port);

#endif /* COVERT_PACKET_PARSER_H */
