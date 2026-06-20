#!/usr/bin/env bash
# lib/firewall-mgmt.sh — Kernel firewall module management via sysfs

readonly SYSFS_FW="/sys/firewall"

# ---------------------------------------------------------------------------
# Menu
# ---------------------------------------------------------------------------

firewall_menu() {
    while true; do
        header "Kernel Firewall"
        local options=(
            "Load Module"
            "Unload Module"
            "Enable Firewall"
            "Disable Firewall"
            "Set ICMP Filter"
            "Set Reject Ports"
            "Status"
            "View Logs"
            "Back"
        )
        PS3=$'\n'"$(echo -e "${BOLD}Choose an option [1-9]:${NC} ")"
        select opt in "${options[@]}"; do
            case $REPLY in
                1) firewall_load       ;;
                2) firewall_unload     ;;
                3) firewall_enable     ;;
                4) firewall_disable    ;;
                5) firewall_set_icmp   ;;
                6) firewall_set_ports  ;;
                7) firewall_status     ;;
                8) firewall_logs       ;;
                9) return              ;;
                *) warn "Invalid choice" ;;
            esac
            break
        done
    done
}

# ---------------------------------------------------------------------------
# Module load / unload
# ---------------------------------------------------------------------------

firewall_load() {
    header "Load Kernel Module"
    local ko="$SCRIPT_DIR/kernel/ubuntu_firewall.ko"
    if [[ -f "$ko" ]]; then
        if lsmod | grep -q "^ubuntu_firewall"; then
            warn "Module 'ubuntu_firewall' is already loaded."
        else
            info "Loading module from: $ko"
            if sudo insmod "$ko" 2>&1; then
                sleep 1
                if [[ -d "$SYSFS_FW" ]]; then
                    success "Module loaded. Sysfs interface available at $SYSFS_FW"
                else
                    warn "Module loaded but sysfs interface not found at $SYSFS_FW"
                fi
            else
                die "insmod failed — check dmesg for details."
            fi
        fi
    else
        warn "Module not found at: $ko"
        info "Build it first or place the .ko file in: $SCRIPT_DIR/kernel/"
    fi
    press_enter
}

firewall_unload() {
    header "Unload Kernel Module"
    if lsmod | grep -q "^ubuntu_firewall"; then
        if confirm "Unload the ubuntu_firewall module?"; then
            if sudo rmmod ubuntu_firewall 2>&1; then
                success "Module unloaded."
            else
                die "rmmod failed — is the module in use?"
            fi
        fi
    else
        info "Module 'ubuntu_firewall' is not currently loaded."
    fi
    press_enter
}

# ---------------------------------------------------------------------------
# Sysfs toggles
# ---------------------------------------------------------------------------

firewall_enable() {
    header "Enable Firewall"
    if [[ ! -w "$SYSFS_FW/enabled" ]]; then
        warn "Module not loaded or sysfs not writable at $SYSFS_FW/enabled"
        press_enter; return
    fi
    echo 1 | sudo tee "$SYSFS_FW/enabled" > /dev/null
    success "Firewall enabled."
    press_enter
}

firewall_disable() {
    header "Disable Firewall"
    if [[ ! -w "$SYSFS_FW/enabled" ]]; then
        warn "Module not loaded or sysfs not writable at $SYSFS_FW/enabled"
        press_enter; return
    fi
    echo 0 | sudo tee "$SYSFS_FW/enabled" > /dev/null
    info "Firewall disabled."
    press_enter
}

firewall_set_icmp() {
    header "ICMP Filter"
    if [[ ! -w "$SYSFS_FW/drop_icmp" ]]; then
        warn "Module not loaded or sysfs not writable at $SYSFS_FW/drop_icmp"
        press_enter; return
    fi
    local reply
    read -r -p "Drop ICMP (ping) requests? [y/N]: " reply
    case ${reply,,} in
        y|yes) echo 1 | sudo tee "$SYSFS_FW/drop_icmp" > /dev/null && success "ICMP drop enabled." ;;
        *)     echo 0 | sudo tee "$SYSFS_FW/drop_icmp" > /dev/null && info "ICMP drop disabled." ;;
    esac
    press_enter
}

# ---------------------------------------------------------------------------
# Port configuration
# ---------------------------------------------------------------------------

firewall_set_ports() {
    header "Set Reject Ports"
    if [[ ! -w "$SYSFS_FW/reject_ports" ]]; then
        warn "Module not loaded or sysfs not writable at $SYSFS_FW/reject_ports"
        press_enter; return
    fi
    local ports
    read -r -p "Comma-separated ports to reject (1-65535) [e.g. 22,80,443]: " ports
    [[ -z "$ports" ]] && warn "No input provided." && press_enter && return

    local invalid=0
    for p in $(echo "$ports" | tr ',' '\n' | tr -d ' '); do
        if ! [[ "$p" =~ ^[0-9]+$ ]] || (( p < 1 || p > 65535 )); then
            warn "Invalid port: '$p' (must be 1-65535)"
            invalid=1
        fi
    done
    [[ $invalid -eq 1 ]] && press_enter && return

    echo "$ports" | sudo tee "$SYSFS_FW/reject_ports" > /dev/null
    success "Reject ports set to: $ports"
    press_enter
}

# ---------------------------------------------------------------------------
# Status & logs
# ---------------------------------------------------------------------------

firewall_status() {
    header "Firewall Status"

    if ! lsmod | grep -q "^ubuntu_firewall"; then
        warn "Module 'ubuntu_firewall' is not loaded."
        info "Use 'Load Module' to load it first."
        press_enter; return
    fi

    local val
    echo -e "${BOLD}Module:${NC} ubuntu_firewall (loaded)"

    for attr in enabled drop_icmp reject_ports; do
        local path="$SYSFS_FW/$attr"
        if [[ -r "$path" ]]; then
            val=$(cat "$path" 2>/dev/null)
            echo -e "${BOLD}${attr}:${NC} $val"
        else
            echo -e "${YELLOW}${attr}:${NC} <not readable>"
        fi
    done

    press_enter
}

firewall_logs() {
    header "Firewall Logs"
    local entries
    entries=$(dmesg | grep "ubuntu_firewall" 2>/dev/null | tail -20)
    if [[ -n "$entries" ]]; then
        echo "$entries"
    else
        info "No ubuntu_firewall entries in dmesg."
    fi
    press_enter
}