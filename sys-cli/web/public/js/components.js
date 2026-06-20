// Alpine.js component state functions for all modules.
// Must be loaded BEFORE alpine.min.js (which carries defer).
// Views use x-html to inject HTML templates — <script> tags inside x-html are
// not executed by browsers, so all component logic lives here instead.

// Copy text to clipboard with execCommand fallback for HTTP contexts.
// Usage in view: x-on:click="copyText('cmd', el => el.dataset.copied = '1')"
function copyText(text, doneCb) {
  const done = () => { if (doneCb) doneCb() }
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).then(done).catch(() => {
      _copyFallback(text)
      done()
    })
  } else {
    _copyFallback(text)
    done()
  }
}

function _copyFallback(text) {
  const el = document.createElement('textarea')
  el.value = text
  el.style.cssText = 'position:fixed;opacity:0;pointer-events:none;'
  document.body.appendChild(el)
  el.select()
  try { document.execCommand('copy') } catch (_) {}
  document.body.removeChild(el)
}

function processesState() {
  return {
    processes: [],
    loading: false,
    error: '',
    sort: 'cpu',
    confirmKill: null,
    portInput: '',
    portResult: null,
    portError: '',
    portLoading: false,

    async init() {
      await this.loadProcesses()
    },

    async loadProcesses() {
      this.loading = true
      this.error = ''
      try {
        const res = await fetch('/api/processes/list?sort=' + this.sort)
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to load processes')
        this.processes = json.data || []
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },

    promptKill(proc, signal) {
      this.confirmKill = { proc, signal }
    },

    async executeKill() {
      if (!this.confirmKill) return
      const { proc, signal } = this.confirmKill
      this.confirmKill = null
      try {
        await Alpine.store('app').api('POST', '/processes/kill', { pid: proc.pid, signal })
        this.processes = this.processes.filter(p => p.pid !== proc.pid)
        Alpine.store('app').showToast('SIG' + signal + ' sent to PID ' + proc.pid, 'success')
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') Alpine.store('app').showToast(e.message, 'error')
      }
    },

    async findByPort() {
      if (!this.portInput) return
      this.portLoading = true
      this.portError = ''
      this.portResult = null
      try {
        const res = await fetch('/api/processes/port/' + this.portInput)
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Not found')
        this.portResult = json.data
      } catch (e) {
        this.portError = e.message
      } finally {
        this.portLoading = false
      }
    }
  }
}

function networkState() {
  return {
    activeTab: 'sockets',
    tabs: [
      { id: 'sockets', label: 'Ports' },
      { id: 'interfaces', label: 'Interfaces' },
      { id: 'routes', label: 'Routes' },
      { id: 'ping', label: 'Ping/DNS' }
    ],
    sockets: [],
    interfaces: [],
    routes: [],
    loading: false,
    ifLoading: false,
    rtLoading: false,
    error: '',
    pingHost: '',
    pingPort: 80,
    pingResult: null,
    pingLoading: false,
    pingError: '',
    dnsQuery: '',
    dnsResult: null,
    dnsLoading: false,
    dnsError: '',

    async init() {
      await this.loadSockets()
    },

    async loadSockets() {
      this.loading = true
      this.error = ''
      try {
        const res = await fetch('/api/network/sockets')
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to load sockets')
        this.sockets = json.data || []
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },

    async loadInterfaces() {
      this.ifLoading = true
      try {
        const res = await fetch('/api/network/interfaces')
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to load interfaces')
        this.interfaces = json.data || []
      } catch (e) {
        this.error = e.message
      } finally {
        this.ifLoading = false
      }
    },

    async loadRoutes() {
      this.rtLoading = true
      try {
        const res = await fetch('/api/network/routes')
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to load routes')
        this.routes = json.data || []
      } catch (e) {
        this.error = e.message
      } finally {
        this.rtLoading = false
      }
    },

    async testConnectivity() {
      if (!this.pingHost) return
      this.pingLoading = true
      this.pingResult = null
      this.pingError = ''
      try {
        const res = await fetch('/api/network/ping', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ host: this.pingHost, port: this.pingPort || 80 })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Test failed')
        this.pingResult = json.data
      } catch (e) {
        this.pingError = e.message
      } finally {
        this.pingLoading = false
      }
    },

    async dnsLookup() {
      if (!this.dnsQuery) return
      this.dnsLoading = true
      this.dnsResult = null
      this.dnsError = ''
      try {
        const res = await fetch('/api/network/dns', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ target: this.dnsQuery })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Lookup failed')
        this.dnsResult = json.data
      } catch (e) {
        this.dnsError = e.message
      } finally {
        this.dnsLoading = false
      }
    },

  }
}

