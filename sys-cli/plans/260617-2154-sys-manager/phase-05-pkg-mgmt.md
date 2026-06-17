# Phase 05: Package Management

**Priority:** Medium
**Status:** Complete
**Blocks:** None | **Blocked by:** Phase 01

## Overview

Implement `lib/pkg-mgmt.sh` covering US4.1, US4.2, US4.3.

## Files to Create

- `lib/pkg-mgmt.sh`

## User Stories

- **US4.1:** Install packages automatically (e.g. git, curl, nginx)
- **US4.2:** Purge a package and autoremove orphaned libraries
- **US4.3:** Full system update (update index + upgrade all packages)

## Implementation Steps

1. `pkg_menu()` — `select` submenu:
   - Install package(s)
   - Remove / purge package
   - Update system (update + upgrade)
   - Autoremove orphaned packages
   - Back

2. `detect_pkg_manager()`:
   - Check in order: `apt-get` → `dnf` → `yum` → `pacman`
   - Echo detected name or `die "Unsupported package manager" $E_PKGMGR`

3. `pkg_install()`:
   - Prompt: "Enter package name(s) to install (space-separated):"
   - Read into array: `read -ra pkgs`
   - `confirm "Install: ${pkgs[*]}?"` → proceed
   - Dispatch by `detect_pkg_manager`:
     - apt: `sudo apt-get update && sudo apt-get install -y "${pkgs[@]}"`
     - dnf: `sudo dnf install -y "${pkgs[@]}"`
     - yum: `sudo yum install -y "${pkgs[@]}"`
     - pacman: `sudo pacman -Sy --noconfirm "${pkgs[@]}"`

4. `pkg_remove()`:
   - Prompt for package name
   - Ask: "Purge config files too? [y/N]"
   - apt purge: `sudo apt-get purge -y "$pkg" && sudo apt-get autoremove -y`
   - dnf/yum remove: `sudo dnf remove -y "$pkg" && sudo dnf autoremove -y`
   - pacman: `sudo pacman -Rns --noconfirm "$pkg"`
   - All paths require `confirm()` first

5. `pkg_update_system()`:
   - `confirm "Update entire system?"` → proceed
   - apt: `sudo apt-get update && sudo apt-get upgrade -y`
   - dnf: `sudo dnf upgrade -y`
   - yum: `sudo yum update -y`
   - pacman: `sudo pacman -Syu --noconfirm`
   - Print elapsed time after completion

6. `pkg_autoremove()`:
   - apt: `sudo apt-get autoremove -y`
   - dnf: `sudo dnf autoremove -y`
   - yum: `sudo yum autoremove -y`
   - pacman: orphan check first:
     ```bash
     orphans=$(pacman -Qdtq 2>/dev/null)
     [[ -z "$orphans" ]] && info "No orphans found." && return 0
     echo "$orphans"
     confirm "Remove orphaned packages?" && sudo pacman -Rns --noconfirm $orphans
     ```

## Success Criteria

- `shellcheck lib/pkg-mgmt.sh` clean
- `detect_pkg_manager` returns correct value on apt/dnf/yum/pacman systems
- All operations require `confirm()` before running with sudo
- Pacman orphan removal handles empty orphan list gracefully
- File under 200 lines
