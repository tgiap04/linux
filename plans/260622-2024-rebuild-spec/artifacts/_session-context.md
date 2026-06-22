# Session Context — rebuild-spec

<!-- Generated: 2026-06-22T13:28:35Z  | Plan: /Users/tgiap.dev/devs/linux/plans/260622-2024-rebuild-spec -->
<!-- All subagents in this session MUST read this file before any other artifact read. -->

## Stack
- detectedStack: C (kernel modules), Bash, Python, JavaScript (Node.js), HTML, CSS [MULTI_STACK — all stacks: C (kernel modules), Bash, Python, JavaScript (Node.js/Express), HTML/CSS]
- isMultiStack: False
- stackNote: C (kernel modules), Bash, Python, JavaScript (Node.js) [MULTI_STACK — all stacks: C (kernel modules), Bash, Python, JavaScript (Node.js/Express), HTML/CSS; apply union of signals for all listed stacks in H-rule tables]

## Counts
- feature_count: <pending-W5>

## Always-read pointers (use Read tool, not Grep)
- plans/260622-2024-rebuild-spec/artifacts/system-overview.md  — global narrative (small)
- claude/skills/rebuild-spec/references/code-formats.md  — code schemas

## Grep-only pointers (DO NOT load in full)
- plans/260622-2024-rebuild-spec/artifacts/scout-report.md  — file inventory + BL inventory; section-scoped reads only
- plans/260622-2024-rebuild-spec/artifacts/feature-list.md  — per-F### entries; grep by code
- plans/260622-2024-rebuild-spec/artifacts/user-stories.md  — per-US### sections
- plans/260622-2024-rebuild-spec/artifacts/screen-list.md, screen-flow.md, behavior-logic.md, permissions.md, route-list.md, data-model.md

## Templates (read once per task, not per check)
- claude/skills/rebuild-spec/templates/feature-spec-template.md
- claude/skills/rebuild-spec/templates/review-report-template.md
- claude/skills/rebuild-spec/templates/scout-report-template.md

## Contracts
- claude/skills/rebuild-spec/references/feature-spec-researcher-contract.md
- claude/skills/rebuild-spec/references/verification-checklist-universal.md
- claude/skills/rebuild-spec/references/verification-checklist-core-artifacts.md (W7a)
- claude/skills/rebuild-spec/references/verification-checklist-feature-spec.md (W7b)
- claude/skills/rebuild-spec/references/verification-checklist-screen-spec.md (SS.2)
- claude/skills/rebuild-spec/references/verification-checklist-quality-gates.md (W4.5/W5.6)
- claude/skills/rebuild-spec/references/canonical-fcode-schema.md

## Reminders (avoid these wastes)
1. Do NOT re-derive detectedStack from scout-report; it's above.
2. Do NOT load scout-report.md in full — Grep `## Background Logic Source Inventory` section if you need BL inventory.
3. Do NOT re-summarize system-overview.md across multiple steps — read once.
4. Do NOT write multi-line PASS evidence — see review-report-template.md § Passed Checks rule.
5. On successful primary output write (spec.md / review-report.md), call `TaskUpdate(status=completed)` on your own task id (see phase-06 self-close rule).
