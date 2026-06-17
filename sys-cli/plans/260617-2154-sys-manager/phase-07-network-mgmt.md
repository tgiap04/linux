# Phase 07: File Descriptors, Sockets & Network Management

**Priority:** High
**Status:** Complete
**Blocks:** None | **Blocked by:** Phase 01

## Overview

Implement `lib/network-mgmt.sh` covering socket inspection, network interfaces, connectivity testing, DNS, and firewall status.

## Files to Create

- `lib/network-mgmt.sh`

## Features

- List listening ports & socket connections
- Show network interfaces & IP addresses
- Show routing table
- Test connectivity (ping / TCP)
- DNS lookup
- List open file descriptors for a process
- Firewall status

## Implementation Steps

1. `network_menu()` — `select` submenu:
   - List listening ports & sockets
   - Show network interfaces
   - Show routing table
   - Test connectivity
   - DNS lookup
   - Open file descriptors (lsof)
   - Firewall status
   - Back

2. `network_list_sockets()`:
   - Primary: `ss -tulpn` (iproute2, present on all target distros)
   - Fallback: `netstat -tulpn 2>/dev/null`
   - Last resort: parse `/proc/net/tcp` + `/proc/net/tcp6`
   - Format: awk printf tabular output (Proto, Local Address, State, Process)

3. `network_show_interfaces()`:
   - Primary: `ip addr show`
   - Fallback: `ifconfig 2>/dev/null`
   - Last resort: read `/proc/net/if_inet6` + `/proc/net/fib_trie`
   - Print: interface name, IPv4, IPv6, state (UP/DOWN)

4. `network_show_routes()`:
   - Primary: `ip route show`
   - Fallback: `route -n 2>/dev/null`
   - Print default gateway clearly

5. `network_test_connectivity()`:
   - Prompt for host/IP to test
   - Step 1 — ICMP ping (3 packets): `ping -c 3 -W 2 "$host"`
     - Note: ICMP may be blocked by firewall — warn on failure, not just "host down"
   - Step 2 — TCP probe (prompt for port, default 80):
     - If `nc` available: `nc -zw3 "$host" "$port"`
     - Fallback: `bash -c ">/dev/tcp/$host/$port" 2>/dev/null`
   - Report both results distinctly

6. `network_dns_lookup()`:
   - Prompt for hostname or IP (reverse lookup if IP)
   - Fallback chain:
     - `dig +short "$host"` if available
     - `host "$host"` if available
     - `nslookup "$host"` if available
     - `getent hosts "$host"` (always present via glibc NSS)

7. `network_list_fds()`:
   - Prompt for PID (or process name → resolve via `pgrep -n`)
   - Primary: `lsof -p "$pid"` if available
   - Fallback: list `/proc/"$pid"/fd/` symlinks with `ls -la`
   - Guard: `[[ -d "/proc/$pid" ]]` before accessing

8. `network_firewall_status()`:
   - Detection chain:
     - `ufw status verbose` (Ubuntu/Debian)
     - `firewall-cmd --state && firewall-cmd --list-all` (RHEL/Fedora)
     - `iptables -L -n -v` (universal fallback)
     - `nft list ruleset` (nftables systems)
   - Run whichever is found, warn if none detected

## Fallback Chain Summary

```
ss → netstat → /proc/net/tcp
ip addr → ifconfig → /proc/net/if_inet6
dig → host → nslookup → getent hosts
nc → bash /dev/tcp
lsof → /proc/<pid>/fd
ufw → firewall-cmd → iptables → nft
```

## Success Criteria

- `shellcheck lib/network-mgmt.sh` clean
- All operations have at least one zero-dep fallback
- TCP connectivity test works without nc/curl (bash /dev/tcp)
- DNS lookup works without dig (getent hosts)
- Firewall section runs on ufw, firewalld, and iptables systems
- File under 200 lines
