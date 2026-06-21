#!/usr/bin/env bash
# measure-boot.sh — Measure and report boot time via systemd-analyze
# Run inside the VM after booting into KMA kernel.
set -euo pipefail

THRESHOLD="${BOOT_THRESHOLD:-10}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; }

echo "=== KMA OS Boot Time Report ==="
echo "Kernel: $(uname -r)"
echo "Date:   $(date)"
echo ""

# Total boot time
echo "--- systemd-analyze (total) ---"
ANALYZE_OUTPUT=$(systemd-analyze 2>/dev/null || echo "systemd-analyze not available")
echo "$ANALYZE_OUTPUT"
echo ""

# Extract time in seconds (format: "X.Xs" or "Xmin X.Xs")
BOOT_SEC=$(echo "$ANALYZE_OUTPUT" | grep -oE '[0-9]+(\.[0-9]+)?s' | tail -1 | tr -d 's')
if [ -n "$BOOT_SEC" ]; then
    BOOT_INT=$(echo "$BOOT_SEC" | cut -d. -f1)
    if [ "$BOOT_INT" -le "$THRESHOLD" ]; then
        info "Boot time: ${BOOT_SEC}s (threshold: ${THRESHOLD}s) — PASS"
    else
        fail "Boot time: ${BOOT_SEC}s (threshold: ${THRESHOLD}s) — FAIL"
    fi
else
    warn "Could not parse boot time from systemd-analyze"
fi

echo ""
echo "--- Top 10 slowest services (blame) ---"
systemd-analyze blame 2>/dev/null | head -10 || echo "Not available"
echo ""

echo "--- Critical chain (bottleneck path) ---"
systemd-analyze critical-chain 2>/dev/null | head -15 || echo "Not available"
echo ""

# Module count
MODULE_COUNT=$(lsmod | tail -n +2 | wc -l)
echo "--- Loaded modules: $MODULE_COUNT ---"
if [ "$MODULE_COUNT" -lt 50 ]; then
    info "Module count: $MODULE_COUNT (< 50) — PASS"
else
    warn "Module count: $MODULE_COUNT (>= 50) — consider further trimming"
fi
