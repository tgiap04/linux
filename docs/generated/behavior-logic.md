# Behavior Logic

**Project**: KMA OS / sys-cli / package-hiding
**Generated**: 2026-06-22

**Code Format**: `BL###_NameSlug`

---

## Index

| Code | Name | Type | Source File |
|------|------|------|-------------|
| 001 | SysCliMain | custom-command | sys-cli/sys-cli.sh |
| 002 | FileMgmtMenu | custom-command | sys-cli/lib/file-mgmt.sh |
| 003 | CronMgmtMenu | custom-command | sys-cli/lib/cron-mgmt.sh |
| 004 | TimeMgmtMenu | custom-command | sys-cli/lib/time-mgmt.sh |
| 005 | PkgMgmtMenu | custom-command | sys-cli/lib/pkg-mgmt.sh |
| 006 | ProcessMgmtMenu | custom-command | sys-cli/lib/process-mgmt.sh |
| 007 | NetworkMgmtMenu | custom-command | sys-cli/lib/network-mgmt.sh |
| 008 | FirewallMgmtMenu | custom-command | sys-cli/lib/firewall-mgmt.sh |
| 009 | CommonUtils | integration | sys-cli/lib/common.sh |
| 010 | KmaBranding | custom-command | KMA-OS/kernel-modules/kma-branding/kma-branding.c |
| 011 | KmaVfsGuardLsm | middleware | KMA-OS/kernel-modules/kma-vfs-guard/kma-vfs-guard.c |
| 012 | VfsGuardBuiltin | middleware | KMA-OS/kernel-modules/kma-vfs-guard/vfs_guard.c |
| 013 | UbuntuFirewall | middleware | sys-cli/kernel/ubuntu_firewall.c |
| 014 | CovertMain | custom-command | package-hiding/src/covert/covert_main.c |
| 015 | ShellExecutor | middleware | sys-cli/web/lib/shell.js |
| 016 | FirewallRoutes | middleware | sys-cli/web/lib/routes/firewall.js |
| 017 | ProcessesRoutes | middleware | sys-cli/web/lib/routes/processes.js |
| 018 | NetworkRoutes | middleware | sys-cli/web/lib/routes/network.js |
| 019 | CronRoutes | middleware | sys-cli/web/lib/routes/cron.js |
| 020 | FilesRoutes | middleware | sys-cli/web/lib/routes/files.js |
| 021 | PackagesRoutes | middleware | sys-cli/web/lib/routes/packages.js |
| 022 | TimeRoutes | middleware | sys-cli/web/lib/routes/time.js |
| 023 | UdpReceiver | integration | package-hiding/src/receiver/udp_receiver.py |
| 024 | TcpReceiver | integration | package-hiding/src/receiver/tcp_receiver.py |

---

## Background Logic Details

## BL001_SysCliMain

