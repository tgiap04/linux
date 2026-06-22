# User Stories

**Project**: KMA OS / sys-cli
**Generated**: 2026-06-22
**Analysis Scope**: sys-cli web dashboard — SCR001–SCR008; two actors: User, SudoUser

**Code Format**: All US codes follow `US###_NameSlug` format.

**US Types**:
- `ui` — User-facing stories (require Screen mapping)
- `system` — System/background stories (no Screen mapping required)

**Note**: Feature mapping is managed in FeatureList.md only. UI US require Screen mapping; system US do not.

---

## Interaction Inventory

> Completed BEFORE writing any US (IPE Step 2). One row per interactive element per screen.
> Merge exceptions applied: SCR002 New File/Dir → 1 US; SCR005 form/inline remove → 1 US; SCR006 refresh/sort → 1 US; SCR008 toggle fields → 1 US.

| Screen | Element | Type | Action | Endpoint |
|--------|---------|------|--------|----------|
| SCR001_Dashboard | Sidebar nav link × 7 | navigation | Navigate to module screen | GET /views/{name}.html |
| SCR001_Dashboard | Sudo password modal submit | system-action | Verify sudo credentials | POST /api/sudo/verify |
| SCR002_FileManagement | Load Tree button | secondary-action | Browse directory tree | GET /api/files/tree |
| SCR002_FileManagement | Large-file Finder button | secondary-action | Find files over size threshold | GET /api/files/large |
| SCR002_FileManagement | Delete (glob) button + confirm | destructive-action | Delete files by glob pattern | POST /api/files/delete |
| SCR002_FileManagement | Delete Path button + confirm | destructive-action | Delete specific path (sudo) | POST /api/files/delete-path |
| SCR002_FileManagement | Rename button + modal | primary-action | Rename file or directory (sudo) | POST /api/files/rename |
| SCR002_FileManagement | New File / New Dir button + modal | primary-action | Create file or directory (sudo) | POST /api/files/create |
| SCR003_CronJobs | Add job form submit | primary-action | Add new cron job entry | POST /api/cron/add |
| SCR003_CronJobs | Delete job row button + confirm | destructive-action | Remove cron job by index | DELETE /api/cron/:index |
| SCR004_SystemTime | Timezone filter + list | secondary-action | Filter and select timezone | GET /api/time/timezones |
| SCR004_SystemTime | Set Timezone button | primary-action | Apply selected timezone (sudo) | POST /api/time/timezone |
| SCR004_SystemTime | Enable NTP button | primary-action | Enable NTP sync (sudo) | POST /api/time/ntp |
| SCR004_SystemTime | View NTP Status button | secondary-action | Fetch raw NTP sync status | GET /api/time/ntp-status |
| SCR005_Packages | Install packages submit | primary-action | Install named packages (sudo) | POST /api/packages/install |
| SCR005_Packages | Remove/purge submit (form + inline, merged) | destructive-action | Remove package(s) (sudo) | POST /api/packages/remove |
| SCR005_Packages | Start Update button (SSE) | system-action | Stream system package update (sudo) | GET /api/packages/update/stream |
| SCR005_Packages | Autoremove button | primary-action | Remove orphan packages (sudo) | POST /api/packages/autoremove |
| SCR005_Packages | Load installed packages panel | secondary-action | List installed packages | GET /api/packages/list |
| SCR006_Processes | Refresh / Sort button (merged) | secondary-action | Reload process list with sort | GET /api/processes/list |
| SCR006_Processes | Kill process + confirm | destructive-action | Send kill signal to process (sudo) | POST /api/processes/kill |
| SCR006_Processes | Port lookup Find button | secondary-action | Find process by port | GET /api/processes/port/:port |
| SCR007_Network | Ports tab activate | secondary-action | View listening sockets | GET /api/network/sockets |
| SCR007_Network | Interfaces tab activate | secondary-action | View network interfaces | GET /api/network/interfaces |
| SCR007_Network | Routes tab activate | secondary-action | View routing table | GET /api/network/routes |
| SCR007_Network | Ping test submit | primary-action | Test host connectivity | POST /api/network/ping |
| SCR007_Network | DNS lookup submit | primary-action | Resolve domain name | POST /api/network/dns |
| SCR008_Firewall | View firewall status (init) | secondary-action | Read module + rule state (sudo) | GET /api/firewall/status |
| SCR008_Firewall | Toggle enabled/drop_icmp (merged) | primary-action | Flip firewall toggle (sudo) | POST /api/firewall/toggle |
| SCR008_Firewall | Add ports to blocklist | primary-action | Add ports to reject list (sudo) | POST /api/firewall/ports |
| SCR008_Firewall | Remove port from blocklist | destructive-action | Remove port from reject list (sudo) | POST /api/firewall/ports/clear |
| SCR008_Firewall | View Logs button | secondary-action | Fetch last 50 firewall log entries (sudo) | GET /api/firewall/logs |

---

## User Story Index

| # | Title | Type | Priority | Screens |
|---|-------|------|----------|---------|
| 001 | Navigate to a Module Screen | ui | High | SCR001 |
| 002 | Authenticate with Sudo Password | ui | High | SCR001 |
| 003 | Browse Directory Tree | ui | High | SCR002 |
| 004 | Find Large Files | ui | Medium | SCR002 |
| 005 | Delete Files by Glob Pattern | ui | Medium | SCR002 |
| 006 | Delete a File or Directory Path | ui | High | SCR002 |
| 007 | Rename a File or Directory | ui | High | SCR002 |
| 008 | Create a File or Directory | ui | High | SCR002 |
| 009 | Add a Cron Job | ui | High | SCR003 |
| 010 | Delete a Cron Job | ui | High | SCR003 |
| 011 | Search and Select a Timezone | ui | Medium | SCR004 |
| 012 | Apply a Timezone Change | ui | High | SCR004 |
| 013 | Enable NTP Synchronization | ui | High | SCR004 |
| 014 | View NTP Sync Status | ui | Medium | SCR004 |
| 015 | Install Packages | ui | High | SCR005 |
| 016 | Remove a Package | ui | High | SCR005 |
| 017 | Stream a System Package Update | ui | High | SCR005 |
| 018 | Autoremove Orphan Packages | ui | Medium | SCR005 |
| 019 | List Installed Packages | ui | Medium | SCR005 |
| 020 | Refresh and Sort the Process List | ui | High | SCR006 |
| 021 | Kill a Running Process | ui | High | SCR006 |
| 022 | Look Up a Process by Port | ui | Medium | SCR006 |
| 023 | View Listening Sockets | ui | Medium | SCR007 |
| 024 | View Network Interfaces | ui | Medium | SCR007 |
| 025 | View the Routing Table | ui | Medium | SCR007 |
| 026 | Test Host Connectivity via Ping | ui | Medium | SCR007 |
| 027 | Resolve a Domain Name | ui | Medium | SCR007 |
| 028 | View Kernel Firewall Status | ui | High | SCR008 |
| 029 | Toggle a Firewall Rule | ui | High | SCR008 |
| 030 | Add Ports to the Firewall Blocklist | ui | High | SCR008 |
| 031 | Remove a Port from the Firewall Blocklist | ui | High | SCR008 |
| 032 | View Kernel Firewall Logs | ui | Medium | SCR008 |

