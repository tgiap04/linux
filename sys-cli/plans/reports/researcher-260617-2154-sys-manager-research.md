# Research Report: Linux System Management Shell Script Best Practices

**Date:** 2026-06-17
**Scope:** Bash scripting patterns for a modular sys-cli covering file mgmt, cron scheduling, time mgmt, and package mgmt.

---

## Summary

A production-quality Linux system management script can be built cleanly in Bash using: `select` builtins for menus (no external deps), `crontab -l | ... | crontab -` pipelines for safe cron manipulation, `timedatectl` for unified timezone/NTP management, and a distro-detection shim for package managers. The key architectural principles are: one file per module (<200 lines), strict `set -euo pipefail`, explicit sudo checks at entry-point, and dry-run confirmation gates before destructive operations.

---

## 1. Interactive Menu Patterns

### Ranked Options

| Tool | Deps | Portability | UX Quality | Verdict |
|------|------|-------------|------------|---------|
| `select` builtin | None | All POSIX bash | Good | **#1 — use this** |
| `whiptail` | ncurses (usually pre-installed) | Debian/RHEL | TUI dialogs | #2 — for enhanced UX |
| `dialog` | Separate pkg | Most distros | Full TUI | #3 — heavy |
| `fzf` | External install | Optional | Fuzzy pick | #4 — optional feature |

**Recommendation: `select` as primary; `whiptail` as optional enhancement behind a feature flag.**

### `select` Pattern (canonical)

```bash
#!/usr/bin/env bash
PS3="Choose option: "
options=("File Management" "Cron Jobs" "Time Management" "Package Management" "Quit")
select opt in "${options[@]}"; do
    case $opt in
        "File Management") file_menu ;;
        "Cron Jobs")        cron_menu ;;
        "Time Management")  time_menu ;;
        "Package Management") pkg_menu ;;
        "Quit")             break ;;
        *) echo "Invalid option $REPLY" ;;
    esac
done
```

Key: `PS3` sets the prompt; `REPLY` holds the raw number typed; `select` loops until `break`.

### `whiptail` Pattern (optional TUI)

```bash
choice=$(whiptail --title "Sys-CLI" --menu "Choose action" 20 60 10 \
    "1" "File Management" \
    "2" "Cron Jobs" \
    3>&1 1>&2 2>&3)
```

The `3>&1 1>&2 2>&3` fd swap is required to capture whiptail output (it writes to stderr).

---

## 2. Crontab Programmatic Manipulation

### Canonical Pattern

Never write directly to `/var/spool/cron/`. Always use `crontab` commands.

```bash
# List current crontab
crontab -l 2>/dev/null

# Add a new job (idempotent — won't duplicate)
add_cron() {
    local entry="$1"
    ( crontab -l 2>/dev/null; echo "$entry" ) | crontab -
}

# Delete a job by pattern
delete_cron() {
    local pattern="$1"
    crontab -l 2>/dev/null | grep -vF "$pattern" | crontab -
}

# List with line numbers for interactive deletion
list_cron_numbered() {
    crontab -l 2>/dev/null | grep -v '^#' | nl -ba
}
```

### Safety Rules

1. Always `2>/dev/null` on `crontab -l` — exits 1 with error if no crontab exists.
2. Use `grep -vF` (fixed-string, not regex) for deletion to avoid accidental pattern matches.
3. Validate cron expression format before inserting: `echo "$entry" | crontab -T -` (vixie-cron supports `-T`; GNU cronie may differ).
4. Final newline is **required** — `cron` logs a warning and may skip the last entry if missing. The pipeline append via `echo` guarantees the newline.
5. Idempotency check before adding:

```bash
add_cron_idempotent() {
    local entry="$1"
    crontab -l 2>/dev/null | grep -qF "$entry" && return 0
    ( crontab -l 2>/dev/null; echo "$entry" ) | crontab -
}
```

### Auto-backup cron example

```bash
# Daily backup at 2 AM
add_cron_idempotent "0 2 * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1"
```

---

## 3. System Time Management

### timedatectl (systemd — Debian/Ubuntu/RHEL/Fedora ≥ systemd)

```bash
# View current timezone and NTP status
timedatectl status

# List available timezones (filter for Vietnam)
timedatectl list-timezones | grep Asia

# Set timezone
sudo timedatectl set-timezone Asia/Ho_Chi_Minh

# Enable NTP (activates systemd-timesyncd or first available NTP service)
sudo timedatectl set-ntp true

# Check NTP sync status
timedatectl timesync-status
```

### Pre-systemd / Container fallback

```bash
# Debian/Ubuntu (no systemd)
sudo ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
echo "Asia/Ho_Chi_Minh" | sudo tee /etc/timezone

# RHEL/CentOS legacy
sudo cp /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
```

### Chrony (RHEL/CentOS preferred NTP)

