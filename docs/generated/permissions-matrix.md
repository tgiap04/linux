# Permissions Matrix

**Project**: sys-cli
**Generated**: 2026-06-22

## Roles

| Role | Description |
|------|-------------|
| User | Any visitor to the web dashboard. No credentials required for read-only operations. |
| SudoUser | Provides sudo password via X-Sudo-Password header; receives one-time token for SSE streams. Elevated OS privileges. |

## Permissions Index

| # | Name | Type | Enforced At | Description |
|---|------|------|-------------|-------------|
| 001 | read:processes | action-permission | Node.js route (no sudo) | View process list, find process by port |
| 002 | kill:processes | action-permission | X-Sudo-Password header | Send kill signal to a process |
| 003 | read:network | action-permission | Node.js route (no sudo) | View sockets, interfaces, routes, run ping/DNS |
| 004 | manage:firewall | action-permission | X-Sudo-Password header + sysfs | Load/unload module, toggle, configure ports, view logs |
| 005 | read:cron | action-permission | Node.js route (no sudo) | View cron job list and current server time |
| 006 | manage:cron | action-permission | Node.js route (crontab as current user) | Add and delete cron jobs |
| 007 | read:files | action-permission | Node.js route (no sudo) | Browse file tree and list large files |
| 008 | manage:files | action-permission | X-Sudo-Password header | Create, rename, delete files and directories |
| 009 | read:packages | action-permission | Node.js route (no sudo) | Detect package manager, list installed packages |
| 010 | manage:packages | action-permission | X-Sudo-Password header | Install, remove, update, autoremove packages |
| 011 | read:time | action-permission | Node.js route (no sudo) | View current time, timezone, NTP status |
| 012 | manage:time | action-permission | X-Sudo-Password header | Change timezone, enable NTP sync |
| 013 | lsm:vfs_protect | route-guard | Linux LSM (kernel enforced, unconditional) | Kernel-level VFS inode protection (enforced at LSM layer regardless of user) |

## Actor × Permission Matrix

| Permission | User | SudoUser | Notes |
|------------|------|----------|-------|
| read:processes | ✓ | ✓ | No auth required |
| kill:processes | ✗ | ✓ | X-Sudo-Password required |
| read:network | ✓ | ✓ | No auth required |
| manage:firewall | ✗ | ✓ | X-Sudo-Password required |
| read:cron | ✓ | ✓ | No auth required |
| manage:cron | ✓ | ✓ | No sudo required (crontab runs as current user) |
| read:files | ✓ | ✓ | No auth required |
| manage:files | ✗ | ✓ | X-Sudo-Password required for destructive ops |
| read:packages | ✓ | ✓ | No auth required |
| manage:packages | ✗ | ✓ | X-Sudo-Password required |
| read:time | ✓ | ✓ | No auth required |
| manage:time | ✗ | ✓ | X-Sudo-Password required |
| lsm:vfs_protect | N/A | N/A | Kernel enforced at OS level |

## Permission Details

### PERM001: read:processes

- **Type**: action-permission
- **Enforced At**: Node.js route (no sudo)
- **Description**: View the running process list and find processes by port. Reads /proc via shell command. No elevated privileges required.
- **Related Modules**: ProcessesRoutes, CommonUtils

| Action | User | SudoUser |
|--------|------|----------|
| GET /api/processes | ✓ | ✓ |
| GET /api/processes/port/:port | ✓ | ✓ |

---

### PERM002: kill:processes

- **Type**: action-permission
- **Enforced At**: X-Sudo-Password header (route middleware)
- **Description**: Send a kill signal to a running process by PID. Requires sudo. The X-Sudo-Password header is validated by middleware before the kill command runs.
- **Related Modules**: ProcessesRoutes, ShellExecutor

| Action | User | SudoUser |
|--------|------|----------|
| POST /api/processes/kill | ✗ | ✓ |

---

### PERM003: read:network

- **Type**: action-permission
- **Enforced At**: Node.js route (no sudo)
- **Description**: View network sockets, interfaces, and routes; run ping and DNS lookups. All operations are read-only shell commands requiring no elevated privileges.
- **Related Modules**: NetworkRoutes, CommonUtils

| Action | User | SudoUser |
|--------|------|----------|
| GET /api/network/sockets | ✓ | ✓ |
| GET /api/network/interfaces | ✓ | ✓ |
| GET /api/network/routes | ✓ | ✓ |
| POST /api/network/ping | ✓ | ✓ |
| POST /api/network/dns | ✓ | ✓ |

---

### PERM004: manage:firewall

- **Type**: action-permission
- **Enforced At**: X-Sudo-Password header + Linux sysfs interface
- **Description**: Load or unload the KMA firewall kernel module, toggle firewall on/off, configure blocked ports, and view firewall logs. All write operations require sudo. Module state is exposed via sysfs.
- **Related Modules**: FirewallRoutes, ShellExecutor

| Action | User | SudoUser |
|--------|------|----------|
| GET /api/firewall/status | ✓ | ✓ |
| GET /api/firewall/logs | ✓ | ✓ |
| POST /api/firewall/load | ✗ | ✓ |
| POST /api/firewall/unload | ✗ | ✓ |
| POST /api/firewall/toggle | ✗ | ✓ |
| POST /api/firewall/ports | ✗ | ✓ |

---

### PERM005: read:cron

- **Type**: action-permission
- **Enforced At**: Node.js route (no sudo)
- **Description**: View the current user's cron job list and the current server time. Reads crontab -l output. No elevated privileges required.
- **Related Modules**: TimeRoutes, CommonUtils