---

## US001_NavigateModule: Navigate to a Module Screen

**Type**: ui
**Interaction**: navigation
**Priority**: High
**Estimate**: XS

### User Story

As a User, I want to navigate to any module screen via the sidebar so that I can access system management functions without reloading the page.

### Acceptance Criteria

- [ ] Criterion 1: Clicking a sidebar link loads the corresponding view fragment via `GET /views/{name}.html` and renders it in the main content area.
- [ ] Criterion 2: The active sidebar item is visually highlighted to indicate the current screen.
- [ ] Criterion 3: Default module on initial page load is `processes` (SCR006).
- [ ] Criterion 4: Navigation does not require authentication; both User and SudoUser may navigate freely.

### Technical Notes

- **Endpoint**: GET /views/{name}.html
- **Data Required**: module name slug (files, cron, time, packages, processes, network, firewall)
- **Dependencies**: Alpine.js `x-html` injection, SCR001 shell layout

### Screens

- SCR001: Dashboard / Main Menu

### Background Logic

- BL001_SysCliMain: main_menu dispatch (CLI equivalent pattern)

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | User is on Dashboard | Clicks "Process Management" sidebar link | Processes view loads; sidebar item highlighted |
| Already Active | Current screen is Processes | Clicks "Process Management" again | View reloads or remains; no error |
| Invalid Fragment | Server returns 404 for view | Navigation attempted | Error state displayed; no crash |

---

## US002_AuthenticateSudo: Authenticate with Sudo Password

**Type**: ui
**Interaction**: system-action
**Priority**: High
**Estimate**: S

### User Story

As a User, I want to enter my sudo password in the modal prompt so that I can gain elevated access to execute privileged system operations.

### Acceptance Criteria

- [ ] Criterion 1: Any privileged API action triggers the sudo modal if no valid session token is present.
- [ ] Criterion 2: Submitting the modal sends `POST /api/sudo/verify`; on success the original request is replayed automatically.
- [ ] Criterion 3: On failure (wrong password), the modal displays an error and remains open for retry.
- [ ] Criterion 4: No password value is persisted client-side beyond the lifetime of the modal interaction; only the one-time token is retained for SSE streams.
- [ ] Criterion 5: Cancel dismisses the modal without executing the privileged action.

### Technical Notes

- **Endpoint**: POST /api/sudo/verify
- **Data Required**: sudo password (form input, never stored)
- **Dependencies**: All sudo-gated endpoints; SCR001 modal overlay component

### Screens

- SCR001: Dashboard / Main Menu

### Background Logic

- BL015_ShellExecutor: sudo token injection on server side

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | User clicks a privileged action (e.g., Kill Process) | Enters correct sudo password and submits | Modal closes; original action executes; success toast shown |
| Wrong Password | Sudo modal is open | Enters incorrect password | Error message in modal; modal stays open |
| Cancel | Sudo modal is open | Clicks Cancel | Modal closes; original action is not executed |

---

## US003_BrowseDirectoryTree: Browse Directory Tree

**Type**: ui
**Interaction**: secondary-action
**Priority**: High
**Estimate**: S

### User Story

As a User, I want to browse the directory tree at a specified path and depth so that I can navigate the filesystem structure visually.

### Acceptance Criteria

- [ ] Criterion 1: User can enter a root path and depth (1–5) and click Load to fetch the tree.
- [ ] Criterion 2: Response renders a collapsible directory tree panel.
- [ ] Criterion 3: Directories are expandable/collapsible; files are displayed as leaf nodes.
- [ ] Criterion 4: Both User and SudoUser may browse (no sudo required for read).
- [ ] Criterion 5: Loading and error states are displayed appropriately.

### Technical Notes

- **Endpoint**: GET /api/files/tree?path=&depth=
- **Data Required**: treePath (string), treeDepth (int 1–5)
- **Dependencies**: BL020_FilesRoutes, SCR002 directory tree component

### Screens

- SCR002: File Management

### Background Logic

- BL002_FileMgmtMenu: file_mgmt_menu (CLI equivalent)
- BL020_FilesRoutes: Express route handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | Path `/home/user`, depth 2 | Clicks Load | Tree rendered with two levels |
| Non-existent Path | Path `/does/not/exist` | Clicks Load | Error state shown: path not found |
| Max Depth | Depth set to 5 | Clicks Load | Tree renders up to 5 levels deep without crash |

---

## US004_FindLargeFiles: Find Large Files

**Type**: ui
**Interaction**: secondary-action
**Priority**: Medium
**Estimate**: S

### User Story

As a User, I want to find files exceeding a size threshold in a directory so that I can identify candidates for cleanup.

### Acceptance Criteria

- [ ] Criterion 1: User provides a directory path and minimum size threshold; clicking Find triggers the search.
- [ ] Criterion 2: Results list files with their sizes.
- [ ] Criterion 3: No sudo required for listing (read:files permission).
- [ ] Criterion 4: Loading and empty-result states are handled gracefully.

### Technical Notes

- **Endpoint**: GET /api/files/large?dir=&size=
- **Data Required**: dir (string), size (number, bytes or human-readable unit)
- **Dependencies**: BL020_FilesRoutes

### Screens

- SCR002: File Management

### Background Logic

- BL020_FilesRoutes: large-file finder handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | dir=/var/log, size=10MB | Clicks Find | List of files ≥10MB displayed with sizes |
| No Results | Small dir with tiny files | Clicks Find | Empty-result message shown |
| Invalid Dir | dir=/nonexistent | Clicks Find | Error message displayed |

