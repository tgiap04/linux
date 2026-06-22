# Route List

**Project**: KMA OS / sys-cli
**Generated**: 2026-06-22

> **Completeness Contract**: one row per leaf route (HTTP method + concrete path). No wildcards or approximation markers. All Web API routes confirmed by static parse. CLI sub-menus 2–7 and SPA client routes are unverified — see Unresolved Questions.

---

## Backend Routes

### Web API (Express/Node.js)

### File: sys-cli/web/server.js

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | /api/sudo/verify | Verify sudo password; issues 30s one-time SSE token (`{ok, token}`) | `X-Sudo-Password` header |

> SPA catch-all (`GET *` → `index.html`) is a static-serving fallback, not an API route; excluded from API count.

### File: sys-cli/web/lib/routes/firewall.js (mounted at /api/firewall)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /api/firewall/status | Read enabled, drop_icmp, reject_ports from sysfs | X-Sudo-Password |
| GET | /api/firewall/logs | Fetch dmesg filtered for ubuntu_firewall entries | X-Sudo-Password |
| POST | /api/firewall/toggle | Write 0/1 to enabled or drop_icmp sysfs attr | X-Sudo-Password |
| POST | /api/firewall/ports | Write comma-separated port list to reject_ports sysfs | X-Sudo-Password |
| POST | /api/firewall/ports/clear | Clear reject_ports (write empty string) | X-Sudo-Password |

### File: sys-cli/web/lib/routes/processes.js (mounted at /api/processes)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /api/processes/list | List all processes via ps aux; sort by cpu or mem | None |
| POST | /api/processes/kill | Send signal to process by PID | X-Sudo-Password |
| GET | /api/processes/port/:port | Find process listening on a given port via ss | None |

### File: sys-cli/web/lib/routes/network.js (mounted at /api/network)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /api/network/sockets | List listening sockets via ss -tulpn | None |
| GET | /api/network/interfaces | List network interfaces via ip addr show | None |
| GET | /api/network/routes | Show routing table via ip route show | None |
| POST | /api/network/ping | ICMP + TCP reachability check for host[:port] | None |
| POST | /api/network/dns | DNS lookup via dig or getent hosts | None |

### File: sys-cli/web/lib/routes/cron.js (mounted at /api/cron)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /api/cron/now | Return server current hour and minute | None |
| GET | /api/cron/list | Parse crontab -l; return indexed job list | None |
| POST | /api/cron/add | Add cron job idempotently; fields: min,hour,day,month,wday,cmd | None |
| DELETE | /api/cron/:index | Remove cron job at 1-based index | None |

### File: sys-cli/web/lib/routes/files.js (mounted at /api/files)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /api/files/tree | Directory tree; params: path, depth (1-5) | None |
| GET | /api/files/large | Files larger than size in dir; params: dir, size | None |
| POST | /api/files/delete | Delete files matching glob pattern under dir | None |
| POST | /api/files/delete-path | Delete single file or directory (rm -rf) | X-Sudo-Password |
| POST | /api/files/rename | Rename file or directory in place (mv) | X-Sudo-Password |
| POST | /api/files/create | Create file (touch) or directory (mkdir -p) | X-Sudo-Password |

### File: sys-cli/web/lib/routes/packages.js (mounted at /api/packages)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /api/packages/detect | Detect available package manager (apt-get/dnf/yum/pacman) | None |
| GET | /api/packages/list | List installed packages with version | None |
| POST | /api/packages/install | Install one or more packages | X-Sudo-Password |
| POST | /api/packages/remove | Remove (or purge) a package | X-Sudo-Password |
| GET | /api/packages/update/stream | SSE stream of system upgrade output | X-Sudo-Password + _sudo_token |
| POST | /api/packages/autoremove | Remove orphaned packages | X-Sudo-Password |

### File: sys-cli/web/lib/routes/time.js (mounted at /api/time)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /api/time/status | Current datetime, timezone, NTP sync status | None |
| GET | /api/time/timezones | List available timezones; optional ?filter= | None |
| POST | /api/time/timezone | Set system timezone via timedatectl | X-Sudo-Password |
| POST | /api/time/ntp | Enable NTP sync via timedatectl set-ntp true | X-Sudo-Password |
| GET | /api/time/ntp-status | Raw timedatectl timesync-status output | None |

