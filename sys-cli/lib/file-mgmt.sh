#!/usr/bin/env bash
# lib/file-mgmt.sh — File & directory management operations
# Sourced by entry point; do NOT set -euo pipefail here.

# Interactive submenu for all file operations
file_menu() {
    local options=("Batch create" "Batch delete" "Move files" \
                   "Find & manage large files" "Set permissions" "Back")
    while true; do
        header "File & Directory Management"
        select choice in "${options[@]}"; do
            case "$REPLY" in
                1) batch_create;       break ;;
                2) batch_delete;       break ;;
                3) batch_move;         break ;;
                4) find_large_files;   break ;;
                5) set_permissions;    break ;;
                6) return 0 ;;
                *) warn "Invalid selection." ; break ;;
            esac
        done
    done
}

# Create N files or directories under a target directory
batch_create() {
    header "Batch Create"

    local dir prefix count kind
    read -r -p "Target directory: " dir
    [[ -z "$dir" ]] && die "Directory cannot be empty"

    read -r -p "Prefix (e.g. 'file', 'dir'): " prefix
    [[ -z "$prefix" ]] && die "Prefix cannot be empty"

    read -r -p "How many to create? " count
    [[ "$count" =~ ^[0-9]+$ ]] || die "Count must be a positive integer"

    read -r -p "Create (f)iles or (d)irectories? [f/d]: " kind

    mkdir -p -- "$dir" || die "Cannot create or access directory: $dir"

    local created=0
    for i in $(seq 1 "$count"); do
        local target="${dir}/${prefix}-${i}"
        if [[ "${kind,,}" == "d" ]]; then
            mkdir -p -- "$target" && (( created++ ))
        else
            touch -- "$target" && (( created++ ))
        fi
    done

    success "Created $created item(s) in '$dir'"
    press_enter
}

# Preview then confirm-gate deletion of files matching a glob pattern
batch_delete() {
    header "Batch Delete"

    local dir pattern
    read -r -p "Base directory: " dir
    [[ -z "$dir" ]] && die "Directory cannot be empty"
    [[ -d "$dir" ]] || die "Directory does not exist: $dir"

    read -r -p "Glob pattern (e.g. '*.tmp'): " pattern
    [[ -z "$pattern" ]] && die "Pattern cannot be empty"

    info "Files matching '$pattern' in '$dir':"
    find "$dir" -name "$pattern" -print   # preview before confirm

    local match_count
    match_count=$(find "$dir" -name "$pattern" | wc -l)
    echo ""
    warn "Found $match_count match(es). This action is irreversible."

    confirm "Delete all $match_count matching files?" || { info "Cancelled."; return 0; }

    # -print0 | xargs -0 handles filenames with spaces safely
    find "$dir" -name "$pattern" -print0 | xargs -0 rm -f --
    success "Deleted $match_count file(s) matching '$pattern'"
    press_enter
}

# Move files matching a glob pattern from source dir to destination dir
batch_move() {
    header "Batch Move"

    local src pattern dest
    read -r -p "Source directory: " src
    [[ -z "$src" ]] && die "Source directory cannot be empty"
    [[ -d "$src" ]] || die "Source directory does not exist: $src"

    read -r -p "Glob pattern (e.g. '*.log'): " pattern
    [[ -z "$pattern" ]] && die "Pattern cannot be empty"

    read -r -p "Destination directory: " dest
    [[ -z "$dest" ]] && die "Destination directory cannot be empty"

    mkdir -p -- "$dest" || die "Cannot create destination: $dest"

    local match_count
    match_count=$(find "$src" -name "$pattern" | wc -l)
    info "Moving $match_count file(s) matching '$pattern' → '$dest'"

    confirm "Proceed with move?" || { info "Cancelled."; return 0; }
    find "$src" -name "$pattern" -print0 | xargs -0 mv -t "$dest" --
    success "Moved $match_count file(s) to '$dest'"
    press_enter
}

