#!/usr/bin/env bash
# test-branding.sh — Verify KMA OS branding (banner, logo, uname)
# Run inside VM after booting into KMA kernel.
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
    # Disable pipefail for the check: assertions pipe a log producer into `grep -q`,
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

echo "=== KMA OS Branding Tests ==="
echo "Kernel: $(uname -r)"
echo ""

# Kernel log reader. With kernel.dmesg_restrict=1 (default on this kernel) a plain
# `dmesg` returns EMPTY but exits 0 for non-root — so we must check for non-empty
# OUTPUT, not exit status, before falling back to sudo, then journalctl -k.
kmsg() {
    local out
    out=$(dmesg 2>/dev/null);            [ -n "$out" ] && { printf '%s\n' "$out"; return; }
    out=$(sudo dmesg 2>/dev/null);       [ -n "$out" ] && { printf '%s\n' "$out"; return; }
    out=$(journalctl -k --no-pager 2>/dev/null); printf '%s\n' "$out"
}

# T3.1: uname -r contains kma-os-minimal
run_test "T3.1" "uname -r contains kma-os-minimal" \
    'uname -r | grep -q "kma-os-minimal"'

# T3.2: Welcome banner in kernel log (from boot patch)
run_test "T3.2" "kernel log contains 'Welcome to KMA OS'" \
    'kmsg | grep -qi "Welcome to KMA OS"'

# T3.3: ASCII logo present (KMA text)
run_test "T3.3" "Boot log contains KMA ASCII art" \
    'kmsg | grep -qi "KMA"'

# Additional info
echo ""
echo "kernel log snippet (branding):"
kmsg | grep -A12 "Welcome to KMA OS" | head -13 || echo "(kernel log not available)"

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
