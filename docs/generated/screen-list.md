# Screen List

**Project**: KMA OS / sys-cli
**Generated**: 2026-06-22
**Scope**: sys-cli web dashboard only (KMA-OS and package-hiding are CLI/kernel — no screens)

---

## Screen Index

| # | Name | Source File | Description |
|---|------|-------------|-------------|
| 001 | Dashboard | sys-cli/web/public/js/app.js | Landing page, navigation shell, sudo modal |
| 002 | File Management | sys-cli/web/public/js/components.js | File tree browser, CRUD operations |
| 003 | Cron Jobs | sys-cli/web/public/js/components.js | Cron job list, add/delete form |
| 004 | System Time | sys-cli/web/public/js/components.js | Current time display, timezone selector, NTP toggle |
| 005 | Package Management | sys-cli/web/public/js/components.js | Install/remove/update packages, SSE stream output |
| 006 | Process Management | sys-cli/web/public/js/components.js | Process list, kill, port lookup |
| 007 | Network & Sockets | sys-cli/web/public/js/components.js | Ports, interfaces, routes, DNS, connectivity |
| 008 | Kernel Firewall | sys-cli/web/public/js/components.js | Module load/unload, firewall toggle, port config, logs |

---

## SCR001: Dashboard / Main Menu

**Source**: sys-cli/web/public/js/app.js, sys-cli/web/public/index.html (inferred)
**Type**: screen
**Description**: Landing page and navigation shell. Hosts the sidebar/nav menu linking to all 7 module screens. Renders the active module view via Alpine.js `x-html` injection from `/views/{name}.html`. Default module on load is `processes`.
**Components**:
- Sidebar navigation (7 module links)
- Active-module view container (`x-html`)
- Toast notification overlay (3.5s auto-dismiss, success/error/info/warning)
- Sudo password modal (intercepts any sudo-required API call, verifies via `/api/sudo/verify`, then replays original request)
**API calls**:
- `POST /api/sudo/verify` (triggered by sudo modal on any privileged action)
- `GET /views/{name}.html` (lazy-loads view HTML fragments per module)

---

## SCR002: File Management

**Source**: sys-cli/web/public/js/components.js → `filesState()`
**Type**: screen
**Description**: File system browser and CRUD operations. Two panels: directory tree viewer (collapsible, depth 1–5) and path-based operations (delete, rename, create file/dir). Confirm modals guard destructive actions.
**Components**:
- Directory tree viewer (collapsible dirs, `treePath`/`treeDepth` inputs, Load button)
- Path input field (`opPath`)
- Action buttons: Delete, Rename, New File, New Dir
- Confirm/input modal (shared for delete/rename/create)
- Status feedback (opSuccess, opError)
- Large-file finder (dir + size threshold inputs) → list + optional delete
**API calls**:
- `GET /api/files/tree?path=&depth=`
- `GET /api/files/large?dir=&size=`
- `POST /api/files/delete` (glob pattern delete)
- `POST /api/files/delete-path` (sudo)
- `POST /api/files/rename` (sudo)
- `POST /api/files/create` (sudo)

---

## SCR003: Cron Jobs

**Source**: sys-cli/web/public/js/components.js → `cronState()`
**Type**: screen
**Description**: Cron job manager. Lists all user crontab entries with delete action. Add-job form with time picker, schedule fields (min/hour/day/month/wday), command input, optional log redirect toggle, and live crontab-line preview.
**Components**:
- Job list table (entry text, delete button with confirm)
- Add-job form (time input, schedule fields, cmd input, log redirect toggle + path)
- Cron preview string (computed, updates live)
- Status feedback (addError, toast)
**API calls**:
- `GET /api/cron/now` (pre-fills hour/min on init)
- `GET /api/cron/list`
- `POST /api/cron/add`
- `DELETE /api/cron/:index`

---

## SCR004: System Time

