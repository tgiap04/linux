#!/usr/bin/env bash
# Shared utilities: colors, output helpers, guards, exit codes

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Exit codes (sysexits.h range 64-113) ---
readonly E_BADARGS=64
readonly E_NOPERM=65
readonly E_NOEXIST=66
readonly E_PKGMGR=67
readonly E_CANCELLED=68

# --- Output helpers ---
die()     { local msg="$1" code="${2:-1}"; echo -e "${RED}${BOLD}ERROR:${NC} $msg" >&2; exit "$code"; }
info()    { echo -e "${GREEN}INFO:${NC} $*"; }
warn()    { echo -e "${YELLOW}WARN:${NC} $*"; }
header()  { echo -e "\n${BLUE}${BOLD}=== $* ===${NC}\n"; }
success() { echo -e "${GREEN}${BOLD}✓${NC} $*"; }

# --- User interaction ---
confirm() {
    local msg="${1:-Are you sure?}"
    local reply
    read -r -p "$(echo -e "${YELLOW}?${NC} $msg [y/N]: ")" reply
    [[ ${reply,,} == "y" ]]
}

press_enter() {
    read -r -p $'\nPress Enter to continue...'
}

# --- Privilege check ---
require_root() {
    [[ $EUID -eq 0 ]] || die "This operation requires root. Run with sudo."
}

# --- Command existence check ---
command_exists() {
    command -v "$1" &>/dev/null
}

# --- Cleanup trap (set in entry point) ---
_TMPFILES=()
register_tmp() { _TMPFILES+=("$1"); }

cleanup() {
    local exit_code=$?
    for f in "${_TMPFILES[@]}"; do
        rm -f -- "$f"
    done
    exit "$exit_code"
}
