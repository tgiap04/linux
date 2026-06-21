#!/usr/bin/env bash
# sync-to-vm.sh — rsync project source to UTM Ubuntu VM
# Run from the macOS host.
set -euo pipefail

# Configurable via env vars
KMA_VM_SSH="${KMA_VM_SSH:-tobi@192.168.64.3}"
KMA_VM_DIR="${KMA_VM_DIR:-/home/tobi/projects/linux/KMA-OS}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

echo "Syncing project to ${KMA_VM_SSH}:${KMA_VM_DIR}"

rsync -avz --progress \
    --exclude='.git/' \
    --exclude='build/' \
    --exclude='*.o' \
    --exclude='*.ko' \
    --exclude='*.mod' \
    --exclude='*.cmd' \
    --exclude='*.order' \
    --exclude='Module.symvers' \
    --exclude='node_modules/' \
    "${PROJECT_DIR}/" "${KMA_VM_SSH}:${KMA_VM_DIR}/"

info "Sync complete — verify with: ssh ${KMA_VM_SSH} 'ls ${KMA_VM_DIR}'"
