# Plan: ubuntu_firewall — Kernel Module + CLI + Web Dashboard

## Overview

Add a custom Linux kernel module (`ubuntu_firewall.ko`) with netfilter hooks, sysfs config interface, CLI wrapper, and Web UI dashboard.

**Module name:** `ubuntu_firewall`  
**Hook:** `NF_INET_PRE_ROUTING`  
**Config:** sysfs at `/sys/firewall/{enabled,drop_icmp,reject_ports,status}`  
**Logging:** `printk` → kernel ring buffer → `dmesg`

## Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 01 | ✅ Done | Kernel module (ubuntu_firewall.c + Makefile) |
| 02 | ✅ Done | CLI wrapper (lib/firewall-mgmt.sh) + sys-cli.sh integration |
| 03 | ✅ Done | Web backend (routes/firewall.js) + dashboard (firewall.html) |
| 04 | ✅ Done | Integration: network-mgmt.sh update, remove firewall tab from network.html |

## Files to create
- `kernel/ubuntu_firewall.c`
- `kernel/Makefile`
- `lib/firewall-mgmt.sh`
- `web/lib/routes/firewall.js`
- `web/public/views/firewall.html`

## Files to modify
- `sys-cli.sh` — source firewall-mgmt.sh, add menu option
- `web/server.js` — mount `/api/firewall` route
- `web/public/index.html` — add firewall nav item
- `web/public/js/components.js` — add `firewallState()`
- `web/public/views/network.html` — remove firewall tab
- `web/lib/routes/network.js` — remove `/firewall` endpoint
- `lib/network-mgmt.sh` — replace firewall_status with module check

## Key decisions
- Sysfs over /proc (more flexible for writes)
- printk over nf_log (no extra dependencies)
- Config not persistent across module reload (KISS for learning)
- CLI uses sudo for insmod/rmmod and sysfs writes
- Web backend uses existing sudo token flow for dmesg reads

## Risk
- Kernel module can only be built/tested on Linux with kernel headers
- Dev machine is macOS — shell wrapper works, module requires Ubuntu VM
