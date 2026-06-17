# Phase 04: Module View HTML Fragments

**Priority:** High
**Status:** Pending
**Blocked by:** Phase 03

## Files to Create

- `web/public/views/files.html`
- `web/public/views/cron.html`
- `web/public/views/time.html`
- `web/public/views/packages.html`
- `web/public/views/processes.html`
- `web/public/views/network.html`

Each file is a self-contained HTML fragment (no `<html>`/`<body>` tags).
Uses Alpine.js `x-data`, `x-on:click`, `x-show`, `x-for` directly.
Calls `window.$app.api()` for all API requests.
Each view defines its own `x-data` scope with local state.

---

## files.html

Sections:
1. **Find Large Files** — form: dir input + size threshold (default 100M) + Submit button
   - Result: table with columns `Size`, `Path`, per-row `Compress` + `Delete` action buttons
2. **Batch Delete** — form: dir + glob pattern + Preview button → shows match list → Confirm Delete
3. **Set Permissions** — form: dir, file mode, dir mode, owner → Submit
   - Show validation error inline if mode not octal

---

## cron.html

Sections:
1. **Current Cron Jobs** — table with `#`, `Entry` columns + `Delete` button per row. Auto-loads on mount.
2. **Add Cron Job** — 6 fields (min/hour/day/month/wday each with `*` default) + command input + Add button
   - Preview assembled entry before submit: `<code x-text="assembledEntry"></code>`
3. **Setup Daily Backup** — form: source dir, backup dest dir, schedule (default `0 0 * * *`) + Submit

---

## time.html

Sections:
1. **Current Status** — card showing current time, timezone, NTP status. Refresh button. Auto-loads on mount.
2. **Change Timezone** — text input with datalist (populated from `GET /api/time/timezones`). Filter-as-you-type. Submit button.
3. **NTP Sync** — two buttons: "Enable NTP" + "Check NTP Status". Status result shown in card below.

---

## packages.html

Sections:
1. **Detected Package Manager** — badge showing detected manager (apt/dnf/yum/pacman). Auto-loads on mount.
2. **Install Packages** — text input (space-separated names) + Install button
3. **Remove Package** — text input + checkbox "Purge config files" + Remove button
4. **System Update** — "Update & Upgrade" button → SSE stream output shown in scrollable log panel:
   ```html
   <div class="log-panel" x-html="updateLog"></div>
   ```
   SSE lines appended in real-time. "Done (exit code N)" shown when stream ends.
5. **Autoremove** — button + result card

---

## processes.html

Sections:
1. **Top Processes** — sort toggle (CPU / Memory) + table:
   Columns: `PID`, `User`, `%CPU`, `%MEM`, `Command` — auto-loads on mount, Refresh button.
   Per-row: `Kill (TERM)` button (red), `Force Kill (KILL)` button (dark red).
2. **Find by Port** — port number input + Search button → result card showing process name + PID.

Kill flow:
- Click Kill → confirm dialog (Alpine modal) → POST `/api/processes/kill`
- Show toast "SIGTERM sent to PID X" on success

---

## network.html

Sections:
1. **Listening Ports** — table: `Proto`, `Local Address`, `State`, `Process`. Auto-loads. Refresh button.
2. **Network Interfaces** — cards per interface: name, IPv4, IPv6, state badge (UP=green, DOWN=red).
3. **Routing Table** — table: `Destination`, `Gateway`, `Interface`. Default route highlighted in blue.
4. **Test Connectivity** — host input + port input (default 80) + Test button → result card with ping + TCP results.
5. **DNS Lookup** — hostname/IP input + Lookup button → result card.
6. **Firewall Status** — "Check Firewall" button → pre-formatted output card.

---

## Shared UI Patterns (apply consistently across all views)

```html
<!-- Loading state -->
<div x-show="loading" class="spinner"></div>

<!-- Error state -->
<div x-show="error" class="alert alert-error" x-text="error"></div>

<!-- Empty state -->
<div x-show="!loading && items.length === 0" class="empty-state">No items found</div>

<!-- Confirm modal -->
<div x-show="confirm.visible" class="modal-overlay">
  <div class="modal">
    <p x-text="confirm.message"></p>
    <button x-on:click="confirm.resolve(true)">Confirm</button>
    <button x-on:click="confirm.resolve(false)">Cancel</button>
  </div>
</div>
```

## Success Criteria

- All 6 views load without JS errors
- Tables render data from API responses correctly
- Forms validate inputs client-side (empty check, octal check for modes) before submitting
- SSE log panel in packages.html streams and scrolls to bottom automatically
- Kill confirmation modal prevents accidental SIGKILL
- Responsive on 1280px screens
