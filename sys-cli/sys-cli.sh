#!/usr/bin/env bash
# sys-cli.sh — Linux System Management Tool entry point
set -euo pipefail

readonly SYS_CLI_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Source modules ---
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/file-mgmt.sh"
source "$SCRIPT_DIR/lib/cron-mgmt.sh"
source "$SCRIPT_DIR/lib/time-mgmt.sh"
source "$SCRIPT_DIR/lib/pkg-mgmt.sh"
source "$SCRIPT_DIR/lib/process-mgmt.sh"
source "$SCRIPT_DIR/lib/network-mgmt.sh"
source "$SCRIPT_DIR/lib/firewall-mgmt.sh"

trap cleanup EXIT INT TERM

# --- Usage ---
usage() {
    cat <<EOF
sys-cli v${SYS_CLI_VERSION} — Linux System Management Tool

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help      Show this help message
  -v, --version   Show version

Modules:
  1) File & Directory Management
  2) Cron Job Scheduling
  3) System Time Management
  4) Package Management
  5) Process Management
  6) Network & Socket Management
  7) Kernel Firewall
EOF
}

# --- Main menu ---
main_menu() {
    while true; do
        clear
        echo -e "${BLUE}${BOLD}"
        cat <<'BANNER'
  ███████╗██╗   ██╗███████╗      ██████╗██╗     ██╗
  ██╔════╝╚██╗ ██╔╝██╔════╝     ██╔════╝██║     ██║
  ███████╗ ╚████╔╝ ███████╗     ██║     ██║     ██║
  ╚════██║  ╚██╔╝  ╚════██║     ██║     ██║     ██║
  ███████║   ██║   ███████║     ╚██████╗███████╗██║
  ╚══════╝   ╚═╝   ╚══════╝      ╚═════╝╚══════╝╚═╝
BANNER
        echo -e "${NC}"
        echo -e "  ${CYAN}Linux System Management Tool${NC} ${BOLD}v${SYS_CLI_VERSION}${NC}\n"

        local options=(
            "File & Directory Management"
            "Cron Job Scheduling"
            "System Time Management"
            "Package Management"
            "Process Management"
            "Network & Socket Management"
            "Kernel Firewall"
            "Quit"
        )

        PS3=$'\n'"$(echo -e "${BOLD}Choose a module [1-8]:${NC} ")"
        select opt in "${options[@]}"; do
            case $opt in
                "File & Directory Management") file_menu;     break ;;
                "Cron Job Scheduling")         cron_menu;     break ;;
                "System Time Management")      time_menu;     break ;;
                "Package Management")          pkg_menu;      break ;;
                "Process Management")          process_menu;  break ;;
                "Network & Socket Management") network_menu;  break ;;
                "Kernel Firewall")             firewall_menu; break ;;
                "Quit")                        echo -e "\n${GREEN}Goodbye!${NC}"; exit 0 ;;
                *) warn "Invalid option: $REPLY" ;;
            esac
        done
    done
}

# --- Argument parsing ---
case "${1:-}" in
    -h|--help)    usage;   exit 0 ;;
    -v|--version) echo "sys-cli v${SYS_CLI_VERSION}"; exit 0 ;;
    "")           main_menu ;;
    *)            die "Unknown option: $1. Use --help for usage." ;;
esac
