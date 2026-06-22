---
failed: 10
warnings: 8
result: FAIL
---

# Review Report — Rebuild-Spec Artifacts

**Reviewer**: Staff Engineer (automated)
**Date**: 2026-06-22
**Scope**: 11 core artifacts (0 feature specs)

---

## Summary

| Metric | Value |
|--------|-------|
| Artifacts reviewed | 11 core + 0 feature specs |
| Critical issues | 10 |
| Warnings | 8 |
| Missing (`.pending` markers) | 0 |
| Result | **FAIL** |

---

## Critical Issues

### C1: SystemOverview — Missing Required Sections — OPEN
- **Severity**: critical
- **Location**: `system-overview.md:1`
- **Description**: Required sections `## System Architecture` (with `### High-Level Architecture` Mermaid graph TB and `### Technology Stack` Layer|Technology|Version table) and `## Data Flow` (Mermaid sequenceDiagram) are absent. The artifact has Key Design Decisions, Security Overview, and Scalability but no architecture Mermaid diagram and no data-flow diagram. Template order is violated.
- **Fix**: Add `## System Architecture` section containing `### High-Level Architecture` (Mermaid graph TB) and `### Technology Stack` table (Layer|Technology|Version columns). Add `## Data Flow` section with a Mermaid sequenceDiagram illustrating end-to-end data flow.

---

### C2: Permissions — Missing Required Sections (wrong template) — OPEN
- **Severity**: critical
- **Location**: `permissions.md:1`
- **Description**: The artifact does not follow `permissions-template.md`. Required sections `## Authorization System Type`, `## Curated View`, `## Access Boundaries`, `## Special Conditions` are all absent. The file uses `## User (unauthenticated)`, `## SudoUser`, `## Kernel VFS Guard` headings — this is a raw matrix layout, not the curated-view template. The checklist also explicitly forbids PERM### codes in the curated view; although PERM codes aren't present, the structural mismatch is critical.
- **Fix**: Restructure permissions.md to match the template: add `## Authorization System Type` (value: `hybrid` — sudo-based elevated privilege + LSM kernel enforcement), `## Curated View` (plain-language summary), `## Access Boundaries` (who can do what), `## Special Conditions` (kernel LSM bypass note). Move current prose into those sections.

---

### C3: PermissionsMatrix — Missing Required Sections — OPEN
- **Severity**: critical
- **Location**: `permissions-matrix.md:1`
- **Description**: Required sections `## Permissions Index` (Code|Name|Type|Enforced At columns), individual `### PERM###: Name` subsections, `## Summary`, and `## Cross-Reference Validation` are absent. The file has `## Roles`, `## Permission Codes`, `## Actor × Permission Matrix`, `## Client-Side Permission Gates` — non-template structure. Each PERM### item is missing `Type` and `Enforced At` fields.
- **Fix**: Restructure to template. Add `## Permissions Index` table with Code|Name|Type|Enforced At. Add `### PERM###: Name` subsections for each of PERM001–PERM013 with Type, Enforced At, Description, Related Modules, and Permission Rules matrix. Add `## Summary` and `## Cross-Reference Validation`.

---

### C4: BehaviorLogic — Systematic Screen Mapping Errors — OPEN
- **Severity**: critical
- **Location**: `behavior-logic.md:78,92,106,120,207,219,231,243`
- **Description**: Eight BL items have wrong SCR### mappings. The CLI lib/*.sh menus (BL004–BL007) and their Node.js route counterparts (BL017, BL018, BL021, BL022) are systematically cross-mapped by one position. Specific errors:
  - BL004_TimeMgmtMenu → `Screens: SCR007` (correct: SCR004)
  - BL005_PkgMgmtMenu → `Screens: SCR006` (correct: SCR005)
  - BL006_ProcessMgmtMenu → `Screens: SCR004` (correct: SCR006)
  - BL007_NetworkMgmtMenu → `Screens: SCR005` (correct: SCR007)
  - BL017_ProcessesRoutes → `Screens: SCR004` (correct: SCR006)
  - BL018_NetworkRoutes → `Screens: SCR005` (correct: SCR007)
  - BL021_PackagesRoutes → `Screens: SCR006` (correct: SCR005)
  - BL022_TimeRoutes → `Screens: SCR007` (correct: SCR004)
