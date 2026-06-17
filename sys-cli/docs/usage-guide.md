# sys-cli Usage Guide

**Version:** 1.0.0  
**Platform:** Linux (any distro with bash 4+)

---

## Quick Start

```bash
# Make executable (first time only)
chmod +x sys-cli.sh

# Launch interactive menu
./sys-cli.sh

# Non-interactive flags
./sys-cli.sh --help
./sys-cli.sh --version
```

The tool opens a numbered main menu. Select a module by number. Navigate back to the main menu from any submenu by choosing "Back".

---

## Requirements

- Bash 4+
- Linux (the modules rely on `/proc`, `systemd`, and standard GNU tools)
- `sudo` access for operations that modify system state (permissions, packages, timezone, NTP, firewall)

---

## Modules

### 1. File & Directory Management

Batch file and directory operations with preview-before-confirm safety gates.

| Option | What it does |
|--------|-------------|
| Batch create | Creates N files or directories under a target path using a prefix (e.g. `file-1`, `file-2`) |
| Batch delete | Lists files matching a glob pattern, shows count, requires confirmation before deletion |
| Move files | Moves files matching a glob from source to destination directory |
| Find & manage large files | Lists top 20 files exceeding a size threshold (default: 100M); offers compress (gzip -9) or delete per file |
| Set permissions | Batch chmod + chown across a directory tree; validates octal modes before applying; requires sudo |

### 2. Cron Job Scheduling

Manages the current user's crontab.

| Option | What it does |
|--------|-------------|
| Add cron job (guided) | Prompts for each cron field individually, previews the full entry, adds idempotently (skips if already present) |
| List cron jobs | Shows non-comment cron entries with line numbers |
| Delete a cron job | Lists entries by number, confirms before removing; deletes by line number to handle duplicate entries correctly |
| Setup daily backup | Prompts for source/destination dirs and schedule; creates a `tar -czf` cron entry logging to `/var/log/sys-cli-backup.log` |

### 3. System Time Management

Prefers `timedatectl` where available; falls back to `/etc/localtime` symlink and `/etc/timezone`.

| Option | What it does |
|--------|-------------|
| Show current time & timezone | Runs `timedatectl status` or `date` + reads timezone file |
| Change timezone | Validates against `/usr/share/zoneinfo/` before applying; requires sudo |
| Enable NTP sync | Enables via `timedatectl set-ntp true`, or starts `chronyd`/`ntpd` as fallback; requires sudo |
| Check NTP sync status | Reports via `timedatectl timesync-status`, `chronyc tracking`, or `ntpq -p` |
| List timezones | Filters by keyword if provided; uses `timedatectl list-timezones` or scans `/usr/share/zoneinfo/` |

### 4. Package Management

Auto-detects the package manager (first match wins: `apt-get` > `dnf` > `yum` > `pacman`). All operations require sudo.

| Option | What it does |
|--------|-------------|
| Install package(s) | Accepts space-separated list; runs apt update first on apt systems |
| Remove / purge package | Optionally purges config files; runs autoremove after removal |
| Update system | Full system upgrade; prints elapsed time |
| Autoremove orphaned packages | On pacman: lists orphans before confirm. On others: delegates to native autoremove |

### 5. Process Management

| Option | What it does |
|--------|-------------|
| List top processes | `ps aux` sorted by CPU or memory; displays top 20 |
| Kill a process | Accepts PID or name; sends SIGTERM, waits 5s, offers SIGKILL if still running; multi-match names require confirmation to kill all |
| Monitor a process | Refreshes `ps` stats every 2s until process exits; Ctrl+C stops monitoring |
| Show process tree | Uses `pstree -p` if available; falls back to `ps --forest` |
| Find process by port | Tries `ss`, then `lsof`, then `/proc/net/tcp` hex parsing in order |

### 6. Network & Socket Management

Falls back gracefully when standard tools are unavailable.

| Option | What it does |
|--------|-------------|
| List listening ports & sockets | `ss -tulpn` > `netstat -tulpn` > `/proc/net/tcp` hex parser |
| Show network interfaces | `ip addr show` > `ifconfig` > `/proc/net/fib_trie` |
| Show routing table | `ip route show` (highlights default gateway) > `route -n` |
| Test connectivity | ICMP ping (3 packets) then TCP probe to a specified port (default 80); uses `nc` or bash `/dev/tcp` |
| DNS lookup | Auto-detects reverse lookup for IPs; uses `dig` > `host` > `nslookup` > `getent` |
| Open file descriptors | Lists FDs for a PID or process name via `lsof -p` or `/proc/<pid>/fd/` |
| Firewall status | Reports from `ufw` > `firewall-cmd` > `iptables` > `nft`, whichever is present |

---

## Exit Codes

| Code | Constant | Meaning |
|------|----------|---------|
| 0 | — | Success |
| 1 | — | General error |
| 64 | `E_BADARGS` | Bad arguments |
| 65 | `E_NOPERM` | Permission denied |
| 66 | `E_NOEXIST` | Resource not found |
| 67 | `E_PKGMGR` | No supported package manager |
| 68 | `E_CANCELLED` | User cancelled operation |

---

## Project Structure

```
sys-cli/
├── sys-cli.sh          # Entry point — sources all modules, main menu
└── lib/
    ├── common.sh       # Colors, output helpers (die/info/warn/success), confirm(), require_root()
    ├── file-mgmt.sh    # File & directory operations
    ├── cron-mgmt.sh    # Cron job management
    ├── time-mgmt.sh    # System time and timezone
    ├── pkg-mgmt.sh     # Package management (apt/dnf/yum/pacman)
    ├── process-mgmt.sh # Process listing, kill, monitor, tree, port lookup
    └── network-mgmt.sh # Sockets, interfaces, routing, DNS, FDs, firewall
```

Modules are sourced (not executed) by `sys-cli.sh`. Each module exposes a `*_menu()` function as its entry point plus individual operation functions that can be called directly in scripts.
