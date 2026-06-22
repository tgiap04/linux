# Feature List

**Project**: KMA OS / sys-cli / package-hiding
**Generated**: 2026-06-22

---

## Feature Hierarchy

| # | Name | Priority | Type | Language | Workspace | Linked US | Linked SCR |
|---|------|----------|------|----------|-----------|-----------|------------|
| 001 | Module Navigation & Layout | High | ui | JavaScript / Bash | sys-cli/web | 001 | SCR001 |
| 002 | File System Browser | High | ui | JavaScript / Bash | sys-cli/web | 003–004 | SCR002 |
| 003 | File CRUD Operations | High | ui | JavaScript / Bash | sys-cli/web | 005–008 | SCR002 |
| 004 | Cron Job Management | High | ui | JavaScript / Bash | sys-cli/web | 009–010 | SCR003 |
| 005 | System Time & Timezone | High | ui | JavaScript / Bash | sys-cli/web | 011–014 | SCR004 |
| 006 | Package Installation & Removal | High | ui | JavaScript / Bash | sys-cli/web | 015–016 | SCR005 |
| 007 | System Package Update & Cleanup | High | ui | JavaScript / Bash | sys-cli/web | 017–019 | SCR005 |
| 008 | Process Management | High | ui | JavaScript / Bash | sys-cli/web | 020–022 | SCR006 |
| 009 | Network Inspection | Medium | ui | JavaScript / Bash | sys-cli/web | 023–025 | SCR007 |
| 010 | Network Connectivity Testing | Medium | ui | JavaScript / Bash | sys-cli/web | 026–027 | SCR007 |
| 011 | Kernel Firewall Status | High | ui | JavaScript / Bash | sys-cli/web | 028 | SCR008 |
| 012 | Kernel Firewall Control | High | ui | JavaScript / Bash | sys-cli/web | 029–032 | SCR008 |
| 013 | KMA Kernel Branding | Low | background | C | KMA-OS/kernel-modules/kma-branding | (none) | (none) |
| 014 | VFS Inode Protection | High | background | C | KMA-OS/kernel-modules/kma-vfs-guard | (none) | (none) |
| 015 | Covert Channel Transmission | Medium | background | C / Python | package-hiding/src | (none) | (none) |
| 016 | Sudo Authentication | High | ui | JavaScript / Bash | sys-cli/web | 002 | (global) |

---

## F001_ModuleNavigation: Module Navigation & Layout

**Priority**: High
**Status**: Implemented
**Actors**: User, SudoUser

**Description**: Provides the main navigation shell (sidebar) for switching between the 7 module screens, along with the toast notification system and lazy-loaded module view container.

**Linked US**: US001
**Linked SCR**: SCR001
**Linked BL**: BL001, BL015

**Acceptance Criteria**:
- Sidebar displays 7 module links; clicking each loads the correct module view
- Default module on load is `processes`
- Toast notifications appear for 3.5 s and auto-dismiss

---

## F002_FileSystemBrowser: File System Browser

**Priority**: High
**Status**: Implemented
**Actors**: User, SudoUser

**Description**: Lets any user browse the directory tree at configurable depth and locate large files above a size threshold.

**Linked US**: US003, US004
**Linked SCR**: SCR002
**Linked BL**: BL002, BL020

**Acceptance Criteria**:
- Directory tree loads for a given path at depth 1–5
- Large-file list returns files above specified byte threshold in given directory
- Both panels display loading and error states

---

## F003_FileCrud: File CRUD Operations

**Priority**: High
**Status**: Implemented
**Actors**: SudoUser

**Description**: Allows privileged users to delete, rename, and create files and directories, with confirmation dialogs guarding destructive actions.

**Linked US**: US005, US006, US007, US008
**Linked SCR**: SCR002
**Linked BL**: BL002, BL020

**Acceptance Criteria**:
- Glob-pattern delete removes matching files; confirm dialog shown before execution
- Path delete requires sudo; confirm dialog shown
- Rename requires sudo; modal prompts for new name
- Create (file or dir) requires sudo; modal prompts for name and type
- All operations surface success/error feedback

---

## F004_CronJobManagement: Cron Job Management

**Priority**: High
**Status**: Implemented
**Actors**: User, SudoUser

**Description**: Provides a UI to list, add, and delete user crontab entries, with a live preview of the crontab line as fields are filled in.

**Linked US**: US009, US010
**Linked SCR**: SCR003
**Linked BL**: BL003, BL019

