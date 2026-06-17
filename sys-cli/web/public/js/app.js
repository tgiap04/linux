// sys-cli Alpine.js application component
// Loaded before alpine.min.js (which carries defer) so sysApp() is defined
// when Alpine initializes.

// Alpine store — exposes showToast and api to child components that can't reach $root.
// Child components use: Alpine.store('app').showToast(...) / Alpine.store('app').api(...)
// _instance is set by sysApp.init() so store methods can call back into the parent component.
document.addEventListener('alpine:init', function () {
  Alpine.store('app', {
    _instance: null,
    showToast: function (msg, type) {
      if (this._instance) return this._instance.showToast(msg, type)
      // Fallback before init: custom event still works for toast bridge
      document.body.dispatchEvent(new CustomEvent('sys-toast', { detail: { msg: msg, type: type || 'info' } }))
    },
    api: function (method, path, body, _sudoPassword) {
      if (this._instance) return this._instance.api(method, path, body, _sudoPassword)
      return Promise.reject(new Error('App not initialized'))
    }
  })
})

function sysApp() {
  return {
    activeModule: 'processes',
    views: {},
    loading: false,
    toast: { visible: false, message: '', type: 'info' },

    // Sudo modal state
    sudo: {
      visible: false,
      password: '',
      error: '',
      loading: false,
      // Pending request to replay once password is confirmed
      _resolve: null,
      _reject: null,
      _pendingMethod: null,
      _pendingPath: null,
      _pendingBody: null,
    },

    async init() {
      // Register this instance so Alpine.store('app').api() and showToast() can call back
      Alpine.store('app')._instance = this

      // Listen for toast events from child components via Alpine.store('app').showToast
      var self = this
      document.body.addEventListener('sys-toast', function (e) {
        self.showToast(e.detail.msg, e.detail.type)
      })
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

    // Show sudo modal and return a Promise that resolves with the password once confirmed.
    _askSudoPassword(incorrect) {
      var self = this
      self.sudo.error = incorrect ? 'Incorrect password, please try again.' : ''
      self.sudo.password = ''
      self.sudo.loading = false
      self.sudo.visible = true
      return new Promise(function (resolve, reject) {
        self.sudo._resolve = resolve
        self.sudo._reject = reject
      })
    },

    // Called by the modal's Confirm button
    async sudoConfirm() {
      var pw = this.sudo.password
      if (!pw) return
      this.sudo.loading = true
      this.sudo.error = ''
      // Verify password first via cheap endpoint
      try {
        var vRes = await fetch('/api/sudo/verify', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-Sudo-Password': pw }
        })
        var vJson = await vRes.json()
        if (!vRes.ok) {
          this.sudo.loading = false
          this.sudo.error = vJson.error === 'incorrect_password'
            ? 'Incorrect password, please try again.'
            : (vJson.error || 'Verification failed')
          return
        }
      } catch (e) {
        this.sudo.loading = false
        this.sudo.error = 'Verification failed: ' + e.message
        return
      }
      // Password good — resolve the pending promise
      this.sudo.visible = false
      this.sudo.loading = false
      var resolve = this.sudo._resolve
      this.sudo._resolve = null
      this.sudo._reject = null
      if (resolve) resolve(pw)
    },

    // Called by the modal's Cancel button
    sudoCancel() {
      this.sudo.visible = false
      var reject = this.sudo._reject
      this.sudo._resolve = null
      this.sudo._reject = null
      if (reject) reject(new Error('Sudo cancelled by user'))
    },

    // api() — fetch wrapper. Automatically prompts for sudo password when needed.
    async api(method, path, body, _sudoPassword) {
      var opts = { method: method, headers: { 'Content-Type': 'application/json' } }
      if (_sudoPassword) opts.headers['X-Sudo-Password'] = _sudoPassword
      if (body !== undefined && body !== null) opts.body = JSON.stringify(body)

      var res = await fetch('/api' + path, opts)
      var json = await res.json()

      if (!res.ok) {
        var err = json.error || 'Request failed'
        // Sudo required — show modal then replay
        if (err === 'sudo_required' || res.status === 400 && err === 'sudo_required') {
          var pw = await this._askSudoPassword(false)
          return this.api(method, path, body, pw)
        }
        // Wrong password — show modal again with error
        if (err === 'incorrect_password' || res.status === 401) {
          var pw2 = await this._askSudoPassword(true)
          return this.api(method, path, body, pw2)
        }
        throw new Error(err)
      }
      return json.data
    }
  }
}
