# Research Report: Process Management & Network/FD Management for sys-cli

**Date:** 2026-06-17
**Scope:** Bash scripting patterns for two new sys-cli modules — process management and network/FD management — targeting Debian/RHEL/Arch portability.

---

## Summary

Both modules can be implemented with near-zero external dependencies for core operations. Process management relies on `ps`, `kill`, `/proc`, and bash builtins — all present on every Linux. Network management has a transitional landscape: `ss` (iproute2) has replaced `netstat` on all modern distros, `ip` replaced `ifconfig`, but both old tools still ship on many systems and must be handled via fallback chains. The critical design patterns are: (1) safe two-phase kill (SIGTERM → sleep → SIGKILL), (2) `command -v` fallback chains for optional tools, (3) `/proc/net/tcp` as zero-dependency port inspection fallback, and (4) a `while true; do ... sleep N; done` loop as a portable `watch` replacement. Privilege separation is the main complexity: `ss -tulpn`, `lsof`, and firewall commands need `sudo`; pure process listing and routing do not.

---

## 1. Process Management

### 1.1 Portable Process Listing

| Goal | Command | Notes |
|------|---------|-------|
| All processes, full | `ps -eo pid,ppid,user,%cpu,%mem,rss,stat,etime,args` | POSIX `-o` — most portable |
| All processes, quick | `ps aux` | BSD form, works everywhere on Linux |
| Sorted by CPU | `ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu` | `--sort` is procps-ng specific but universal on Linux |
| Sorted by MEM | `ps -eo pid,user,%cpu,%mem,comm --sort=-%mem` | Same |
| Find by name | `pgrep -a nginx` | Returns PID + cmdline; `pgrep` is procps, present everywhere |
| Process tree | `pstree -p` | `pstree` (psmisc package); fallback: `ps -ejH` or `ps axjf` |
| Threads | `ps -eLf` | `-L` lists threads with LWP column |

**Portability verdict:**
- `ps -e -o ...` (POSIX style) + `--sort` works on all Debian/RHEL/Arch (all use procps-ng).
- Avoid `ps axuf` mixed syntax (works but man page warns about conflicts).
- `pgrep`/`pkill` are procps-ng tools — present by default on all three distros.
- `pstree` is `psmisc` — installed by default on Debian/Ubuntu, usually on RHEL/Arch; add `command -v pstree` guard.

### 1.2 Safe Process Kill Pattern

**Rule: always SIGTERM first, then SIGKILL after a grace period.**

```bash
# Safe kill with grace period
safe_kill() {
    local pid="$1"
    local grace="${2:-10}"  # seconds, default 10

    if ! kill -0 "$pid" 2>/dev/null; then
        echo "PID $pid does not exist"
        return 1
    fi

    kill -TERM "$pid" 2>/dev/null
    local i=0
    while kill -0 "$pid" 2>/dev/null && (( i < grace )); do
        sleep 1
        (( i++ ))
    done

    if kill -0 "$pid" 2>/dev/null; then
        echo "Process $pid did not exit after ${grace}s — sending SIGKILL"
        kill -KILL "$pid" 2>/dev/null
    else
        echo "Process $pid terminated cleanly"
    fi
}
```

Key points:
- `kill -0 PID` tests existence without sending a signal (no-op, exit code only).
- `kill -TERM` (15) first — allows the process to flush buffers, close FDs, run cleanup handlers.
- `kill -KILL` (9) is uncatchable — OS terminates immediately, no cleanup. Use as last resort only.
- By-name: `pkill -TERM nginx` → wait → `pkill -KILL nginx`. But be careful: `pkill` pattern-matches, can hit multiple processes.
- `killall nginx` kills all processes named exactly "nginx" — safer for name-based kills than `pkill`.

**Signal reference:**

| Signal | Number | Catchable | Typical use |
|--------|--------|-----------|-------------|
| SIGHUP | 1 | Yes | Reload config (daemons) |
| SIGTERM | 15 | Yes | Graceful shutdown — always try first |
| SIGINT | 2 | Yes | Keyboard Ctrl+C equivalent |
| SIGKILL | 9 | NO | Force kill — last resort |
| SIGSTOP | 19 | NO | Pause process |
| SIGCONT | 18 | Yes | Resume paused process |

### 1.3 Process Monitoring (watch-style polling)

`watch` itself is not available on all systems and requires a TTY. Use a bash loop:

