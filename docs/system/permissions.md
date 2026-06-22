# Permissions

**Project**: sys-cli
**Generated**: 2026-06-22

## Authorization System Type

`hybrid` — sudo-based elevated privilege via `X-Sudo-Password` header (web layer) combined with LSM kernel enforcement for VFS guard (kernel layer).

## Curated View

The sys-cli web dashboard uses a two-tier access model:

- **User** (unauthenticated): read-only access to system information — processes, network, file system, packages, and cron jobs that require no elevated privilege.
- **SudoUser** (authenticated via sudo password): full access to all User capabilities plus destructive and system-mutating operations, granted by passing the sudo password in the `X-Sudo-Password` request header.

Above both tiers, the KMA-OS Linux Security Module enforces VFS-level directory protection at the kernel layer. This enforcement is unconditional — it cannot be bypassed through web dashboard credentials regardless of role.

## Access Boundaries

### User (unauthenticated)

Any visitor to the dashboard can:

- View live process list and find processes by port
- Browse network interfaces, routing table, open sockets, and run DNS lookups and connectivity checks
- View and add/delete cron jobs (crontab runs as the current Linux user — no elevated privilege needed)
- Browse the file system tree and find large files
- Detect the package manager and list installed packages
- View current system time, timezone, and NTP sync status

### SudoUser (authenticated with sudo password)

In addition to all User permissions, a SudoUser can:

- Kill processes by PID
- Load, unload, toggle, and configure the kernel firewall module
- Create, rename, and delete files and directories (including recursive deletion)
- Install, remove, and update system packages (SSE stream requires one-time token)
- Change system timezone and enable NTP synchronization

### Kernel VFS Guard (all roles)

The KMA-OS VFS guard module enforces directory protection at the Linux Security Module (LSM) layer. Protected paths block `unlink`, `rmdir`, and `rename` operations regardless of user credentials or web dashboard access level.

## Special Conditions

- **PERM013 — lsm:vfs_protect is enforced at kernel level regardless of user role.** Even a SudoUser cannot delete or rename paths that the KMA-OS LSM has marked as protected. This enforcement happens below the web layer and cannot be overridden through the dashboard.
- **One-time SSE token mechanism.** Package install, remove, and update operations stream output via SSE. Because standard request headers cannot be attached to an `EventSource` connection, the API issues a short-lived one-time token on the initial sudo-authenticated request. The SSE endpoint accepts this token as a query parameter to authorize the stream without re-transmitting the sudo password.