function firewallState() {
  return {
    status: null,
    logs: [],
    loading: false,
    error: '',
    logLoading: false,
    portsInput: '',
    portsLoading: false,

    async init() {
      await this.loadStatus()
    },

    async loadStatus() {
      this.loading = true
      this.error = ''
      this.status = null
      try {
        const d = await Alpine.store('app').api('GET', '/firewall/status')
        this.status = d
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') {
          if (e.message && e.message.includes('module is not loaded')) {
            this.status = { moduleLoaded: false }
          } else {
            this.error = e.message
          }
        }
      } finally {
        this.loading = false
      }
    },

    async toggleField(field) {
      if (!this.status) return
      const current = this.status[field] === 1 || this.status[field] === '1' ? 1 : 0
      const newVal = current ? 0 : 1
      try {
        await Alpine.store('app').api('POST', '/firewall/toggle', { field, value: newVal })
        this.status[field] = newVal
        Alpine.store('app').showToast(field + ' set to ' + (newVal ? 'ON' : 'OFF'), 'success')
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') Alpine.store('app').showToast(e.message, 'error')
      }
    },

    async updatePorts() {
      if (!this.portsInput.trim()) return
      this.portsLoading = true
      try {
        const result = await Alpine.store('app').api('POST', '/firewall/ports', { ports: this.portsInput.trim() })
        if (this.status) this.status.reject_ports = result.ports
        this.portsInput = ''
        Alpine.store('app').showToast('Ports updated', 'success')
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') Alpine.store('app').showToast(e.message, 'error')
      } finally {
        this.portsLoading = false
      }
    },

    async loadLogs() {
      this.logLoading = true
      try {
        const d = await Alpine.store('app').api('GET', '/firewall/logs')
        this.logs = (d.logs || []).slice(0, 50)
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') Alpine.store('app').showToast(e.message, 'error')
      } finally {
        this.logLoading = false
      }
    }
  }
}

