# Phase 04: System Time Management

**Priority:** Medium
**Status:** Complete
**Blocks:** None | **Blocked by:** Phase 01

## Overview

Implement `lib/time-mgmt.sh` covering US3.1, US3.2, US3.3.

## Files to Create

- `lib/time-mgmt.sh`

## User Stories

- **US3.1:** View current time and timezone
- **US3.2:** Change timezone (e.g. Asia/Ho_Chi_Minh)
- **US3.3:** Enable NTP/chrony time synchronization

## Implementation Steps

1. `time_menu()` — `select` submenu:
   - Show current time & timezone
   - Change timezone
   - Enable NTP sync
   - Check NTP sync status
   - Back

2. `time_show_status()`:
   - If `timedatectl` available: `timedatectl status`
   - Fallback: `date` + `cat /etc/timezone 2>/dev/null || readlink /etc/localtime`

3. `time_set_timezone()`:
   - Prompt for timezone string (default suggestion: Asia/Ho_Chi_Minh)
   - Validate: `[[ -f "/usr/share/zoneinfo/$tz" ]]` or die
   - If `timedatectl` available: `sudo timedatectl set-timezone "$tz"`
   - Fallback: `sudo ln -sf "/usr/share/zoneinfo/$tz" /etc/localtime`
     + `echo "$tz" | sudo tee /etc/timezone > /dev/null`
   - Print confirmation with new time

4. `time_list_timezones()`:
   - Helper: list timezones filtered by optional keyword
   - If `timedatectl`: `timedatectl list-timezones | grep -i "$filter"`
   - Fallback: `find /usr/share/zoneinfo -type f | sed 's|.*/zoneinfo/||' | grep -i "$filter"`

5. `time_enable_ntp()`:
   - If `timedatectl`: `sudo timedatectl set-ntp true` → confirm with `timedatectl show --property=NTP`
   - Elif `chronyc` available: `sudo systemctl enable --now chronyd`
   - Elif `ntpd` available: `sudo systemctl enable --now ntp`
   - Else: `warn "No NTP daemon found. Install chrony or ntp."`

6. `time_check_ntp_status()`:
   - If `timedatectl`: `timedatectl timesync-status 2>/dev/null || timedatectl status`
   - If `chronyc`: `chronyc tracking`
   - Fallback: `ntpq -p 2>/dev/null` or warn not available

## Detection Helpers

```bash
has_timedatectl() { command_exists timedatectl; }
has_chrony()      { command_exists chronyc; }
has_ntpd()        { command_exists ntpq; }
```

## Success Criteria

- `shellcheck lib/time-mgmt.sh` clean
- Works on systemd distros (timedatectl path)
- Falls back gracefully without timedatectl
- Timezone validation prevents invalid tz strings
- File under 200 lines
