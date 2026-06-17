#!/usr/bin/env bash
# lib/cron-mgmt.sh — Cron job management helpers (sourced, not executed directly)

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Add an entry idempotently
_cron_add_idempotent() {
    local entry="$1"
    if crontab -l 2>/dev/null | grep -qF "$entry"; then
        warn "Cron entry already exists — skipping."
        return 0
    fi
    ( crontab -l 2>/dev/null; echo "$entry" ) | crontab -
    success "Cron job added."
}

# Return the count of non-comment cron lines
_cron_count() {
    crontab -l 2>/dev/null | grep -cv '^#' || true
}

# ---------------------------------------------------------------------------
# Public functions
# ---------------------------------------------------------------------------

cron_list() {
    header "Current Cron Jobs"
    local output
    output=$(crontab -l 2>/dev/null | grep -v '^#')
    if [[ -z "$output" ]]; then
        info "No cron jobs found."
        return 0
    fi
    echo "$output" | nl -ba
}

cron_add_guided() {
    header "Add Cron Job (Guided)"

    local min hour day month wday cmd

    read -r -p "Minute   [default *]: " min;   min="${min:-*}"
    read -r -p "Hour     [default *]: " hour;  hour="${hour:-*}"
    read -r -p "Day      [default *]: " day;   day="${day:-*}"
    read -r -p "Month    [default *]: " month; month="${month:-*}"
    read -r -p "Weekday  [default *]: " wday;  wday="${wday:-*}"
    read -r -p "Command to run: " cmd

    if [[ -z "$cmd" ]]; then
        warn "No command entered — aborting."
        return 1
    fi

    local entry="$min $hour $day $month $wday $cmd"
    echo
    info "Cron entry preview:"
    echo "  $entry"
    echo

    confirm "Add this cron job?" || { info "Cancelled."; return 0; }
    _cron_add_idempotent "$entry"
}

cron_delete() {
    header "Delete Cron Job"

    local count
    count=$(_cron_count)
    if [[ "$count" -eq 0 ]]; then
        info "No cron jobs to delete."
        return 0
    fi

    cron_list
    echo

    local n
    read -r -p "Enter line number to delete: " n
    if ! [[ "$n" =~ ^[0-9]+$ ]]; then
        warn "Invalid input — aborting."
        return 1
    fi

    # Snapshot once — avoids race window and handles duplicate lines correctly
    local snapshot
    snapshot=$(crontab -l 2>/dev/null)

    local target_line
    target_line=$(echo "$snapshot" | grep -v '^#' | sed -n "${n}p")
    if [[ -z "$target_line" ]]; then
        warn "Line $n not found — aborting."
        return 1
    fi

    echo
    info "Line to delete:"
    echo "  $target_line"
    echo

    confirm "Delete this cron job?" || { info "Cancelled."; return 0; }

    # Delete by line number (not content) to handle duplicate entries correctly
    echo "$snapshot" | awk -v skip="$n" 'NR != skip' | crontab -
    success "Cron job removed."
}

cron_setup_backup() {
    header "Setup Daily Backup"

    local src dest schedule

    read -r -p "Source directory to backup: " src
    if [[ -z "$src" ]]; then
        warn "No source directory entered — aborting."
        return 1
    fi

    read -r -p "Backup destination directory: " dest
    if [[ -z "$dest" ]]; then
        warn "No destination directory entered — aborting."
        return 1
    fi

    read -r -p "Cron schedule [default '0 0 * * *' = daily midnight]: " schedule
    schedule="${schedule:-0 0 * * *}"

    local cmd="tar -czf \"${dest}/backup-\$(date +\\%Y\\%m\\%d).tar.gz\" \"${src}\" >> /var/log/sys-cli-backup.log 2>&1"
    local entry="${schedule} ${cmd}"

    echo
    info "Full cron entry preview:"
    echo "  $entry"
    echo

    confirm "Schedule this backup job?" || { info "Cancelled."; return 0; }
    _cron_add_idempotent "$entry"
}

cron_menu() {
    while true; do
        header "Cron Job Management"
        select choice in \
            "Add cron job (guided)" \
            "List cron jobs" \
            "Delete a cron job" \
            "Setup daily backup" \
            "Back"; do
            case "$REPLY" in
                1) cron_add_guided;   press_enter; break ;;
                2) cron_list;         press_enter; break ;;
                3) cron_delete;       press_enter; break ;;
                4) cron_setup_backup; press_enter; break ;;
                5) return 0 ;;
                *) warn "Invalid choice." ; break ;;
            esac
        done
    done
}
