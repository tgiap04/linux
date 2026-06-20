# Phase 03: Web Backend + Dashboard

## Overview
- Priority: High
- Status: Pending
- Description: Express route + Alpine.js view for firewall management and blocked-attacks visualization

## API endpoints
- `GET /api/firewall/status` — read sysfs attributes (enabled, drop_icmp, reject_ports, status counters)
- `GET /api/firewall/logs` — read dmesg filtered for `ubuntu_firewall`, parsed into structured events
- `POST /api/firewall/enable` — write to sysfs enabled (requires sudo)
- `POST /api/firewall/disable` — write to sysfs enabled (requires sudo)
- `POST /api/firewall/set-icmp` — write to sysfs drop_icmp (requires sudo)
- `POST /api/firewall/set-ports` — write to sysfs reject_ports (requires sudo)

## Web UI dashboard
- Toggle switches for enabled / drop_icmp
- Text input for reject_ports (comma-separated)
- Table of blocked events parsed from dmesg (timestamp, protocol, source, port)
- Auto-refresh button for logs
- Status badges showing active/inactive

## Files to create
- `web/lib/routes/firewall.js` (~100 lines)
- `web/public/views/firewall.html` (~150 lines)

## Files to modify
- `web/server.js` — add `app.use('/api/firewall', require('./lib/routes/firewall'))`
- `web/public/index.html` — add Firewall nav item to sidebar
- `web/public/js/components.js` — add `firewallState()` function

## Implementation Steps
1. Create `web/lib/routes/firewall.js`:
   - Import `{runSudo, badRequest}` from `../shell`
   - GET /status: `runSudo(pw, 'cat', ['/sys/firewall/enabled'])` etc for each attribute
   - GET /logs: `runSudo(pw, 'dmesg', [])` then filter lines containing `ubuntu_firewall`
   - POST endpoints: `runSudo(pw, 'bash', ['-c', 'echo VALUE > /sys/firewall/ATTR'])`
2. Create `web/public/views/firewall.html` with Alpine.js state
3. Add `firewallState()` to components.js
4. Register route in server.js
5. Add sidebar nav item in index.html

## Success Criteria
- `/api/firewall/status` returns JSON with all sysfs values
- `/api/firewall/logs` returns parsed array of blocked packet events
- POST endpoints toggle sysfs values via sudo
- Dashboard renders toggle switches, port config, and event table
- Sidebar shows Firewall nav item with shield icon
- All sudo operations go through existing modal flow (no new auth mechanism)

## Risk Assessment
- sysfs writes via `echo VALUE > /sys/firewall/X` need sudo — use runSudo
- dmesg output format varies by kernel version — regex must be flexible
- Module not loaded → sysfs paths don't exist → API returns meaningful error
