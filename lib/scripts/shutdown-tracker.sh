#!/usr/bin/env bash
###############################################################################
# Shutdown Issue Tracker Script
# Helps identify services causing shutdown delays
###############################################################################

echo "=== Shutdown Issue Analysis ==="
echo

echo "1. Services that took longest to stop (last boot):"
systemd-analyze blame | head -10
echo

echo "2. Critical chain analysis:"
systemd-analyze critical-chain
echo

echo "3. Recent shutdown/stop events from journal:"
journalctl -b -1 --no-pager | grep -E "(Stopping|Failed|timeout|kill|SIGTERM|SIGKILL)" | tail -20
echo

echo "4. Services with stop timeouts:"
journalctl -b -1 --no-pager | grep -i "stop.*timeout" | tail -10
echo

echo "5. Failed services:"
systemctl --failed --no-pager
echo

echo "=== Tips ==="
echo "- Run this script after a reboot to analyze the previous shutdown"
echo "- Look for services with high stop times in section 1"
echo "- Check section 3 for timeout/kill messages"
echo "- Use 'journalctl -u <service-name>' to investigate specific services"
echo "- Consider reducing TimeoutStopSec for problematic services"