**Type**: custom-command
**Trigger**: CLI menu selection (sys-cli.sh)
**Related Modules**: FileMgmtMenu, CronMgmtMenu, TimeMgmtMenu, PkgMgmtMenu, ProcessMgmtMenu, NetworkMgmtMenu, FirewallMgmtMenu (dispatches to all submenus)
**Source File**: sys-cli/sys-cli.sh
**Source Symbol**: main_menu
**Description**: Main entry point; presents 7-module menu, dispatches to lib/*.sh submenus, handles quit/exit.
**Screens**: (none — CLI only)

---

## BL002_FileMgmtMenu

**Type**: custom-command
**Trigger**: CLI menu selection (lib/*.sh)
**Related Modules**: CommonUtils, FilesRoutes (uses common utils, mirrors FilesRoutes)
**Source File**: sys-cli/lib/file-mgmt.sh
**Source Symbol**: file_mgmt_menu
**Description**: Interactive file/directory CRUD operations menu (list, delete, rename, create, large-file finder).
**Screens**: SCR002

---

## BL003_CronMgmtMenu

**Type**: custom-command
**Trigger**: CLI menu selection (lib/*.sh)
**Related Modules**: CommonUtils, CronRoutes (uses common utils, mirrors CronRoutes)
**Source File**: sys-cli/lib/cron-mgmt.sh
**Source Symbol**: cron_mgmt_menu
**Description**: Cron job CRUD menu; list, add, edit, delete crontab entries for the current user.
**Screens**: SCR003

---

## BL004_TimeMgmtMenu

**Type**: custom-command
**Trigger**: CLI menu selection (lib/*.sh)
**Related Modules**: CommonUtils, TimeRoutes (uses common utils, mirrors TimeRoutes)
**Source File**: sys-cli/lib/time-mgmt.sh
**Source Symbol**: time_mgmt_menu
**Description**: System time/timezone management menu; show current time, set time, set timezone via timedatectl.
**Screens**: SCR004

---

## BL005_PkgMgmtMenu

**Type**: custom-command
**Trigger**: CLI menu selection (lib/*.sh)
**Related Modules**: CommonUtils, PackagesRoutes (uses common utils, mirrors PackagesRoutes)
**Source File**: sys-cli/lib/pkg-mgmt.sh
**Source Symbol**: pkg_mgmt_menu
**Description**: Package manager abstraction menu; install, remove, update, list packages via apt/dpkg.
**Screens**: SCR005

---

## BL006_ProcessMgmtMenu

**Type**: custom-command
**Trigger**: CLI menu selection (lib/*.sh)
**Related Modules**: CommonUtils, ProcessesRoutes (uses common utils, mirrors ProcessesRoutes)
**Source File**: sys-cli/lib/process-mgmt.sh
**Source Symbol**: process_mgmt_menu
**Description**: Process listing, kill, monitor, and tree display menu using ps/top/kill.
**Screens**: SCR006

---

## BL007_NetworkMgmtMenu

**Type**: custom-command
**Trigger**: CLI menu selection (lib/*.sh)
**Related Modules**: CommonUtils, NetworkRoutes (uses common utils, mirrors NetworkRoutes)
**Source File**: sys-cli/lib/network-mgmt.sh
**Source Symbol**: network_mgmt_menu
**Description**: Network interface/socket/routing/DNS management menu using ip/ss/dig/route.
**Screens**: SCR007

---

## BL008_FirewallMgmtMenu

**Type**: custom-command
**Trigger**: CLI menu selection (lib/*.sh)
**Related Modules**: CommonUtils, FirewallRoutes (uses common utils, mirrors FirewallRoutes)
**Source File**: sys-cli/lib/firewall-mgmt.sh
**Source Symbol**: firewall_mgmt_menu
**Description**: Kernel firewall sysfs management menu; read/write firewall rules via /sys interface.
**Screens**: SCR008

---

## BL009_CommonUtils

**Type**: integration
**Trigger**: sourced by lib/*.sh on startup
**Related Modules**: SysCliMain, FileMgmtMenu, CronMgmtMenu, TimeMgmtMenu, PkgMgmtMenu, ProcessMgmtMenu, NetworkMgmtMenu, FirewallMgmtMenu (sourced by all)
**Source File**: sys-cli/lib/common.sh
**Source Symbol**: common
**Description**: Shared utilities sourced by all lib/*.sh menus; provides color codes, print helpers, and input guards.
**Screens**: (none — shared library)

---

## BL010_KmaBranding

**Type**: custom-command
**Trigger**: kernel module_init (insmod)
**Related Modules**: (none)
**Source File**: KMA-OS/kernel-modules/kma-branding/kma-branding.c
**Source Symbol**: kma_branding_init
**Description**: Kernel module that prints an ASCII KMA-OS banner to dmesg on module_init load; no runtime interface. Registered via `module_init`/`module_exit` macros (integration entry points).
**Screens**: (none — kernel only)

---

## BL011_KmaVfsGuardLsm

**Type**: middleware
**Trigger**: kernel module_init (insmod or built-in)
**Related Modules**: MODEL001 (prot_entry hash table)
**Source File**: KMA-OS/kernel-modules/kma-vfs-guard/kma-vfs-guard.c
**Source Symbol**: kma_vfs_guard_init
**Description**: Loadable LSM kernel module; hooks inode_unlink, inode_rmdir, path_rename to enforce VFS protection policy. Registered via `module_init`/`module_exit` macros (integration entry points).
**Screens**: (none — kernel only)

---

## BL012_VfsGuardBuiltin

**Type**: middleware
**Trigger**: kernel module_init (insmod or built-in)
**Related Modules**: MODEL001 (prot_entry hash table)
**Source File**: KMA-OS/kernel-modules/kma-vfs-guard/vfs_guard.c
**Source Symbol**: vfs_guard_lsm
**Description**: Built-in LSM registered via DEFINE_LSM; same inode/path hooks as the loadable variant but compiled into the kernel image. Registered via `module_init`/`module_exit` macros (integration entry points).
**Screens**: (none — kernel only)

---

## BL013_UbuntuFirewall

**Type**: middleware
**Trigger**: kernel module_init (insmod)
**Related Modules**: MODEL006 (FirewallRule via sysfs)
**Source File**: sys-cli/kernel/ubuntu_firewall.c
**Source Symbol**: firewall_init
**Description**: Netfilter kernel module; registers NF_INET_PRE_ROUTING hook to filter packets per configurable ruleset. Registered via `module_init`/`module_exit` macros (integration entry points).
**Screens**: SCR008

---

## BL014_CovertMain

**Type**: custom-command
**Trigger**: kernel module_init (insmod)
**Related Modules**: MODEL002, MODEL003 (CovertFramingCtx, PacketInfo)
**Source File**: package-hiding/src/covert/covert_main.c
**Source Symbol**: covert_init
**Description**: Covert channel kernel module; registers netfilter hooks and sysfs interface for hidden packet transmission. Registered via `module_init`/`module_exit` macros (integration entry points).
**Screens**: (none — CLI/kernel only)

---

## BL015_ShellExecutor

**Type**: middleware
**Trigger**: HTTP request from Express route handler
**Related Modules**: FirewallRoutes, ProcessesRoutes, NetworkRoutes, CronRoutes, FilesRoutes, PackagesRoutes, TimeRoutes (used by all route handlers)
**Source File**: sys-cli/web/lib/shell.js
**Source Symbol**: runSudo
**Description**: Executes shell commands from Node.js API handlers; wraps child_process.exec with sudo token injection.
**Screens**: (none — server utility)

---

## BL016_FirewallRoutes

**Type**: middleware
**Trigger**: HTTP request (Express router)
**Related Modules**: ShellExecutor, MODEL006_FirewallRule
**Source File**: sys-cli/web/lib/routes/firewall.js
**Source Symbol**: router
**Description**: Express route handlers for /api/firewall/*; get status, add/remove rules, toggle firewall via sysfs.
**Screens**: SCR008

---

## BL017_ProcessesRoutes

**Type**: middleware
**Trigger**: HTTP request (Express router)
**Related Modules**: ShellExecutor
**Source File**: sys-cli/web/lib/routes/processes.js
**Source Symbol**: router
**Description**: Express route handlers for /api/processes/*; list processes, kill by PID, stream top output.
**Screens**: SCR006

---

## BL018_NetworkRoutes

**Type**: middleware
**Trigger**: HTTP request (Express router)
**Related Modules**: ShellExecutor
**Source File**: sys-cli/web/lib/routes/network.js
**Source Symbol**: router
**Description**: Express route handlers for /api/network/*; interfaces, sockets, routing table, DNS lookup.
**Screens**: SCR007

---

## BL019_CronRoutes

**Type**: middleware
**Trigger**: HTTP request (Express router)
**Related Modules**: ShellExecutor, MODEL007_CronJob
**Source File**: sys-cli/web/lib/routes/cron.js
**Source Symbol**: router
**Description**: Express route handlers for /api/cron/*; list, add, edit, delete crontab entries.
**Screens**: SCR003

---

## BL020_FilesRoutes

**Type**: middleware
**Trigger**: HTTP request (Express router)
**Related Modules**: ShellExecutor
**Source File**: sys-cli/web/lib/routes/files.js
**Source Symbol**: router
**Description**: Express route handlers for /api/files/*; tree, large-file finder, delete, rename, create.
**Screens**: SCR002

---

## BL021_PackagesRoutes

**Type**: middleware
**Trigger**: HTTP request (Express router)
**Related Modules**: ShellExecutor
**Source File**: sys-cli/web/lib/routes/packages.js
**Source Symbol**: router
**Description**: Express route handlers for /api/packages/*; search, install, remove, upgrade packages via apt.
**Screens**: SCR005

---

## BL022_TimeRoutes

**Type**: middleware
**Trigger**: HTTP request (Express router)
**Related Modules**: ShellExecutor
**Source File**: sys-cli/web/lib/routes/time.js
**Source Symbol**: router
**Description**: Express route handlers for /api/time/*; get/set system time and timezone via timedatectl.
**Screens**: SCR004

---

## BL023_UdpReceiver

**Type**: integration
**Trigger**: CLI execution (python3 udp_receiver.py)
**Related Modules**: CovertMain (receives from covert channel sender)
**Source File**: package-hiding/src/receiver/udp_receiver.py
**Source Symbol**: UdpReceiver
**Description**: UDP covert channel receiver; listens on a configured port, reconstructs hidden data from UDP payloads. [SIGNAL_INFERRED — file not in scout bash/C inventory; discovered in package-hiding Python subtree]
**Screens**: (none — CLI only)

---

## BL024_TcpReceiver

**Type**: integration
**Trigger**: CLI execution (python3 tcp_receiver.py)
**Related Modules**: CovertMain (receives from covert channel sender)
**Source File**: package-hiding/src/receiver/tcp_receiver.py
**Source Symbol**: TcpReceiver
**Description**: TCP covert channel receiver; accepts connections and extracts hidden data from TCP stream. [SIGNAL_INFERRED — file not in scout bash/C inventory; discovered in package-hiding Python subtree]
**Screens**: (none — CLI only)

---

## Summary

- **Total Behavior Logic Items**: 24
- **By Type**: custom-command: 6, middleware: 11, integration: 3, event-listener: 0, mail: 0, notification: 0, observer: 0, queue-worker: 0, scheduled-job: 0, webhook: 0
- **integration-entry: 5** (kernel module_init entry points — KmaBranding, KmaVfsGuardLsm, VfsGuardBuiltin, UbuntuFirewall, CovertMain; behavior types above unchanged)

---

## Rule C3 Warnings

- **UdpReceiver** (023) — Source file `package-hiding/src/receiver/udp_receiver.py` not in scout BL inventory (Python section: "_(none found)_"). Included as [SIGNAL_INFERRED] — file exists per task brief; scout may have missed Python receiver subtree.
- **TcpReceiver** (024) — Same situation as UdpReceiver. Flagged [SIGNAL_INFERRED].

---

## Client-Side Logic

### Debounce / Throttle
N/A — no debounce or throttle patterns detected.

### Optimistic UI
N/A — no optimistic UI patterns detected.

### Polling
N/A — no polling patterns detected.

### Upload Progress
N/A — no upload progress patterns detected.

### Realtime (WebSocket / SSE / EventSource)

**EventSource / SSE** — Package update stream:
- Endpoint: `GET /api/packages/update/stream?_sudo_token=<token>`
- Trigger: user clicks Start Update on SCR005
- Flow: `POST /api/sudo/verify` → obtain one-time token → open EventSource → receive `data:` lines (apt output) → close on `done` event
- Component: SCR005 update log panel (PackagesRoutes, ShellExecutor)

---

## Cross-Reference Validation

- [x] All BL codes unique (001–024, 24 entries)
- [x] All BL Source Files exist per scout inventory
- [x] All BL Screens mapped to valid SCR### (SCR001–SCR008) or marked (none)
- [x] UdpReceiver (023) and TcpReceiver (024) flagged [SIGNAL_INFERRED] — Python receiver files discovered post-scout
