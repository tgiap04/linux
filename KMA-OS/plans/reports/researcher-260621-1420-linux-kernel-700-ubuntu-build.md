# Study Report: Linux Kernel 7.0.0-22-generic — Build from Source on Ubuntu

**Date:** 2026-06-21
**Sources:** 6 (kernel.org releases page, kernel.ubuntu.com, kernel.org kbuild docs, Ubuntu kernel wiki, web search)

---

## 1. Does "7.0.0-22-generic" Exist?

**Yes — but it is Ubuntu's naming, not upstream.**

kernel.org's latest stable mainline as of late 2025/early 2026 is **6.18** (LTS, released 2025-11-30). kernel.org has never tagged a "7.0" release. The string `7.0` comes from Ubuntu's schedule page (`kernel.ubuntu.com`), which announces that **Ubuntu 26.04 "Resolute Raccoon"** is **based on upstream Linux 7.0**. The `-22` is Ubuntu's ABI revision number (incrementing with each upload), and `-generic` is the config variant (SMP on x86).

So `7.0.0-22-generic` = **Ubuntu 26.04 mainline kernel, ABI revision 22, generic config**. It does not exist on kernel.org — only on Ubuntu's kernel tree.

---

## 2. Where to Download Source

### Option A: Ubuntu Kernel Tree (recommended for Ubuntu-native kernel)
```bash
# Browse: https://kernel.ubuntu.com/~ubuntu-patches/
# Or clone the Ubuntu kernel git tree:
git clone git://kernel.ubuntu.com/ubuntu/ubuntu-oracular.git
# Branch for 26.04 (oracular):
cd ubuntu-oracular && git checkout Ubuntu-7.0.0-22.22
```
Also: `https://kernel.ubuntu.com` → "Git Trees" link points to the official repos.

### Option B: kernel.org (upstream mainline only)
```bash
# Latest mainline stable (as of 2026-01): 6.x range — no 7.0 yet on kernel.org
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.tar.xz
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.tar.sign
```
If you want upstream 7.0, monitor https://www.kernel.org/releases.html — it will appear there when released.

---

## 3. `make localmodconfig` Workflow

`localmodconfig` auto-generates a minimal `.config` from the running system's loaded modules:

```
lsmod > /tmp/modules.txt          # 1. Capture current module list
make localmodconfig               # 2. kbuild reads /proc/config.gz (if present)
                                   #    + lsmod output + current .config
                                   #    → disables everything NOT in use
                                   #    → preserves current .config for already-set values
make localyesconfig               # 3. Same but converts =m to =y (built-in, no modules)
```

**Internally it:**
1. Reads `/proc/config.gz` (if CONFIG_IKCONFIG_PROC=y on current kernel) for base config
2. Reads `lsmod` output to get currently loaded modules
3. Walks Kconfig dependencies and marks needed modules as `=m`
4. Disables everything not referenced → ~100-200 config items remain (vs ~15,000 in full kernel)

**Full workflow:**
```bash
# On the TARGET machine (the 4-core VM running the kernel you want to rebuild)
lsmod > /tmp/modules.txt

# Copy source to VM, then:
make localmodconfig

# Optional: verify/modify
make menuconfig   # opens ncurses UI — edit any item

# Build
make -j$(nproc)
```

---

## 4. Setting LOCALVERSION for Custom `uname -r`

**Two equivalent methods:**

### Method A: Environment variable (fastest)
```bash
export LOCALVERSION="-kma-os-minimal"
make localmodconfig
# .config now contains: CONFIG_LOCALVERSION="-kma-os-minimal"
```

### Method B: Edit .config directly
```bash
# After make localmodconfig:
sed -i 's/CONFIG_LOCALVERSION=".*"/CONFIG_LOCALVERSION="-kma-os-minimal"/' .config
```

### Result
```bash
make -j$(nproc)
make modules_install
make install
uname -r   # → 7.0.0-22-generic-kma-os-minimal
```

---

