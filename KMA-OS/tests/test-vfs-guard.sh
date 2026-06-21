#!/usr/bin/env bash
# test-vfs-guard.sh — Test VFS unlink protection module
# Run as root inside VM.
set -euo pipefail

PASS=0
FAIL=0
TOTAL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

run_test() {
    local id="$1" desc="$2"
    TOTAL=$((TOTAL + 1))
    if eval "$3" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $id: $desc"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}✗${NC} $id: $desc"
        FAIL=$((FAIL + 1))
    fi
}

cleanup() {
    sudo rmmod kma-vfs-guard 2>/dev/null || true
    rm -rf /tmp/kma-vfs-test /tmp/kma-vfs-protected
}

echo "=== KMA OS VFS Guard Tests ==="
echo ""

# Ensure clean state
cleanup 2>/dev/null || true

# T4.1: Module loads
sudo insmod /lib/modules/$(uname -r)/extra/kma-vfs-guard.ko 2>/dev/null \
    || sudo insmod /usr/lib/modules/$(uname -r)/extra/kma-vfs-guard.ko 2>/dev/null \
    || sudo insmod kma-vfs-guard.ko 2>/dev/null
run_test "T4.1" "kma-vfs-guard module loads" \
    'lsmod | grep -q kma_vfs_guard'

# Setup test directories
mkdir -p /tmp/kma-vfs-protected
touch /tmp/kma-vfs-protected/testfile.txt

# Add path to protected list
echo "/tmp/kma-vfs-protected" | sudo tee /sys/kernel/kma-vfs-guard/add_path >/dev/null
sleep 0.1

# T4.2: Protected dir — rm blocked as root
run_test "T4.2" "rm /protected/file returns EPERM as root" \
    '! sudo rm -f /tmp/kma-vfs-protected/testfile.txt'

# File should still exist
run_test "T4.2b" "Protected file still exists after failed rm" \
    '[ -f /tmp/kma-vfs-protected/testfile.txt ]'

# T4.3: Unprotected dir — rm succeeds
touch /tmp/kma-vfs-unprotected-test.txt
run_test "T4.3" "rm /tmp/unprotected file succeeds" \
    'rm -f /tmp/kma-vfs-unprotected-test.txt'

# T4.5: Rename blocked
touch /tmp/kma-vfs-protected/rename-test.txt
run_test "T4.5" "mv from protected dir returns EPERM" \
    '! sudo mv /tmp/kma-vfs-protected/rename-test.txt /tmp/'

# T4.4: Stats show hits
HITS=$(cat /sys/kernel/kma-vfs-guard/stats 2>/dev/null | grep hits | awk '{print $2}')
run_test "T4.4" "Stats show hits > 0 (got hits=$HITS)" \
    '[ "${HITS:-0}" -gt 0 ]'

# Module unloads cleanly
cleanup

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
