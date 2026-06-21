#!/usr/bin/env bash
# test-vfs-guard.sh — Test built-in VFS guard LSM (always active from boot)
# Run inside VM after booting into KMA kernel with kma_vfs_guard built-in.
# No insmod/rmmod needed — guard is active as soon as the kernel boots.
# Protecting a directory blocks unlink/rmdir/rename of entries INSIDE it.
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
    # Disable pipefail for the assertion: checks pipe a log producer into `grep -q`,
    # and grep exits on first match — closing the pipe and killing the producer with
    # SIGPIPE. Under `set -o pipefail` that turns a genuine PASS into a spurious FAIL.
    set +o pipefail
    if eval "$3" >/dev/null 2>&1; then
        set -o pipefail
        echo -e "${GREEN}✓${NC} $id: $desc"
        PASS=$((PASS + 1))
    else
        set -o pipefail
        echo -e "${RED}✗${NC} $id: $desc"
        FAIL=$((FAIL + 1))
    fi
}

cleanup() {
    rm -rf /tmp/kma-vfs-protected /tmp/kma-vfs-unprotected-test.txt
}

echo "=== KMA OS VFS Guard Tests ==="
echo "Kernel: $(uname -r)"
echo ""

# Prime sudo so the protected-path writes + root rm tests don't prompt mid-run.
sudo -v 2>/dev/null || true

# Ensure clean state
cleanup 2>/dev/null || true

# T4.1: sysfs interface exists (LSM loaded and active from boot)
run_test "T4.1" "kma-vfs-guard sysfs exists (/sys/kernel/kma-vfs-guard/)" \
    '[ -d /sys/kernel/kma-vfs-guard ]'

# T4.1b: kernel log confirms LSM init (built-in LSM logs "ready" at late_initcall).
# journalctl -k works without sudo/TTY; dmesg_restrict may blank a plain dmesg.
run_test "T4.1b" "kernel log confirms kma_vfs_guard loaded" \
    'journalctl -k --no-pager 2>/dev/null | grep -q "kma_vfs_guard: ready" || dmesg 2>/dev/null | grep -q "kma_vfs_guard: ready"'

# Setup protected directory + a file inside it
mkdir -p /tmp/kma-vfs-protected
touch /tmp/kma-vfs-protected/testfile.txt

# Add the directory to the protected list via sysfs (write as root)
echo "/tmp/kma-vfs-protected" | sudo tee /sys/kernel/kma-vfs-guard/add_path >/dev/null
sleep 0.1

# T4.2: unlink inside protected dir — blocked even as root
run_test "T4.2" "rm /protected/file returns EPERM as root" \
    '! sudo rm -f /tmp/kma-vfs-protected/testfile.txt'

# File should still exist
run_test "T4.2b" "Protected file still exists after failed rm" \
    '[ -f /tmp/kma-vfs-protected/testfile.txt ]'

# T4.3: Unprotected dir — rm succeeds
touch /tmp/kma-vfs-unprotected-test.txt
run_test "T4.3" "rm /tmp/unprotected file succeeds" \
    'rm -f /tmp/kma-vfs-unprotected-test.txt'

# T4.5: rename-out of protected dir — blocked
touch /tmp/kma-vfs-protected/rename-test.txt
run_test "T4.5" "mv from protected dir returns EPERM" \
    '! sudo mv /tmp/kma-vfs-protected/rename-test.txt /tmp/'

# T4.4: Stats show hits
HITS=$(cat /sys/kernel/kma-vfs-guard/stats 2>/dev/null | grep hits | awk '{print $2}')
run_test "T4.4" "Stats show hits > 0 (got hits=$HITS)" \
    '[ "${HITS:-0}" -gt 0 ]'

# Remove the protected path + cleanup test dirs
echo "/tmp/kma-vfs-protected" | sudo tee /sys/kernel/kma-vfs-guard/remove_path >/dev/null 2>&1 || true
cleanup

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
