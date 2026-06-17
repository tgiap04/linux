# Phase 01: Common Utilities + Entry Point

**Priority:** Critical (blocks all other phases)
**Status:** Complete

## Overview

Create `lib/common.sh` (shared utilities) and `sys-cli.sh` (entry point + main menu).

## Files to Create

- `sys-cli.sh` — entry point, sources modules, renders main menu
- `lib/common.sh` — shared helpers, color vars, error handling

## Implementation Steps

1. Create `lib/common.sh`:
   - Color vars: `RED`, `GREEN`, `YELLOW`, `BLUE`, `NC`
   - `die(msg)` — print error to stderr, exit 1
   - `info(msg)` — print green info
   - `warn(msg)` — print yellow warning
   - `confirm(msg)` — `read -r -p "$1 [y/N]: "`, return 0 if "y"
   - `command_exists(cmd)` — `command -v "$1" &>/dev/null`
   - `require_root()` — check `$EUID -eq 0` or die
   - `print_header(title)` — clear + styled banner
   - Exit code constants: `E_BADARGS=64`, `E_NOPERM=65`, `E_NOEXIST=66`, `E_PKGMGR=67`, `E_CANCELLED=68`
   - `trap cleanup EXIT INT TERM`

2. Create `sys-cli.sh`:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - `SCRIPT_DIR` detection via `${BASH_SOURCE[0]}`
   - Source all `lib/*.sh` modules
   - `main_menu()` using `select` with 5 options
   - `--help` / `-h` flag handling
   - Version string: `SYS_CLI_VERSION="1.0.0"`

## Success Criteria

- `bash sys-cli.sh --help` prints usage without errors
- `bash sys-cli.sh` shows interactive main menu
- All `source` statements resolve correctly
- `shellcheck sys-cli.sh lib/common.sh` passes with no errors