**Acceptance Criteria**:
- Cron job list displays all non-comment crontab entries on load
- Add form builds a valid crontab line; duplicate entries are silently skipped
- Delete removes the entry at the given 1-based index; confirm dialog shown
- Live crontab preview updates as schedule fields change

---

## F005_SystemTime: System Time & Timezone

**Priority**: High
**Status**: Implemented
**Actors**: SudoUser (set operations), User (view operations)

**Description**: Displays current system time, timezone, and NTP status; allows privileged users to change the timezone and enable NTP synchronization.

**Linked US**: US011, US012, US013, US014
**Linked SCR**: SCR004
**Linked BL**: BL004, BL022

**Acceptance Criteria**:
- Current time, timezone, and NTP sync status displayed on load
- Timezone filter narrows list to max 50 matches; Set Timezone applies via timedatectl (sudo)
- Enable NTP triggers timedatectl NTP enable (sudo)
- NTP status panel shows raw timedatectl output on demand

---

## F006_PackageInstallRemove: Package Installation & Removal

**Priority**: High
**Status**: Implemented
**Actors**: SudoUser

**Description**: Lets privileged users install named packages (space/comma-separated) and remove/purge packages via the detected system package manager.

**Linked US**: US015, US016
**Linked SCR**: SCR005
**Linked BL**: BL005, BL021

**Acceptance Criteria**:
- Package manager detected on screen init (apt/dpkg)
- Install accepts one or more package names; result shown on completion
- Remove form accepts package name with optional purge checkbox
- Both operations require sudo; error feedback shown on failure

---

## F007_PackageUpdateCleanup: System Package Update & Cleanup

**Priority**: High
**Status**: Implemented
**Actors**: SudoUser

**Description**: Streams a full system package update to the browser via SSE and allows autoremoval of orphan packages; also provides a searchable installed-package panel.

**Linked US**: US017, US018, US019
**Linked SCR**: SCR005
**Linked BL**: BL005, BL021

**Acceptance Criteria**:
- Start Update obtains a one-time sudo token then opens SSE stream; output scrolls in real time
- Autoremove runs apt autoremove (sudo); result shown on completion
- Installed-package panel loads on demand; search input filters the list; per-row Remove button removes package (sudo)

---

## F008_ProcessManagement: Process Management

**Priority**: High
**Status**: Implemented
**Actors**: User (view), SudoUser (kill)

**Description**: Lists all running processes sortable by CPU or memory, allows killing a process by PID with signal selection, and identifies which process owns a given port.

**Linked US**: US020, US021, US022
**Linked SCR**: SCR006
**Linked BL**: BL006, BL017

**Acceptance Criteria**:
- Process table loads on init sorted by CPU; toggle switches to MEM sort
- Kill dialog shows signal choice (TERM/KILL/HUP); confirmation required; sudo required
- Port lookup returns the process owning the given port or an empty result

---

## F009_NetworkInspection: Network Inspection

**Priority**: Medium
**Status**: Implemented
**Actors**: User, SudoUser

**Description**: Provides a three-tab view of listening sockets, network interfaces, and routing table, each loaded on first tab activation.

**Linked US**: US023, US024, US025
**Linked SCR**: SCR007
**Linked BL**: BL007, BL018

**Acceptance Criteria**:
- Ports tab shows listening sockets (proto, addr, port, process) via `ss`
- Interfaces tab shows interface cards (name, addresses, state) via `ip addr show`
- Routes tab shows routing table rows via `ip route show`
- Each tab loads only on first activation; per-tab loading/error states shown

---

## F010_NetworkConnectivity: Network Connectivity Testing

**Priority**: Medium
**Status**: Implemented
**Actors**: User, SudoUser

**Description**: Allows users to test host reachability via ping and resolve domain names via DNS lookup.

**Linked US**: US026, US027
**Linked SCR**: SCR007
**Linked BL**: BL007, BL018

**Acceptance Criteria**:
- Ping form accepts host + optional port; result panel shows success/failure output
- DNS lookup accepts domain name; result panel shows resolved addresses
- Both panels show error states on failure

---

## F011_FirewallStatus: Kernel Firewall Status

**Priority**: High
**Status**: Implemented
**Actors**: SudoUser

**Description**: Reads and displays the current state of the `ubuntu_firewall` kernel module (loaded/unloaded, enabled toggle, drop-ICMP flag, rejected ports) on screen init.

**Linked US**: US028
**Linked SCR**: SCR008
**Linked BL**: BL008, BL013, BL016

