# Architecture

## 1. System Context — Three Independent Sub-Projects

```mermaid
graph TB
    subgraph REPO["linux/ (repo root — monorepo)"]
        A["KMA-OS\nCustom Linux 7.0 kernel + LSM modules\nC / Bash"]
        B["sys-cli\nSystem management CLI + Web UI\nBash / Node.js"]
        C["package-hiding\nCovert channel over TCP/UDP\nC kernel module + Python"]
    end

    HOST["macOS Host\nApple Silicon / UTM"] -->|SSH + rsync| A
    BROWSER["Browser"] -->|HTTP :3000| B
    TERMINAL["Terminal"] -->|bash| B
    NET["Network\nTCP/UDP traffic"] <-->|steganographic embed| C
    A -. "same Ubuntu VM guest" .-> C
```

No runtime dependency between the three sub-projects; they share the Ubuntu ARM64 VM as execution environment and the repo as monorepo container only.

---

## 2. KMA-OS — Kernel Build Topology

```mermaid
flowchart TD
    M["macOS Host\nApple Silicon"] -->|rsync over SSH| SRC

    subgraph VM["Ubuntu Guest VM (ARM64) — UTM/QEMU"]
        SRC["/mnt/shared\n9p virtio FS — source tree"]
        BS["scripts/build-kernel.sh\ngit clone → localmodconfig → make -j"]
        BOOT["/boot\nkernel image + initrd\nuname -r: 7.0.0-22-generic-kma-os-minimal"]
        GRUB["update-grub\ngrub-set-default"]

        subgraph MODULES["Out-of-tree kernel modules (make M=)"]
            BRAND["kma-branding.ko\nmodule_init → pr_info ASCII logo"]
            VFS["kma-vfs-guard.ko\nLSM hooks: inode_unlink / inode_rmdir / path_rename\nRCU hash table (4096 buckets)\nsysfs: /sys/kernel/kma-vfs-guard/"]
        end

        SRC --> BS --> BOOT --> GRUB
        BS --> MODULES
        MODULES -->|insmod / /etc/modules| KERNEL["Running kernel\nLSM stack active from boot"]
    end

    PATCH["patches/0002-kma-boot-banner.patch\ninit/main.c — always-on banner\npatches/0003-kma-vfs-guard-lsm.patch\nbuilt-in DEFINE_LSM"] --> BS
```

Key decisions:
- `make localmodconfig` strips ~15 000 config items to ~200 — minimal build footprint
- Boot target <10 s; loaded modules <50
- VFS Guard: RCU lockless O(1) reads; spin_lock only on insert/remove
- Built-in LSM (`DEFINE_LSM`) cannot be bypassed at runtime — enforcement is mandatory

---

## 3. sys-cli — Dual Interface Architecture

```mermaid
graph LR
    subgraph CLI["Terminal — Bash TUI"]
        ENTRY["sys-cli.sh\nselect menu loop"]
        LIBS["lib/*.sh modules\nfile-mgmt / cron-mgmt / time-mgmt\npkg-mgmt / process-mgmt\nnetwork-mgmt / firewall-mgmt"]
        ENTRY --> LIBS
    end

    subgraph WEB["Web UI — Node.js/Express (port 3000)"]
        SRV["server.js\nExpress + Helmet + rate-limit"]
        ROUTES["lib/routes/*.js\nfiles / cron / time / packages\nprocesses / network / firewall"]
        SHELL["lib/shell.js\nrunSudo() — spawns bash subprocesses"]
        PUB["public/\nSPA — HTML/CSS/JS"]

        SRV --> ROUTES --> SHELL
        SRV --> PUB
    end

    BROWSER -->|HTTP| SRV
    LIBS -->|syscall / shell| OS[("Ubuntu OS\nkernel APIs")]
    SHELL -->|child_process.spawn| LIBS
    SHELL --> OS
```

Shared logic: both interfaces call the same `lib/*.sh` bash functions — the web layer spawns them as subprocesses via `shell.js:runSudo()`. No business logic duplication.

Security: sudo password in `X-Sudo-Password` header only; 30 s one-time tokens for SSE streams; rate limit 120 req/min; Helmet CSP disabled only for inline scripts.

---

## 4. package-hiding — Covert Channel Architecture

```mermaid
flowchart LR
    subgraph SENDER["Sender (Ubuntu kernel space — covert.ko)"]
        SYSFS["/sys/kernel/covert/message\nsysfs write interface"]
        FRAME["framing.c\nbyte-stream state machine\n0xFF 0x00 [data] 0xFF 0xFF"]
        NF["Netfilter hook\nNF_INET_LOCAL_OUT\nfilter: dst port 9999"]
        TCP_E["tcp_embed.c\nembed byte → TCP Seq# low 8 bits"]
        UDP_E["udp_embed.c\nembed byte → IP ID field"]

        SYSFS --> FRAME --> NF
        NF --> TCP_E
        NF --> UDP_E
    end

    subgraph RECEIVER["Receiver (user space — Python/Scapy)"]
        TCP_R["tcp_receiver.py\nScapy raw socket sniff"]
        UDP_R["udp_receiver.py\nScapy raw socket sniff"]
    end

    NET["Network — normal TCP/UDP traffic\n(default target: 10.0.2.15:9999)"]

    SENDER -->|packets with embedded bytes| NET -->|sniffed| RECEIVER
```

One byte per packet; packet_parser.c identifies target flows; framing.c manages byte sequencing. Receiver is pure user-space Python — no kernel module needed on receiver side. Checksums recalculated after header mutation.

---

## 5. Technology Stack

| Sub-project | Layer | Technology | Notes |
|---|---|---|---|
| KMA-OS | Kernel | Linux 7.0.0 (Ubuntu oracular) | ARM64, custom localmodconfig build |
| KMA-OS | Module language | C (GPL-2.0) | kma-branding, kma-vfs-guard |
| KMA-OS | Kernel API | LSM hooks, sysfs kobject, RCU hashtable | VFS Guard hooks: inode_unlink/rmdir, path_rename |
| KMA-OS | Build | Makefile (kbuild out-of-tree `make M=`) | |
| KMA-OS | VM | UTM (QEMU userspace), 9p virtio FS | macOS host → ARM64 guest |
| KMA-OS | Scripts | Bash | build-kernel.sh, sync-to-vm.sh, test-*.sh |
| sys-cli | CLI | Bash (modular lib/*.sh) | 7 domain modules |
| sys-cli | Web server | Node.js + Express 4 | port 3000, rate-limited |
| sys-cli | Web security | helmet, express-rate-limit | sudo token in-memory, 30 s TTL |
| sys-cli | Web frontend | Vanilla HTML/CSS/JS SPA | static files in public/ |
| sys-cli | Subprocess bridge | shell.js (child_process.spawn) | ties web routes to bash libs |
| package-hiding | Sender | C kernel module (GPL-2.0) | Netfilter NF_INET_LOCAL_OUT |
| package-hiding | Steganography | tcp_embed.c, udp_embed.c, framing.c | 1 byte/packet bandwidth |
| package-hiding | Receiver | Python + Scapy | raw socket, user space only |
| package-hiding | Trigger | sysfs write | /sys/kernel/covert/message |

---

## Unresolved Questions

- `tcp_embed.c` / `udp_embed.c`: exact header subfield used (urgent pointer? reserved bits?) — needs file read to confirm.
- sys-cli `public/` SPA: Alpine.js + HTMX confirmed in scout; bundled vs. CDN not verified.
- package-hiding receiver: byte-order and framing reassembly logic in Python not examined.
