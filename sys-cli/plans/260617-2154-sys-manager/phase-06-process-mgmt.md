# Phase 06: Process Management

**Priority:** High
**Status:** Complete
**Blocks:** None | **Blocked by:** Phase 01

## Overview

Implement `lib/process-mgmt.sh` covering process listing, killing, monitoring, and job control.

## Files to Create

- `lib/process-mgmt.sh`

## Features

- List running processes (top CPU/mem consumers)
- Kill process by PID or name (SIGTERM → SIGKILL grace pattern)
- Monitor a process (watch-style loop, no `watch` dep)
- Show process tree (`pstree` with fallback)
- Find process using a specific port

## Implementation Steps

1. `process_menu()` — `select` submenu:
   - List top processes
   - Kill a process
   - Monitor a process
   - Show process tree
   - Find process by port
   - Back

2. `process_list()`:
   - `ps aux --sort=-%cpu | head -20` (by CPU)
   - Prompt: "Sort by [c]pu or [m]em?" → adjust `--sort` flag
   - Format with `awk` printf for tabular output (portable, no `column -t` dep)

3. `process_kill()`:
   - Prompt: "Kill by [p]id or [n]ame?"
   - By PID: validate numeric, `ps -p "$pid" -o comm=` to show process name before killing
   - By name: `pgrep -l "$name"` to list matches first, `confirm()` before kill
   - Safe kill sequence:
     ```bash
     kill -TERM "$pid"
     for i in $(seq 1 5); do
         kill -0 "$pid" 2>/dev/null || { info "Process $pid terminated."; return 0; }
         sleep 1
     done
     confirm "Process still running. Force kill (SIGKILL)?" && kill -KILL "$pid"
     ```
   - Require sudo if process owned by another user

4. `process_monitor()`:
   - Prompt for PID or process name
   - Resolve name → PID via `pgrep -n "$name"` if needed
   - Watch loop (zero-dep):
     ```bash
     trap 'break' INT
     while kill -0 "$pid" 2>/dev/null; do
         clear
         ps -p "$pid" -o pid,ppid,user,%cpu,%mem,vsz,rss,stat,comm
         sleep 2
     done
     info "Process $pid is no longer running."
     ```

5. `process_tree()`:
   - If `pstree` available: `pstree -p` (with PIDs)
   - Fallback: `ps --ppid 1 --pid 1 -o pid,ppid,comm --forest` (procps `--forest` flag)

6. `process_find_by_port()`:
   - Prompt for port number
   - Primary: `ss -tulpn | grep ":$port"` (no sudo needed for listening ports)
   - With sudo for process names: `sudo ss -tulpn | grep ":$port"`
   - Fallback: `lsof -i ":$port"` if `ss` unavailable
   - Last resort: parse `/proc/net/tcp` + `/proc/net/tcp6` for hex port match

## Safety Rules

- Always show process info before killing, never silent kill
- SIGTERM before SIGKILL with 5s grace period
- `pgrep` name match can hit multiple processes — always list and confirm
- Guard empty PID: `[[ -z "$pid" ]]` before any kill call

## Success Criteria

- `shellcheck lib/process-mgmt.sh` clean
- Kill sequence uses SIGTERM→SIGKILL pattern
- Monitor loop exits cleanly on Ctrl+C (trap INT)
- Port lookup works without lsof (ss fallback)
- File under 200 lines