---

## Frontend Routes

## CLI Commands (sys-cli.sh — Bash interactive menus)

Top-level: `sys-cli.sh` launches `main_menu`, which maps numeric choices 1-8 to module submenus.

### Module 1 — File & Directory Management (file-mgmt.sh)

| Command / Option | Description |
|------------------|-------------|
| 1 › 1 Batch create | Prompt: dir, prefix, count, type (f/d) — batch-create files or dirs |
| 1 › 2 Batch delete | Prompt: dir, glob pattern — preview then delete matching files |
| 1 › 3 Move files | Prompt: source, destination — move files between directories |
| 1 › 4 Find & manage large files | Find files exceeding a size threshold, list and optionally delete |
| 1 › 5 Set permissions | Prompt: path, mode — chmod recursively |
| 1 › Back | Return to main menu |

### Modules 2–7 — Sub-menu options below are INFERRED (not statically parsed)

The following six sub-menu tables are derived from the web API source and general knowledge of the CLI structure. They have NOT been confirmed by reading `cron-mgmt.sh`, `time-mgmt.sh`, `pkg-mgmt.sh`, `process-mgmt.sh`, `network-mgmt.sh`, or `firewall-mgmt.sh`.

### Module 2 — Cron Job Scheduling (cron-mgmt.sh)

| Command / Option | Description |
|------------------|-------------|
| 2 › 1 Add cron job (guided) | Interactive: min, hour, day, month, wday, cmd → appends to crontab |
| 2 › 2 List cron jobs | Display numbered current crontab entries |
| 2 › 3 Delete a cron job | Prompt for entry number; remove from crontab |
| 2 › 4 Setup daily backup | Guided: source dir, dest dir → creates daily backup cron entry |
| 2 › Back | Return to main menu |

### Module 3 — System Time Management (time-mgmt.sh)

| Command / Option | Description |
|------------------|-------------|
| 3 › 1 Show current time & timezone | timedatectl status or date fallback |
| 3 › 2 Change timezone | Prompt for TZ string; sudo timedatectl set-timezone |
| 3 › 3 List timezones | timedatectl list-timezones with optional filter |
| 3 › Back | Return to main menu |

### Module 4 — Package Management (pkg-mgmt.sh)

| Command / Option | Description |
|------------------|-------------|
| 4 › 1 Install package(s) | Prompt: space-separated pkg names; detect manager; sudo install |
| 4 › 2 Remove / purge package | Prompt: pkg name; detect manager; sudo remove |
| 4 › 3 Update all packages | sudo apt-get upgrade -y (or dnf/pacman equivalent) |
| 4 › 4 Autoremove orphans | sudo apt-get autoremove -y (or equivalent) |
| 4 › Back | Return to main menu |

### Module 5 — Process Management (process-mgmt.sh)

| Command / Option | Description |
|------------------|-------------|
| 5 › 1 List top processes | ps aux sorted by CPU or mem; top 20 shown |
| 5 › 2 Kill a process | Prompt: PID, signal (default TERM) → sudo kill |
| 5 › 3 Monitor a process | Live watch of ps for a given PID |
| 5 › 4 Show process tree | pstree or ps forest output |
| 5 › 5 Find process by port | ss -tulpn filtered for port |
| 5 › Back | Return to main menu |

### Module 6 — Network & Socket Management (network-mgmt.sh)

| Command / Option | Description |
|------------------|-------------|
| 6 › 1 List listening ports & sockets | ss -tulpn (fallback netstat / /proc/net/tcp) |
| 6 › 2 Show network interfaces | ip addr show |
| 6 › 3 Show routing table | ip route show |
| 6 › 4 Test connectivity | ping + TCP bash /dev/tcp probe |
| 6 › 5 DNS lookup | dig +short or getent hosts |
| 6 › 6 Open file descriptors | lsof or ls /proc/PID/fd |
| 6 › 7 Firewall status | cat sysfs firewall attrs |
| 6 › Back | Return to main menu |

