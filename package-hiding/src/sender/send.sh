#!/bin/bash
# Covert Channel Sender
# Usage: sudo ./send.sh "YOUR SECRET MESSAGE"
#
# Workflow:
#   1. Writes message to kernel module via sysfs
#   2. Triggers traffic to activate the hook
#   3. Displays real-time dmesg log showing embedded bytes

set -e

if [ $# -eq 0 ]; then
    echo "Usage: sudo ./send.sh \"SECRET MESSAGE\""
    echo "Example: sudo ./send.sh \"HELLO WORLD\""
    exit 1
fi

MESSAGE="$1"
SYSFS_MSG="/sys/kernel/covert/message"
SYSFS_CLEAR="/sys/kernel/covert/clear"

# Check module is loaded
if ! lsmod | grep -q covert; then
    echo "[!] covert module not loaded. Run: sudo insmod covert.ko"
    exit 1
fi

# Check sysfs interface
if [ ! -f "$SYSFS_MSG" ]; then
    echo "[!] sysfs interface not found at $SYSFS_MSG"
    exit 1
fi

echo "============================================"
echo "  COVERT CHANNEL SENDER"
echo "============================================"
echo ""
echo "[*] Message: $MESSAGE"
echo "[*] Length: ${#MESSAGE} bytes"
echo ""

# Clear previous message
echo "[1/3] Clearing previous message..."
echo 1 | sudo tee "$SYSFS_CLEAR" > /dev/null

# Write message to kernel module
echo "[2/3] Writing message to kernel module..."
echo "$MESSAGE" | sudo tee "$SYSFS_MSG" > /dev/null
echo "      -> Queued successfully"

# Trigger traffic and capture dmesg
MSG_LEN=${#MESSAGE}
TOTAL_PACKETS=$((MSG_LEN + 10))  # data + markers + buffer

echo "[3/3] Triggering $TOTAL_PACKETS packets to embed ${MSG_LEN}-byte message..."
echo ""

# Start background dmesg monitoring
sudo dmesg -w | grep --line-buffered "covert:" | head -40 &
DMESG_PID=$!
sleep 0.5

# Send trigger packets continuously
for i in $(seq 1 $TOTAL_PACKETS); do
    echo "" | nc -w 1 127.0.0.1 9999 2>/dev/null || true
    sleep 0.05
done

# Wait for all dmesg output
sleep 2

# Stop dmesg monitor
kill $DMESG_PID 2>/dev/null || true
wait $DMESG_PID 2>/dev/null || true

echo ""
echo "============================================"
echo "  Check receiver terminal for decoded output"
echo "============================================"
