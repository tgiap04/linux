# Covert Channel Kernel Module

Hidden data channel via TCP/UDP header embedding using Linux Netfilter hooks.

## Build

```bash
# Install kernel headers (Ubuntu/Debian)
sudo apt install linux-headers-$(uname -r) build-essential

# Build the module
make
```

## Load

```bash
# Load with default settings (port 9999, IP 10.0.2.15)
sudo insmod covert.ko

# Load with custom settings
sudo insmod covert.ko target_port=8080 target_ip="192.168.1.100"

# Check module info
lsmod | grep covert
dmesg | tail -20
```

## Unload

```bash
sudo rmmod covert
dmesg | tail -10
```

## Send Messages

Messages are queued to the module via a sysfs interface (planned) or hardcoded in the module for testing. Currently, the module embeds framing markers (`0xFF00` start, `0xFFFF` end) around each message.

## Receive Messages

```bash
cd src/receiver

# Listen for TCP covert channel
sudo python3 tcp_receiver.py --port 9999

# Listen for UDP covert channel
sudo python3 udp_receiver.py --port 9999
```

## Architecture

```
Sender Machine                          Receiver Machine
┌──────────────────┐                   ┌──────────────────┐
│  covert.ko       │                   │  tcp_receiver.py │
│  ┌────────────┐  │    TCP/UDP        │  (Python/Scapy)  │
│  │ Netfilter  │──│─── packets ───────│──► Decode markers │
│  │ Hook       │  │    (port 9999)    │  └────────────────┘
│  │ Embed byte │  │                   │
│  │ in header  │  │                   │
│  └────────────┘  │                   │
└──────────────────┘                   └──────────────────┘
```

## How It Works

1. **Netfilter hook** intercepts outgoing packets to the target port
2. **Framing protocol** wraps message: `0xFF 0x00 [data...] 0xFF 0xFF`
3. **Embedding** hides one byte per packet:
   - TCP: lower 8 bits of TCP sequence number
   - UDP: lower 8 bits of IP Identification field
4. **Checksum recalculation** ensures packets are valid
5. **Receiver (Scapy)** captures packets, extracts hidden bytes, reassembles message

## Cleanup

Module properly unregisters all Netfilter hooks on `rmmod`. No resources leaked.

## Troubleshooting

```bash
# Module won't load — check kernel headers
ls /lib/modules/$(uname -r)/build

# No packets intercepted — check target port/IP
dmesg | grep "covert:"

# Bad checksum in Wireshark — verify covert_tcp_recalc_checksum() is called
```
