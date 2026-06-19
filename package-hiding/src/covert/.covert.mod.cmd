savedcmd_covert.mod := printf '%s\n'   covert_main.o packet_parser.o tcp_embed.o udp_embed.o framing.o | awk '!x[$$0]++ { print("./"$$0) }' > covert.mod
