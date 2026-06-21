# Kernel Development Workflow

## 1. Development Loop

```
macOS (Host)                         Ubuntu VM (Guest)
  Edit source files                   
    └── rsync ──────────────────────►  ./scripts/build-kernel.sh
    ↑                                     └── make -j$(nproc)
    │                                     └── make modules_install
    │                                     └── update-grub
    │                                     └── reboot
    └──────── SSH / shared folder ◄─────
```

### Sync & Build (macOS host)

```bash
./scripts/sync-to-vm.sh              # push source to guest
ssh kma@10.0.2.15                     # connect to guest
# inside VM:
./scripts/build-kernel.sh
sudo reboot
```

---

## 2. VM Setup (One-Time)

```bash
# inside the VM (after booting Ubuntu ISO)
bash /mnt/shared/scripts/setup-vm.sh
```

This installs all build dependencies, enables SSH, configures swap, and sets up the shared folder mount.

---

## 3. Running Tests

After booting the custom kernel:

```bash
# Branding
./tests/test-branding.sh

# Boot minimalism
./tests/test-boot.sh

# VFS guard
./tests/test-vfs-guard.sh
```

All three should exit 0. If any fail, `set -x` or read the script to diagnose.

---

## 4. Rebuilding Modules

Modules are built out-of-tree against the installed kernel headers:

```bash
make -C kernel-modules/kma-vfs-guard clean all
sudo insmod kernel-modules/kma-vfs-guard/kma-vfs-guard.ko
```

---

## 5. Applying Kernel Patches

Patches are applied inside the kernel source tree during the build:

```bash
cd $KERNEL_SRC
git apply ../patches/0002-kma-boot-banner.patch
git apply ../patches/0003-kma-boot-logo.patch
```

Verify with `git apply --check` before applying.

---

## 6. SSH Access

After `setup-vm.sh` runs, the VM prints its IP. Connect from the host:

```bash
ssh kma@10.0.2.15
```

Use `KMA_VM_SSH` and `KMA_VM_DIR` env vars with `sync-to-vm.sh` if the defaults need overriding.

---

## 7. Shared Folder

The 9p virtio shared folder is configured in `vm/kma-os-utm.toml`. Inside the guest it mounts at `/mnt/shared`. Use it as the exchange point between the macOS source tree and the VM build directory.

```bash
# inside guest
ls /mnt/shared/scripts/
sudo mount -t 9p -o trans=virtio,version=9p2000.L KMA-SRC /mnt/shared
```