function packagesState() {
  return {
    manager: '',
    pkgInput: '',
    removeInput: '',
    purge: false,
    updateLog: '',
    updating: false,
    loading: false,
    error: '',
    installLoading: false,
    installError: '',
    installSuccess: '',
    removeLoading: false,
    removeError: '',
    removeSuccess: '',
    autoremoveLoading: false,
    autoremoveError: '',
    autoremoveSuccess: '',
    installedPkgs: [],
    pkgSearch: '',
    pkgListLoading: false,
    pkgListLoaded: false,
    pkgListError: '',
    removingPkg: '',

    async init() {
      this.loading = true
      try {
        const res = await fetch('/api/packages/detect')
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to detect package manager')
        this.manager = json.data || 'unknown'
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },

    parsePackageNames(input) {
      return input.split(/[\s,]+/).map(s => s.trim()).filter(Boolean)
    },

    async installPackages() {
      const names = this.parsePackageNames(this.pkgInput)
      if (!names.length) return
      this.installLoading = true
      this.installError = ''
      this.installSuccess = ''
      try {
        await Alpine.store('app').api('POST', '/packages/install', { packages: names })
        this.installSuccess = 'Installed: ' + names.join(', ')
        this.pkgInput = ''
        Alpine.store('app').showToast('Packages installed successfully', 'success')
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') {
          this.installError = e.message
          Alpine.store('app').showToast(e.message, 'error')
        }
      } finally {
        this.installLoading = false
      }
    },

    async removePackages() {
      const names = this.parsePackageNames(this.removeInput)
      if (!names.length) return
      this.removeLoading = true
      this.removeError = ''
      this.removeSuccess = ''
      try {
        await Alpine.store('app').api('POST', '/packages/remove', { pkg: names[0], purge: this.purge })
        this.removeSuccess = 'Removed: ' + names.join(', ')
        this.removeInput = ''
        Alpine.store('app').showToast('Packages removed successfully', 'success')
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') {
          this.removeError = e.message
          Alpine.store('app').showToast(e.message, 'error')
        }
      } finally {
        this.removeLoading = false
      }
    },

    async startUpdate() {
      if (this.updating) return
      this.updateLog = ''
      // Get a one-time sudo token (triggers password modal if needed)
      let token
      try {
        const data = await Alpine.store('app').api('POST', '/sudo/verify', null)
        token = data && data.token
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') Alpine.store('app').showToast(e.message, 'error')
        return
      }
      this.updating = true
      const url = '/api/packages/update/stream' + (token ? '?_sudo_token=' + token : '')
      const evtSource = new EventSource(url)
      evtSource.onmessage = (e) => {
        try {
          const d = JSON.parse(e.data)
          if (d.error === 'sudo_required') {
            evtSource.close()
            this.updating = false
            Alpine.store('app').showToast('Sudo password required — please retry', 'warning')
            return
          }
          if (d.line) {
            this.updateLog += d.line
            this.$nextTick(() => {
              const panel = this.$refs.logPanel
              if (panel) panel.scrollTop = panel.scrollHeight
            })
          }
          if (d.done) {
            evtSource.close()
            this.updating = false
            Alpine.store('app').showToast('Update complete (exit ' + (d.code || 0) + ')', d.code === 0 ? 'success' : 'warning')
          }
        } catch (_) {
          this.updateLog += e.data + '\n'
        }
      }
      evtSource.onerror = () => {
        evtSource.close()
        this.updating = false
        Alpine.store('app').showToast('Update stream disconnected', 'warning')
      }
    },

    get filteredPkgs() {
      const q = this.pkgSearch.trim().toLowerCase()
      if (!q) return this.installedPkgs
      return this.installedPkgs.filter(p => p.name.toLowerCase().includes(q))
    },

    async removeFromList(name) {
      if (this.removingPkg) return
      this.removingPkg = name
      try {
        await Alpine.store('app').api('POST', '/packages/remove', { pkg: name, purge: false })
        this.installedPkgs = this.installedPkgs.filter(p => p.name !== name)
        Alpine.store('app').showToast('Removed: ' + name, 'success')
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') Alpine.store('app').showToast(e.message, 'error')
      } finally {
        this.removingPkg = ''
      }
    },

    async loadInstalledPackages() {
      this.pkgListLoading = true
      this.pkgListError = ''
      try {
        const res = await fetch('/api/packages/list')
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to load packages')
        this.installedPkgs = json.data || []
        this.pkgListLoaded = true
      } catch (e) {
        this.pkgListError = e.message
      } finally {
        this.pkgListLoading = false
      }
    },

    async runAutoremove() {
      this.autoremoveLoading = true
      this.autoremoveError = ''
      this.autoremoveSuccess = ''
      try {
        await Alpine.store('app').api('POST', '/packages/autoremove', null)
        this.autoremoveSuccess = 'Autoremove completed successfully'
        Alpine.store('app').showToast('Autoremove completed', 'success')
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') {
          this.autoremoveError = e.message
          Alpine.store('app').showToast(e.message, 'error')
        }
      } finally {
        this.autoremoveLoading = false
      }
    }
  }
}