| Action | User | SudoUser |
|--------|------|----------|
| GET /api/time/cron | ✓ | ✓ |
| GET /api/time/current | ✓ | ✓ |

---

### PERM006: manage:cron

- **Type**: action-permission
- **Enforced At**: Node.js route (crontab runs as current OS user — no sudo)
- **Description**: Add and delete cron jobs for the current OS user. Uses crontab without sudo, so both User and SudoUser actors can manage cron.
- **Related Modules**: TimeRoutes, CommonUtils

| Action | User | SudoUser |
|--------|------|----------|
| POST /api/time/cron | ✓ | ✓ |
| DELETE /api/time/cron/:id | ✓ | ✓ |

---

### PERM007: read:files

- **Type**: action-permission
- **Enforced At**: Node.js route (no sudo)
- **Description**: Browse the file system tree and list files above a configurable size threshold. Uses find and ls shell commands with no elevated privileges.
- **Related Modules**: FileMgmtMenu, CommonUtils

| Action | User | SudoUser |
|--------|------|----------|
| GET /api/files/tree | ✓ | ✓ |
| GET /api/files/large | ✓ | ✓ |

---

### PERM008: manage:files

- **Type**: action-permission
- **Enforced At**: X-Sudo-Password header (route middleware)
- **Description**: Create, rename, and delete files and directories. Destructive operations require sudo so the X-Sudo-Password header is validated by middleware before execution.
- **Related Modules**: FileMgmtMenu, ShellExecutor

| Action | User | SudoUser |
|--------|------|----------|
| POST /api/files/create | ✗ | ✓ |
| POST /api/files/rename | ✗ | ✓ |
| DELETE /api/files | ✗ | ✓ |

---

### PERM009: read:packages

- **Type**: action-permission
- **Enforced At**: Node.js route (no sudo)
- **Description**: Detect the system package manager and list installed packages. Uses read-only package manager queries (e.g., dpkg -l, rpm -qa). No elevated privileges required.
- **Related Modules**: PackagesRoutes, CommonUtils

| Action | User | SudoUser |
|--------|------|----------|
| GET /api/packages | ✓ | ✓ |
| GET /api/packages/manager | ✓ | ✓ |

---

### PERM010: manage:packages

- **Type**: action-permission
- **Enforced At**: X-Sudo-Password header (route middleware)
- **Description**: Install, remove, update, and autoremove system packages. All package mutations require sudo. Streaming updates are delivered via SSE using a one-time token issued after sudo authentication.
- **Related Modules**: PackagesRoutes, ShellExecutor

| Action | User | SudoUser |
|--------|------|----------|
| POST /api/packages/install | ✗ | ✓ |
| POST /api/packages/remove | ✗ | ✓ |
| POST /api/packages/update | ✗ | ✓ |
| GET /api/packages/update/stream | ✗ | ✓ (one-time token) |
| POST /api/packages/autoremove | ✗ | ✓ |

---

### PERM011: read:time

- **Type**: action-permission
- **Enforced At**: Node.js route (no sudo)
- **Description**: View current system time, timezone, and NTP synchronization status. Uses timedatectl and related read-only commands. No elevated privileges required.
- **Related Modules**: TimeRoutes, CommonUtils

| Action | User | SudoUser |
|--------|------|----------|
| GET /api/time | ✓ | ✓ |
| GET /api/time/timezone | ✓ | ✓ |
| GET /api/time/ntp | ✓ | ✓ |

---

### PERM012: manage:time

- **Type**: action-permission
- **Enforced At**: X-Sudo-Password header (route middleware)
- **Description**: Change the system timezone and enable or disable NTP synchronization. Both operations require sudo via the X-Sudo-Password header middleware.
- **Related Modules**: TimeRoutes, ShellExecutor

| Action | User | SudoUser |
|--------|------|----------|
| POST /api/time/timezone | ✗ | ✓ |
| POST /api/time/ntp | ✗ | ✓ |

---

### PERM013: lsm:vfs_protect

- **Type**: route-guard
- **Enforced At**: Linux LSM hook (kernel-enforced, unconditional — applies regardless of web actor)
- **Description**: Kernel-level VFS inode protection enforced by the KMA OS LSM module. The LSM hook intercepts inode_permission calls and denies write access to protected paths. This permission is not checked at the Node.js layer; it is enforced by the kernel before any user-space code runs.
- **Related Modules**: KMA-OS LSM module (kma_os.ko)

| Actor | Effect |
|-------|--------|
| User | Write operations on protected VFS paths are rejected at kernel level |
| SudoUser | Write operations on protected VFS paths are rejected at kernel level |
| OS Kernel | Unconditionally enforced via LSM inode_permission hook |

## Summary

- Total PERM codes: 13
- User-accessible (no sudo): read:processes, read:network, read:cron, manage:cron, read:files, read:packages, read:time (7 permissions)
- SudoUser only: kill:processes, manage:firewall, manage:files, manage:packages, manage:time (5 permissions)
- Kernel-enforced unconditionally: lsm:vfs_protect (1 permission)

## Client-Side Permission Gates

The web UI disables/hides privileged action buttons until the sudo modal completes successfully. No client-side secret is stored — the one-time token is used for SSE streams only.

## Cross-Reference Validation

- [x] All permission codes unique (001–013, 13 entries)
- [x] All actors defined in Roles section
- [x] All permissions consistent with permissions.md Access Boundaries
- [x] Kernel LSM enforcement (lsm:vfs_protect) documented in Special Conditions
