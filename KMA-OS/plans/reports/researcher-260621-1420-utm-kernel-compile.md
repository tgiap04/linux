---
name: researcher-260621-1420-utm-kernel-compile
description: UTM VM setup research for KMA OS kernel compilation
metadata:
  type: report
---

# Study Report: UTM VM Setup for Kernel Compilation

## Key Findings

1. **UTM VM:** Virtualize → Linux → Ubuntu ISO → 50GB+ storage, 8GB+ RAM, max CPU cores
2. **Shared folder:** virtio-9p (built into UTM) — mount with `mount -t 9p -o trans=virtio,version=9p2000.L`
3. **SSH recommended:** `openssh-server` in VM for better terminal than UTM display
4. **No official CLI:** UTM has no built-in `utmctl`; community Homebrew tap exists

## Commands

```bash
# VM disk: 50GB+ (kernel source ~2GB + build artifacts ~8GB)
# RAM: 8GB min, 16GB recommended
# CPU: allocate N-2 for Intel, max cores for Apple Silicon

# SSH setup in VM:
sudo apt install -y openssh-server
ip a  # get VM IP (10.0.2.15 for default NAT)

# Shared folder mount in VM:
sudo mount -t 9p -o trans=virtio,version=9p2000.L <tag> /mnt/shared

# Swap for 8GB RAM VM:
sudo fallocate -l 8G /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
```

## Gotchas
- QEMU I/O bottleneck: use qcow2, enable hypervisor acceleration
- Swap: increase for 8GB RAM VMs doing `make -j$(nproc)`
- Apple Silicon: native ARM64, no cross-compile needed