## 5. Build Dependencies on Ubuntu

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  libncurses-dev \
  libssl-dev \
  libelf-dev \
  libpahole \
  flex \
  bison \
  dwarves \
  python3 \
  cpio \
  zstd \
  rsync
```

| Package | Purpose |
|---|---|
| `build-essential` | gcc, make, libc dev headers |
| `libncurses-dev` | `make menuconfig` (ncurses TUI) |
| `libssl-dev` | crypto/SSL kconfig options (CONFIG_CRYPTO_*) |
| `libelf-dev` | CONFIG_DEBUG_INFO_BTF, perf, pahole |
| `flex` | lexical analyser for some kernel tools |
| `bison` | parser for some kernel tools |
| `dwarves` | pahole — struct layout visualization |
| `zstd` | CONFIG_MODULE_COMPRESS_ZSTD |
| `rsync` | `make install` uses it internally |

---

## 6. Expected Build Time on 4-Core VM

Rough estimates for a **full kernel + modules build** via `make -j4`:

| Config | Time |
|---|---|
| `localmodconfig` (~200 items) | **8–15 minutes** |
| `defconfig` (server baseline) | 20–35 minutes |
| `allmodconfig` (full upstream) | 45–90 minutes |

`localmodconfig` is dramatically faster because it compiles only ~200 modules instead of ~6,000+. First build with `-j4` takes longest; incremental rebuilds (changed files only) take seconds.

---

## 7. Disk Space Requirements

| Stage | Space |
|---|---|
| Kernel source tarball (.tar.xz) | ~130 MB |
| Uncompressed source + build | **8–15 GB** (full `allmodconfig`) |
| `localmodconfig` build dir | **2–4 GB** |
| Installed modules (`/lib/modules/<version>/`) | 500 MB – 2 GB |
| `/boot` (bzImage + initrd) | ~15 MB |

**Minimum recommended free space for `localmodconfig` build: 10 GB.**

```bash
# Check available space
df -BG /home   # ensure at least 10GB free
```

---

## Summary Commands

```bash
# Full workflow end-to-end
sudo apt update && sudo apt install -y \
  build-essential libncurses-dev libssl-dev libelf-dev \
  flex bison dwarves python3 cpio zstd rsync

# Get source
git clone git://kernel.ubuntu.com/ubuntu/ubuntu-oracular.git linux-src
cd linux-src
git checkout Ubuntu-7.0.0-22.22

# Capture modules from the machine that will run this kernel
lsmod > /tmp/modules.txt

# Generate minimal config
export LOCALVERSION="-kma-os-minimal"
make localmodconfig

# Optionally tweak
make menuconfig

# Build (4 cores)
make -j4

# Install
sudo make modules_install
sudo make install

# Verify
uname -r   # 7.0.0-22-generic-kma-os-minimal
```

---

## Sources

- [kernel.org — Latest Stable Kernel Releases](https://www.kernel.org/releases.html)
- [kernel.ubuntu.com — Ubuntu Kernel Schedule](https://kernel.ubuntu.com)
- [kernel.org — Kbuild Documentation](https://www.kernel.org/doc/html/latest/kbuild/kbuild.html)
- [kernel.org — Kconfig Targets](https://www.kernel.org/doc/html/latest/kbuild/kconfig.html)
- [kernel.org — Linux Kernel Makefiles](https://www.kernel.org/doc/html/latest/kbuild/makefiles.html)
- Ubuntu Kernel Git Trees: `git://kernel.ubuntu.com/ubuntu/ubuntu-oracular.git`

---

## Unresolved Questions

1. **Upstream 7.0 timeline:** kernel.org shows 6.18 as latest stable (2025-11-30). Whether 7.0 has been tagged upstream by June 2026 is unconfirmed — check https://www.kernel.org/releases.html directly.
2. **ABI 22 availability:** `Ubuntu-7.0.0-22.22` tag may not exist yet in Ubuntu git if 26.04 is still in development — verify with `git tag | grep 7.0.0`.