```bash
# Portable watch replacement — monitor a process
watch_process() {
    local pid="$1"
    local interval="${2:-2}"
    while true; do
        clear
        echo "=== Process Monitor: PID $pid | $(date) ==="
        if ! ps -p "$pid" -o pid,user,%cpu,%mem,rss,etime,stat,args 2>/dev/null; then
            echo "Process $pid is no longer running."
            break
        fi
        sleep "$interval"
    done
}
```

For system-wide top-style polling without `htop`:
```bash
watch_top() {
    local interval="${1:-3}"
    while true; do
        clear
        echo "=== Top Processes by CPU | $(date) ==="
        ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -20
        sleep "$interval"
    done
}
```

**Why not `watch`:** `watch` forks a new process per tick, clears screen via terminfo, not portable to minimal systems. The `while/clear/sleep` pattern works in any terminal with no deps.

### 1.4 Find Process Using a Port

```bash
# Requires ss (iproute2) — no sudo for own processes, sudo for all
port_owner() {
    local port="$1"
    if command -v ss &>/dev/null; then
        sudo ss -tulpn | grep ":${port}\b"
    elif command -v lsof &>/dev/null; then
        sudo lsof -iTCP:"$port" -sTCP:LISTEN -n -P
    else
        # Zero-dependency fallback via /proc/net
        echo "Warning: ss and lsof not found; reading /proc/net/tcp directly"
        # Convert decimal port to hex for /proc/net/tcp lookup
        printf "%04X\n" "$port" | \
            xargs -I{} grep -i ":{}[[:space:]]" /proc/net/tcp /proc/net/tcp6 2>/dev/null
    fi
}
```

The `/proc/net/tcp` fallback is always available (Linux kernel), but output is hex and requires parsing — suitable as a last resort.

### 1.5 Background/Foreground Job Management

These are bash builtins — zero deps, zero sudo:

```bash
# List background jobs
jobs -l          # -l adds PID to output

# Send job to background (from stopped job)
bg %1            # %1 = job number from jobs output

# Bring to foreground
fg %1

# Detach job from shell (survive shell exit, no HUP)
disown %1        # removes from job table
disown -h %1     # keeps in table but ignores SIGHUP

# Start a command in background and disown immediately
some_command &
disown $!        # $! = PID of last backgrounded job
```

**Note:** `disown` does NOT redirect stdout/stderr — if shell exits, output to terminal is lost. For long-running background tasks, redirect output: `some_command > /tmp/cmd.log 2>&1 & disown $!`

### 1.6 Process Tree

```bash
show_proc_tree() {
    if command -v pstree &>/dev/null; then
        pstree -p -a          # -p shows PIDs, -a shows args
    else
        echo "pstree not found — fallback:"
        ps -ejH               # POSIX process tree fallback
    fi
}
```

### 1.7 Privilege Requirements — Process Module

