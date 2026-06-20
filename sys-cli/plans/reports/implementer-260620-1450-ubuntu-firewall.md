# Implementation Report

## Task
- Task: Phase 01 — Linux kernel module `ubuntu_firewall`
- Status: completed

## Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `kernel/ubuntu_firewall.c` | 319 | Netfilter module |
| `kernel/Makefile` | 9 | Kernel build target |

## Acceptance Criteria

- [x] `kernel/ubuntu_firewall.c` created with full implementation
- [x] `kernel/Makefile` created with `obj-m := ubuntu_firewall.o`
- [x] Hook on `NF_INET_PRE_ROUTING`, priority `NF_IP_PRI_FIRST + 1`
- [x] ICMP drop when `drop_icmp=1`, TCP port reject via `reject_ports`
- [x] All other packets return `NF_ACCEPT`
- [x] Sysfs at `/sys/firewall/` with `enabled`, `drop_icmp`, `reject_ports`, `status`
- [x] Atomic counters for dropped/rejected packets
- [x] Port bounds validation (1–65535) on `reject_ports` write
- [x] Proper cleanup in module exit (hook unregister, sysfs remove, port array free)
- [x] `MODULE_LICENSE("GPL")`, `MODULE_AUTHOR("Tobi")`, `MODULE_DESCRIPTION(...)`
- [x] `[ubuntu_firewall]` prefix on all printk output
- [x] `firewall_kobj` declared as global (fix applied during implementation)

## Design Notes

- Line count is ~319 vs ~180 spec target. The spec target is too aggressive for a full
  netfilter module with proper sysfs, port-parsing, mutex-protected shared state, and
  all error unwind paths. All required functionality is present.
- `module_param_named` calls were removed (cannot alias `atomic_t` to `int` for module params);
  sysfs attributes (`/sys/firewall/enabled`, `/sys/firewall/drop_icmp`) provide the same
  runtime-config interface cleanly.

## Test Status
- Cannot build on macOS (no Linux kernel headers); C code reviewed for correct kernel API usage.
- Build on Linux: `cd kernel && make`

## Issues Encountered
- `firewall_kobj` was declared locally inside `ubuntu_firewall_init()` but referenced in
  `ubuntu_firewall_exit()`. Fixed by hoisting to file scope.
- Two `module_param_named()` calls targeting `atomic_t` variables would not compile.
  Removed; sysfs attributes already provide equivalent runtime configuration.
