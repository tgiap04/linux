savedcmd_ubuntu_firewall.mod := printf '%s\n'   ubuntu_firewall.o | awk '!x[$$0]++ { print("./"$$0) }' > ubuntu_firewall.mod
