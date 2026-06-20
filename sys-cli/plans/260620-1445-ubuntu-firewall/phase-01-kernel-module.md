# Phase 01: Kernel Module (ubuntu_firewall.ko)

## Overview
- Priority: High
- Status: Pending
- Description: Create the netfilter kernel module with ICMP drop, TCP port reject, sysfs config, and printk logging

## Requirements
- Hook `NF_INET_PRE_ROUTING` to inspect incoming packets
- Drop all ICMP packets when `drop_icmp=1`
- Reject TCP packets to configured ports when `reject_ports` contains them
- Accept all other TCP/UDP traffic (SSH port 22, web port 3000 pass through)
- Export sysfs attributes at `/sys/firewall/` for runtime config
- Log every blocked packet via `printk` with protocol info
- Print activation/deactivation message to kernel ring buffer on init/exit

## Sysfs interface
- `/sys/firewall/enabled` (rw) — 0/1 toggle
- `/sys/firewall/drop_icmp` (rw) — 0/1 toggle
- `/sys/firewall/reject_ports` (rw) — comma-separated port list, e.g. "21,23,8080"
- `/sys/firewall/status` (ro) — JSON-like status: enabled, dropped_count, rejected_count, last_event

## Files to create
- `kernel/ubuntu_firewall.c` (~180 lines)
- `kernel/Makefile` (obj-m target for kernel build)

## Implementation Steps
1. Create `kernel/Makefile` with `obj-m := ubuntu_firewall.o`
2. Create `kernel/ubuntu_firewall.c`:
   - Module init/exit with printk messages
   - Netfilter hook struct on NF_INET_PRE_ROUTING
   - Hook callback: check enabled flag → drop ICMP → check reject_ports for TCP → accept rest
   - Sysfs kobject with attributes: enabled, drop_icmp, reject_ports, status
   - Module metadata (license, author, description)

## Success Criteria
- `make -C /lib/modules/$(uname -r)/build M=$PWD` compiles cleanly
- `insmod ubuntu_firewall.ko` loads without error
- `dmesg | tail` shows activation message
- sysfs attributes appear under `/sys/firewall/`
- ICMP ping is blocked when `drop_icmp=1`
- TCP connection to rejected port returns RST
- `dmesg | grep ubuntu_firewall` shows blocked packet logs

## Risk Assessment
- Requires Linux with kernel headers installed (not buildable on macOS)
- Incorrect hook logic could cause kernel panic (test on VM first)
- Must free resources properly in module exit to avoid memory leaks
