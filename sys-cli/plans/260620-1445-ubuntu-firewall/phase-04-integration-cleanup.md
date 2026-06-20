# Phase 04: Integration + Cleanup

## Overview
- Priority: Medium
- Status: Pending
- Description: Remove old firewall code from network module, verify full integration, update docs

## Requirements
- Remove "Firewall" tab from network.html and `checkFirewall()` from networkState()
- Remove POST /firewall endpoint from network.js
- Replace `network_firewall_status()` in network-mgmt.sh with a note pointing to firewall module
- Update usage docs if present

## Files to modify
- `web/public/views/network.html` — remove Firewall tab + tab button
- `web/public/js/components.js` — remove `firewallOutput`, `fwLoading`, `fwError`, `checkFirewall()` from `networkState()`
- `web/lib/routes/network.js` — remove POST /firewall handler
- `lib/network-mgmt.sh` — replace firewall_status function

## Implementation Steps
1. Remove firewall tab from network.html (tab button + tab content)
2. Clean up networkState() in components.js — remove firewall-related state and methods
3. Remove POST /firewall route from network.js
4. Update network-mgmt.sh firewall_status to show "Use the Kernel Firewall module (menu 7)"
5. Run final verification: no broken references, no unused imports

## Success Criteria
- Network view has no Firewall tab
- No JS errors in browser console (firewall references removed from networkState)
- API /api/network/firewall returns 404
- Firewall module standalone and self-contained
- network-mgmt.sh has no ufw/iptables/nft calls

## Risk Assessment
- Low risk — this is cleanup/removal work
- Must verify no other code references the removed endpoints