**Source**: sys-cli/web/public/js/components.js → `timeState()`
**Type**: screen
**Description**: System time viewer and manager. Shows current datetime and timezone. Provides timezone search-and-set (filtered list, max 50 shown) and NTP enable button. Secondary action: fetch raw NTP sync status from timedatectl.
**Components**:
- Current time/timezone/NTP-sync status display
- Timezone filter input + filtered list (max 50 entries)
- Set Timezone button (sudo)
- Enable NTP button (sudo)
- NTP Status panel (raw timedatectl output on demand)
- Error/loading states per action
**API calls**:
- `GET /api/time/status`
- `GET /api/time/timezones?filter=`
- `POST /api/time/timezone` (sudo)
- `POST /api/time/ntp` (sudo)
- `GET /api/time/ntp-status`

---

## SCR005: Package Management

**Source**: sys-cli/web/public/js/components.js → `packagesState()`
**Type**: screen
**Description**: Package manager UI. Detects available package manager on init. Four operations: install (space/comma-separated names), remove/purge, system update via SSE stream (real-time log output), autoremove orphans. Secondary panel: searchable installed-package list with inline remove.
**Components**:
- Package manager badge (detected on init)
- Install form (text input, Install button)
- Remove/purge form (text input, purge checkbox, Remove button)
- Update panel (Start Update button, real-time SSE log output scrollable panel)
- Autoremove button
- Installed packages panel (load-on-demand, search input, per-row Remove button)
- Per-action success/error feedback
**API calls**:
- `GET /api/packages/detect`
- `GET /api/packages/list`
- `POST /api/packages/install` (sudo)
- `POST /api/packages/remove` (sudo)
- `GET /api/packages/update/stream` (SSE, sudo token via `?_sudo_token=`)
- `POST /api/packages/autoremove` (sudo)
- `POST /api/sudo/verify` (obtains one-time token before SSE stream)

---

## SCR006: Process Management

**Source**: sys-cli/web/public/js/components.js → `processesState()`
**Type**: screen
**Description**: Process list and kill utility. Loads all processes sorted by CPU or MEM on init. Kill action with confirm dialog (signal selection). Port-lookup panel finds which process owns a given port.
**Components**:
- Process table (PID, user, CPU%, MEM%, command; sort toggle CPU/MEM)
- Refresh button
- Kill confirm dialog (signal choice: TERM/KILL/HUP)
- Port lookup panel (port input, Find button, result display)
- Error display
**API calls**:
- `GET /api/processes/list?sort=`
- `POST /api/processes/kill` (sudo)
- `GET /api/processes/port/:port`

---

## SCR007: Network & Sockets

**Source**: sys-cli/web/public/js/components.js → `networkState()`
**Type**: screen
**Description**: Four-tab network inspection panel. Tabs: Ports (listening sockets via ss), Interfaces (ip addr show), Routes (ip route show), Ping/DNS (connectivity test + DNS lookup). Each tab loads on first activation.
**Components**:
- Tab bar (Ports / Interfaces / Routes / Ping/DNS)
- Ports tab: socket list table (proto, addr, port, process)
- Interfaces tab: interface cards (name, addresses, state)
- Routes tab: routing table rows
- Ping/DNS tab: host + port inputs (ping), domain input (DNS), result panels
- Per-tab loading/error states
**API calls**:
- `GET /api/network/sockets`
- `GET /api/network/interfaces`
- `GET /api/network/routes`
- `POST /api/network/ping`
- `POST /api/network/dns`

---

## SCR008: Kernel Firewall

**Source**: sys-cli/web/public/js/components.js → `firewallState()`
**Type**: screen
**Description**: Ubuntu kernel firewall control panel. Reads firewall state from sysfs via API on init. Handles module-not-loaded state gracefully. Provides toggles for enabled/drop_icmp flags, port blocklist management (add/remove individual ports), and dmesg log viewer.
**Components**:
- Module-not-loaded banner (when `status.moduleLoaded === false`)
- Enabled toggle (sudo)
- Drop ICMP toggle (sudo)
- Reject ports list (tag-style, per-port remove button; sudo)
- Add ports input (comma-separated, merge-deduplicates with existing list; sudo)
- View Logs button + log lines panel (last 50 entries from dmesg; sudo)
- Loading/error states
**API calls**:
- `GET /api/firewall/status` (sudo)
- `POST /api/firewall/toggle` (sudo)
- `POST /api/firewall/ports` (sudo)
- `POST /api/firewall/ports/clear` (sudo)
- `GET /api/firewall/logs` (sudo)
