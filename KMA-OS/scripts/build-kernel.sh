#!/usr/bin/env bash
# build-kernel.sh — Download, configure, and build KMA OS minimal kernel
# Run inside the Ubuntu VM.
set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
KMA_KERNEL_SRC="${KMA_KERNEL_SRC:-$HOME/kernel-src/linux-7.0}"
KMA_LOCALVERSION="${KMA_LOCALVERSION:--kma-os-minimal}"
KMA_KERNEL_VERSION="${KMA_KERNEL_VERSION:-7.0}"
KMA_JOBS="${KMA_JOBS:-$(nproc)}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# --- Check if running inside VM ---
if [ ! -f /proc/modules ]; then
    fail "Script must run INSIDE the Ubuntu VM, not on macOS host!
    SSH into VM first: ssh tobi@192.168.64.3
    Then run: bash ~/projects/linux/KMA-OS/scripts/build-kernel.sh"
fi

# --- 1. Download kernel source ---
info "Kernel source: $KMA_KERNEL_SRC"
info "Project dir:   $PROJECT_DIR"
info "HOME:          $HOME"

if [ ! -f "$KMA_KERNEL_SRC/Makefile" ]; then
    TARBALL="linux-${KMA_KERNEL_VERSION}.tar.xz"
    URL="https://cdn.kernel.org/pub/linux/kernel/v7.x/${TARBALL}"
    mkdir -p "$(dirname "$KMA_KERNEL_SRC")" || fail "Cannot create kernel-src dir"
    info "Downloading kernel ${KMA_KERNEL_VERSION} source tarball..."
    cd "$(dirname "$KMA_KERNEL_SRC")"
    if [ ! -f "$TARBALL" ]; then
        wget -q --show-progress "$URL" || fail "Download failed"
    fi
    info "Extracting tarball..."
    tar xf "$TARBALL"
    # Rename extracted dir to expected path
    EXTRACTED="linux-${KMA_KERNEL_VERSION}"
    if [ "$EXTRACTED" != "$(basename "$KMA_KERNEL_SRC")" ]; then
        rm -rf "$KMA_KERNEL_SRC"
        mv "$EXTRACTED" "$KMA_KERNEL_SRC"
    fi
    info "Kernel source ready"
else
    info "Kernel source exists at $KMA_KERNEL_SRC"
fi

cd "$KMA_KERNEL_SRC"

