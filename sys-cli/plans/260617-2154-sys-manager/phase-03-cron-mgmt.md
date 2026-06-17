# Phase 03: Cron Job Management

**Priority:** High
**Status:** Complete
**Blocks:** None | **Blocked by:** Phase 01

## Overview

Implement `lib/cron-mgmt.sh` covering US2.1, US2.2, US2.3.

## Files to Create

- `lib/cron-mgmt.sh`

## User Stories

- **US2.1:** Menu to add new cron job (guided, no syntax memorization)
- **US2.2:** List and delete existing cron jobs
- **US2.3:** Schedule daily midnight backup for a directory

## Implementation Steps

1. `cron_menu()` — `select` submenu:
   - Add new cron job (guided)
   - List cron jobs
   - Delete a cron job
   - Setup daily backup
   - Back

2. `cron_add_guided()`:
   - Prompt user for: minute, hour, day, month, weekday (each with default "*")
   - Prompt for command to run
   - Assemble: `entry="$min $hour $day $month $wday $cmd"`
   - Preview assembled entry, `confirm()` before adding
   - Idempotency check: `crontab -l 2>/dev/null | grep -qF "$entry"` → skip if exists
   - Add: `( crontab -l 2>/dev/null; echo "$entry" ) | crontab -`

3. `cron_list()`:
   - `crontab -l 2>/dev/null | grep -v '^#' | nl -ba`
   - If empty, print info "No cron jobs found"

4. `cron_delete()`:
   - Call `cron_list()` to show numbered jobs
   - Prompt for line number to delete
   - Extract matching line: `crontab -l 2>/dev/null | sed -n "${n}p"`
   - Preview the line, `confirm()` before deletion
   - Delete: `crontab -l 2>/dev/null | grep -vF "$target_line" | crontab -`

5. `cron_setup_backup()`:
   - Prompt for source directory to backup
   - Prompt for backup destination directory
   - Prompt for time (default: 00:00 midnight → `0 0 * * *`)
   - Generate backup command:
     `tar -czf "$dest/backup-$(date +\%Y\%m\%d).tar.gz" "$src" >> /var/log/sys-cli-backup.log 2>&1`
   - Preview full cron entry, `confirm()` → `add_cron_idempotent`

## Safety Rules

- Always `2>/dev/null` on `crontab -l`
- Use `grep -vF` (fixed-string) for deletion
- Never write directly to `/var/spool/cron/`
- Guard empty crontab: check return from `crontab -l` before piping

## Success Criteria

- `shellcheck lib/cron-mgmt.sh` clean
- Add/delete round-trip works correctly
- Duplicate entries not created (idempotency check)
- File under 200 lines
