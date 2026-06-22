## Detected Language
C (kernel modules), Bash, Python, JavaScript (Node.js), HTML, CSS [MULTI_STACK — all stacks: C (kernel modules), Bash, Python, JavaScript (Node.js/Express), HTML/CSS]

## Scanned Directories
- KMA-OS/
- KMA-OS/kernel-modules/kma-branding/
- KMA-OS/kernel-modules/kma-vfs-guard/
- KMA-OS/scripts/
- KMA-OS/tests/
- KMA-OS/patches/
- KMA-OS/vm/
- KMA-OS/docs/
- package-hiding/
- package-hiding/src/covert/
- package-hiding/src/sender/
- package-hiding/src/receiver/
- sys-cli/
- sys-cli/lib/
- sys-cli/web/
- sys-cli/web/lib/
- sys-cli/web/lib/routes/
- sys-cli/web/public/
- sys-cli/web/public/js/
- sys-cli/web/public/css/
- sys-cli/web/public/views/
- sys-cli/kernel/

## File Inventory

### Subproject: KMA-OS (Linux Kernel Customization)

KMA-OS/kernel-modules/kma-branding/kma-branding.c	background
KMA-OS/kernel-modules/kma-branding/Makefile	config
KMA-OS/kernel-modules/kma-vfs-guard/kma-vfs-guard.c	permission
KMA-OS/kernel-modules/kma-vfs-guard/vfs_guard.c	permission
KMA-OS/kernel-modules/kma-vfs-guard/Makefile	config
KMA-OS/scripts/build-kernel.sh	other
KMA-OS/scripts/setup-vm.sh	other
KMA-OS/scripts/sync-to-vm.sh	other
KMA-OS/scripts/measure-boot.sh	other
KMA-OS/tests/test-branding.sh	other
KMA-OS/tests/test-vfs-guard.sh	other
KMA-OS/tests/test-boot.sh	other
KMA-OS/patches/0002-kma-boot-branding.patch	config
KMA-OS/patches/0003-kma-vfs-guard-lsm.patch	config
KMA-OS/vm/kma-os-utm.toml	config

### Subproject: package-hiding (Covert Channel)

package-hiding/src/covert/covert_main.c	background
package-hiding/src/covert/framing.c	other
package-hiding/src/covert/framing.h	model
package-hiding/src/covert/packet_parser.c	other
package-hiding/src/covert/packet_parser.h	model
package-hiding/src/covert/tcp_embed.c	other
package-hiding/src/covert/tcp_embed.h	model
package-hiding/src/covert/udp_embed.c	other
package-hiding/src/covert/udp_embed.h	model
package-hiding/src/covert/error_handler.h	other
package-hiding/src/covert/Makefile	config
package-hiding/src/sender/send.sh	other
package-hiding/src/receiver/udp_receiver.py	other
package-hiding/src/receiver/tcp_receiver.py	other

### Subproject: sys-cli (System Management CLI + Web UI)

sys-cli/sys-cli.sh	other
sys-cli/lib/common.sh	other
sys-cli/lib/cron-mgmt.sh	other
sys-cli/lib/file-mgmt.sh	other
sys-cli/lib/firewall-mgmt.sh	other
sys-cli/lib/network-mgmt.sh	other
sys-cli/lib/pkg-mgmt.sh	other
sys-cli/lib/process-mgmt.sh	other
sys-cli/lib/time-mgmt.sh	other
sys-cli/web/server.js	route
sys-cli/web/package.json	config
sys-cli/web/lib/shell.js	other
sys-cli/web/lib/routes/cron.js	route
sys-cli/web/lib/routes/files.js	route
sys-cli/web/lib/routes/firewall.js	route
sys-cli/web/lib/routes/network.js	route
sys-cli/web/lib/routes/packages.js	route
sys-cli/web/lib/routes/processes.js	route
sys-cli/web/lib/routes/time.js	route
sys-cli/web/public/index.html	screen
sys-cli/web/public/css/style.css	screen
sys-cli/web/public/js/app.js	screen
sys-cli/web/public/js/components.js	screen
sys-cli/web/public/views/cron.html	screen
sys-cli/web/public/views/files.html	screen
sys-cli/web/public/views/firewall.html	screen
sys-cli/web/public/views/network.html	screen
sys-cli/web/public/views/packages.html	screen
sys-cli/web/public/views/processes.html	screen
sys-cli/web/public/views/time.html	screen
sys-cli/kernel/ubuntu_firewall.c	other
sys-cli/kernel/Makefile	config

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

## Notes

### Monorepo Layout

This is a multi-subproject mono-repository with 3 independent sub-projects sharing the same git root:

1. **KMA-OS/** -- Linux kernel customization project. Contains out-of-tree loadable kernel modules (kma-branding, kma-vfs-guard LSM), kernel patch files, VM provisioning scripts, and a test suite. The VFS Guard has two implementations: a loadable module (kma-vfs-guard.c) and a built-in variant (vfs_guard.c using DEFINE_LSM). The branding has both a boot-time kernel patch (0002-kma-boot-branding.patch) and a loadable module (kma-branding.c). Target VM: Ubuntu ARM64 on UTM/QEMU.

2. **package-hiding/** -- Covert channel implementation using kernel netfilter hooks. Embeds data bytes into TCP sequence numbers (lower 8 bits) and UDP IP Identification fields. Framing protocol: 0xFF 0x00 [data] 0xFF 0xFF. Sender is a shell script writing to sysfs; receivers are Python/Scapy user-space listeners. Includes pre-built kernel object artifacts (covert.ko).

3. **sys-cli/** -- System management CLI with 7 modules + web UI Express server. CLI is purely Bash-sourced modules. Web UI uses Express, Alpine.js, HTMX. Includes a supplementary kernel module (ubuntu_firewall.c) for netfilter-based firewall.

### Build Artifacts Present

The package-hiding and sys-cli kernel directories contain pre-compiled kernel object files (.ko, .o, .mod, etc.) from prior builds. These are build artifacts, not source.

The sys-cli/web/node_modules/ directory is populated (~4.2 MB) with Express dependencies.

### Sudo Password Architecture (sys-cli web)

The web UI handles sudo password via X-Sudo-Password header with a one-time token system for EventSource (SSE) connections. Tokens are short-lived (30s TTL) and one-time use. Password is never logged or stored, only lives in the request object.

### No Standard Web Framework Background Logic

None of the sub-projects use standard web framework background logic patterns (NestJS, Laravel, etc.). All background logic is inferred from kernel hooks (module_init/module_exit, netfilter, LSM), shell library patterns, and Express middleware. All Background Logic Source Inventory entries use the [SIGNAL_INFERRED] marker.

### KMA-OS Architecture

The KMA-OS sub-project runs on a macOS host with UTM/QEMU hosting an Ubuntu ARM64 guest VM. Source is synced via rsync over SSH (10.0.2.15). Shared folder uses 9p virtio. Kernel build uses localmodconfig to strip ~15,000 config items to ~200.