```bash
sudo systemctl enable --now chronyd
chronyc tracking        # view sync status
chronyc sources -v      # view NTP sources
```

### Detection Logic

```bash
has_systemd() { command -v timedatectl &>/dev/null; }
has_chrony()  { command -v chronyc &>/dev/null; }

set_timezone() {
    local tz="$1"
    if has_systemd; then
        sudo timedatectl set-timezone "$tz"
    else
        sudo ln -sf "/usr/share/zoneinfo/$tz" /etc/localtime
    fi
}
```

---

## 4. Package Manager Detection & Commands

### Detection Shim (distro-agnostic)

```bash
detect_pkg_manager() {
    if   command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf     &>/dev/null; then echo "dnf"
    elif command -v yum     &>/dev/null; then echo "yum"
    elif command -v pacman  &>/dev/null; then echo "pacman"
    else echo "unknown"; fi
}
```

### Command Matrix

| Operation | apt (Debian/Ubuntu) | dnf (Fedora/RHEL9+) | yum (RHEL/CentOS7) | pacman (Arch) |
|-----------|--------------------|--------------------|---------------------|---------------|
| Update index | `apt-get update` | `dnf check-update` | `yum check-update` | `pacman -Sy` |
| Upgrade all | `apt-get upgrade -y` | `dnf upgrade -y` | `yum update -y` | `pacman -Syu` |
| Install pkg | `apt-get install -y PKG` | `dnf install -y PKG` | `yum install -y PKG` | `pacman -S PKG` |
| Remove pkg | `apt-get remove -y PKG` | `dnf remove -y PKG` | `yum remove -y PKG` | `pacman -R PKG` |
| Purge+config | `apt-get purge -y PKG` | `dnf remove -y PKG` | `yum remove -y PKG` | `pacman -Rns PKG` |
| Autoremove | `apt-get autoremove -y` | `dnf autoremove -y` | `yum autoremove -y` | `pacman -Rns $(pacman -Qdtq)` |

### Wrapper Pattern (DRY)

```bash
pkg_install() {
    case $(detect_pkg_manager) in
        apt)    sudo apt-get install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        yum)    sudo yum install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm "$@" ;;
        *)      die "Unsupported package manager" ;;
    esac
}
```

---

## 5. Privilege Escalation (sudo) Best Practices

### Patterns

**Pattern A — Require root at entry (recommended for system scripts):**

```bash
require_root() {
    [[ $EUID -eq 0 ]] || { echo "Run as root or with sudo." >&2; exit 1; }
}
# Call at top of script: require_root
```

**Pattern B — Per-command sudo (recommended for user-facing interactive tools):**

```bash
# Invoke specific privileged commands with sudo inline
sudo timedatectl set-timezone "$tz"
sudo apt-get install -y "$pkg"
```

**Pattern C — Elevate self (use sparingly, traps environment issues):**

```bash
[[ $EUID -eq 0 ]] || exec sudo -E "$0" "$@"
```

### Critical Rules (from ShellCheck SC2024)

- `sudo command > file` — redirection runs as **current user**, not root. Fix: `command | sudo tee file > /dev/null`
- `sudo command >> file` — same issue. Fix: `command | sudo tee -a file > /dev/null`
- Never use `sudo` inside subshells for file creation; use `sudo tee` pattern instead.
- Avoid `sudo -i` in scripts (loads root env, changes `$HOME`, breaks relative paths).
- Prefer `sudo -E` to preserve environment when needed.

---

## 6. File & Directory Operations Safety

### Destructive Op Gates

```bash
confirm() {
    local msg="$1"
    read -r -p "$msg [y/N]: " resp
    [[ ${resp,,} == "y" ]]
}

safe_delete() {
    local target="$1"
    [[ -e "$target" ]] || { echo "Not found: $target" >&2; return 1; }
    confirm "Delete $target?" || return 0
    rm -rf -- "$target"
}
```

### Find Large Files

```bash
find_large_files() {
    local dir="${1:-.}" threshold="${2:-100M}"
    find "$dir" -type f -size "+$threshold" -printf '%s\t%p\n' | sort -rn | head -20
}
```

### Compress Old Files

```bash
compress_old() {
    local dir="$1" days="${2:-30}"
    find "$dir" -type f -mtime "+$days" -not -name "*.gz" \
        -exec gzip -9 {} \;
}
```

### chmod/chown Automation

```bash
fix_perms() {
    local dir="$1" owner="${2:-root:root}"
    sudo find "$dir" -type d -exec chmod 755 {} \;
    sudo find "$dir" -type f -exec chmod 644 {} \;
    sudo chown -R "$owner" "$dir"
}
```

### Safety Rules