| Operation | Privilege | Notes |
|-----------|-----------|-------|
| `ps` (list all) | User | No sudo needed |
| `pgrep`/`pkill` (own processes) | User | No sudo needed |
| `pkill`/`kill` (other user's processes) | Sudo | Permission denied without it |
| `pstree` | User | Reads /proc, public |
| `ss -tulpn` (see process names) | Sudo | `-p` flag needs it to read `/proc/<pid>/fd` of other users |
| `jobs`/`bg`/`fg`/`disown` | User (builtins) | Shell job table only |
| `/proc/net/tcp` | User | World-readable |

---

## 2. File Descriptors, Sockets & Network Management

### 2.1 Tool Availability Matrix

| Tool | Package | Debian | RHEL | Arch | Fallback |
|------|---------|--------|------|------|----------|
| `ss` | iproute2 | Default | Default | Default | `/proc/net/tcp` |
| `ip` | iproute2 | Default | Default | Default | `ifconfig` |
| `lsof` | lsof | Default | Default | Default | `ss -p` |
| `netstat` | net-tools | Not default | Not default | AUR | `ss` |
| `ifconfig` | net-tools | Not default | Not default | AUR | `ip addr` |
| `dig` | bind-utils/dnsutils | Optional | Optional | Optional | `nslookup`/`host` |
| `nslookup` | bind-utils/dnsutils | Optional | Optional | Optional | `host` |
| `host` | bind-utils/dnsutils | Optional | Optional | Optional | `getent hosts` |
| `nc`/`ncat` | netcat/nmap-ncat | Usually | Usually | Usually | `bash /dev/tcp` |
| `iftop` | iftop | Optional | Optional | Optional | no fallback |
| `nethogs` | nethogs | Optional | Optional | Optional | no fallback |
| `ufw` | ufw | Ubuntu default | Not available | AUR | `iptables -L` |
| `firewall-cmd` | firewalld | Optional | Default | Optional | `iptables -L` |
| `ping` | iputils | Default | Default | Default | none |
| `curl` | curl | Default | Default | Default | `wget` |

**Canonical check pattern:**

```bash
require_tool() {
    local tool="$1"
    if ! command -v "$tool" &>/dev/null; then
        echo "Error: '$tool' not installed. Install with:"
        case "$(detect_distro)" in   # reuse existing distro detection
            debian|ubuntu) echo "  sudo apt install $2" ;;
            rhel|fedora|centos) echo "  sudo dnf install $3" ;;
            arch) echo "  sudo pacman -S $4" ;;
        esac
        return 1
    fi
}

# Usage: require_tool lsof lsof lsof lsof || return
```

### 2.2 List Open File Descriptors

```bash
list_fds() {
    local target="${1:-}"  # optional PID or process name
    if command -v lsof &>/dev/null; then
        if [[ -n "$target" ]]; then
            if [[ "$target" =~ ^[0-9]+$ ]]; then
                lsof -p "$target"
            else
                lsof -c "$target"
            fi
        else
            sudo lsof
        fi
    else
        echo "lsof not available — use ss for network sockets"
        echo "Open FDs for PID (kernel-level):"
        if [[ -n "$target" && "$target" =~ ^[0-9]+$ ]]; then
            ls -la "/proc/${target}/fd" 2>/dev/null || echo "No access to /proc/$target/fd"
        fi
    fi
}
```

**Privilege:** `lsof` without args — needs sudo to see all processes. `lsof -p <own-pid>` — no sudo. `/proc/<pid>/fd` — readable only for own processes or root.

### 2.3 List Listening Ports and Socket Connections

Primary tool: `ss` (iproute2, always present):

```bash
list_ports() {
    local mode="${1:-listening}"  # listening | all | established
    case "$mode" in
        listening)
            # -t TCP, -u UDP, -l listening, -p process, -n numeric
            sudo ss -tulpn
            ;;
        all)
            sudo ss -tupan
            ;;
        established)
            ss -tn state established
            ;;
    esac
}
```

Fallback to `netstat` if `ss` somehow absent (extremely rare on modern systems):
```bash
list_ports_compat() {
    if command -v ss &>/dev/null; then
        sudo ss -tulpn
    elif command -v netstat &>/dev/null; then
        sudo netstat -tulpn
    else
        echo "Neither ss nor netstat available — reading /proc/net/tcp"
        awk 'NR>1 {printf "Port: %d State: %s\n", strtonum("0x"substr($2,index($2,":")+1)), $4}' \
            /proc/net/tcp /proc/net/tcp6 2>/dev/null
    fi
}
```

**Tabular formatting** — `ss` output is already columnar; for custom tables use `column -t`:
```bash
sudo ss -tulpn | column -t
```

### 2.4 Connectivity Testing

```bash
test_connectivity() {
    local host="$1"
    local port="${2:-}"

    # ICMP ping
    if ping -c3 -W2 "$host" &>/dev/null; then
        echo "ICMP: $host reachable"
    else
        echo "ICMP: $host unreachable (may be firewalled)"
    fi

    # TCP port test
    if [[ -n "$port" ]]; then
        if command -v nc &>/dev/null; then
            if nc -zw3 "$host" "$port" 2>/dev/null; then
                echo "TCP $host:$port open"
            else
                echo "TCP $host:$port closed/filtered"
            fi
        elif command -v curl &>/dev/null; then
            if curl -s --connect-timeout 3 "http://${host}:${port}" &>/dev/null; then
                echo "TCP $host:$port reachable via curl"
            fi
        else
            # Bash /dev/tcp — no external tools needed
            if (echo >/dev/tcp/"$host"/"$port") 2>/dev/null; then
                echo "TCP $host:$port open (bash /dev/tcp)"
            else
                echo "TCP $host:$port closed/filtered"
            fi
        fi
    fi
}
```

**`bash /dev/tcp/host/port`** — built into bash, zero deps. Disabled on some hardened systems (`/etc/bash.bashrc` or compile-time). Use as last fallback.

### 2.5 Network Interfaces

```bash
show_interfaces() {
    if command -v ip &>/dev/null; then
        ip addr show
    elif command -v ifconfig &>/dev/null; then
        ifconfig -a
    else
        echo "Neither ip nor ifconfig available"
        cat /proc/net/if_inet6 2>/dev/null
        cat /proc/net/fib_trie 2>/dev/null | grep -A1 "LOCAL" | head -40
    fi
}

show_routing() {
    if command -v ip &>/dev/null; then
        ip route show
    elif command -v route &>/dev/null; then
        route -n
    else
        cat /proc/net/route
    fi
}
```

### 2.6 DNS Lookup

```bash
dns_lookup() {
    local target="$1"
    if command -v dig &>/dev/null; then
        dig "$target" +short
    elif command -v host &>/dev/null; then
        host "$target"
    elif command -v nslookup &>/dev/null; then
        nslookup "$target"
    else
        # Pure bash/system fallback
        getent hosts "$target"
    fi
}
```

**`getent hosts`** — uses NSS (`/etc/nsswitch.conf`), respects `/etc/hosts` and DNS. Always available on glibc systems. No external tools needed.

### 2.7 Network Traffic Monitoring (Optional Tools)

```bash
monitor_traffic() {
    local iface="${1:-$(ip route show default | awk '/default/{print $5; exit}')}"
    if command -v iftop &>/dev/null; then
        sudo iftop -i "$iface"
    elif command -v nethogs &>/dev/null; then
        sudo nethogs "$iface"
    else
        echo "iftop/nethogs not installed. Manual polling via /proc/net/dev:"
        watch_net_stats "$iface"
    fi
}

watch_net_stats() {
    local iface="${1:-eth0}"
    local interval=2
    while true; do
        clear
        echo "=== Network Stats: $iface | $(date) ==="
        grep "$iface" /proc/net/dev | \
            awk '{printf "RX: %s bytes  TX: %s bytes\n", $2, $10}'
        sleep "$interval"
    done
}
```

`/proc/net/dev` — always available, no deps. Shows cumulative byte/packet counters; take two snapshots to compute rate if needed.

### 2.8 Firewall Status

```bash
firewall_status() {
    if command -v ufw &>/dev/null; then
        sudo ufw status verbose
    elif command -v firewall-cmd &>/dev/null; then
        sudo firewall-cmd --state
        sudo firewall-cmd --list-all
    elif command -v iptables &>/dev/null; then
        sudo iptables -L -n -v
    else
        echo "No firewall tool found (ufw, firewalld, iptables)"
    fi
}
```

**Distro mapping:**
- Ubuntu/Debian: `ufw` (built on iptables/nftables)
- RHEL/CentOS/Fedora: `firewalld` (`firewall-cmd`)
- Arch: none by default; `iptables` or `nftables` direct
- All: `iptables -L` works everywhere as universal fallback (but may show empty chains if `nftables` is primary)

### 2.9 Privilege Requirements — Network Module

| Operation | Privilege | Notes |
|-----------|-----------|-------|
| `ss -tuln` (no -p) | User | Port numbers only, no process info |
| `ss -tulpn` | Sudo | `-p` needs `/proc/<pid>/fd` access |
| `lsof -i` (own processes) | User | Own sockets only |
| `lsof -i` (all) | Sudo | See all processes |
| `ip addr`, `ip route` | User | Read-only, no sudo |
| `ip link set` (change interface) | Sudo | Modification |
| `ping` (Linux ≥ 4.x) | User | CAP_NET_RAW or group `ping` |
| `ping` (older systems) | Sudo | setuid binary on some distros |
| `dig`/`host`/`nslookup` | User | DNS only |
| `ufw status` | Sudo | Rule inspection |
| `firewall-cmd --list` | Sudo | Rule inspection |
| `iptables -L` | Sudo | Always |
| `iftop`/`nethogs` | Sudo | Raw socket capture |

---

## 3. Cross-Cutting Patterns

### 3.1 Tool Fallback Chain Pattern (canonical)

```bash
# Generic fallback chain — try tools in order
run_first_available() {
    local -n cmds=$1   # nameref to array of commands (bash 4.3+)
    for cmd_fn in "${cmds[@]}"; do
        if command -v "${cmd_fn%%[[:space:]]*}" &>/dev/null; then
            "$cmd_fn"
            return 0
        fi
    done
    echo "No suitable tool found for this operation" >&2
    return 1
}
```

Or simpler inline pattern (preferred for readability):
```bash
if command -v ss &>/dev/null; then
    ss_cmd
elif command -v netstat &>/dev/null; then
    netstat_cmd
else
    proc_fallback
fi
```

**`command -v`** vs `which`: use `command -v` — it's a bash builtin, handles functions/aliases/builtins correctly, no external dep, POSIX.

### 3.2 Tabular Output in Bash

Three approaches, ranked:

| Approach | When to use |
|----------|-------------|
| `column -t` | Pipe to it; auto-aligns columns by max width; available everywhere |
| `printf "%-15s %-10s %s\n"` | Fixed-width known-schema output; no external tool |
| `awk '{printf ...}'` | Complex formatting, math, conditional coloring |

```bash
# Example: clean process table
printf "%-8s %-12s %5s %5s %s\n" "PID" "USER" "%CPU" "%MEM" "COMMAND"
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | tail -n +2 | head -20 | \
    while read -r pid user cpu mem comm; do
        printf "%-8s %-12s %5s %5s %s\n" "$pid" "$user" "$cpu" "$mem" "$comm"
    done
```

### 3.3 Polling Loop (watch replacement)

```bash
poll_loop() {
    local interval="${1:-2}"
    local fn="${2:-}"        # function name to call each tick
    trap 'echo "Stopped."; break' INT
    while true; do
        clear
        [[ -n "$fn" ]] && "$fn" || echo "(no refresh function provided)"
        echo ""
        echo "Refreshing every ${interval}s — Ctrl+C to stop"
        sleep "$interval"
    done
}
```

Key: `trap ... INT` catches Ctrl+C cleanly inside the loop; otherwise the trap propagates to the caller.

---

## 4. Architectural Fit Notes (sys-cli context)

Aligned with existing report conventions:

1. **Module files:** `process.sh` and `network.sh` — each <200 lines; split into `process-utils.sh` if needed.
2. **Sudo guard:** reuse the existing sudo check pattern from the entry point; individual functions accept a `--sudo` flag or check `$EUID`.
3. **Distro detection:** reuse existing shim for install-hint messages on missing tools.
4. **`set -euo pipefail`:** be careful with `kill -0` checks — they return non-zero if PID absent; wrap in `if` or use `|| true`.
5. **`/proc` fallbacks** are Linux-specific — acceptable since project targets Linux only.
6. **`ss` is the only required new tool** beyond procps-ng (which is already assumed). Everything else has `/proc` fallbacks.

---

## Sources

- [ps(1) man page — man7.org](https://man7.org/linux/man-pages/man1/ps.1.html) — authoritative, procps-ng maintainer docs
- [ss(8) man page — man7.org](https://man7.org/linux/man-pages/man8/ss.8.html) — authoritative, iproute2 maintainer docs
- [lsof(8) man page — man7.org](https://man7.org/linux/man-pages/man8/lsof.8.html) — authoritative
- [Advanced Bash Scripting Guide (TLDP) — signals chapter](https://tldp.org/LDP/abs/html/x9644.html) — signal/kill patterns

Note: WebSearch unavailable (provider error during session). Report based on authoritative man page content via WebFetch + knowledge synthesis. No tutorial-grade sources used.

---

## Unresolved Questions

1. **`ping` privilege on target distros:** On newer Linux (≥4.x), `ping` uses `CAP_NET_RAW` via group membership; older systems need setuid. Should sys-cli detect and warn, or silently ignore failures?
2. **nftables vs iptables on Arch/modern RHEL:** `iptables` may be a compatibility shim over nftables. `iptables -L` works but misses nftables-native rules. Should the firewall module also check `nft list ruleset`?
3. **`/dev/tcp` availability:** Some hardened systems (AppArmor/SELinux profiles or bash compiled with `--without-bash-dev-tcp`) disable it. Need a test: `(echo >/dev/tcp/localhost/1) 2>/dev/null; [[ $? -eq 1 ]] && echo "disabled"` — worth adding to capability detection at script startup?
4. **`column -t` availability on minimal containers:** busybox `column` exists but may lack `-t`. Worth adding a guard or using `awk printf` as default.
