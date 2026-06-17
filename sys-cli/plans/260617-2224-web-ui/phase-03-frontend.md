# Phase 03: Frontend Shell — index.html + CSS + Alpine.js

**Priority:** High
**Status:** Pending
**Blocked by:** Phase 01

## Files to Create

- `web/public/index.html`
- `web/public/css/style.css`
- `web/public/js/app.js`
- `web/public/js/alpine.min.js` (vendor — download from cdn.jsdelivr.net/npm/alpinejs)
- `web/public/js/htmx.min.js` (vendor — download from unpkg.com/htmx.org)

## index.html Structure

```
<html>
  <head> title, meta, link style.css </head>
  <body x-data="sysApp()">
    <!-- Sidebar navigation -->
    <nav> 6 module buttons, each sets activeModule </nav>

    <!-- Main content area -->
    <main>
      <!-- Dynamic view loaded by Alpine based on activeModule -->
      <div x-show="activeModule === 'files'"   x-html="views.files"></div>
      <div x-show="activeModule === 'cron'"    x-html="views.cron"></div>
      <div x-show="activeModule === 'time'"    x-html="views.time"></div>
      <div x-show="activeModule === 'packages'" x-html="views.packages"></div>
      <div x-show="activeModule === 'processes'" x-html="views.processes"></div>
      <div x-show="activeModule === 'network'" x-html="views.network"></div>
    </main>

    <!-- Toast notification area -->
    <div x-show="toast.visible" x-text="toast.message"></div>

    <script src="/js/alpine.min.js"></script>
    <script src="/js/htmx.min.js"></script>
    <script src="/js/app.js"></script>
  </body>
</html>
```

## app.js — Alpine component

```js
function sysApp() {
  return {
    activeModule: 'processes',  // default landing page
    views: {},                  // cached HTML fragments per module
    toast: { visible: false, message: '', type: 'info' },

    async init() {
      await this.loadModule(this.activeModule)
    },

    async loadModule(name) {
      this.activeModule = name
      if (!this.views[name]) {
        const res = await fetch(`/views/${name}.html`)
        this.views[name] = await res.text()
      }
    },

    showToast(msg, type = 'info') {
      this.toast = { visible: true, message: msg, type }
      setTimeout(() => this.toast.visible = false, 3500)
    },

    // Generic API helper — used by view scripts
    async api(method, path, body) {
      const opts = { method, headers: { 'Content-Type': 'application/json' } }
      if (body) opts.body = JSON.stringify(body)
      const res = await fetch('/api' + path, opts)
      const json = await res.json()
      if (!res.ok) throw new Error(json.error || 'Request failed')
      return json.data
    }
  }
}
```

## style.css — Design system

Dashboard layout:
- Sidebar: 220px fixed left, dark bg (`#1e293b`), white text
- Main: remaining width, light bg (`#f1f5f9`)
- Nav items: hover highlight, active = accent color (`#3b82f6`)
- Cards: white bg, `border-radius: 8px`, `box-shadow`, `padding: 1.5rem`
- Tables: full width, striped rows, sticky header
- Buttons: primary (blue), danger (red), secondary (gray) — consistent sizing
- Toast: fixed bottom-right, color by type (info=blue, success=green, error=red)
- Loading spinner: CSS-only, shown during fetch
- Responsive: sidebar collapses to top nav on narrow screens (≤768px)
- Monospace font for command output / paths: `font-family: 'Courier New', monospace`

## Success Criteria

- `GET /` serves index.html
- Navigation switches between modules without page reload
- Alpine.js renders views from `/views/*.html` fragments
- Toast appears and auto-dismisses after 3.5s
- Layout is clean on 1280px+ screens
- Alpine + htmx load from local vendor files (no CDN dependency at runtime)