**Acceptance Criteria**:
- Module-not-loaded banner shown when `status.moduleLoaded === false`
- When loaded: enabled, drop_icmp, and reject_ports values displayed
- All status data read from sysfs via `/api/firewall/status` (sudo)

---

## F012_FirewallControl: Kernel Firewall Control

**Priority**: High
**Status**: Implemented
**Actors**: SudoUser

**Description**: Allows privileged users to toggle firewall rules, manage the port blocklist, and view kernel firewall log entries from dmesg.

**Linked US**: US029, US030, US031, US032
**Linked SCR**: SCR008
**Linked BL**: BL008, BL013, BL016

**Acceptance Criteria**:
- Enabled and drop_icmp toggles write to sysfs via `/api/firewall/toggle` (sudo)
- Add ports input accepts comma-separated values; merges/deduplicates with existing list (sudo)
- Per-port remove button removes a single port from the blocklist (sudo)
- View Logs panel shows last 50 dmesg entries matching firewall module (sudo)

---

## F013_KmaBranding: KMA Kernel Branding

**Priority**: Low
**Status**: Implemented
**Actors**: (none — kernel-only)

**Description**: Loadable kernel module that prints an ASCII KMA-OS banner to dmesg on `insmod`; no runtime interface or user-facing UI.

**Linked US**: (none)
**Linked SCR**: (none)
**Linked BL**: BL010

**Acceptance Criteria**:
- `insmod kma-branding.ko` emits the banner text to dmesg
- `rmmod` succeeds without errors
- No sysfs or procfs interface exposed

---

## F014_VfsGuard: VFS Inode Protection

**Priority**: High
**Status**: Implemented
**Actors**: (none — kernel LSM enforced)

**Description**: LSM (Linux Security Module) hooks that prevent deletion or renaming of protected directory inodes registered via sysfs; available as both a loadable module and a built-in kernel variant.

**Linked US**: (none)
**Linked SCR**: (none)
**Linked BL**: BL011, BL012

**Acceptance Criteria**:
- Protected paths registered via `echo /path > /sys/kma_vfs_guard/add_path`
- `unlink` / `rmdir` / `rename` on protected inodes returns `-EPERM`
- Hash table uses RCU for lockless reads; insert/delete uses spinlock
- Both loadable (kma-vfs-guard.c) and built-in (vfs_guard.c) variants compile and pass LSM hooks

---

## F015_CovertChannel: Covert Channel Transmission

**Priority**: Medium
**Status**: Implemented
**Actors**: (none — CLI/kernel only)

**Description**: Steganographic covert channel that embeds hidden message bytes into TCP sequence numbers (low 8 bits) or UDP IP Identification fields (low 8 bits) via a Netfilter kernel hook; receivers decode on the other end.

**Linked US**: (none)
**Linked SCR**: (none)
**Linked BL**: BL014, BL023, BL024

**Acceptance Criteria**:
- Sender embeds 1 byte per packet using start (0xFF00) / data / end (0x00FF) framing
- TCP embed recalculates IP and TCP checksums after modification
- UDP embed recalculates IP checksum only
- Receiver reconstructs message by extracting framed bytes from matching packets
- `covert_framing_set_message` returns `-BUSY` when a send is already in progress

---

## F016_SudoAuthentication: Sudo Authentication

**Priority**: High
**Status**: Implemented
**Actors**: User (initiates), SudoUser (result)

**Description**: Cross-cutting sudo password modal that intercepts any privileged API call from any screen, verifies credentials via `/api/sudo/verify`, and replays the original request on success; issues a one-time token for SSE streams.

**Linked US**: US002
**Linked SCR**: (global — triggered from SCR002, SCR003, SCR004, SCR005, SCR006, SCR007, SCR008)
**Linked BL**: BL015

**Acceptance Criteria**:
- Sudo modal appears when any privileged action is triggered from any screen
- On success, original request is replayed with sudo credentials
- One-time token issued for SSE stream operations
- On failure, error shown in modal; original request not replayed

---

## Cross-Reference Validation

- [x] All 32 user stories covered by at least one feature
- [x] All 8 screens (SCR001–SCR008) covered by at least one feature
- [x] No orphan story or screen references
- [x] All 16 feature codes unique (001–016)

---

## Summary

- **Total Features**: 16
- **With web UI**: 13 features (001–012, 016, linked to SCR001–SCR008)
- **Kernel/CLI only**: 3 features (013–015, no web UI)
- **US coverage**: 32 stories covered (001–032)
- **SCR coverage**: SCR001–SCR008 (all 8 screens covered)