function filesState() {
  return {
    opPath: '',
    opLoading: false,
    opError: '',
    opSuccess: '',
    crudAction: '',
    modal: { open: false, type: '', path: '', input: '' },
    treePath: '/',
    treeDepth: 3,
    treeItems: [],
    treeLoading: false,
    treeLoaded: false,
    treeError: '',
    collapsedDirs: {},

    init() {},

    async loadTree() {
      if (!this.treePath.trim()) return
      this.treeLoading = true
      this.treeError = ''
      this.treeLoaded = false
      try {
        const params = new URLSearchParams({ path: this.treePath.trim(), depth: this.treeDepth })
        const res = await fetch('/api/files/tree?' + params)
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to load tree')
        this.treeItems = json.data || []
        // Default all dirs to collapsed
        const collapsed = {}
        this.treeItems.forEach(item => { if (item.type === 'dir') collapsed[item.relPath] = true })
        this.collapsedDirs = collapsed
        this.treeLoaded = true
      } catch (e) {
        this.treeError = e.message
      } finally {
        this.treeLoading = false
      }
    },

    toggleDir(relPath) {
      // true = collapsed, false = expanded; reassign to trigger Alpine reactivity
      this.collapsedDirs[relPath] = !this.collapsedDirs[relPath]
    },

    isVisible(item) {
      // Depth-1 items (direct children of root) are always visible
      // An item is hidden if any ancestor dir is collapsed (collapsedDirs[ancestor] === true)
      const parts = item.relPath.split('/')
      for (let i = 1; i < parts.length; i++) {
        const ancestor = parts.slice(0, i).join('/')
        if (this.collapsedDirs[ancestor] === true) return false
      }
      return true
    },

    confirmDeletePath() {
      if (!this.opPath.trim()) return
      this.opError = ''
      this.opSuccess = ''
      this.crudAction = 'delete'
      this.modal = { open: true, type: 'delete', path: this.opPath.trim(), input: '' }
    },

    openRename() {
      if (!this.opPath.trim()) return
      this.opError = ''
      this.opSuccess = ''
      this.crudAction = 'rename'
      this.modal = { open: true, type: 'rename', path: this.opPath.trim(), input: '' }
      this.$nextTick(() => { if (this.$refs.modalInput) this.$refs.modalInput.focus() })
    },

    openCreate(type) {
      if (!this.opPath.trim()) return
      this.opError = ''
      this.opSuccess = ''
      this.crudAction = 'create-' + type
      this.modal = { open: true, type: 'create-' + type, path: this.opPath.trim(), input: '' }
      this.$nextTick(() => { if (this.$refs.modalInput) this.$refs.modalInput.focus() })
    },

    async executeOp() {
      const { type, path, input } = this.modal
      if (!type || !path) return
      if ((type === 'rename' || type === 'create-file' || type === 'create-dir') && !input.trim()) return
      this.modal.open = false
      this.opLoading = true
      this.opError = ''
      this.opSuccess = ''
      try {
        let endpoint, body
        if (type === 'delete') {
          endpoint = '/files/delete-path'
          body = { path }
        } else if (type === 'rename') {
          endpoint = '/files/rename'
          body = { path, newName: input.trim() }
        } else {
          endpoint = '/files/create'
          body = { path, name: input.trim(), type: type === 'create-dir' ? 'dir' : 'file' }
        }
        await Alpine.store('app').api('POST', endpoint, body)
        if (type === 'delete') {
          this.opSuccess = 'Deleted: ' + path
          Alpine.store('app').showToast('Deleted: ' + path, 'success')
          this.opPath = ''
        } else if (type === 'rename') {
          const dir = path.includes('/') ? path.slice(0, path.lastIndexOf('/')) || '/' : '.'
          this.opSuccess = 'Renamed to: ' + dir.replace(/\/$/, '') + '/' + input.trim()
          Alpine.store('app').showToast('Renamed successfully', 'success')
          this.opPath = ''
        } else {
          this.opSuccess = 'Created: ' + path.replace(/\/$/, '') + '/' + input.trim()
          Alpine.store('app').showToast('Created successfully', 'success')
        }
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') {
          this.opError = e.message
          Alpine.store('app').showToast(e.message, 'error')
        }
      } finally {
        this.opLoading = false
        this.crudAction = ''
      }
    },

  }
}