- **Fix**: Correct all 8 Screens fields to the proper SCR###. SCR004=System Time, SCR005=Package Management, SCR006=Process Management, SCR007=Network & Sockets.

---

### C5: BehaviorLogic — Missing Required Sections — OPEN
- **Severity**: critical
- **Location**: `behavior-logic.md:1`
- **Description**: Required sections `## Background Logic Details` (as a distinct heading) and `## Cross-Reference Validation` are absent. The BL items are written directly without the `## Background Logic Details` wrapper heading. `## Cross-Reference Validation` is not present at the end of the artifact. `## Rule C3 Warnings` appears at line ~288 but this is not a required section.
- **Fix**: Add `## Background Logic Details` wrapper heading (or verify template allows omission). Add `## Cross-Reference Validation` section at the end.

---

### C6: BehaviorLogic — C (Kernel) Category Drop — OPEN
- **Severity**: critical
- **Location**: `behavior-logic.md:1`, `_scout-bl-inventory.md:22-39`
- **Description**: The C (Kernel) scout inventory lists `integration` as a category present with 5 entries (kma-branding.c, kma-vfs-guard.c, vfs_guard.c, covert_main.c, ubuntu_firewall.c — all under module_init/module_exit macros). The behavior-logic.md artifact contains zero BL items of type `integration` sourced from C files. All five C kernel files are represented with types `custom-command` or `middleware` only. Per Rule 2 (Category Drop): a category present in inventory with ≥1 entry must have ≥1 BL of matching type in the artifact.
- **Fix**: Either (a) add `integration`-typed BL items for the C kernel module_init/module_exit macro surface, or (b) if the scout's multi-category listing of the same file is intentional (same file under both middleware and integration), document a justification in the BL items' Description fields and raise a scout re-run request to clarify whether `integration` is a distinct source signal for these files.

---

### C7: ScreenFlow — Missing `## Feature Entry Points` Section — OPEN
- **Severity**: critical (checklist: `## Feature Entry Points` absent → warning; but the checklist rule states `{POPULATED_BY_W6}` raw token → critical; here the section is entirely absent which maps to warning per rule text)
- **Severity override**: warning (re-classified below — see W1)
- **Location**: see W1

---

### C7: FeatureList — Missing Required Sections — OPEN
- **Severity**: critical
- **Location**: `feature-list.md:1`
- **Description**: `## Feature Hierarchy` section is absent — the artifact has `## Feature Index` instead, which lacks the required columns `Type|Language|Workspace`. The column structure is `#|Name|Priority|Linked US|Linked SCR`, missing `Type` (ui/background/mixed), `Language`, and `Workspace` per the template. `## Cross-Reference Validation` section is also absent.
- **Fix**: Rename `## Feature Index` to `## Feature Hierarchy` and add `Type`, `Language`, `Workspace` columns to each row. Add `## Cross-Reference Validation` section listing all cross-validated codes.

---

