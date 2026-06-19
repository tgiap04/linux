# Delivery Report: Covert Channel TCP/UDP Implementation

**Date:** 2026-06-19
**Branch:** main
**Status:** Complete (cannot compile on macOS — needs Linux VM)

## Files Created

### Kernel Module (`src/covert/`)
| File | Purpose | Lines |
|------|---------|-------|
| `covert_main.c` | Module init/exit, Netfilter hooks, parameters | 207 |
| `packet_parser.c/.h` | sk_buff parsing, target port/IP filtering | 85 |
| `tcp_embed.c/.h` | TCP seq number embedding + checksum | 83 |
| `udp_embed.c/.h` | IP ID field embedding + checksum | 47 |
| `framing.c/.h` | Start/End marker protocol (0xFF00/0xFFFF) | 130 |
| `error_handler.h` | Safe skb header parsing wrappers | 50 |
| `Makefile` | Kernel module build system | 20 |

### Receiver (`src/receiver/`)
| File | Purpose | Lines |
|------|---------|-------|
| `tcp_receiver.py` | Scapy TCP listener, extracts from TCP seq | 115 |
| `udp_receiver.py` | Scapy UDP listener, extracts from IP ID | 110 |

### Documentation
| File | Purpose |
|------|---------|
| `src/covert/README.md` | Build, load, use instructions |
| `user_stories.md` | Updated: 6 → 12 stories |
| `plans/260619-1544-.../plan.md` | Implementation plan |

## Bugs Fixed During Review
1. **Typo:** `coevert_skb_pull` → `covert_skb_pull` (error_handler.h)
2. **Critical framing bug:** State machine was broken — rewrote with proper PHASE_* state tracking (framing.c)

## Known Limitations
- **Cannot compile on macOS** — kernel module requires Linux build system
- **No sysfs interface** — messages currently hardcoded in module for testing
- **Static phase variable** in framing.c — works because spinlock protects the call, but not reentrant-safe for multiple messages concurrently

## Validation Steps (on Linux VM)
```bash
# 1. Build
cd src/covert && make

# 2. Load module
sudo insmod covert.ko target_port=9999

# 3. Send test traffic
nc -u 127.0.0.1 9999 < /dev/null

# 4. Check dmesg
dmesg | tail -20

# 5. Receiver (separate terminal)
cd src/receiver
sudo python3 tcp_receiver.py --port 9999 --verbose

# 6. Unload
sudo rmmod covert
```
