# sys-cli — Linux System Management Tool

A modular interactive shell script for managing Linux systems from the terminal.

## Modules

| # | Module | What it manages |
|---|--------|----------------|
| 1 | File & Directory | Batch create/delete/move, find large files, chmod/chown |
| 2 | Cron Jobs | Add/list/delete cron jobs, schedule daily backups |
| 3 | System Time | Timezone, NTP sync (timedatectl / chrony) |
| 4 | Package Management | Install/purge/update packages (apt on Ubuntu) |
| 5 | Process Management | List, kill, monitor processes; find process by port |
| 6 | Network & Sockets | Ports, interfaces, routes, DNS, firewall (ufw) |

---

## Requirements (Ubuntu)

- Ubuntu 20.04+ (or any Debian-based distro)
- Bash 4+ (pre-installed)
- `sudo` access

---

## Installation & Running on Ubuntu

### 1. Clone or download

```bash
git clone https://github.com/your-username/sys-cli.git
cd sys-cli
```

Or download directly:

```bash
wget https://github.com/your-username/sys-cli/archive/main.tar.gz
tar -xzf main.tar.gz && cd sys-cli-main
```

### 2. Make executable

```bash
chmod +x sys-cli.sh
```

### 3. Run

```bash
./sys-cli.sh
```

Or with sudo if you want privileged operations to work without prompting each time:

```bash
sudo ./sys-cli.sh
```

### 4. Optional: install system-wide

```bash
sudo cp sys-cli.sh /usr/local/bin/sys-cli
sudo cp -r lib/ /usr/local/lib/sys-cli/
```

Then run from anywhere:

```bash
sys-cli
```

---

## Web UI

A browser-based interface for sys-cli. Access all modules via `http://<IP>:<PORT>` — no terminal required.

### Requirements

- Node.js 18+

```bash
node --version   # should be >= 18
```

### Run

```bash
cd web
npm install
node server.js
```

Default port is **3000**. Access at `http://localhost:3000` or `http://<your-server-ip>:3000`.

### Custom port

```bash
PORT=8080 node server.js
```

### Run in background (production)

```bash
# Using nohup
PORT=3000 nohup node server.js > web.log 2>&1 &

# Or with pm2
npm install -g pm2
PORT=3000 pm2 start server.js --name sys-cli-web
pm2 save
```

---

## Usage

```
./sys-cli.sh [OPTIONS]

Options:
  -h, --help      Show help
  -v, --version   Show version
  (none)          Launch interactive menu
```

Navigate the menu by typing the option number and pressing Enter. Choose **Back** from any submenu to return to the main menu. Press `Ctrl+C` at any time to exit.

---

## Ubuntu-specific notes

| Feature | Tool used on Ubuntu |
|---------|-------------------|
| Package management | `apt-get` (auto-detected) |
| Timezone | `timedatectl` (systemd) |
| NTP sync | `systemd-timesyncd` via `timedatectl set-ntp true` |
| Firewall status | `ufw` |
| Port/socket listing | `ss` (iproute2, pre-installed) |

All required tools (`ss`, `ip`, `timedatectl`, `apt-get`) are pre-installed on Ubuntu. Optional tools that enhance output if present: `pstree`, `lsof`, `nc`, `dig`.

Install optional tools in one command:

```bash
sudo apt-get install -y psmisc lsof netcat-openbsd dnsutils
```

---

## Project structure

```
sys-cli/
├── sys-cli.sh          # Entry point (shell CLI)
├── lib/
│   ├── common.sh       # Shared helpers
│   ├── file-mgmt.sh
│   ├── cron-mgmt.sh
│   ├── time-mgmt.sh
│   ├── pkg-mgmt.sh
│   ├── process-mgmt.sh
│   └── network-mgmt.sh
├── docs/
│   └── usage-guide.md  # Full module reference
└── web/                # Web UI (Node.js + Express)
    ├── server.js
    ├── package.json
    ├── lib/
    │   ├── shell.js    # Choke point for all shell calls
    │   └── routes/     # API routes per module
    └── public/         # Frontend (Alpine.js, no build step)
        ├── index.html
        ├── css/
        ├── js/
        └── views/      # Per-module HTML views
```