# Locate oversized files, then offer compress, delete, or view actions
find_large_files() {
    header "Find Large Files"

    local dir threshold
    read -r -p "Search directory: " dir
    [[ -z "$dir" ]] && die "Directory cannot be empty"
    [[ -d "$dir" ]] || die "Directory does not exist: $dir"

    read -r -p "Size threshold (default: 100M): " threshold
    threshold="${threshold:-100M}"

    info "Top 20 files larger than $threshold in '$dir':"
    # -printf '%s\t%p\n' emits bytes+path; sort -rn ranks largest first
    find "$dir" -type f -size "+${threshold}" -printf '%s\t%p\n' | sort -rn | head -20

    echo ""
    local action_options=("Compress a file (gzip -9)" "Delete a file" "Done / back")
    select action in "${action_options[@]}"; do
        case "$REPLY" in
            1)  # Compress
                local target_file
                read -r -p "Enter full path to compress: " target_file
                [[ -z "$target_file" ]] && { warn "No path entered."; break; }
                [[ -f "$target_file" ]] || { warn "File not found: $target_file"; break; }
                confirm "Compress '$target_file' with gzip -9?" || break
                gzip -9 -- "$target_file" && success "Compressed: ${target_file}.gz"
                break ;;
            2)  # Delete
                local del_file
                read -r -p "Enter full path to delete: " del_file
                [[ -z "$del_file" ]] && { warn "No path entered."; break; }
                [[ -f "$del_file" ]] || { warn "File not found: $del_file"; break; }
                confirm "Permanently delete '$del_file'?" || break
                rm -f -- "$del_file" && success "Deleted: $del_file"
                break ;;
            3) return 0 ;;
            *) warn "Invalid selection." ; break ;;
        esac
    done
    press_enter
}

# Batch chmod + chown across a directory tree
set_permissions() {
    header "Set Permissions"

    local dir owner fmode dmode
    read -r -p "Target directory: " dir
    [[ -z "$dir" ]] && die "Directory cannot be empty"
    [[ -d "$dir" ]] || die "Directory does not exist: $dir"

    read -r -p "Owner (user:group, leave blank to skip): " owner
    read -r -p "File mode (e.g. 644, blank to skip): " fmode
    read -r -p "Directory mode (e.g. 755, blank to skip): " dmode

    # Validate octal format before applying to prevent silent failures
    [[ -n "$fmode" && ! "$fmode" =~ ^[0-7]{3,4}$ ]] && die "Invalid file mode '$fmode' — use octal (e.g. 644)"
    [[ -n "$dmode" && ! "$dmode" =~ ^[0-7]{3,4}$ ]] && die "Invalid dir mode '$dmode' — use octal (e.g. 755)"

    # Require at least one operation
    [[ -z "$owner" && -z "$fmode" && -z "$dmode" ]] \
        && die "Specify at least one of: owner, file mode, or directory mode"

    # Preview: count affected items
    local file_count dir_count
    file_count=$(find "$dir" -type f | wc -l)
    dir_count=$(find "$dir" -type d | wc -l)
    info "Affected: $file_count file(s), $dir_count director(ies) under '$dir'"
    [[ -n "$fmode" ]]  && info "  File mode  → $fmode"
    [[ -n "$dmode" ]]  && info "  Dir mode   → $dmode"
    [[ -n "$owner" ]]  && info "  Ownership  → $owner"

    confirm "Apply permissions?" || { info "Cancelled."; return 0; }

    [[ -n "$dmode" ]] && { sudo find "$dir" -type d -exec chmod "$dmode" {} \; && success "Dir mode → $dmode"; }
    [[ -n "$fmode" ]] && { sudo find "$dir" -type f -exec chmod "$fmode" {} \; && success "File mode → $fmode"; }
    [[ -n "$owner" ]] && { sudo chown -R "$owner" -- "$dir" && success "Ownership → $owner"; }

    press_enter
}
