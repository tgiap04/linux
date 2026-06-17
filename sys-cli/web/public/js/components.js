// Alpine.js component state functions for all modules.
// Must be loaded BEFORE alpine.min.js (which carries defer).
// Views use x-html to inject HTML templates — <script> tags inside x-html are
// not executed by browsers, so all component logic lives here instead.

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
        const res = await fetch('/api/processes/kill', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ pid: proc.pid, signal })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Kill failed')
        this.$root.showToast('SIG' + signal + ' sent to PID ' + proc.pid, 'success')
        await this.loadProcesses()
      } catch (e) {
        this.$root.showToast(e.message, 'error')
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
      { id: 'ping', label: 'Ping/DNS' },
      { id: 'firewall', label: 'Firewall' }
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
    firewallOutput: '',
    fwLoading: false,
    fwError: '',

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

    async checkFirewall() {
      this.fwLoading = true
      this.firewallOutput = ''
      this.fwError = ''
      try {
        const res = await fetch('/api/network/firewall')
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to check firewall')
        const d = json.data || {}
        this.firewallOutput = (d.tool ? '[' + d.tool + ']\n' : '') + (d.output || '(no output)')
      } catch (e) {
        this.fwError = e.message
      } finally {
        this.fwLoading = false
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
        const res = await fetch('/api/packages/install', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ packages: names })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Install failed')
        this.installSuccess = 'Installed: ' + names.join(', ')
        this.pkgInput = ''
        this.$root.showToast('Packages installed successfully', 'success')
      } catch (e) {
        this.installError = e.message
        this.$root.showToast(e.message, 'error')
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
        const res = await fetch('/api/packages/remove', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ pkg: names[0], purge: this.purge })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Remove failed')
        this.removeSuccess = 'Removed: ' + names.join(', ')
        this.removeInput = ''
        this.$root.showToast('Packages removed successfully', 'success')
      } catch (e) {
        this.removeError = e.message
        this.$root.showToast(e.message, 'error')
      } finally {
        this.removeLoading = false
      }
    },

    startUpdate() {
      if (this.updating) return
      this.updating = true
      this.updateLog = ''
      const evtSource = new EventSource('/api/packages/update/stream')
      evtSource.onmessage = (e) => {
        try {
          const d = JSON.parse(e.data)
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
            this.$root.showToast('Update complete (exit ' + (d.code || 0) + ')', d.code === 0 ? 'success' : 'warning')
          }
        } catch (_) {
          this.updateLog += e.data + '\n'
        }
      }
      evtSource.onerror = () => {
        evtSource.close()
        this.updating = false
        this.$root.showToast('Update stream disconnected', 'warning')
      }
    },

    async runAutoremove() {
      this.autoremoveLoading = true
      this.autoremoveError = ''
      this.autoremoveSuccess = ''
      try {
        const res = await fetch('/api/packages/autoremove', { method: 'POST' })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Autoremove failed')
        this.autoremoveSuccess = 'Autoremove completed successfully'
        this.$root.showToast('Autoremove completed', 'success')
      } catch (e) {
        this.autoremoveError = e.message
        this.$root.showToast(e.message, 'error')
      } finally {
        this.autoremoveLoading = false
      }
    }
  }
}

