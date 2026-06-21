#!/usr/bin/env bash
# setup-vm.sh — Prepare Ubuntu VM for KMA OS kernel development
# Run inside the UTM Ubuntu VM as a regular user with sudo access.
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# --- 1. Update system ---
info "Updating package lists..."
sudo apt-get update -qq

# --- 2. Install kernel build dependencies ---
info "Installing build dependencies..."
sudo apt-get install -y -qq \
    build-essential \
    libncurses-dev \
    libssl-dev \
    libelf-dev \
    flex \
    bison \
    dwarves \
    pahole \
    python3 \
    cpio \
    zstd \
    rsync \
    bc \
    git \
    wget \
    xz-utils

info "Build dependencies installed"

# --- 3. Configure SSH ---
info "Setting up SSH server..."
sudo apt-get install -y -qq openssh-server
sudo systemctl enable --now ssh

VM_IP=$(hostname -I | awk '{print $1}')
info "SSH ready — connect from host: ssh kma@${VM_IP}"

# --- 4. Setup shared folder mount point ---
info "Setting up shared folder mount..."
sudo mkdir -p /mnt/shared

if ! grep -q "9p.*KMA-SRC" /etc/fstab 2>/dev/null; then
    warn "Add to /etc/fstab (after UTM share configured):"
    echo "  KMA-SRC  /mnt/shared  9p  trans=virtio,version=9p2000.L,_netdev  0  0"
    warn "Or mount manually: sudo mount -t 9p -o trans=virtio,version=9p2000.L KMA-SRC /mnt/shared"
else
    info "Shared folder already configured in fstab"
fi

# --- 5. Create 8GB swap file ---
info "Setting up swap (8GB)..."
SWAPFILE="/swapfile"
if [ ! -f "$SWAPFILE" ]; then
    sudo fallocate -l 8G "$SWAPFILE"
    sudo chmod 600 "$SWAPFILE"
    sudo mkswap -q "$SWAPFILE"
    sudo swapon "$SWAPFILE"
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
    info "Swap enabled: $(free -h | grep Swap | awk '{print $2}')"
else
    info "Swap file already exists"
fi

# --- 6. Create kernel source directory ---
mkdir -p ~/kernel-src
info "Kernel source directory: ~/kernel-src"

# --- 7. Summary ---
echo ""
info "=== VM Setup Complete ==="
echo "  RAM:       $(free -h | grep Mem | awk '{print $2}')"
echo "  Swap:      $(free -h | grep Swap | awk '{print $2}')"
echo "  CPU cores: $(nproc)"
echo "  Disk free: $(df -h / | tail -1 | awk '{print $4}')"
echo "  SSH:       ssh kma@${VM_IP}"
echo ""
info "Next: sync kernel source with scripts/sync-to-vm.sh"