### Module 7 — Kernel Firewall (firewall-mgmt.sh)

| Command / Option | Description |
|------------------|-------------|
| 7 › 1 Load Module | insmod ubuntu_firewall.ko from ./kernel/ |
| 7 › 2 Unload Module | rmmod ubuntu_firewall with confirm prompt |
| 7 › 3 Enable Firewall | echo 1 > /sys/firewall/enabled |
| 7 › 4 Disable Firewall | echo 0 > /sys/firewall/enabled |
| 7 › 5 Set ICMP Filter | echo 1/0 > /sys/firewall/drop_icmp |
| 7 › 6 Set Reject Ports | echo <ports> > /sys/firewall/reject_ports |
| 7 › 7 Status | cat all /sys/firewall/* attrs |
| 7 › 8 View Logs | dmesg filtered for ubuntu_firewall |
| 7 › Back | Return to main menu |

---

## 3. Kernel sysfs Interfaces

### ubuntu_firewall module — /sys/firewall/

Kobject: `kobject_create_and_add("firewall", NULL)` (root kset — NOT under `kernel_kobj`).

| Interface Path | Attribute | Access | Type | Description |
|----------------|-----------|--------|------|-------------|
| /sys/firewall/enabled | `enabled_attr` | RW | `0\|1` | Master packet-filtering on/off switch |
| /sys/firewall/drop_icmp | `drop_icmp_attr` | RW | `0\|1` | Drop all ICMP packets when 1 |
| /sys/firewall/reject_ports | `reject_ports_attr` | RW | string | Comma-separated TCP ports to reject (1–65535) |
| /sys/firewall/status | `status_attr` | RO | string | Human-readable firewall status summary (not consumed by web API routes) |

### kma-vfs-guard module — /sys/kernel/kma-vfs-guard/

Kobject: `kobject_create_and_add("kma-vfs-guard", kernel_kobj)` (under kernel kset).

| Interface Path | Attribute | Access | Type | Description |
|----------------|-----------|--------|------|-------------|
| /sys/kernel/kma-vfs-guard/add_path | `add_path_attr` | WO | string | Write absolute path to add to LSM protected-inode set |
| /sys/kernel/kma-vfs-guard/remove_path | `remove_path_attr` | WO | string | Write absolute path to remove from protected-inode set |
| /sys/kernel/kma-vfs-guard/stats | `stats_attr` | RO | string | Protection stats: protected inode count + blocked-operation counters |

---

## Summary

| Interface | Category | Verified | Count |
|-----------|----------|----------|-------|
| Web API | Express HTTP routes (excl. SPA catch-all) | Yes — static parse | 35 |
| CLI | Main menu options | Yes — static parse | 8 |
| CLI | File sub-menu functions (`file-mgmt.sh`) | Yes — static parse | 5 |
| CLI | Sub-menus 2–7 functions (cron/time/pkg/process/network/firewall) | No — not in parse scope | — |
| Kernel sysfs | `ubuntu_firewall` attributes | Yes — C source | 4 |
| Kernel sysfs | `kma-vfs-guard` attributes | Yes — C source | 3 |
| **Confirmed total** | | | **47** |

---

## Unresolved Questions

1. **CLI sub-menus 2–7 not statically parsed**: `cron-mgmt.sh`, `time-mgmt.sh`, `pkg-mgmt.sh`, `process-mgmt.sh`, `network-mgmt.sh`, `firewall-mgmt.sh` were not in the file-read scope for this pass. Option counts, function names, and exact labels for those sub-menus are inferred, not verified.
2. **SPA client-side routes**: no JS router config file was read. If a client router (page.js, Navigo, etc.) defines named routes, its route table is not captured here.
3. **`vfs_guard.c` vs `kma-vfs-guard.c`**: both files define identical sysfs attributes under the same kobject path. One appears to be a refactored variant of the other. Which is compiled and loaded cannot be determined from static analysis.
4. **`/sys/firewall/status` web API gap**: `status_attr` is `__ATTR_RO` in the kernel module but never read by `firewall.js` (which only reads `enabled`, `drop_icmp`, `reject_ports`). May be intentional or an oversight in the route implementation.
