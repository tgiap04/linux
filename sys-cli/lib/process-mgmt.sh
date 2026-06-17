#!/usr/bin/env bash
# Process management: list, kill, monitor, tree, port lookup

process_menu() {
    local options=("List top processes" "Kill a process" "Monitor a process"
                   "Show process tree" "Find process by port" "Back")
    while true; do
        header "Process Management"
        select opt in "${options[@]}"; do
            case "$REPLY" in
                1) process_list ;;
                2) process_kill ;;
                3) process_monitor ;;
                4) process_tree ;;
                5) process_find_by_port ;;
                6) return 0 ;;
                *) warn "Invalid option" ;;
            esac
            break
        done
    done
}

process_list() {
    header "Top Processes"
    local sort_key
    read -r -p "Sort by [c]pu or [m]em? (default: c): " sort_key
    case "${sort_key,,}" in
        m|mem) sort_key="-%mem" ;;
        *)     sort_key="-%cpu" ;;
    esac

    info "Sorted by ${sort_key#-}"
    echo ""
    ps aux --sort="$sort_key" | head -21 | \
        awk 'NR==1 { printf "%-10s %6s %5s %5s %-8s %s\n", "USER","PID","%CPU","%MEM","STAT","COMMAND"; next }
             { printf "%-10s %6s %5s %5s %-8s %s\n", $1,$2,$3,$4,$8,$11 }'
    press_enter
}

_safe_kill() {
    local pid="$1"
    [[ -z "$pid" ]] && die "No PID specified"
    [[ ! "$pid" =~ ^[0-9]+$ ]] && die "Invalid PID: $pid"

    local comm
    comm=$(ps -p "$pid" -o comm= 2>/dev/null) || { warn "PID $pid not found."; return 1; }
    info "Target: PID=$pid  COMMAND=$comm"
    confirm "Terminate process $pid ($comm)?" || { info "Aborted."; return 0; }

    kill -TERM "$pid" 2>/dev/null || { warn "Could not send SIGTERM to $pid (permission denied?)."; return 1; }
    local i
    for i in $(seq 1 5); do
        kill -0 "$pid" 2>/dev/null || { success "Process $pid terminated."; return 0; }
        sleep 1
    done
    warn "Process $pid still running after 5s."
    if confirm "Force kill (SIGKILL)?"; then
        kill -KILL "$pid" 2>/dev/null && success "SIGKILL sent to $pid." || warn "SIGKILL failed (permission denied?)."
    else
        info "Left running."
    fi
}

process_kill() {
    header "Kill a Process"
    local mode
    read -r -p "Kill by [p]id or [n]ame? " mode
    case "${mode,,}" in
        p|pid)
            local pid
            read -r -p "Enter PID: " pid
            _safe_kill "$pid"
            ;;
        n|name)
            local name
            read -r -p "Enter process name: " name
            [[ -z "$name" ]] && { warn "No name given."; return 1; }
            local matches
            matches=$(pgrep -l "$name" 2>/dev/null)
            if [[ -z "$matches" ]]; then
                warn "No processes found matching '$name'."
                return 1
            fi
            info "Matching processes:"
            echo "$matches"
            local pid_list count
            pid_list=$(pgrep "$name")
            count=$(echo "$pid_list" | wc -l)
            if [[ "$count" -gt 1 ]]; then
                confirm "Kill ALL $count matching processes?" || { info "Aborted."; return 0; }
                while IFS= read -r p; do _safe_kill "$p"; done <<< "$pid_list"
            else
                _safe_kill "$(echo "$pid_list" | tr -d '[:space:]')"
            fi
            ;;
        *)
            warn "Unknown option."
            ;;
    esac
    press_enter
}

process_monitor() {
    header "Monitor Process"
    local input pid
    read -r -p "Enter PID or process name: " input
    [[ -z "$input" ]] && { warn "No input."; return 1; }

    if [[ "$input" =~ ^[0-9]+$ ]]; then
        pid="$input"
    else
        pid=$(pgrep -n "$input" 2>/dev/null)
        [[ -z "$pid" ]] && { warn "No process found matching '$input'."; return 1; }
        info "Resolved '$input' to PID $pid"
    fi

    kill -0 "$pid" 2>/dev/null || { warn "PID $pid not found."; return 1; }
    info "Monitoring PID $pid — Ctrl+C to stop"
    sleep 1

    # shellcheck disable=SC2064
    trap 'echo; info "Monitoring stopped."; trap - INT; return 0' INT
    while kill -0 "$pid" 2>/dev/null; do
        clear
        echo -e "${BOLD}Monitoring PID $pid — Ctrl+C to stop${NC}"
        echo ""
        ps -p "$pid" -o pid,ppid,user,%cpu,%mem,vsz,rss,stat,comm 2>/dev/null
        sleep 2
    done
    trap - INT
    info "Process $pid is no longer running."
    press_enter
}

process_tree() {
    header "Process Tree"
    if command_exists pstree; then
        pstree -p
    else
        ps --ppid 1 --pid 1 -o pid,ppid,comm --forest 2>/dev/null || \
            ps -e -o pid,ppid,comm | sort -k2 -n
    fi
    press_enter
}

process_find_by_port() {
    header "Find Process by Port"
    local port
    read -r -p "Enter port number: " port
    [[ -z "$port" ]] && { warn "No port given."; return 1; }
    [[ ! "$port" =~ ^[0-9]+$ ]] && { warn "Invalid port: $port"; return 1; }

    local found=0

    if command_exists ss; then
        local result
        result=$(ss -tulpn 2>/dev/null | grep ":${port}[^0-9]")
        if [[ -n "$result" ]]; then
            info "ss output:"
            echo "$result"
            found=1
        fi
    fi

    if [[ "$found" -eq 0 ]] && command_exists lsof; then
        local result
        result=$(lsof -i ":$port" 2>/dev/null)
        if [[ -n "$result" ]]; then
            info "lsof output:"
            echo "$result"
            found=1
        fi
    fi

    if [[ "$found" -eq 0 ]] && [[ -f /proc/net/tcp ]]; then
        local hex_port
        hex_port=$(printf '%04X' "$port")
        info "Parsing /proc/net/tcp for port $port (hex: $hex_port)..."
        grep -i " [0-9A-F]*:${hex_port} " /proc/net/tcp /proc/net/tcp6 2>/dev/null | \
            awk '{print "inode:", $10, "local:", $2, "remote:", $3, "state:", $4}'
        found=1
    fi

    [[ "$found" -eq 0 ]] && warn "No process found on port $port (ss/lsof unavailable and /proc/net/tcp gave no results)."
    press_enter
}
