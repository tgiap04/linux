# Phase 02: File & Directory Management

**Priority:** High
**Status:** Complete
**Blocks:** None | **Blocked by:** Phase 01

## Overview

Implement `lib/file-mgmt.sh` covering US1.1, US1.2, US1.3.

## Files to Create

- `lib/file-mgmt.sh`

## User Stories

- **US1.1:** Batch create/delete/move files & directories
- **US1.2:** Find files larger than threshold → compress or delete
- **US1.3:** Batch chmod/chown on a directory tree

## Implementation Steps

1. `file_menu()` — `select` submenu with options:
   - Batch create files/dirs
   - Batch delete files/dirs
   - Move files/dirs
   - Find & manage large files
   - Set permissions (chmod/chown)
   - Back

2. `batch_create()`:
   - Prompt for target dir, prefix, count
   - `mkdir -p` or `touch` in loop
   - Print summary

3. `batch_delete()`:
   - Prompt for pattern (glob) and base dir
   - `find "$dir" -name "$pattern" -print` to preview
   - `confirm()` gate → `find ... -delete`
   - Guard: `[[ -z "$dir" ]]` check before any rm

4. `batch_move()`:
   - Prompt for source pattern, source dir, destination dir
   - `find "$src" -name "$pattern" -print0 | xargs -0 mv -t "$dest"`
   - Confirm before execution

5. `find_large_files()`:
   - Prompt for dir and size threshold (default 100M)
   - `find "$dir" -type f -size "+${threshold}" -printf '%s\t%p\n' | sort -rn | head -20`
   - Submenu: compress selected (gzip), delete selected, or just view
   - Compress: `gzip -9 -- "$file"`

6. `set_permissions()`:
   - Prompt for target dir, owner (user:group), file mode, dir mode
   - Preview affected count first
   - `confirm()` → `sudo find ... -type d -exec chmod "$dmode" {} \;`
   - `sudo find ... -type f -exec chmod "$fmode" {} \;`
   - `sudo chown -R "$owner" "$dir"`
   - Use `sudo tee` pattern for any file writes

## Success Criteria

- All 5 operations complete without unquoted variable warnings
- `shellcheck lib/file-mgmt.sh` clean
- Destructive ops (delete, chmod) require confirm() before execution
- File under 200 lines