# --- 1b. Apply KMA OS patches (branding banner/logo, etc.) ---
# Patches live in $PROJECT_DIR/patches and are applied onto the clean kernel tree
# before configuring/building, so the changes are compiled INTO the kernel image
# (permanent — printed every boot, no module to load). Idempotent: re-running the
# script skips patches already applied, so it is safe to run repeatedly.
PATCH_DIR="$PROJECT_DIR/patches"
if [ -d "$PATCH_DIR" ]; then
    shopt -s nullglob
    for patch in "$PATCH_DIR"/*.patch; do
        name="$(basename "$patch")"
        # Already applied? `patch -R --dry-run` succeeds when the change is present.
        if patch -p1 -R --dry-run --force <"$patch" >/dev/null 2>&1; then
            info "Patch already applied, skipping: $name"
            continue
        fi
        # Not applied yet — verify it applies cleanly, then apply for real.
        if patch -p1 --dry-run --force <"$patch" >/dev/null 2>&1; then
            patch -p1 <"$patch" >/dev/null && info "Applied patch: $name" \
                || fail "Failed to apply patch: $name"
        else
            fail "Patch does not apply cleanly to this kernel tree: $name
    Regenerate it against linux-${KMA_KERNEL_VERSION} (see README 'Branding')."
        fi
    done
    shopt -u nullglob
else
    warn "No patches directory at $PATCH_DIR — skipping branding patches"
fi

# --- 2. LOCALVERSION ---
# The real suffix (-kma-os-minimal) is set ONLY via .config (scripts/config below).
# We must NOT export LOCALVERSION with a value, or the build appends BOTH the env var
# and the .config value -> doubled suffix (-kma-os-minimal-kma-os-minimal).
#
# BUT scripts/setlocalversion appends a trailing "+" whenever the tree is a git repo
# with uncommitted changes (our case: patches applied into a git-init'd tree). Its own
# comment says: if LOCALVERSION is set "(including being set to an empty string), we
# don't want to append a plus sign." So we export it as EMPTY: kills the "+", adds
# nothing to the name. Result: a clean "-kma-os-minimal" with no "+".
info "LOCALVERSION will be set in .config: $KMA_LOCALVERSION"
export LOCALVERSION=""
rm -f .scmversion 2>/dev/null || true

# --- 3. Configure with localmodconfig ---
info "Generating minimal config via localmodconfig..."
if [ -f /proc/modules ]; then
    yes "" | make localmodconfig || true
    # Resolve any NEW options that localmodconfig couldn't handle
    info "Resolving config dependencies..."
    yes "" | make olddefconfig || true
else
    warn "Not running inside VM — using default config"
    make defconfig
fi

# Set LOCALVERSION in .config
info "Setting LOCALVERSION..."
scripts/config --set-str LOCALVERSION "$KMA_LOCALVERSION"
yes "" | make olddefconfig || true
info "LOCALVERSION set to: $KMA_LOCALVERSION"

# Disable DWARF5 debug info (kernel 7.0 needs libdwarf-dev which may not be available)
info "Disabling DWARF5 debug info (not needed for custom kernel)..."
scripts/config --disable CONFIG_DEBUG_INFO_DWARF5

# Disable Ubuntu/Debian signing & revocation keys.
# localmodconfig inherits the running Ubuntu kernel's config, which points
# CONFIG_SYSTEM_TRUSTED_KEYS / CONFIG_SYSTEM_REVOCATION_KEYS / CONFIG_MODULE_SIG_KEY
# at debian/*.pem files that do NOT exist in the kernel.org tarball, causing:
#   "No rule to make target 'debian/canonical-revoked-certs.pem'"
info "Disabling Ubuntu signing/revocation cert keys..."
scripts/config --disable CONFIG_SYSTEM_REVOCATION_KEYS
scripts/config --disable CONFIG_SYSTEM_TRUSTED_KEYS
scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""
scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""

# Disable module signing entirely. With MODULE_SIG_KEY="" but MODULE_SIG_ALL=y,
# `make modules_install` tries to sign each .ko with an empty key path and fails:
#   "SSL error: DECODER routines::unsupported ... sign-file: ./"
info "Disabling module signing..."
scripts/config --disable CONFIG_MODULE_SIG
scripts/config --disable CONFIG_MODULE_SIG_ALL
scripts/config --disable CONFIG_MODULE_SIG_FORCE
scripts/config --set-str CONFIG_MODULE_SIG_KEY ""
yes "" | make olddefconfig || true

# --- 3b. Enable KMA VFS guard LSM (built-in) ---
# Patch 0003 adds security/kma-vfs-guard/Kconfig which defines this option.
# We enable it and append the LSM name to CONFIG_LSM so the hooks actually run at boot.
if grep -q "CONFIG_SECURITY_KMA_VFS_GUARD" "$KMA_KERNEL_SRC/security/kma-vfs-guard/Kconfig" 2>/dev/null; then
    info "Enabling KMA VFS guard LSM in .config..."
    scripts/config --enable CONFIG_SECURITY_KMA_VFS_GUARD
    CURRENT_LSM=$(sed -n 's/^CONFIG_LSM="//p' .config | tr -d '"' 2>/dev/null || echo "")
    case "$CURRENT_LSM" in
        *kma_vfs_guard*) ;;
        *) scripts/config --set-str CONFIG_LSM "${CURRENT_LSM:+${CURRENT_LSM},}kma_vfs_guard" ;;
    esac
    yes "" | make olddefconfig || true
    info "CONFIG_LSM: $(sed -n 's/^CONFIG_LSM="//p' .config | tr -d '"')"
else
    warn "security/kma-vfs-guard/Kconfig not found — VFS guard not enabled (patch 0003 missing?)"
fi

# --- 4. Build ---
info "Building kernel with -j${KMA_JOBS}..."
info "This will take 20-60 minutes depending on CPU..."
# Verify required build dependencies (libdwarf-dev not needed — DWARF5 disabled)
dpkg -s libelf-dev >/dev/null 2>&1 || fail "Missing dependency: libelf-dev — run: sudo apt install -y libelf-dev"
BUILD_START=$(date +%s)
make -j"$KMA_JOBS"
BUILD_END=$(date +%s)
BUILD_MIN=$(( (BUILD_END - BUILD_START) / 60 ))
BUILD_SEC=$(( (BUILD_END - BUILD_START) % 60 ))
info "Build completed in ${BUILD_MIN}m${BUILD_SEC}s"

# --- 5. Install ---
info "Installing modules..."
sudo make modules_install

info "Installing kernel..."
# The zz-flash-kernel postinst hook targets embedded ARM boards (Raspberry Pi, etc.)
# and fails on a UTM/QEMU virtual machine ("dpkg-query: no packages found matching").
# The kernel + initrd are already installed before that hook runs, so we tolerate
# its non-zero exit. Real install failures still surface via the boot check below.
sudo make install || warn "make install hook returned non-zero (likely zz-flash-kernel on a VM) — continuing"

# Verify the kernel image actually landed in /boot before claiming success.
KREL=$(make -s kernelrelease 2>/dev/null || echo "")
if [ -n "$KREL" ] && ! ls /boot/vmlinu*"-${KREL}" >/dev/null 2>&1; then
    fail "Kernel image for ${KREL} not found in /boot — install genuinely failed"
fi
info "Kernel image present in /boot for ${KREL}"

# --- 6. Update GRUB + set new kernel as default ---
# grub-set-default only takes effect when GRUB_DEFAULT=saved. Ubuntu ships GRUB_DEFAULT=0,
# which always boots the first (stock generic) entry. Switch to "saved" first.
if ! grep -q '^GRUB_DEFAULT=saved' /etc/default/grub 2>/dev/null; then
    info "Switching GRUB_DEFAULT to 'saved' so we can pin our kernel..."
    sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
fi

info "Updating GRUB..."
sudo update-grub 2>/dev/null || sudo grub-mkconfig -o /boot/grub/grub.cfg

# update-grub lists the stock generic kernel first, so GRUB_DEFAULT=0 keeps booting
# the old kernel even though ours installed fine. Pin our kernel via grub-set-default,
# which keys off the menuentry_id_option (the 'gnulinux-...-VERSION-...' string at the
# end of each menuentry line) — NOT the human title. The id reliably contains $KREL,
# whereas the title may just read "Ubuntu". Modern Ubuntu also nests non-default
# kernels inside the "Advanced options" submenu, so the target id is "<submenu-id>>
# <entry-id>". We resolve both ids from grub.cfg and join them.
info "Setting ${KREL} as the default GRUB entry..."
GRUB_CFG=/boot/grub/grub.cfg

# Entry id for our kernel: the 'gnulinux-<KREL>-advanced-...' string, excluding the
# recovery variant and the .old duplicate left by a previous install. Each grub.cfg
# menuentry/submenu line ends with: $menuentry_id_option 'ID' { — extract that ID.
ENTRY_ID=$(grep "menuentry_id_option '" "$GRUB_CFG" 2>/dev/null \
    | grep -- "$KREL" | grep -v 'recovery' | grep -v '\.old' \
    | head -1 | sed -E "s/.*menuentry_id_option '([^']*)'.*/\1/")

