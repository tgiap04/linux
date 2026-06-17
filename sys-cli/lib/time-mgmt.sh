#!/usr/bin/env bash
# lib/time-mgmt.sh — System time and timezone management

# --- Detection helpers ---
has_timedatectl() { command_exists timedatectl; }
has_chrony()      { command_exists chronyc; }
has_ntpd()        { command_exists ntpq; }

# --- Show current time and timezone status ---
time_show_status() {
    header "Current Time & Timezone"
    if has_timedatectl; then
        timedatectl status
    else
        date
        local tz
        tz=$(cat /etc/timezone 2>/dev/null || readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')
        echo "Timezone: ${tz:-unknown}"
    fi
    press_enter
}

# --- List timezones with optional filter ---
time_list_timezones() {
    header "List Timezones"
    local filter
    read -r -p "Filter keyword (leave blank for all): " filter

    if has_timedatectl; then
        if [[ -n "$filter" ]]; then
            timedatectl list-timezones | grep -i -- "$filter"
        else
            timedatectl list-timezones
        fi
    else
        if [[ -n "$filter" ]]; then
            find /usr/share/zoneinfo -type f \
                | sed 's|.*/zoneinfo/||' \
                | grep -i -- "$filter" \
                | sort
        else
            find /usr/share/zoneinfo -type f \
                | sed 's|.*/zoneinfo/||' \
                | sort
        fi
    fi
    press_enter
}

# --- Set timezone ---
time_set_timezone() {
    header "Change Timezone"
    local tz
    read -r -p "Enter timezone (e.g. Asia/Ho_Chi_Minh): " tz

    if [[ -z "$tz" ]]; then
        warn "No timezone entered. Aborting."
        press_enter
        return
    fi

    if [[ ! -f "/usr/share/zoneinfo/$tz" ]]; then
        warn "Invalid timezone: $tz"
        info "Use option 5 to list valid timezones."
        press_enter
        return
    fi

    confirm "Set timezone to $tz?" || { info "Cancelled."; press_enter; return; }

    if has_timedatectl; then
        sudo timedatectl set-timezone "$tz"
    else
        sudo ln -sf "/usr/share/zoneinfo/$tz" /etc/localtime
        echo "$tz" | sudo tee /etc/timezone > /dev/null
    fi

    success "Timezone set to $tz"
    echo "Current time: $(date)"
    press_enter
}

# --- Enable NTP synchronization ---
time_enable_ntp() {
    header "Enable NTP Sync"

    if has_timedatectl; then
        sudo timedatectl set-ntp true
        success "NTP enabled via timedatectl"
        timedatectl show --property=NTP 2>/dev/null || timedatectl status
    elif has_chrony; then
        sudo systemctl enable --now chronyd
        success "chronyd enabled and started"
    elif has_ntpd; then
        sudo systemctl enable --now ntp
        success "ntpd enabled and started"
    else
        warn "No NTP daemon found. Install chrony or ntp."
    fi
    press_enter
}

# --- Check NTP sync status ---
time_check_ntp_status() {
    header "NTP Sync Status"

    if has_timedatectl; then
        timedatectl timesync-status 2>/dev/null || timedatectl status
    elif has_chrony; then
        chronyc tracking
    elif has_ntpd; then
        ntpq -p 2>/dev/null || warn "ntpq returned an error."
    else
        warn "No NTP daemon found. Cannot check sync status."
    fi
    press_enter
}

# --- Time management submenu ---
time_menu() {
    local choice
    while true; do
        header "Time Management"
        PS3=$'\nSelect option: '
        select choice in \
            "Show current time & timezone" \
            "Change timezone" \
            "Enable NTP sync" \
            "Check NTP sync status" \
            "List timezones" \
            "Back"; do
            case "$REPLY" in
                1) time_show_status ;;
                2) time_set_timezone ;;
                3) time_enable_ntp ;;
                4) time_check_ntp_status ;;
                5) time_list_timezones ;;
                6) break 2 ;;
                *) warn "Invalid selection: $REPLY" ;;
            esac
            break
        done
    done
}