function cronState() {
  return {
    jobs: [],
    loading: false,
    error: '',
    min: '0',
    hour: '0',
    day: '*',
    month: '*',
    wday: '*',
    timeValue: '00:00',
    cmd: '',
    logEnabled: false,
    logFile: '',
    addLoading: false,
    addError: '',
    confirmDeleteIndex: null,

    async init() {
      await Promise.all([this.loadJobs(), this.loadCurrentTime()])
    },

    async loadCurrentTime() {
      try {
        const res = await fetch('/api/cron/now')
        const json = await res.json()
        if (res.ok && json.data) {
          this.hour = String(json.data.hour)
          this.min = String(json.data.min)
          this.timeValue = String(json.data.hour).padStart(2, '0') + ':' + String(json.data.min).padStart(2, '0')
        }
      } catch (_) {}
    },

    onTimeChange(val) {
      const [h, m] = (val || '00:00').split(':')
      this.hour = String(parseInt(h, 10))
      this.min = String(parseInt(m, 10))
    },

    buildCmd() {
      if (!this.cmd.trim()) return ''
      const logPath = this.logEnabled && this.logFile.trim() ? this.logFile.trim() : null
      return logPath ? `${this.cmd.trim()} >> ${logPath} 2>&1` : this.cmd.trim()
    },

    cronPreview() {
      const min = this.min || '*'
      const hour = this.hour || '*'
      const day = this.day || '*'
      const month = this.month || '*'
      const wday = this.wday || '*'
      return `${min} ${hour} ${day} ${month} ${wday} ${this.buildCmd()}`
    },

    async loadJobs() {
      this.loading = true
      this.error = ''
      try {
        const res = await fetch('/api/cron/list')
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to load cron jobs')
        this.jobs = json.data || []
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },

    promptDeleteJob(index) {
      this.confirmDeleteIndex = index
    },

    async executeDeleteJob() {
      const index = this.confirmDeleteIndex
      if (index === null) return
      this.confirmDeleteIndex = null
      try {
        const res = await fetch('/api/cron/' + (index + 1), { method: 'DELETE' })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Delete failed')
        this.jobs.splice(index, 1)
        Alpine.store('app').showToast('Cron job deleted', 'success')
      } catch (e) {
        Alpine.store('app').showToast(e.message, 'error')
      }
    },

    async addJob() {
      if (!this.cmd.trim()) return
      this.addLoading = true
      this.addError = ''
      try {
        const min = this.min || '*'
        const hour = this.hour || '*'
        const day = this.day || '*'
        const month = this.month || '*'
        const wday = this.wday || '*'
        const cmd = this.buildCmd()
        const entry = [min, hour, day, month, wday, cmd].join(' ')
        const res = await fetch('/api/cron/add', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ min, hour, day, month, wday, cmd })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to add cron job')
        this.jobs.push({ index: this.jobs.length, entry })
        this.cmd = ''
        this.logFile = ''
        this.logEnabled = false
        Alpine.store('app').showToast('Cron job added', 'success')
      } catch (e) {
        this.addError = e.message
        Alpine.store('app').showToast(e.message, 'error')
      } finally {
        this.addLoading = false
      }
    }
  }
}

function timeState() {
  return {
    status: null,
    timezones: [],
    tzFilter: '',
    newTz: '',
    loading: false,
    error: '',
    tzLoading: false,
    tzError: '',
    ntpStatus: '',
    ntpEnableLoading: false,
    ntpStatusLoading: false,
    ntpError: '',

    get filteredTimezones() {
      const q = this.tzFilter.toLowerCase()
      if (!q) return this.timezones.slice(0, 50)
      return this.timezones.filter(tz => tz.toLowerCase().includes(q)).slice(0, 50)
    },

    async init() {
      await Promise.all([this.loadStatus(), this.loadTimezones()])
    },

    async loadStatus() {
      this.loading = true
      this.error = ''
      try {
        const res = await fetch('/api/time/status')
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to load time status')
        this.status = json.data
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },

    async loadTimezones() {
      try {
        const res = await fetch('/api/time/timezones')
        const json = await res.json()
        if (!res.ok) return
        this.timezones = json.data || []
      } catch (_) {}
    },

    async changeTimezone() {
      const tz = this.tzFilter.trim()
      if (!tz) return
      this.tzLoading = true
      this.tzError = ''
      try {
        await Alpine.store('app').api('POST', '/time/timezone', { tz })
        if (this.status) this.status.timezone = tz
        Alpine.store('app').showToast('Timezone set to ' + tz, 'success')
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') {
          this.tzError = e.message
          Alpine.store('app').showToast(e.message, 'error')
        }
      } finally {
        this.tzLoading = false
      }
    },

    async enableNtp() {
      this.ntpEnableLoading = true
      this.ntpError = ''
      try {
        await Alpine.store('app').api('POST', '/time/ntp', null)
        if (this.status) this.status.ntpSync = true
        Alpine.store('app').showToast('NTP sync enabled', 'success')
      } catch (e) {
        if (e.message !== 'Sudo cancelled by user') {
          this.ntpError = e.message
          Alpine.store('app').showToast(e.message, 'error')
        }
      } finally {
        this.ntpEnableLoading = false
      }
    },

    async checkNtpStatus() {
      this.ntpStatusLoading = true
      this.ntpError = ''
      this.ntpStatus = ''
      try {
        const res = await fetch('/api/time/ntp-status')
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to get NTP status')
        const d = json.data
        this.ntpStatus = (d && d.raw) || d || '(no output)'
      } catch (e) {
        this.ntpError = e.message
      } finally {
        this.ntpStatusLoading = false
      }
    }
  }
}
