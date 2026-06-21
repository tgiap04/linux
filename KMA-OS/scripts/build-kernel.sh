#!/usr/bin/env bash
# build-kernel.sh — Clone, configure, and build KMA OS minimal kernel
# Run inside the Ubuntu VM.
set -euo pipefail

# --- Configuration ---
KMA_KERNEL_SRC="${KMA_KERNEL_SRC:-$HOME/kernel-src/ubuntu-kernel}"
KMA_LOCALVERSION="${KMA_LOCALVERSION:--kma-os-minimal}"
KMA_KERNEL_TAG="${KMA_KERNEL_TAG:-Ubuntu-7.0.0-22.22}"
KMA_KERNEL_REPO="${KMA_KERNEL_REPO:-git://kernel.ubuntu.com/ubuntu/ubuntu-oracular.git}"
KMA_JOBS="${KMA_JOBS:-$(nproc)}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# --- 1. Clone or update kernel source ---
if [ ! -d "$KMA_KERNEL_SRC/.git" ]; then
    info "Cloning Ubuntu kernel tree (this may take a while)..."
    mkdir -p "$(dirname "$KMA_KERNEL_SRC")"
    git clone --depth=1 --branch "$KMA_KERNEL_TAG" "$KMA_KERNEL_REPO" "$KMA_KERNEL_SRC" 2>/dev/null \
        || git clone --depth=1 "$KMA_KERNEL_REPO" "$KMA_KERNEL_SRC"
    cd "$KMA_KERNEL_SRC"
    git fetch --tags 2>/dev/null || true
    git checkout "$KMA_KERNEL_TAG" 2>/dev/null || warn "Tag $KMA_KERNEL_TAG not found, using default branch"
else
    info "Kernel source exists at $KMA_KERNEL_SRC"
    cd "$KMA_KERNEL_SRC"
    git pull --ff-only 2>/dev/null || warn "Pull failed, using existing source"
fi

# --- 2. Set LOCALVERSION ---
export LOCALVERSION="$KMA_LOCALVERSION"
info "LOCALVERSION=$LOCALVERSION"

# --- 3. Configure with localmodconfig ---
info "Generating minimal config via localmodconfig..."
if [ -f /proc/modules ]; then
    make localmodconfig
else
    warn "Not running inside VM — using default config"
    make defconfig
fi

# Verify LOCALVERSION in .config
ACTUAL_LOCAL=$(grep CONFIG_LOCALVERSION= .config | cut -d'"' -f2)
if [ "$ACTUAL_LOCAL" = "$KMA_LOCALVERSION" ]; then
    info "Config LOCALVERSION verified: $ACTUAL_LOCAL"
else
    warn "LOCALVERSION mismatch: expected=$KMA_LOCALVERSION got=$ACTUAL_LOCAL"
    warn "Updating .config..."
    scripts/config --set-str LOCALVERSION "$KMA_LOCALVERSION"
    make olddefconfig
fi

# --- 4. Build ---
info "Building kernel with -j${KMA_JOBS}..."
BUILD_START=$(date +%s)
make -j"$KMA_JOBS" 2>&1 | tail -5
BUILD_END=$(date +%s)
BUILD_MIN=$(( (BUILD_END - BUILD_START) / 60 ))
BUILD_SEC=$(( (BUILD_END - BUILD_START) % 60 ))
info "Build completed in ${BUILD_MIN}m${BUILD_SEC}s"

# --- 5. Install ---
info "Installing modules..."
sudo make modules_install

info "Installing kernel..."
sudo make install

# --- 6. Update GRUB ---
info "Updating GRUB..."
sudo update-grub 2>/dev/null || sudo grub-mkconfig -o /boot/grub/grub.cfg

# --- 7. Summary ---
NEW_KERNEL=$(make kernelrelease 2>/dev/null || echo "unknown")
info "=== Build Complete ==="
echo "  Kernel:    $NEW_KERNEL"
echo "  Build dir: $KMA_KERNEL_SRC"
echo "  Config:    $KMA_KERNEL_SRC/.config"
echo ""
info "Reboot into new kernel: sudo reboot"
info "After reboot, verify: uname -r"