# Submenu id ("Advanced options for Ubuntu") — non-default kernels are nested under it.
SUBMENU_ID=$(grep "^submenu '" "$GRUB_CFG" 2>/dev/null \
    | head -1 | sed -E "s/.*menuentry_id_option '([^']*)'.*/\1/")

if [ -n "$ENTRY_ID" ]; then
    if [ -n "$SUBMENU_ID" ]; then
        TARGET="${SUBMENU_ID}>${ENTRY_ID}"
    else
        TARGET="$ENTRY_ID"
    fi
    sudo grub-set-default "$TARGET" \
        && info "GRUB default set to: $TARGET" \
        || warn "grub-set-default failed for '$TARGET' — pick ${KREL} manually in the GRUB menu at boot"
else
    warn "No menuentry_id_option found for ${KREL} — select it manually in the GRUB menu at boot"
fi

# --- 7. Summary ---
NEW_KERNEL=$(make kernelrelease 2>/dev/null || echo "unknown")
info "=== Build Complete ==="
echo "  Kernel:    $NEW_KERNEL"
echo "  Build dir: $KMA_KERNEL_SRC"
echo "  Config:    $KMA_KERNEL_SRC/.config"
echo ""
info "Reboot into new kernel: sudo reboot"
info "After reboot, verify: uname -r"
