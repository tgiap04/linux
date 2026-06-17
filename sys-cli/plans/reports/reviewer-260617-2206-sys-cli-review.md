# sys-cli Code Review Report
**Date:** 2026-06-17  
**Reviewer:** Staff Engineer (reviewer agent)  
**Scope:** All 8 source files — sys-cli.sh + lib/*.sh (1177 total LOC)

---

## Summary

Overall quality: **7.5 / 10**  
The codebase is well-structured, follows bash best practices (quoting, `--` guards, `command_exists` checks, no `set -euo pipefail` in sourced files), and every destructive operation is behind `confirm()`. Three issues need attention before shipping: a shell injection vector, a `die()` API contract violation, and a cron duplicate-line hazard.

---

## Critical Issues

### 1. Shell injection in `network_test_connectivity` — `bash -c ">/dev/tcp/$host/$port"` (network-mgmt.sh:112)

**Severity: Critical**

The fallback TCP probe expands `$host` inside a double-quoted `bash -c` string, making it a live shell injection vector:

```bash
bash -c ">/dev/tcp/$host/$port" 2>/dev/null && tcp_ok=true
```

A user who enters `x$(rm -rf ~)` as the host value causes `rm -rf ~` to execute as the current user. Since this function runs without root, data loss (not privilege escalation) is the risk, but it is real.

**Fix:** Use the Bash built-in `/dev/tcp` without `bash -c`:

```bash
(: > /dev/tcp/"$host"/"$port") 2>/dev/null && tcp_ok=true
```

Or redirect in a subshell where word splitting doesn't apply:

```bash
( exec 3>/dev/tcp/"$host"/"$port" ) 2>/dev/null && tcp_ok=true
```

Both avoid the `bash -c` string interpolation entirely.

---

### 2. `die()` silently ignores the exit-code argument — `pkg-mgmt.sh:13`

**Severity: Critical (API contract violation)**

```bash
# common.sh
die() { echo -e "${RED}${BOLD}ERROR:${NC} $*" >&2; exit 1; }

# pkg-mgmt.sh
else die "No supported package manager found (apt-get/dnf/yum/pacman)" "$E_PKGMGR"
```

`die()` uses `$*`, so `$E_PKGMGR` (value `67`) is concatenated into the error message and the script always exits with code `1`. Callers expecting `$E_PKGMGR` in `$?` (e.g., scripts that wrap sys-cli) will silently receive the wrong exit code, and the error message will read: `"...pkg manager found ... 67"`.

**Fix option A** — make `die()` accept an optional exit code:
```bash
die() { local code="${2:-1}"; echo -e "${RED}${BOLD}ERROR:${NC} $1" >&2; exit "$code"; }
```

**Fix option B** — remove the second arg at call site if callers never check the code.

---

## Important Issues

### 3. `cron_delete`: `grep -vF "$target_line"` deletes ALL matching lines (cron-mgmt.sh:100)

**Severity: High**

When a crontab contains duplicate entries (which `_cron_add_idempotent` prevents on add, but which may exist from pre-existing crontabs), the delete path removes every occurrence of the selected line, not just the nth one. A user sees line 3 and line 7 are identical and selects 3; both are silently deleted.

This is a correctness bug, not a security issue, but data loss (lost cron jobs) is the impact.

**Fix:** Snapshot the crontab once, then reconstruct it without line N by number:
```bash
local snapshot
snapshot=$(crontab -l 2>/dev/null)
# strip comments for display/count, operate on snapshot by line number
local new_crontab
new_crontab=$(echo "$snapshot" | grep -v '^#' | awk -v n="$n" 'NR != n')
echo "$new_crontab" | crontab -
```

This also eliminates the current 3-call race window (cron_list → extract target_line → delete all call `crontab -l` independently).

---

### 4. `cron_setup_backup`: paths with spaces break the scheduled `tar` command (cron-mgmt.sh:124)

**Severity: High**

```bash
local cmd="tar -czf \"${dest}/backup-\$(date +\\%Y\\%m\\%d).tar.gz\" \"${src}\" >> ..."
```

The double-quote escaping works for simple paths, but a path containing a single-quote, a backslash, or dollar sign will produce a broken cron entry (either a syntax error at cron execution time or the wrong path). Spaces in paths are quoted, but `"${src}"` containing `it's here` would produce `"it's here"` which breaks the shell context inside cron.

**Fix:** After constructing `$entry`, validate that `$src` and `$dest` contain only safe characters `[A-Za-z0-9/_.-]`, or document clearly that paths with special characters are unsupported.

---

### 5. `set_permissions`: no validation of `$fmode`/`$dmode` before passing to `sudo chmod` (file-mgmt.sh:184–185)

**Severity: High**

`$fmode` and `$dmode` are passed directly from user input to `chmod` with no format check. While `chmod` itself rejects invalid modes, there is no pre-validation:

- An octal typo like `864` causes `chmod` to silently exit non-zero, the `&&` short-circuits, and the success message is suppressed — but the script continues without warning the user.
- A symbolic mode like `u+s` on executables in a web-served directory could be unexpected.

**Fix:** Add a format guard:
```bash
[[ "$fmode" =~ ^[0-7]{3,4}$ ]] || die "Invalid file mode: $fmode (use 3-4 octal digits)"
[[ "$dmode" =~ ^[0-7]{3,4}$ ]] || die "Invalid directory mode: $dmode"
```

---

### 6. `batch_delete` / `batch_move`: reported count can be stale (file-mgmt.sh:73, 104)

**Severity: Medium-High**

Both functions compute `$match_count` from a separate `find` call, then perform the actual operation with another `find` call. If files are created or deleted between the two calls (e.g., log rotation, concurrent process), the reported count in the success message will be incorrect. More critically in `batch_delete`, the confirm prompt says "Delete all N matching files?" but N may have changed.

This is TOCTOU, not exploitable for privilege escalation, but produces misleading output in production systems with concurrent activity.

**Fix:** Use `-delete` primary with `find` or capture the list once and operate on that list:
```bash
mapfile -d '' files < <(find "$dir" -name "$pattern" -print0)
count="${#files[@]}"
# ... confirm with $count ...
rm -f -- "${files[@]}"
```

---

## Minor Issues

### 7. `time_list_timezones`: unquoted `$filter` in grep (time-mgmt.sh:31, 39)

`grep -i "$filter"` — the variable is quoted, which is correct. However a `$filter` value of `-e` or starting with `-` could be interpreted as a grep option. Prefer:
```bash
grep -i -e "$filter"
# or
grep -i -- "$filter"
```
Low impact (interactive tool), but worth fixing for robustness.

### 8. `batch_delete` line 78: redundant empty-guard after `confirm()` (file-mgmt.sh:78)

```bash
confirm "Delete..." || { info "Cancelled."; return 0; }
[[ -z "$dir" ]] && die "Directory cannot be empty"  # safety re-guard
```

This guard is dead code: `$dir` was already validated non-empty and as an existing directory at lines 63–64, and no reassignment happens between those lines and line 78. The comment "safety re-guard" suggests intentional defensive coding, but it adds confusion.

### 9. `process_monitor`: SC2064 suppress comment is slightly misleading (process-mgmt.sh:122)

The `# shellcheck disable=SC2064` is correct — the trap intentionally uses single quotes to prevent expansion at trap-definition time. But the comment should explain why (to allow `return 0` to work in the current function context), otherwise future maintainers may remove the suppression.

### 10. `network_list_sockets` `ss` output field mapping (network-mgmt.sh:37)

```bash
ss -tulpn | awk '... $5,$2,$7 ...'
```

`ss` column positions vary between versions and options. On some systems field 5 is the local address but on others (newer iproute2 with `--no-header` removed) the process column is absent or shifted. Consider using `ss -tulpnH` (no header, predictable) and parsing by field name with `--output` if available, or add a version guard.

### 11. `pkg_autoremove` pacman orphans: `$orphans` intentional word-split comment could be improved (pkg-mgmt.sh:119–121)

The `# shellcheck disable=SC2086` with explanation is good practice. However, a package name containing a space (rare but possible on some AUR entries) would still break the command. Consider `mapfile -t orphan_arr <<< "$orphans"` and `"${orphan_arr[@]}"` for robustness.

### 12. `cron_list` displays non-comment lines only; line numbers in `cron_delete` reference that filtered view (cron-mgmt.sh:31, 87)

`cron_list` strips comments with `grep -v '^#'`, and `cron_delete` extracts the target line from the same filtered view using `sed -n "${n}p"`. This is consistent. However, inline comments (`* * * * * cmd # note`) are not stripped, so a comment-only line interspersed in an unusual crontab would still show and count correctly. This is acceptable but worth documenting.

---

## Positive Observations

- `set -euo pipefail` only in `sys-cli.sh` (entry point); all sourced libs deliberately omit it — correct pattern.
- `trap cleanup EXIT INT TERM` wired in entry point; `_TMPFILES` array pattern is clean.
- Every destructive operation (delete, kill, chmod, pkg remove) is gated by `confirm()`.
- `crontab -l 2>/dev/null` used consistently — never direct file writes to cron spool.
- `-- "$var"` guards used correctly on `rm`, `mv`, `mkdir`, `touch`, `gzip`, `chown`.
- `command_exists` called before all optional tools; fallback chains are complete (ss→lsof→/proc, ip→ifconfig→/proc, timedatectl→symlink/tee).
- SIGTERM→grace-period→SIGKILL pattern in `_safe_kill` is correct; second `confirm()` before SIGKILL is a nice UX touch.
- `/proc/net/tcp` hex-port parsing in `process_find_by_port` is thorough.
- All modules well under 200 lines; no duplicated logic across modules.
- `read -ra pkgs <<< "$input"` for splitting package names is correct and safe.
- `sudo tee` pattern used for `/etc/timezone` write (time-mgmt.sh:75) — correct.

---

## Recommended Actions (priority order)

1. **Fix shell injection** in `network_test_connectivity` bash TCP fallback (Critical)
2. **Fix `die()` API** to accept exit code as `$2`, or strip the second arg from its one caller (Critical)
3. **Fix `cron_delete`** to snapshot crontab once and delete by line number, not by content match (High)
4. **Validate `fmode`/`dmode`** as octal before passing to `sudo chmod` (High)
5. **Add `--` to grep** calls in `time_list_timezones` to prevent option injection (Minor)
6. **Remove dead re-guard** at `batch_delete:78` (Minor)
7. **Document or guard** special characters in `cron_setup_backup` paths (High, document at minimum)

---

## Verdict

**NEEDS_REVISION**

Two critical issues (shell injection, die() exit-code contract) and one high-severity correctness bug (cron duplicate-line deletion) must be addressed. The rest of the codebase is solid and production-quality. Estimated fix effort: < 2 hours.