### C8: BehaviorLogic — BL items missing required fields (Trigger, Related Modules) — OPEN
- **Severity**: critical
- **Location**: `behavior-logic.md:42–277` (all BL entries)
- **Description**: The checklist requires each BL item to have `Type + Trigger + Description + Related Modules + Source File + Source Symbol`. Every BL entry in this artifact is missing `**Trigger**` and `**Related Modules**` fields. Only Type, Source File, Source Symbol, Description, and Screens are present.
- **Fix**: Add `**Trigger**` field (e.g., "CLI menu selection", "HTTP request", "kernel module_init", "insmod") and `**Related Modules**` field (cross-references to BL###/MODEL###/ROUTE### as applicable) to each BL entry.

---

### C9: BehaviorLogic — BL015_ShellExecutor Source Symbol mismatch — OPEN
- **Severity**: critical
- **Location**: `behavior-logic.md:183`
- **Description**: BL015_ShellExecutor has `Source Symbol: exec` but the Description says "wraps child_process.exec with sudo token injection" and the architecture doc names the function `runSudo()`. The symbol `exec` is a Node.js built-in, not the module's own symbol. This violates the Source Symbol accuracy requirement.
- **Fix**: Correct Source Symbol to `runSudo` (the actual exported function from shell.js per architecture.md description) or to the true exported symbol found in the source file.

---

### C10: BehaviorLogic — Realtime SSE pattern undocumented in Client-Side Logic — OPEN
- **Severity**: critical
- **Location**: `behavior-logic.md:307–311`
- **Description**: The `## Client-Side Logic → Realtime (WebSocket / SSE / EventSource)` subsection states "N/A — no realtime patterns detected." However, `GET /api/packages/update/stream` is an SSE endpoint explicitly documented in route-list.md, screen-list.md (SCR005), screen-flow.md, and user-stories.md (US017). EventSource/SSE is a realtime pattern that must be documented here.
- **Fix**: Replace "N/A" with a description of the SSE stream: EventSource opened at `/api/packages/update/stream?_sudo_token=`; log lines streamed to SCR005 update panel; stream closed on `done` event. Sudo one-time token obtained via `POST /api/sudo/verify` before stream open.

---

## Warnings

### W1: ScreenFlow — Missing `## Feature Entry Points` Section — OPEN
- **Severity**: warning
- **Location**: `screen-flow.md:1`
- **Description**: The checklist states: "`## Feature Entry Points` section absent from screen-flow.md → warning". Section is not present in the artifact.
- **Fix**: Add `## Feature Entry Points` section mapping each feature (F001–F016) to its entry screen and trigger condition.

---

### W2: RouteList — Summary Count Mismatch — OPEN
- **Severity**: warning
- **Location**: `route-list.md:212`
- **Description**: The Summary table states Web API confirmed count = 27. Actual route count from the documented tables: `/api/sudo/verify`(1) + firewall(5) + processes(3) + network(5) + cron(4) + files(6) + packages(6) + time(5) = 35. Discrepancy of 8 routes — the count is wrong.
- **Fix**: Update the Summary table Web API count to 35 (or recount from the actual tables and correct).

---

### W3: SystemOverview — Missing `## Executive Summary` sub-sections for Technology Stack — OPEN
- **Severity**: warning
- **Location**: `system-overview.md:5`
- **Description**: The executive summary is present as a paragraph but the required `### Technology Stack` table (Layer|Technology|Version columns) is absent from the overview. Architecture.md has a tech stack table but system-overview.md is expected to carry its own.
- **Fix**: Add `### Technology Stack` table in `## System Architecture` section with Layer, Technology, and Version columns (Linux 7.0.0, Node.js+Express 4, Bash, Python+Scapy).

---

### W4: BehaviorLogic — BL023/BL024 Python files not in scout inventory — OPEN
- **Severity**: warning
- **Location**: `behavior-logic.md:262,270`
- **Description**: BL023_UdpReceiver and BL024_TcpReceiver have source files in `package-hiding/src/receiver/` which are absent from the Python section of scout inventory (which states "_(none found)_"). The BL items carry [SIGNAL_INFERRED] tags and Rule C3 warnings in-document. Scout should be re-run with Python receiver subtree in scope.
- **Fix**: Re-run scout with Python subtree inclusion, or manually verify files exist and add justification in Description confirming the file was discovered post-scout.

---

### W5: PermissionsMatrix — PERM codes missing Type and Enforced At — OPEN
- **Severity**: warning (already escalated to C3 as critical for missing sections; this is a secondary warning for individual items)
- **Location**: `permissions-matrix.md:16–29`
- **Description**: All PERM001–PERM013 entries in the Permission Codes table lack `Type` (valid values: route-guard, screen-permission, action-permission, etc.) and `Enforced At` fields.
- **Fix**: Addressed by C3 fix — adding `### PERM###` subsections will include these fields.

---

### W6: BehaviorLogic — Inferred ratio for Bash stack — OPEN
- **Severity**: warning
- **Location**: `_scout-bl-inventory.md:3–20`, `behavior-logic.md:1`
- **Description**: All 7 Bash inventory entries are tagged [SIGNAL_INFERRED]. Stack inventory count = 7, inferred count = 7, ratio = 100% (> 50% threshold → critical per Rule 5). However, for MULTI_STACK projects the task brief notes [SIGNAL_INFERRED] applies because no standard framework routing patterns exist for Bash. Rule 5 exempts stacks "outside the bl-source-patterns.md table" — Bash is likely not in that table, so the guard may not fire. Flagged as warning pending confirmation that Bash is exempt from Rule 5.
- **Fix**: Confirm Bash is in the bl-source-patterns.md exempt list. If not exempt, re-run scout with explicit Bash glob patterns to reduce inferred ratio.

---

### W7: UserStories — manage:cron User permission not reflected in actor split — OPEN
- **Severity**: warning
- **Location**: `user-stories.md:66,72`
- **Description**: US009 and US010 are authored as "As a User" which is correct per permissions-matrix.md (manage:cron granted to User). However, US009 acceptance criteria states "No sudo required (crontab runs as current user)" — this is correct and consistent. No actual violation, but the Permissions checklist cross-ref on actor split should be explicitly noted as verified.
- **Fix**: No change required; noting as confirmed pass.

---

### W8: Architecture — Unresolved Questions present in released artifact — OPEN
- **Severity**: warning
- **Location**: `architecture.md:142–145`
- **Description**: The `## Unresolved Questions` section contains 3 open items about tcp_embed.c/udp_embed.c exact subfield, SPA bundling method, and Python receiver reassembly logic. While unresolved questions are not forbidden, their presence in a spec artifact signals incomplete source verification.
- **Fix**: Resolve by reading the referenced source files or mark explicitly as known gaps with no functional impact on the spec.

---

## BehaviorLogic Cardinality

- Inventory total (Bash): 7 | Artifact BL count (Bash): 9 | Abs gap: 2 — **PASS** (small-project floor ≤2)
- Inventory total (C Kernel, unique files): 5 | Artifact BL count (C): 5 | Abs gap: 0 — **PASS**
- C Kernel — category drop: `integration` present in inventory (5 entries), 0 BL items of type `integration` for C files — **CRITICAL** (see C6)
- Inventory total (Node.js): 8 | Artifact BL count (Node.js): 8 | Abs gap: 0 — **PASS**
- Inventory total (Python): 0 | Artifact BL count (Python): 2 | Abs gap: 2 — **PASS** (small-project floor ≤2; BL023/BL024 flagged [SIGNAL_INFERRED] — see W4)
- Missing categories: C `integration` (see C6)
- Orphan files: BL001_SysCliMain sources `sys-cli/sys-cli.sh` — not in Bash inventory (lib/ scope only); BL023/BL024 source files not in Python inventory

---

## Passed Checks

✓ Universal.artifact_exists_non_empty @ system-overview.md
✓ Universal.artifact_exists_non_empty @ architecture.md
✓ Universal.artifact_exists_non_empty @ route-list.md
✓ Universal.artifact_exists_non_empty @ data-model.md
✓ Universal.artifact_exists_non_empty @ screen-list.md
✓ Universal.artifact_exists_non_empty @ screen-flow.md
✓ Universal.artifact_exists_non_empty @ behavior-logic.md
✓ Universal.artifact_exists_non_empty @ permissions.md
✓ Universal.artifact_exists_non_empty @ permissions-matrix.md
✓ Universal.artifact_exists_non_empty @ user-stories.md
✓ Universal.artifact_exists_non_empty @ feature-list.md
✓ Universal.no_placeholder_text @ system-overview.md
✓ Universal.no_placeholder_text @ architecture.md
✓ Universal.no_placeholder_text @ route-list.md
✓ Universal.no_placeholder_text @ data-model.md
✓ Universal.no_placeholder_text @ screen-list.md
✓ Universal.no_placeholder_text @ screen-flow.md
✓ Universal.no_placeholder_text @ behavior-logic.md
✓ Universal.no_placeholder_text @ permissions.md
✓ Universal.no_placeholder_text @ permissions-matrix.md
✓ Universal.no_placeholder_text @ user-stories.md
✓ Universal.no_placeholder_text @ feature-list.md
✓ Architecture.mermaid_present @ architecture.md
✓ Architecture.technology_accuracy @ architecture.md
✓ RouteList.no_duplicate_routes @ route-list.md
✓ RouteList.sysfs_interfaces_documented @ route-list.md
✓ DataModel.entity_completeness @ data-model.md
✓ DataModel.disc_scope @ data-model.md
✓ DataModel.MODEL_uniqueness @ data-model.md
✓ DataModel.DISC_anchor @ data-model.md
✓ DataModel.validation_rules_present @ data-model.md
✓ DataModel.no_boolean_discriminators @ data-model.md
✓ ScreenList.no_duplicate_SCR_codes @ screen-list.md
✓ ScreenList.all_screens_have_US_mapped @ screen-list.md
✓ ScreenList.all_screens_have_routes @ screen-list.md
✓ ScreenList.scope_correctly_limited_to_web_ui @ screen-list.md
✓ ScreenFlow.all_SCR_in_ScreenList_present @ screen-flow.md
✓ ScreenFlow.no_circular_nav @ screen-flow.md
✓ ScreenFlow.CLI_flow_documented @ screen-flow.md
✓ ScreenFlow.mermaid_flowchart_present @ screen-flow.md
✓ BehaviorLogic.BL_codes_unique @ behavior-logic.md
✓ BehaviorLogic.BL_format_valid @ behavior-logic.md
✓ BehaviorLogic.valid_type_values @ behavior-logic.md
✓ BehaviorLogic.cardinality_bash_gap @ behavior-logic.md
✓ BehaviorLogic.cardinality_c_gap @ behavior-logic.md
✓ BehaviorLogic.cardinality_nodejs_gap @ behavior-logic.md
✓ BehaviorLogic.cardinality_python_gap @ behavior-logic.md
✓ BehaviorLogic.inferred_BL023_BL024_flagged @ behavior-logic.md
✓ BehaviorLogic.no_exclusion_pattern_leak @ behavior-logic.md
✓ PermissionsMatrix.PERM_codes_unique @ permissions-matrix.md
✓ PermissionsMatrix.roles_defined @ permissions-matrix.md
✓ PermissionsMatrix.matrix_table_present @ permissions-matrix.md
✓ PermissionsMatrix.client_side_gates_documented @ permissions-matrix.md
✓ UserStories.US_codes_unique @ user-stories.md
✓ UserStories.interaction_inventory_present @ user-stories.md
✓ UserStories.all_US_have_SCR_mapped @ user-stories.md
✓ UserStories.all_US_referenced_by_F @ user-stories.md
✓ UserStories.no_compound_stories @ user-stories.md
✓ UserStories.destructive_actions_have_confirm @ user-stories.md
✓ UserStories.UI_US_count_ge_SCR_count @ user-stories.md
✓ UserStories.actor_split_consistent_with_permissions @ user-stories.md
✓ UserStories.acceptance_criteria_testable @ user-stories.md
✓ FeatureList.F_codes_unique @ feature-list.md
✓ FeatureList.all_US_referenced @ feature-list.md
✓ FeatureList.all_SCR_referenced @ feature-list.md
✓ FeatureList.all_BL_mapped_to_F @ feature-list.md
✓ FeatureList.kernel_only_features_no_SCR @ feature-list.md
✓ FeatureList.feature_count_16 @ feature-list.md

---

## Metrics

| Metric | Value |
|--------|-------|
| Feature Specs | 0 |
| User Stories | 32 |
| Screens | 8 |
| Background Logic Items | 24 |
| Permissions | 13 |
| Backend Route Rows | 35 (summary says 27 — see W2) |
| Frontend Pages | 8 (SCR001–SCR008) |
| Data Model Entities | 7 |
