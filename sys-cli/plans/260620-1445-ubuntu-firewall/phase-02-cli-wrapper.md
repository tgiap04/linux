# Phase 02: CLI Wrapper + sys-cli.sh Integration

## Overview
- Priority: High
- Status: Pending
- Description: Shell functions to insmod/rmmod, toggle sysfs, read status — new menu in sys-cli.sh

## Requirements
- `firewall_load` — insmod the kernel module
- `firewall_unload` — rmmod the module
- `firewall_enable` / `firewall_disable` — toggle sysfs enabled
- `firewall_set_icmp` — toggle drop_icmp
- `firewall_set_ports` — configure reject_ports
- `firewall_status` — show sysfs status + recent dmesg entries
- `firewall_logs` — show filtered dmesg output
- New standalone menu in sys-cli.sh (module 7), not merged into network_menu
- Replace `network_firewall_status()` in network-mgmt.sh with module-not-loaded notice

## Sysfs path conventions
All reads/writes go through `/sys/firewall/`:
```bash
cat /sys/firewall/enabled
echo 1 > /sys/firewall/drop_icmp
```

## Files to create
- `lib/firewall-mgmt.sh` (~120 lines)

## Files to modify
- `sys-cli.sh` — source lib/firewall-mgmt.sh, add module 7 to menu
- `lib/network-mgmt.sh` — replace firewall_status function

## Implementation Steps
1. Create `lib/firewall-mgmt.sh` with `firewall_menu()` and helper functions
2. Add `source "$SCRIPT_DIR/lib/firewall-mgmt.sh"` to sys-cli.sh
3. Add "Kernel Firewall" option to sys-cli.sh main menu
4. Replace `network_firewall_status()` in network-mgmt.sh with a note about using the firewall module
5. Each function uses `runSudo` pattern for insmod/rmmod, plain `cat/echo` for sysfs reads/writes

## Success Criteria
- `sys-cli.sh` shows "Kernel Firewall" as option 7
- `firewall_menu` provides sub-menu: Load, Unload, Enable/Disable, Set ICMP, Set Ports, Status, Logs, Back
- `firewall_status` shows current sysfs values + last 10 dmesg entries for ubuntu_firewall
- `firewall_load` calls insmod with sudo, shows success/error
- Network menu no longer has "Firewall status" option (replaced with note or removed)

## Risk Assessment
- Shell wrapper runs on macOS but commands won't execute without Linux kernel
- Input validation needed for port numbers in `firewall_set_ports`
