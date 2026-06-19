---
name: Covert Channel Implementation Plan
status: in_progress
created: 2026-06-19T15:44:00+07:00
branch: main
---

# Implementation Plan: Covert Channel TCP/UDP

## Overview
Linux Kernel Module (LKM) hiding secret data in TCP/UDP packet headers via Netfilter hooks, with a Python/Scapy user-space receiver.

## Target Environment
- Ubuntu Server VM (kernel 5.15+)
- Build: GCC, make, linux-headers-$(uname -r)
- Receiver: Python 3.10+, Scapy

## Phases

### Phase 0: Build System
- `src/covert/Makefile` — Kbuild for out-of-tree module
- `src/covert/Kbuild` — obj-m definition

### Phase 1: Kernel Module Foundation
- `src/covert/covert.c` — Main module: init, exit, parameters, logging
- `src/covert/Makefile` — Build system
- Features: Hello World, Netfilter hook, cleanup, MODULE_PARM

### Phase 2: Sender Logic
- `src/covert/packet_parser.c/.h` — sk_buff parsing, filter by target port
- `src/covert/tcp_embed.c/.h` — TCP header data embedding + checksum
- `src/covert/udp_embed.c/.h` — UDP header data embedding + checksum
- `src/covert/error_handler.c/.h` — Safe error handling in hook

### Phase 3: Framing Protocol
- `src/covert/framing.c/.h` — Start/End marker protocol (0xFF00/0xFFFF)
- `src/covert/message_buffer.c/.h` — Circular buffer for outgoing messages

### Phase 4: Receiver (Python)
- `src/receiver/tcp_receiver.py` — Scapy TCP listener on port 9999
- `src/receiver/udp_receiver.py` — Scapy UDP listener on port 9999
- Both decode framing protocol, reassemble messages

## File Count
~12 files (8 C/headers + 2 Python + Makefile + README)

## Key Design Decisions
- Module params: target_port (default 9999), target_ip (default "10.0.2.15")
- Embed 1 byte per packet into TCP seq number (bits 0-7) or IP ID
- Framing: 0xFF00 (start) → data bytes → 0xFFFF (end)
- Receiver: Scapy raw socket, kernel BPF filter
- License: GPL v2 (required for kernel modules)

## Not in Scope
- Stealth/anti-detection
- IPv6
- Multi-packet fragmentation
- Encryption of hidden data
- Automated test harness (manual validation only)