- Always use `-- "$var"` after command to prevent `-` prefixed filenames being parsed as flags.
- Never `rm -rf $var` without quoting: `rm -rf -- "$var"`.
- Check `[[ -z "$var" ]]` before destructive ops — empty var + `rm -rf` = disaster.
- Use `find ... -print0 | xargs -0` for filenames with spaces.
- Never parse `ls` output (filenames can contain newlines).

---

## 7. Modular Script Architecture (<200 lines/file)

### Recommended Layout

```
sys-cli/
├── sys-cli.sh          # entry point: arg parsing, menu, sources modules
├── lib/
│   ├── common.sh       # die(), confirm(), require_root(), color vars
│   ├── file-mgmt.sh    # file_menu() and helpers
│   ├── cron-mgmt.sh    # cron_menu() and helpers
│   ├── time-mgmt.sh    # time_menu() and helpers
│   └── pkg-mgmt.sh     # pkg_menu() and helpers
└── README.md
```

### Entry Point Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/file-mgmt.sh"
source "$SCRIPT_DIR/lib/cron-mgmt.sh"
source "$SCRIPT_DIR/lib/time-mgmt.sh"
source "$SCRIPT_DIR/lib/pkg-mgmt.sh"

main_menu
```

### common.sh Skeleton

```bash
#!/usr/bin/env bash
# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

die()     { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
info()    { echo -e "${GREEN}INFO: $*${NC}"; }
warn()    { echo -e "${YELLOW}WARN: $*${NC}"; }
confirm() { read -r -p "$1 [y/N]: " r; [[ ${r,,} == "y" ]]; }

require_root() {
    [[ $EUID -eq 0 ]] || die "Must run as root or with sudo."
}

command_exists() { command -v "$1" &>/dev/null; }
```

---

## 8. Error Handling & Exit Codes

### Standard Setup

```bash
set -euo pipefail
# -e: exit on any command failure
# -u: treat unset vars as errors
# -o pipefail: pipe fails if any command in pipeline fails
```

### Trap for Cleanup

```bash
cleanup() {
    local exit_code=$?
    rm -f "$TMPFILE"   # cleanup temp files
    exit $exit_code
}
trap cleanup EXIT INT TERM
```

### Exit Code Conventions

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (use sparingly — ambiguous) |
| 2 | Misuse of builtins / bad args |
| 64–113 | User-defined (recommended range per `/usr/include/sysexits.h`) |
| 126 | Command not executable |
| 127 | Command not found |
| 130 | Script terminated by Ctrl+C |

**Recommended user-defined codes for this project:**

```bash
readonly E_BADARGS=64       # invalid arguments
readonly E_NOPERM=65        # permission denied
readonly E_NOEXIST=66       # file/resource not found
readonly E_PKGMGR=67        # unsupported package manager
readonly E_CANCELLED=68     # user cancelled operation
```

### Error Propagation Pattern

```bash
run_or_die() {
    "$@" || die "Command failed: $*"
}

# Usage:
run_or_die sudo apt-get update
```

---

## 9. Source Credibility Assessment

| Source | Type | Reliability |
|--------|------|-------------|
| `man7.org/linux/man-pages` (timedatectl) | Official kernel/systemd man pages | **High** |
| `tldp.org/LDP/abs` (exit codes) | Long-running reference doc | **High** (stable content) |
| `mywiki.wooledge.org` (BashGuide, BashFAQ) | Community canonical reference (Greg Wooledge) | **High** — de facto bash authority |
| `shellcheck.net/wiki` (SC2024) | Maintainer docs for ShellCheck tool | **High** |
| `man7.org/crontab(5)` | Official man page | **High** |
| General bash knowledge synthesized | Compiler of known patterns | Validated against above |

---

## Comparative Analysis: Menu Tools

| | select | whiptail | fzf |
|-|--------|----------|-----|
| Zero-dep | Yes | No (ncurses) | No (install) |
| Pre-installed on minimal Linux | Yes | Usually | No |
| Multi-column display | No | Yes | Yes |
| Fuzzy search | No | No | Yes |
| Script complexity added | Minimal | Medium | Low |
| Recommended for | Main menus | Sub-menus w/ many options | File/package picker |

**Verdict:** Implement `select` as the baseline; wrap `whiptail`/`fzf` calls in `command_exists` guards to enhance UX when available.

---

## Unresolved Questions

1. **Target distros**: Is pacman/Arch required, or Debian/RHEL only? Pacman autoremove requires listing orphans first (`pacman -Qdtq`) — adds complexity.
2. **Privilege model**: Should the tool require root at startup, or use per-command sudo? Impacts UX and file ownership of logs.
3. **Cron validation**: Target crond flavor (vixie-cron, cronie, fcron)? Only cronie supports `crontab -T` for pre-install validation.
4. **Container/WSL support**: `timedatectl` fails in Docker containers without systemd. Need fallback path?
5. **Logging**: Structured log to file, or stderr-only? Affects `trap cleanup` design.
