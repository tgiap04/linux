#!/usr/bin/env bash
# test-boot.sh — Validate kernel build, boot time, and config
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

echo "=== KMA OS Boot Tests ==="
echo "Kernel: $(uname -r)"
echo ""

# T1.1: Kernel version contains kma-os-minimal
run_test "T1.1" "uname -r contains kma-os-minimal" \
    'uname -r | grep -q "kma-os-minimal"'

# T2.1: Config is minimal (< 300 items)
CONFIG_COUNT=$(grep -c '=y\|=m' /boot/config-$(uname -r) 2>/dev/null || echo "0")
run_test "T2.1" "Config items < 300 (got $CONFIG_COUNT)" \
    '[ "$CONFIG_COUNT" -lt 300 ]'

# T2.2: Boot time < 10s
if command -v systemd-analyze >/dev/null 2>&1; then
    BOOT_TIME=$(systemd-analyze 2>/dev/null | grep -oE '[0-9]+\.[0-9]+s' | head -1 | tr -d 's')
    BOOT_INT=$(echo "${BOOT_TIME:-99}" | cut -d. -f1)
    run_test "T2.2" "Boot time < 10s (got ${BOOT_TIME:-unknown}s)" \
        '[ "${BOOT_INT:-99}" -le 10 ]'
else
    run_test "T2.2" "Boot time < 10s" 'false'
fi

# T2.3: systemd-analyze produces output
run_test "T2.3" "systemd-analyze produces output" \
    'systemd-analyze 2>/dev/null | grep -q "s"'

# Module count
MOD_COUNT=$(lsmod | tail -n +2 | wc -l)
echo ""
echo "Info: $MOD_COUNT modules loaded (threshold: < 50)"

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