function filesState() {
  return {
    largeFiles: [],
    dir: '',
    size: '100M',
    findLoading: false,
    findError: '',
    largeFilesSearched: false,
    deleteDir: '',
    deletePattern: '',
    batchLoading: false,
    batchError: '',
    batchSuccess: '',
    chmodDir: '',
    fmode: '',
    dmode: '',
    owner: '',
    chmodLoading: false,
    chmodError: '',
    chmodSuccess: '',
    chmodValidationError: '',
    confirmDelete: null,

    init() {},

    octalPattern: /^[0-7]{3,4}$/,

    async findLargeFiles() {
      if (!this.dir.trim()) return
      this.findLoading = true
      this.findError = ''
      this.largeFilesSearched = false
      this.largeFiles = []
      try {
        const params = new URLSearchParams({ dir: this.dir, size: this.size || '100M' })
        const res = await fetch('/api/files/large?' + params.toString())
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Search failed')
        this.largeFiles = json.data || []
        this.largeFilesSearched = true
      } catch (e) {
        this.findError = e.message
      } finally {
        this.findLoading = false
      }
    },

    deleteSingleFile(path) {
      this.confirmDelete = { path, mode: 'single' }
    },

    async executeDelete() {
      if (!this.confirmDelete) return
      const { path } = this.confirmDelete
      this.confirmDelete = null
      try {
        const res = await fetch('/api/files/delete', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ path })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Delete failed')
        this.largeFiles = this.largeFiles.filter(f => f.path !== path)
        this.$root.showToast('Deleted: ' + path, 'success')
      } catch (e) {
        this.$root.showToast(e.message, 'error')
      }
    },

    async batchDelete() {
      if (!this.deleteDir.trim() || !this.deletePattern.trim()) return
      if (!confirm('Delete all files matching "' + this.deletePattern + '" in ' + this.deleteDir + '? This cannot be undone.')) return
      this.batchLoading = true
      this.batchError = ''
      this.batchSuccess = ''
      try {
        const res = await fetch('/api/files/delete', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ dir: this.deleteDir, pattern: this.deletePattern })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Batch delete failed')
        this.batchSuccess = 'Batch delete completed'
        this.deleteDir = ''
        this.deletePattern = ''
        this.$root.showToast('Batch delete completed', 'success')
      } catch (e) {
        this.batchError = e.message
        this.$root.showToast(e.message, 'error')
      } finally {
        this.batchLoading = false
      }
    },

    validateModes() {
      if (this.fmode && !this.octalPattern.test(this.fmode)) return 'File mode must be 3-4 octal digits (e.g. 644)'
      if (this.dmode && !this.octalPattern.test(this.dmode)) return 'Dir mode must be 3-4 octal digits (e.g. 755)'
      return ''
    },

    async applyPermissions() {
      if (!this.chmodDir.trim()) return
      this.chmodValidationError = this.validateModes()
      if (this.chmodValidationError) return
      this.chmodLoading = true
      this.chmodError = ''
      this.chmodSuccess = ''
      try {
        const body = { dir: this.chmodDir }
        if (this.fmode) body.fileMode = this.fmode
        if (this.dmode) body.dirMode = this.dmode
        if (this.owner) body.owner = this.owner
        const res = await fetch('/api/files/chmod', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'chmod failed')
        this.chmodSuccess = 'Permissions applied to ' + this.chmodDir
        this.$root.showToast('Permissions applied', 'success')
      } catch (e) {
        this.chmodError = e.message
        this.$root.showToast(e.message, 'error')
      } finally {
        this.chmodLoading = false
      }
    }
  }
}

function cronState() {
  return {
    jobs: [],
    loading: false,
    error: '',
    min: '*',
    hour: '*',
    day: '*',
    month: '*',
    wday: '*',
    cmd: '',
    addLoading: false,
    addError: '',
    backupSrc: '',
    backupDest: '',
    backupSchedule: '0 0 * * *',
    backupLoading: false,
    backupError: '',
    confirmDeleteIndex: null,

    async init() {
      await this.loadJobs()
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
        const res = await fetch('/api/cron/' + index, { method: 'DELETE' })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Delete failed')
        this.$root.showToast('Cron job deleted', 'success')
        await this.loadJobs()
      } catch (e) {
        this.$root.showToast(e.message, 'error')
      }
    },

    async addJob() {
      if (!this.cmd.trim()) return
      this.addLoading = true
      this.addError = ''
      try {
        const res = await fetch('/api/cron/add', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            min: this.min || '*',
            hour: this.hour || '*',
            day: this.day || '*',
            month: this.month || '*',
            wday: this.wday || '*',
            cmd: this.cmd
          })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to add cron job')
        this.$root.showToast('Cron job added', 'success')
        this.cmd = ''
        this.min = '*'
        this.hour = '*'
        this.day = '*'
        this.month = '*'
        this.wday = '*'
        await this.loadJobs()
      } catch (e) {
        this.addError = e.message
        this.$root.showToast(e.message, 'error')
      } finally {
        this.addLoading = false
      }
    },

    async scheduleBackup() {
      if (!this.backupSrc.trim() || !this.backupDest.trim()) return
      this.backupLoading = true
      this.backupError = ''
      try {
        const res = await fetch('/api/cron/backup', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            src: this.backupSrc,
            dest: this.backupDest,
            schedule: this.backupSchedule || '0 0 * * *'
          })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to schedule backup')
        this.$root.showToast('Backup job scheduled', 'success')
        await this.loadJobs()
      } catch (e) {
        this.backupError = e.message
        this.$root.showToast(e.message, 'error')
      } finally {
        this.backupLoading = false
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
        const res = await fetch('/api/time/timezone', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ tz })
        })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to set timezone')
        this.$root.showToast('Timezone set to ' + tz, 'success')
        await this.loadStatus()
      } catch (e) {
        this.tzError = e.message
        this.$root.showToast(e.message, 'error')
      } finally {
        this.tzLoading = false
      }
    },

    async enableNtp() {
      this.ntpEnableLoading = true
      this.ntpError = ''
      try {
        const res = await fetch('/api/time/ntp', { method: 'POST' })
        const json = await res.json()
        if (!res.ok) throw new Error(json.error || 'Failed to enable NTP')
        this.$root.showToast('NTP sync enabled', 'success')
        await this.loadStatus()
      } catch (e) {
        this.ntpError = e.message
        this.$root.showToast(e.message, 'error')
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
