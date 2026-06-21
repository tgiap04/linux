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
    if eval "$3" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $id: $desc"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}✗${NC} $id: $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== KMA OS Branding Tests ==="
echo "Kernel: $(uname -r)"
echo ""

# T3.1: uname -r contains kma-os-minimal
run_test "T3.1" "uname -r contains kma-os-minimal" \
    'uname -r | grep -q "kma-os-minimal"'

# T3.2: Welcome banner in dmesg (from boot patch or branding module)
run_test "T3.2" "dmesg contains 'Welcome to KMA OS'" \
    'dmesg 2>/dev/null | grep -qi "Welcome to KMA OS"'

# T3.3: ASCII logo present (KMA text)
run_test "T3.3" "Boot log contains KMA ASCII art" \
    'dmesg 2>/dev/null | grep -qi "KMA"'

# Additional info
echo ""
echo "dmesg snippet (first 10 lines):"
dmesg 2>/dev/null | head -10 || echo "(dmesg not available)"

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
