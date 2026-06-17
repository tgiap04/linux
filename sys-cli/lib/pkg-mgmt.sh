#!/usr/bin/env bash
# Package management helpers: install, remove, update, autoremove
# Sourced by main entry point — do NOT add set -euo pipefail here

# ---------------------------------------------------------------------------
# detect_pkg_manager — echo the first supported package manager found, or die
# ---------------------------------------------------------------------------
detect_pkg_manager() {
    if   command_exists apt-get; then echo "apt"
    elif command_exists dnf;     then echo "dnf"
    elif command_exists yum;     then echo "yum"
    elif command_exists pacman;  then echo "pacman"
    else die "No supported package manager found (apt-get/dnf/yum/pacman)" "$E_PKGMGR"
    fi
}

# ---------------------------------------------------------------------------
# pkg_install — prompt for packages, confirm, then install
# ---------------------------------------------------------------------------
pkg_install() {
    header "Install Package(s)"
    local input pkgs pm

    read -r -p "Enter package name(s) to install (space-separated): " input
    [[ -z "$input" ]] && warn "No packages entered." && return 0

    read -ra pkgs <<< "$input"
    pm=$(detect_pkg_manager)

    info "Packages to install: ${pkgs[*]}"
    confirm "Install ${#pkgs[@]} package(s) via $pm?" || { warn "Installation cancelled."; return 0; }

    case "$pm" in
        apt)    sudo apt-get update && sudo apt-get install -y "${pkgs[@]}" ;;
        dnf)    sudo dnf install -y "${pkgs[@]}" ;;
        yum)    sudo yum install -y "${pkgs[@]}" ;;
        pacman) sudo pacman -Sy --noconfirm "${pkgs[@]}" ;;
    esac && success "Package(s) installed successfully."
    press_enter
}

# ---------------------------------------------------------------------------
# pkg_remove — prompt for package, optionally purge, then remove
# ---------------------------------------------------------------------------
pkg_remove() {
    header "Remove / Purge Package"
    local pkg purge pm

    read -r -p "Enter package name to remove: " pkg
    [[ -z "$pkg" ]] && die "Package name cannot be empty"

    pm=$(detect_pkg_manager)

    local purge_reply
    read -r -p "$(echo -e "${YELLOW}?${NC} Purge config files too? [y/N]: ")" purge_reply
    purge=false
    [[ ${purge_reply,,} == "y" ]] && purge=true

    confirm "Remove package '$pkg' (purge=$purge) via $pm?" || { warn "Removal cancelled."; return 0; }

    case "$pm" in
        apt)
            if $purge; then
                sudo apt-get purge -y "$pkg" && sudo apt-get autoremove -y
            else
                sudo apt-get remove -y "$pkg" && sudo apt-get autoremove -y
            fi
            ;;
        dnf)  sudo dnf remove -y "$pkg" && sudo dnf autoremove -y ;;
        yum)  sudo yum remove -y "$pkg" && sudo yum autoremove -y ;;
        pacman) sudo pacman -Rns --noconfirm "$pkg" ;;
    esac && success "Package '$pkg' removed."
    press_enter
}

# ---------------------------------------------------------------------------
# pkg_update_system — full system update; prints elapsed time
# ---------------------------------------------------------------------------
pkg_update_system() {
    header "Update System"
    local pm

    pm=$(detect_pkg_manager)
    confirm "Update entire system via $pm?" || { warn "Update cancelled."; return 0; }

    local start=$SECONDS

    case "$pm" in
        apt)    sudo apt-get update && sudo apt-get upgrade -y ;;
        dnf)    sudo dnf upgrade -y ;;
        yum)    sudo yum update -y ;;
        pacman) sudo pacman -Syu --noconfirm ;;
    esac

    local elapsed=$(( SECONDS - start ))
    success "System update complete. Elapsed: ${elapsed}s"
    press_enter
}

# ---------------------------------------------------------------------------
# pkg_autoremove — remove orphaned/unused packages
# ---------------------------------------------------------------------------
pkg_autoremove() {
    header "Autoremove Orphaned Packages"
    local pm
    pm=$(detect_pkg_manager)

    if [[ "$pm" == "pacman" ]]; then
        local orphans
        orphans=$(pacman -Qdtq 2>/dev/null)
        if [[ -z "$orphans" ]]; then
            info "No orphans found."
            press_enter
            return 0
        fi
        info "Orphaned packages:"
        echo "$orphans"
        confirm "Remove these orphaned packages?" || { warn "Autoremove cancelled."; return 0; }
        # word-split intentional: orphans is a newline-separated list of package names
        # shellcheck disable=SC2086
        sudo pacman -Rns --noconfirm $orphans
    else
        confirm "Remove orphaned packages via $pm?" || { warn "Autoremove cancelled."; return 0; }
        case "$pm" in
            apt) sudo apt-get autoremove -y ;;
            dnf) sudo dnf autoremove -y ;;
            yum) sudo yum autoremove -y ;;
        esac
    fi && success "Orphaned packages removed."
    press_enter
}

# ---------------------------------------------------------------------------
# pkg_menu — interactive submenu
# ---------------------------------------------------------------------------
pkg_menu() {
    local choice
    while true; do
        header "Package Management"
        PS3=$'\nChoose an option: '
        select choice in \
            "Install package(s)" \
            "Remove / purge package" \
            "Update system" \
            "Autoremove orphaned packages" \
            "Back"
        do
            case "$REPLY" in
                1) pkg_install         ; break ;;
                2) pkg_remove          ; break ;;
                3) pkg_update_system   ; break ;;
                4) pkg_autoremove      ; break ;;
                5) return 0            ;;
                *) warn "Invalid option '$REPLY'" ; break ;;
            esac
        done
    done
}
