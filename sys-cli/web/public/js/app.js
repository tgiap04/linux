// sys-cli Alpine.js application component
// Loaded before alpine.min.js (which carries defer) so sysApp() is defined
// when Alpine initializes.

function sysApp() {
  return {
    activeModule: 'processes',
    views: {},
    loading: false,
    toast: { visible: false, message: '', type: 'info' },

    async init() {
      await this.loadModule(this.activeModule)
    },

    async loadModule(name) {
      this.activeModule = name
      if (!this.views[name]) {
        this.loading = true
        try {
          const res = await fetch('/views/' + name + '.html')
          if (!res.ok) throw new Error('Failed to load view (HTTP ' + res.status + ')')
          this.views[name] = await res.text()
        } catch (e) {
          this.views[name] = '<div class="alert alert-error">Failed to load module: ' + e.message + '</div>'
        } finally {
          this.loading = false
        }
      }
      // After x-html updates the DOM, tell Alpine to initialize any new components
      this.$nextTick(() => {
        const slot = document.querySelector('[x-show="activeModule === \'' + name + '\'"]')
        if (slot) Alpine.initTree(slot)
      })
    },

    showToast(msg, type) {
      type = type || 'info'
      this.toast = { visible: true, message: msg, type: type }
      var self = this
      setTimeout(function () { self.toast.visible = false }, 3500)
    },

    async api(method, path, body) {
      var opts = { method: method, headers: { 'Content-Type': 'application/json' } }
      if (body !== undefined && body !== null) {
        opts.body = JSON.stringify(body)
      }
      var res = await fetch('/api' + path, opts)
      var json = await res.json()
      if (!res.ok) throw new Error(json.error || 'Request failed')
      return json.data
    }
  }
}
