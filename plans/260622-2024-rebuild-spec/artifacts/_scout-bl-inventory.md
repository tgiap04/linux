## Background Logic Source Inventory

### Bash [SIGNAL_INFERRED]
- custom-command: sys-cli/lib/common.sh (shared utilities: colors, output helpers, guards)
- custom-command: sys-cli/lib/cron-mgmt.sh (cron job CRUD management)
- custom-command: sys-cli/lib/file-mgmt.sh (file/directory operations)
- custom-command: sys-cli/lib/firewall-mgmt.sh (kernel firewall sysfs management)
- custom-command: sys-cli/lib/network-mgmt.sh (network interface/socket/routing/DNS)
- custom-command: sys-cli/lib/pkg-mgmt.sh (package manager abstraction)
- custom-command: sys-cli/lib/process-mgmt.sh (process listing/kill/monitor/tree)
- custom-command: sys-cli/lib/time-mgmt.sh (system time/timezone management)
- scheduled-job: _(none found)_ (cron-mgmt.sh manages cron jobs externally but no internal scheduled scripts)
- queue-worker: _(none found)_
- event-listener: _(none found)_
- observer: _(none found)_
- mail: _(none found)_
- notification: _(none found)_
- middleware: _(none found)_
- integration: _(none found)_
- webhook: _(none found)_

### C (Kernel) [SIGNAL_INFERRED]
- middleware: KMA-OS/kernel-modules/kma-vfs-guard/kma-vfs-guard.c (LSM security hooks: inode_unlink, inode_rmdir, path_rename)
- middleware: KMA-OS/kernel-modules/kma-vfs-guard/vfs_guard.c (built-in LSM via DEFINE_LSM with same hooks)
- custom-command: KMA-OS/kernel-modules/kma-branding/kma-branding.c (module_init prints ASCII banner/logo at load)
- custom-command: package-hiding/src/covert/covert_main.c (module_init registers netfilter hooks + sysfs interface)
- custom-command: sys-cli/kernel/ubuntu_firewall.c (module_init registers netfilter PRE_ROUTING hook)
- integration: KMA-OS/kernel-modules/kma-branding/kma-branding.c (module_init / module_exit macros)
- integration: KMA-OS/kernel-modules/kma-vfs-guard/kma-vfs-guard.c (module_init / module_exit macros for loadable variant)
- integration: KMA-OS/kernel-modules/kma-vfs-guard/vfs_guard.c (DEFINE_LSM boot-time registration)
- integration: package-hiding/src/covert/covert_main.c (module_init / module_exit macros)
- integration: sys-cli/kernel/ubuntu_firewall.c (module_init / module_exit macros)
- scheduled-job: _(none found)_
- queue-worker: _(none found)_
- event-listener: _(none found)_
- observer: _(none found)_
- mail: _(none found)_
- notification: _(none found)_
- webhook: _(none found)_

### Node.js [SIGNAL_INFERRED]
- middleware: sys-cli/web/server.js (helmet security, rate limiting, audit logging, sudo password extraction, sudo token consumption, global error handler)
- middleware: sys-cli/web/lib/routes/cron.js (route handlers for /api/cron/*)
- middleware: sys-cli/web/lib/routes/files.js (route handlers for /api/files/*)
- middleware: sys-cli/web/lib/routes/firewall.js (route handlers for /api/firewall/*)
- middleware: sys-cli/web/lib/routes/network.js (route handlers for /api/network/*)
- middleware: sys-cli/web/lib/routes/packages.js (route handlers for /api/packages/*)
- middleware: sys-cli/web/lib/routes/processes.js (route handlers for /api/processes/*)
- middleware: sys-cli/web/lib/routes/time.js (route handlers for /api/time/*)
- webhook: _(none found)_
- scheduled-job: _(none found)_
- queue-worker: _(none found)_
- event-listener: _(none found)_
- observer: _(none found)_
- mail: _(none found)_
- notification: _(none found)_
- custom-command: _(none found)_
- integration: _(none found)_

### Python [SIGNAL_INFERRED]
- _(none found)_