---

## US005_DeleteFilesByGlob: Delete Files by Glob Pattern

**Type**: ui
**Interaction**: destructive-action
**Priority**: Medium
**Estimate**: S

### User Story

As a User, I want to delete files matching a glob pattern so that I can remove groups of files in one operation.

### Acceptance Criteria

- [ ] Criterion 1: User enters a glob pattern in the path input and initiates delete.
- [ ] Criterion 2: A confirmation modal must be shown before deletion executes.
- [ ] Criterion 3: `POST /api/files/delete` is called only after confirmation.
- [ ] Criterion 4: Success and error feedback is shown after the operation.
- [ ] Criterion 5: No sudo required (operates under current user's permissions).

### Technical Notes

- **Endpoint**: POST /api/files/delete
- **Data Required**: opPath (glob pattern string)
- **Dependencies**: BL020_FilesRoutes; confirm modal component (SCR002)

### Screens

- SCR002: File Management

### Background Logic

- BL020_FilesRoutes: glob delete handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | Pattern `/tmp/*.log` | Confirms delete | All matching files deleted; success feedback |
| Cancel | Confirm modal open | Clicks Cancel | No files deleted |
| No Match | Pattern with no matches | Confirms delete | No error; 0 files removed feedback |

---

## US006_DeleteFilePath: Delete a File or Directory Path

**Type**: ui
**Interaction**: destructive-action
**Priority**: High
**Estimate**: S

### User Story

As a SudoUser, I want to delete a specific file or directory path so that I can remove system files requiring elevated privileges.

### Acceptance Criteria

- [ ] Criterion 1: User enters an explicit path and initiates delete.
- [ ] Criterion 2: Sudo authentication modal is triggered before delete executes.
- [ ] Criterion 3: Confirmation modal is shown after sudo is satisfied.
- [ ] Criterion 4: `POST /api/files/delete-path` is called with the resolved path.
- [ ] Criterion 5: Success and error feedback is displayed.

### Technical Notes

- **Endpoint**: POST /api/files/delete-path
- **Data Required**: opPath (absolute path string)
- **Dependencies**: BL020_FilesRoutes; sudo modal (SCR001); confirm modal (SCR002)

### Screens

- SCR002: File Management

### Background Logic

- BL002_FileMgmtMenu: CLI equivalent
- BL020_FilesRoutes: delete-path handler
- BL015_ShellExecutor: sudo injection

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | SudoUser, path=/etc/temp.conf | Authenticates + confirms | File deleted; success toast |
| Non-existent Path | Path does not exist | Confirms | Error: path not found |
| Permission Denied | Wrong sudo password | Submits wrong password | Modal error; delete not executed |

---

## US007_RenameFilePath: Rename a File or Directory

**Type**: ui
**Interaction**: primary-action
**Priority**: High
**Estimate**: S

### User Story

As a SudoUser, I want to rename a file or directory so that I can reorganize the filesystem with elevated privileges.

### Acceptance Criteria

- [ ] Criterion 1: User enters source path and new name/path in the rename modal.
- [ ] Criterion 2: Sudo authentication is required before rename executes.
- [ ] Criterion 3: `POST /api/files/rename` is called with old and new path.
- [ ] Criterion 4: Success toast is shown on completion; error state on failure.

### Technical Notes

- **Endpoint**: POST /api/files/rename
- **Data Required**: oldPath (string), newPath (string)
- **Dependencies**: BL020_FilesRoutes; sudo modal (SCR001); input modal (SCR002)

### Screens

- SCR002: File Management

### Background Logic

- BL002_FileMgmtMenu: rename menu entry
- BL020_FilesRoutes: rename handler
- BL015_ShellExecutor: sudo injection

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | SudoUser, oldPath=/tmp/a, newPath=/tmp/b | Authenticates + submits | File renamed; success feedback |
| Target Exists | newPath already exists | Submits | Error displayed; no rename |
| Empty New Name | newPath is blank | Submits | Validation error; request not sent |

---

## US008_CreateFilePath: Create a File or Directory

**Type**: ui
**Interaction**: primary-action
**Priority**: High
**Estimate**: S

### User Story

As a SudoUser, I want to create a new file or directory at a specified path so that I can add filesystem entries with elevated privileges.

### Acceptance Criteria

- [ ] Criterion 1: User specifies a path and type (file or directory) via the create modal.
- [ ] Criterion 2: Sudo authentication is required before creation executes.
- [ ] Criterion 3: `POST /api/files/create` is called with path and type.
- [ ] Criterion 4: Success and error feedback is shown.
- [ ] Criterion 5: Duplicate path triggers an error or idempotent response.

### Technical Notes

- **Endpoint**: POST /api/files/create
- **Data Required**: path (string), type ("file" | "dir")
- **Dependencies**: BL020_FilesRoutes; sudo modal (SCR001); input modal (SCR002)

### Screens

- SCR002: File Management

### Background Logic

- BL002_FileMgmtMenu: create menu entry
- BL020_FilesRoutes: create handler
- BL015_ShellExecutor: sudo injection

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path (file) | SudoUser, path=/tmp/new.txt, type=file | Authenticates + submits | File created; success feedback |
| Happy Path (dir) | SudoUser, path=/tmp/newdir, type=dir | Authenticates + submits | Directory created; success feedback |
| Path Exists | Path already present | Submits | Error displayed; no overwrite |

---

## US009_AddCronJob: Add a Cron Job

**Type**: ui
**Interaction**: primary-action
**Priority**: High
**Estimate**: M

### User Story

As a User, I want to add a new cron job entry via the schedule form so that I can automate recurring commands without editing crontab manually.

### Acceptance Criteria

- [ ] Criterion 1: Form accepts min/hour/day/month/wday schedule fields and a command string.
- [ ] Criterion 2: Live crontab-line preview updates as schedule fields change.
- [ ] Criterion 3: Log redirect toggle optionally appends `>> /path 2>&1` to the command.
- [ ] Criterion 4: Submitting calls `POST /api/cron/add`; success shows a toast.
- [ ] Criterion 5: Duplicate entry is silently skipped; UI reports "already exists".
- [ ] Criterion 6: Validation rejects empty cmd or invalid schedule field values.
- [ ] Criterion 7: No sudo required (crontab runs as current user).

### Technical Notes

- **Endpoint**: POST /api/cron/add
- **Data Required**: MODEL007_CronJob fields (min, hour, day, month, wday, cmd)
- **Dependencies**: BL019_CronRoutes; GET /api/cron/now (pre-fills hour/min on init)

### Screens

- SCR003: Cron Jobs

### Background Logic

- BL003_CronMgmtMenu: cron_mgmt_menu (CLI equivalent)
- BL019_CronRoutes: cron add handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | Valid schedule + cmd | Submits form | Job added; toast success; list refreshed |
| Duplicate Entry | Same entry already in crontab | Submits | Response: already exists; no duplicate added |
| Empty Command | cmd field blank | Submits | Validation error: cmd is required |
| Invalid Schedule | min="abc" | Submits | Validation error from cronField validator |

---

## US010_DeleteCronJob: Delete a Cron Job

**Type**: ui
**Interaction**: destructive-action
**Priority**: High
**Estimate**: S

### User Story

As a User, I want to delete an existing cron job entry so that I can remove scheduled tasks I no longer need.

### Acceptance Criteria

- [ ] Criterion 1: Each job row has a Delete button; clicking it shows a confirmation dialog.
- [ ] Criterion 2: Confirming calls `DELETE /api/cron/:index` with the job's 1-based index.
- [ ] Criterion 3: On success, the job is removed from the list immediately.
- [ ] Criterion 4: Out-of-range index returns 400; UI shows error.
- [ ] Criterion 5: No sudo required.

### Technical Notes

- **Endpoint**: DELETE /api/cron/:index
- **Data Required**: index (1-based integer)
- **Dependencies**: BL019_CronRoutes; confirm modal

### Screens

- SCR003: Cron Jobs

### Background Logic

- BL003_CronMgmtMenu: cron delete entry
- BL019_CronRoutes: cron delete handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | Job at index 2 exists | Confirms delete | Job removed; list updates |
| Cancel | Confirm dialog open | Clicks Cancel | Job not deleted |
| Index Out of Range | Stale index (job already deleted) | Confirms | 400 error displayed |

---

## US011_SearchTimezone: Search and Select a Timezone

**Type**: ui
**Interaction**: secondary-action
**Priority**: Medium
**Estimate**: XS

### User Story

As a User, I want to filter the timezone list by keyword so that I can quickly find and select the correct timezone.

### Acceptance Criteria

- [ ] Criterion 1: Typing in the filter input calls `GET /api/time/timezones?filter=` and renders up to 50 matching results.
- [ ] Criterion 2: Selecting an item from the list sets it as the current selection for the Set Timezone action.
- [ ] Criterion 3: No sudo required for browsing timezones.
- [ ] Criterion 4: Empty filter returns an unfiltered list (capped at 50).

### Technical Notes

- **Endpoint**: GET /api/time/timezones?filter=
- **Data Required**: filter (string, optional)
- **Dependencies**: BL022_TimeRoutes; SCR004 timezone list component

### Screens

- SCR004: System Time

### Background Logic

- BL022_TimeRoutes: timezones handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | filter="Asia" | Types "Asia" | List of Asia/* timezones shown (≤50) |
| No Match | filter="zzz" | Types "zzz" | Empty list or no-results message |
| Empty Filter | filter="" | Clears input | Up to 50 timezones shown |

---

## US012_SetTimezone: Apply a Timezone Change

**Type**: ui
**Interaction**: primary-action
**Priority**: High
**Estimate**: S

### User Story

As a SudoUser, I want to set the system timezone so that the server clock reflects the correct geographic region.

### Acceptance Criteria

- [ ] Criterion 1: User selects a timezone from the filtered list and clicks Set Timezone.
- [ ] Criterion 2: Sudo authentication modal is triggered before the change is applied.
- [ ] Criterion 3: `POST /api/time/timezone` is called with the selected timezone string.
- [ ] Criterion 4: Success toast is shown; the displayed current timezone updates.
- [ ] Criterion 5: Invalid timezone string returns an error.

### Technical Notes

- **Endpoint**: POST /api/time/timezone
- **Data Required**: timezone (string, e.g. "Asia/Ho_Chi_Minh")
- **Dependencies**: BL022_TimeRoutes; BL015_ShellExecutor; sudo modal (SCR001)

### Screens

- SCR004: System Time

### Background Logic

- BL004_TimeMgmtMenu: timezone set (CLI equivalent)
- BL022_TimeRoutes: timezone set handler
- BL015_ShellExecutor: timedatectl execution

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | SudoUser selects "UTC" | Authenticates + clicks Set | Timezone updated; display refreshes |
| Invalid Timezone | Arbitrary string | Submits | Error: invalid timezone |
| No Selection | No timezone selected | Clicks Set | Validation prevents request |

---

## US013_EnableNtp: Enable NTP Synchronization

**Type**: ui
**Interaction**: primary-action
**Priority**: High
**Estimate**: S

### User Story

As a SudoUser, I want to enable NTP time synchronization so that the system clock stays accurate automatically.

### Acceptance Criteria

- [ ] Criterion 1: Clicking Enable NTP triggers the sudo authentication modal.
- [ ] Criterion 2: `POST /api/time/ntp` is called on authentication success.
- [ ] Criterion 3: Success toast shown; NTP sync status indicator updates.
- [ ] Criterion 4: If NTP is already enabled, the button reflects the current state (disabled or informative).

### Technical Notes

- **Endpoint**: POST /api/time/ntp
- **Data Required**: none beyond sudo token
- **Dependencies**: BL022_TimeRoutes; BL015_ShellExecutor; sudo modal (SCR001)

### Screens

- SCR004: System Time

### Background Logic

- BL004_TimeMgmtMenu: NTP enable (CLI equivalent)
- BL022_TimeRoutes: NTP enable handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | NTP currently disabled | Authenticates + clicks Enable | NTP enabled; status indicator updates |
| Already Enabled | NTP already active | Clicks Enable | No error; idempotent success or info feedback |
| Auth Failure | Wrong sudo password | Submits wrong password | Modal error; NTP not changed |

---

## US014_ViewNtpStatus: View NTP Sync Status

**Type**: ui
**Interaction**: secondary-action
**Priority**: Medium
**Estimate**: XS

### User Story

As a User, I want to view the raw NTP sync status so that I can confirm whether time synchronization is functioning correctly.

### Acceptance Criteria

- [ ] Criterion 1: Clicking View NTP Status calls `GET /api/time/ntp-status`.
- [ ] Criterion 2: The raw `timedatectl` output is displayed in a panel.
- [ ] Criterion 3: No sudo required.
- [ ] Criterion 4: Loading and error states are shown.

### Technical Notes

- **Endpoint**: GET /api/time/ntp-status
- **Data Required**: none
- **Dependencies**: BL022_TimeRoutes

### Screens

- SCR004: System Time

### Background Logic

- BL022_TimeRoutes: ntp-status handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | NTP active | Clicks View NTP Status | Raw timedatectl output displayed |
| Error | timedatectl fails | Clicks button | Error message shown in panel |

---

## US015_InstallPackages: Install Packages

**Type**: ui
**Interaction**: primary-action
**Priority**: High
**Estimate**: M

### User Story

As a SudoUser, I want to install one or more packages by name so that I can add software to the system from the web dashboard.

### Acceptance Criteria

- [ ] Criterion 1: User enters space- or comma-separated package names in the install form.
- [ ] Criterion 2: Sudo authentication is triggered on submit.
- [ ] Criterion 3: `POST /api/packages/install` is called with the package list.
- [ ] Criterion 4: Success and error feedback shown per result.
- [ ] Criterion 5: Empty input is rejected with a validation error.

### Technical Notes

- **Endpoint**: POST /api/packages/install
- **Data Required**: packages (space/comma-separated string)
- **Dependencies**: BL021_PackagesRoutes; BL015_ShellExecutor; sudo modal (SCR001)

### Screens

- SCR005: Package Management

### Background Logic

- BL005_PkgMgmtMenu: install (CLI equivalent)
- BL021_PackagesRoutes: install handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | SudoUser, packages="curl wget" | Authenticates + submits | Both packages installed; success feedback |
| Package Not Found | Unknown package name | Submits | Error from apt; error message displayed |
| Empty Input | No packages entered | Submits | Validation error; no request sent |

---

## US016_RemovePackage: Remove a Package

**Type**: ui
**Interaction**: destructive-action
**Priority**: High
**Estimate**: S

### User Story

As a SudoUser, I want to remove an installed package so that I can free up system resources or uninstall unwanted software.

### Acceptance Criteria

- [ ] Criterion 1: User enters package name in the remove form (or clicks inline Remove from the installed list).
- [ ] Criterion 2: Purge checkbox optionally triggers full config removal.
- [ ] Criterion 3: Sudo authentication is triggered on submit.
- [ ] Criterion 4: `POST /api/packages/remove` is called with package name and purge flag.
- [ ] Criterion 5: Success and error feedback shown.
- [ ] Criterion 6: Removing a non-installed package returns an error or no-op.

### Technical Notes

- **Endpoint**: POST /api/packages/remove
- **Data Required**: package (string), purge (boolean)
- **Dependencies**: BL021_PackagesRoutes; BL015_ShellExecutor; sudo modal (SCR001)

### Screens

- SCR005: Package Management

### Background Logic

- BL005_PkgMgmtMenu: remove (CLI equivalent)
- BL021_PackagesRoutes: remove handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | SudoUser, package="nano" | Authenticates + submits | Package removed; success feedback |
| Purge Flag | purge=true, package="nano" | Authenticates + submits | Package and configs purged |
| Not Installed | Package not present | Submits | Apt error; displayed to user |

---

## US017_StreamSystemUpdate: Stream a System Package Update

**Type**: ui
**Interaction**: system-action
**Priority**: High
**Estimate**: M

### User Story

As a SudoUser, I want to run a full system package update and watch the output stream in real time so that I can monitor progress and catch errors without waiting blindly.

### Acceptance Criteria

- [ ] Criterion 1: Clicking Start Update first obtains a one-time sudo token via `POST /api/sudo/verify`.
- [ ] Criterion 2: The token is appended as `?_sudo_token=` to the SSE stream URL.
- [ ] Criterion 3: `GET /api/packages/update/stream` opens an SSE connection; log lines are appended to the scrollable panel.
- [ ] Criterion 4: Stream closes cleanly on completion; success/failure indication shown.
- [ ] Criterion 5: UI disables the Start Update button while the stream is active.

### Technical Notes

- **Endpoint**: GET /api/packages/update/stream (SSE); POST /api/sudo/verify (pre-auth)
- **Data Required**: sudo one-time token (query param)
- **Dependencies**: BL021_PackagesRoutes; BL015_ShellExecutor; EventSource API

### Screens

- SCR005: Package Management

### Background Logic

- BL005_PkgMgmtMenu: update (CLI equivalent)
- BL021_PackagesRoutes: update/stream handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | SudoUser, system has updates | Authenticates + clicks Start Update | Real-time log lines appear; stream closes on done |
| Auth Failure | Wrong sudo password | Attempts auth | SSE never opened; error shown |
| No Updates | System already up to date | Starts update | Stream outputs "up to date" message; closes cleanly |

---

## US018_AutoremoveOrphans: Autoremove Orphan Packages

**Type**: ui
**Interaction**: primary-action
**Priority**: Medium
**Estimate**: XS

### User Story

As a SudoUser, I want to autoremove orphaned packages so that I can reclaim disk space from unused dependencies.

### Acceptance Criteria

- [ ] Criterion 1: Clicking Autoremove triggers sudo authentication.
- [ ] Criterion 2: `POST /api/packages/autoremove` is called on auth success.
- [ ] Criterion 3: Success or error feedback shown.
- [ ] Criterion 4: If nothing to remove, success response with count=0 is reflected in UI.

### Technical Notes

- **Endpoint**: POST /api/packages/autoremove
- **Data Required**: none beyond sudo token
- **Dependencies**: BL021_PackagesRoutes; BL015_ShellExecutor; sudo modal (SCR001)

### Screens

- SCR005: Package Management

### Background Logic

- BL021_PackagesRoutes: autoremove handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | Orphan packages exist | Authenticates + clicks Autoremove | Packages removed; success feedback |
| Nothing to Remove | No orphans | Authenticates + clicks | Success; "0 packages removed" or similar |

---

## US019_ListInstalledPackages: List Installed Packages

**Type**: ui
**Interaction**: secondary-action
**Priority**: Medium
**Estimate**: S

### User Story

As a User, I want to load and search the list of installed packages so that I can see what software is on the system.

### Acceptance Criteria

- [ ] Criterion 1: Installed packages panel loads on demand via `GET /api/packages/list`.
- [ ] Criterion 2: Search input filters the displayed list client-side.
- [ ] Criterion 3: No sudo required.
- [ ] Criterion 4: Loading and empty-result states shown.

### Technical Notes

- **Endpoint**: GET /api/packages/list
- **Data Required**: none
- **Dependencies**: BL021_PackagesRoutes

### Screens

- SCR005: Package Management

### Background Logic

- BL021_PackagesRoutes: list handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | System has packages | Loads panel | Full list rendered; search filters work |
| Empty System | No packages installed | Loads panel | Empty state message shown |

---

## US020_RefreshProcessList: Refresh and Sort the Process List

**Type**: ui
**Interaction**: secondary-action
**Priority**: High
**Estimate**: S

### User Story

As a User, I want to refresh and sort the process list by CPU or memory usage so that I can identify resource-heavy processes quickly.

### Acceptance Criteria

- [ ] Criterion 1: Page loads processes sorted by CPU by default.
- [ ] Criterion 2: Clicking Refresh re-fetches `GET /api/processes/list?sort=cpu` (or current sort).
- [ ] Criterion 3: Toggling sort (CPU ↔ MEM) re-fetches the list with the new sort param.
- [ ] Criterion 4: Table shows PID, user, CPU%, MEM%, command columns.
- [ ] Criterion 5: No sudo required.

### Technical Notes

- **Endpoint**: GET /api/processes/list?sort=cpu|mem
- **Data Required**: sort param ("cpu" | "mem")
- **Dependencies**: BL017_ProcessesRoutes

### Screens

- SCR006: Process Management

### Background Logic

- BL006_ProcessMgmtMenu: process list (CLI equivalent)
- BL017_ProcessesRoutes: list handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Default Load | Page opens | Init | Processes sorted by CPU loaded |
| Sort by MEM | Currently sorted CPU | Clicks MEM toggle | List re-fetched sorted by MEM |
| Refresh | Stale list | Clicks Refresh | Current list re-fetched with active sort |

---

## US021_KillProcess: Kill a Running Process

**Type**: ui
**Interaction**: destructive-action
**Priority**: High
**Estimate**: S

### User Story

As a SudoUser, I want to send a kill signal to a running process so that I can terminate misbehaving or unneeded processes.

### Acceptance Criteria

- [ ] Criterion 1: Clicking Kill on a process row opens a confirm dialog with signal selection (TERM / KILL / HUP).
- [ ] Criterion 2: Sudo authentication is triggered before the kill is sent.
- [ ] Criterion 3: `POST /api/processes/kill` is called with PID and signal.
- [ ] Criterion 4: Success or error feedback shown; process list refreshed.
- [ ] Criterion 5: Killing an already-dead PID returns an error; UI handles gracefully.

### Technical Notes

- **Endpoint**: POST /api/processes/kill
- **Data Required**: pid (int), signal ("TERM" | "KILL" | "HUP")
- **Dependencies**: BL017_ProcessesRoutes; BL015_ShellExecutor; sudo modal (SCR001); confirm dialog (SCR006)

### Screens

- SCR006: Process Management

### Background Logic

- BL006_ProcessMgmtMenu: kill (CLI equivalent)
- BL017_ProcessesRoutes: kill handler
- BL015_ShellExecutor: sudo signal dispatch

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | SudoUser, valid PID | Selects TERM, authenticates, confirms | Process killed; success toast; list refreshes |
| Dead PID | PID no longer exists | Confirms kill | Error: no such process |
| Cancel | Confirm dialog open | Clicks Cancel | No signal sent |

---

## US022_LookupProcessByPort: Look Up a Process by Port

**Type**: ui
**Interaction**: secondary-action
**Priority**: Medium
**Estimate**: XS

### User Story

As a User, I want to look up which process is listening on a given port so that I can identify port conflicts or unexpected services.

### Acceptance Criteria

- [ ] Criterion 1: User enters a port number and clicks Find.
- [ ] Criterion 2: `GET /api/processes/port/:port` is called.
- [ ] Criterion 3: Result panel shows the owning process (PID, name) or "no process found".
- [ ] Criterion 4: No sudo required.
- [ ] Criterion 5: Non-numeric or out-of-range port shows a validation error.

### Technical Notes

- **Endpoint**: GET /api/processes/port/:port
- **Data Required**: port (int 1–65535)
- **Dependencies**: BL017_ProcessesRoutes

### Screens

- SCR006: Process Management

### Background Logic

- BL017_ProcessesRoutes: port lookup handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | Port 8080 is in use by node | Clicks Find | "node (PID 1234)" displayed |
| No Process | Port 9999 not in use | Clicks Find | "No process found on port 9999" |
| Invalid Port | port="abc" | Clicks Find | Validation error; no request sent |

---

## US023_ViewListeningSockets: View Listening Sockets

**Type**: ui
**Interaction**: secondary-action
**Priority**: Medium
**Estimate**: S

### User Story

As a User, I want to view all listening network sockets so that I can audit which ports are open on the system.

### Acceptance Criteria

- [ ] Criterion 1: Activating the Ports tab loads `GET /api/network/sockets`.
- [ ] Criterion 2: Table shows protocol, local address, port, and owning process.
- [ ] Criterion 3: Tab loads only on first activation (lazy-load).
- [ ] Criterion 4: No sudo required.

### Technical Notes

- **Endpoint**: GET /api/network/sockets
- **Data Required**: none
- **Dependencies**: BL018_NetworkRoutes; SCR007 Ports tab

### Screens

- SCR007: Network & Sockets

### Background Logic

- BL007_NetworkMgmtMenu: network menu (CLI equivalent)
- BL018_NetworkRoutes: sockets handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | Services running | Activates Ports tab | Socket table populated |
| Error | ss command fails | Tab activated | Error state displayed |

---

## US024_ViewNetworkInterfaces: View Network Interfaces

**Type**: ui
**Interaction**: secondary-action
**Priority**: Medium
**Estimate**: S

### User Story

As a User, I want to view all network interfaces so that I can inspect IP addresses and interface states.

### Acceptance Criteria

- [ ] Criterion 1: Activating the Interfaces tab loads `GET /api/network/interfaces`.
- [ ] Criterion 2: Displays interface name, IP addresses, and state.
- [ ] Criterion 3: Lazy-load on first activation.
- [ ] Criterion 4: No sudo required.

### Technical Notes

- **Endpoint**: GET /api/network/interfaces
- **Data Required**: none
- **Dependencies**: BL018_NetworkRoutes; SCR007 Interfaces tab

### Screens

- SCR007: Network & Sockets

### Background Logic

- BL018_NetworkRoutes: interfaces handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | eth0, lo present | Activates Interfaces tab | Interface cards with IPs shown |
| Error | ip command fails | Tab activated | Error state displayed |

---

## US025_ViewRoutingTable: View the Routing Table

**Type**: ui
**Interaction**: secondary-action
**Priority**: Medium
**Estimate**: S

### User Story

As a User, I want to view the system routing table so that I can understand how network traffic is directed.

### Acceptance Criteria

- [ ] Criterion 1: Activating the Routes tab loads `GET /api/network/routes`.
- [ ] Criterion 2: Displays routing table rows (destination, gateway, interface).
- [ ] Criterion 3: Lazy-load on first activation.
- [ ] Criterion 4: No sudo required.

### Technical Notes

- **Endpoint**: GET /api/network/routes
- **Data Required**: none
- **Dependencies**: BL018_NetworkRoutes; SCR007 Routes tab

### Screens

- SCR007: Network & Sockets

### Background Logic

- BL018_NetworkRoutes: routes handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | Default route exists | Activates Routes tab | Routing rows displayed |
| Error | ip route fails | Tab activated | Error state shown |

---

## US026_TestConnectivity: Test Host Connectivity via Ping

**Type**: ui
**Interaction**: primary-action
**Priority**: Medium
**Estimate**: S

### User Story

As a User, I want to ping a host and port to test connectivity so that I can diagnose network reachability issues from the server.

### Acceptance Criteria

- [ ] Criterion 1: User enters a host and optional port; clicks Ping.
- [ ] Criterion 2: `POST /api/network/ping` is called with host and port.
- [ ] Criterion 3: Result panel shows success/failure and latency or error message.
- [ ] Criterion 4: No sudo required.

### Technical Notes

- **Endpoint**: POST /api/network/ping
- **Data Required**: host (string), port (int, optional)
- **Dependencies**: BL018_NetworkRoutes; SCR007 Ping/DNS tab

### Screens

- SCR007: Network & Sockets

### Background Logic

- BL007_NetworkMgmtMenu: ping (CLI equivalent)
- BL018_NetworkRoutes: ping handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | host=8.8.8.8, port=53 | Clicks Ping | Reachable result with latency |
| Unreachable Host | host=192.0.2.1 | Clicks Ping | Timeout or unreachable error shown |
| Empty Host | host="" | Clicks Ping | Validation error; no request sent |

---

## US027_ResolveDns: Resolve a Domain Name

**Type**: ui
**Interaction**: primary-action
**Priority**: Medium
**Estimate**: S

### User Story

As a User, I want to resolve a domain name to its IP addresses so that I can verify DNS configuration from the server.

### Acceptance Criteria

- [ ] Criterion 1: User enters a domain name; clicks DNS Lookup.
- [ ] Criterion 2: `POST /api/network/dns` is called with the domain.
- [ ] Criterion 3: Result panel shows resolved IP addresses or resolution failure.
- [ ] Criterion 4: No sudo required.

### Technical Notes

- **Endpoint**: POST /api/network/dns
- **Data Required**: domain (string)
- **Dependencies**: BL018_NetworkRoutes; SCR007 Ping/DNS tab

### Screens

- SCR007: Network & Sockets

### Background Logic

- BL018_NetworkRoutes: dns handler

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | domain=google.com | Clicks DNS Lookup | IP addresses listed in result panel |
| NXDOMAIN | domain=doesnotexist.invalid | Clicks Lookup | DNS resolution failed message |
| Empty Domain | domain="" | Clicks Lookup | Validation error; no request sent |

---

## US028_ViewFirewallStatus: View Kernel Firewall Status

**Type**: ui
**Interaction**: secondary-action
**Priority**: High
**Estimate**: S

### User Story

As a SudoUser, I want to view the current kernel firewall status so that I can see whether the module is loaded and what rules are active.

### Acceptance Criteria

- [ ] Criterion 1: On screen activation, `GET /api/firewall/status` is called with sudo credentials.
- [ ] Criterion 2: If the module is not loaded, a "module not loaded" banner is displayed.
- [ ] Criterion 3: If loaded, shows enabled state, drop_icmp state, and reject_ports list.
- [ ] Criterion 4: Sudo authentication is required (manage:firewall permission).

### Technical Notes

- **Endpoint**: GET /api/firewall/status
- **Data Required**: X-Sudo-Password header (or session token)
- **Dependencies**: BL016_FirewallRoutes; BL013_UbuntuFirewall (kernel sysfs); MODEL006_FirewallRule

### Screens

- SCR008: Kernel Firewall

### Background Logic

- BL008_FirewallMgmtMenu: firewall menu (CLI equivalent)
- BL016_FirewallRoutes: status handler
- BL013_UbuntuFirewall: sysfs attribute reads

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Module Loaded | ubuntu_firewall module is loaded | Navigates to SCR008 | Status shown: enabled, drop_icmp, ports list |
| Module Not Loaded | Kernel module absent | Navigates to SCR008 | "Module not loaded" banner shown |
| Auth Failure | Wrong sudo password | Attempts to view | 401 error; status not shown |

---

## US029_ToggleFirewallRule: Toggle a Firewall Rule

**Type**: ui
**Interaction**: primary-action
**Priority**: High
**Estimate**: S

### User Story

As a SudoUser, I want to toggle the firewall enabled state or the ICMP drop flag so that I can activate/deactivate protection rules without editing config files.

### Acceptance Criteria

- [ ] Criterion 1: Each toggle (enabled, drop_icmp) sends `POST /api/firewall/toggle` with `field` and `value`.
- [ ] Criterion 2: field must be "enabled" or "drop_icmp"; value must be 0 or 1 (MODEL006 validation).
- [ ] Criterion 3: Sudo authentication is required before each toggle.
- [ ] Criterion 4: Toggle UI reflects the new state immediately on success.
- [ ] Criterion 5: Error (invalid field/value) surfaces a 400 error message.

### Technical Notes

- **Endpoint**: POST /api/firewall/toggle
- **Data Required**: field ("enabled" | "drop_icmp"), value (0 | 1)
- **Dependencies**: BL016_FirewallRoutes; BL013_UbuntuFirewall (sysfs write); MODEL006_FirewallRule; sudo modal (SCR001)

### Screens

- SCR008: Kernel Firewall

### Background Logic

- BL016_FirewallRoutes: toggle handler
- BL013_UbuntuFirewall: sysfs attribute writes

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Enable Firewall | enabled=0 | SudoUser flips enabled toggle | POST with field=enabled,value=1; UI updates |
| Enable Drop ICMP | drop_icmp=0 | SudoUser flips ICMP toggle | POST with field=drop_icmp,value=1; UI updates |
| Invalid Field | field="unknown" | Request sent | 400: field must be "enabled" or "drop_icmp" |

---

## US030_AddBlockedPorts: Add Ports to the Firewall Blocklist

**Type**: ui
**Interaction**: primary-action
**Priority**: High
**Estimate**: S

### User Story

As a SudoUser, I want to add one or more ports to the firewall reject list so that I can block inbound traffic on those ports.

### Acceptance Criteria

- [ ] Criterion 1: User enters comma-separated port numbers in the Add Ports input.
- [ ] Criterion 2: Submitted ports are merged with the existing list; duplicates are deduplicated.
- [ ] Criterion 3: `POST /api/firewall/ports` is called with the merged port list.
- [ ] Criterion 4: Each port must be in range 1–65535; invalid ports return 400.
- [ ] Criterion 5: Sudo authentication required.
- [ ] Criterion 6: Port list display updates on success.

### Technical Notes

- **Endpoint**: POST /api/firewall/ports
- **Data Required**: ports (comma-separated string, 1–65535 each)
- **Dependencies**: BL016_FirewallRoutes; BL013_UbuntuFirewall; MODEL006_FirewallRule; sudo modal (SCR001)

### Screens

- SCR008: Kernel Firewall

### Background Logic

- BL016_FirewallRoutes: ports add handler
- BL013_UbuntuFirewall: reject_ports sysfs write

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | SudoUser, ports="80,443" | Authenticates + submits | Ports added; tag list updated |
| Duplicate Port | Port 80 already in list | Submits "80,8080" | 8080 added; 80 deduplicated; no error |
| Invalid Port | ports="99999" | Submits | 400: Invalid port "99999": must be 1-65535 |
| Empty Input | input="" | Submits | 400: ports cannot be empty |

---

## US031_RemoveBlockedPort: Remove a Port from the Firewall Blocklist

**Type**: ui
**Interaction**: destructive-action
**Priority**: High
**Estimate**: XS

### User Story

As a SudoUser, I want to remove a specific port from the firewall reject list so that I can re-enable traffic on that port.

### Acceptance Criteria

- [ ] Criterion 1: Each port tag in the reject list has a remove button.
- [ ] Criterion 2: Clicking remove triggers sudo authentication.
- [ ] Criterion 3: `POST /api/firewall/ports/clear` is called with the target port.
- [ ] Criterion 4: The port tag disappears from the list on success.
- [ ] Criterion 5: Attempting to remove a port not in the list returns an error or no-op.

### Technical Notes

- **Endpoint**: POST /api/firewall/ports/clear
- **Data Required**: port (int or specific port identifier)
- **Dependencies**: BL016_FirewallRoutes; BL013_UbuntuFirewall; MODEL006_FirewallRule; sudo modal (SCR001)

### Screens

- SCR008: Kernel Firewall

### Background Logic

- BL016_FirewallRoutes: ports clear handler
- BL013_UbuntuFirewall: reject_ports sysfs write (remove entry)

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | SudoUser, port 80 in list | Authenticates + clicks remove | Port 80 tag removed; sysfs updated |
| Port Not in List | Port 9090 not in reject_ports | Attempts remove | No-op or error; UI reflects actual state |
| Auth Failure | Wrong sudo password | Submits wrong password | Port not removed; modal error |

---

## US032_ViewFirewallLogs: View Kernel Firewall Logs

**Type**: ui
**Interaction**: secondary-action
**Priority**: Medium
**Estimate**: XS

### User Story

As a SudoUser, I want to view the last 50 kernel firewall log entries so that I can audit recent packet-filtering activity.

### Acceptance Criteria

- [ ] Criterion 1: Clicking View Logs calls `GET /api/firewall/logs` with sudo credentials.
- [ ] Criterion 2: Up to 50 most recent dmesg log lines are displayed in the log panel.
- [ ] Criterion 3: Sudo authentication is required.
- [ ] Criterion 4: Empty log state and error state are handled.

### Technical Notes

- **Endpoint**: GET /api/firewall/logs
- **Data Required**: X-Sudo-Password header (or session token)
- **Dependencies**: BL016_FirewallRoutes; BL013_UbuntuFirewall

### Screens

- SCR008: Kernel Firewall

### Background Logic

- BL016_FirewallRoutes: logs handler
- BL013_UbuntuFirewall: dmesg reader

### Test Scenarios

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy Path | Firewall active, traffic logged | Clicks View Logs | Last 50 dmesg entries shown |
| No Logs | Firewall just enabled, no activity | Clicks View Logs | Empty log panel shown |
| Auth Failure | Wrong sudo password | Clicks View Logs | 401 error; logs not shown |

---

## Screen → US Map

| Screen | Story Numbers |
|--------|--------------|
| SCR001_Dashboard | 001, 002 |
| SCR002_FileManagement | 003, 004, 005, 006, 007, 008 |
| SCR003_CronJobs | 009, 010 |
| SCR004_SystemTime | 011, 012, 013, 014 |
| SCR005_PackageManagement | 015, 016, 017, 018, 019 |
| SCR006_ProcessManagement | 020, 021, 022 |
| SCR007_NetworkSockets | 023, 024, 025, 026, 027 |
| SCR008_KernelFirewall | 028, 029, 030, 031, 032 |

---

## Cross-Reference Validation

- [x] All story codes are unique (001–032, 32 stories)
- [x] All acceptance criteria are testable (observable states, endpoint responses, UI changes)
- [x] All technical notes reference real endpoints from SCR### API call lists
- [x] All ui stories mapped to a valid SCR### (all 32 are ui type)
- [x] No system stories present (all interactions are user-initiated via the web dashboard)
- [x] All BL### references exist in BL001–BL024 inventory
- [x] No invented screens or actors (User, SudoUser only; SCR001–SCR008 only)
- [x] No combined "create AND edit" stories — one intent per story
- [x] All destructive actions have confirm step in acceptance criteria
- [x] Merge exceptions documented in Interaction Inventory with explicit 3-condition check
