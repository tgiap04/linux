# Design Guidelines

## 1. Kernel Branding

- Banner text: `╔══════════════════════════════════════╗` box with "Welcome to KMA OS" and "Minimalist Linux Kernel" on separate lines.
- ASCII logo: box-drawing characters forming the "KMA OS" wordmark — no raster images, no colour codes, max 80 columns wide.
- Both must print via `pr_info()` so they appear in `dmesg` and `journalctl -b`.

## 2. VFS Guard

- **Block, never corrupt.** The guard returns `-EPERM`; it does not rename, move, or modify the target.
- **Hardlink-aware.** Use `(inode->i_ino, sb->s_dev)` as the hash key — stable under rename, correct across hardlinks.
- **Fail closed.** If the hash lookup fails, allow the operation (not deny it by default).
- **No sleeping in hooks.** All hook functions must be non-sleeping; never call `mutex_lock` or `kmalloc(GFP_KERNEL)` in hook context.

## 3. VM Configuration

- Headless only (`display = "none"`); all interaction over SSH.
- Default SSH target: `kma@10.0.2.15`; change via `KMA_VM_SSH` env var.
- Default sync destination: `/home/kma/kernel-src/`; change via `KMA_VM_DIR` env var.
- Swap: exactly 8 GB at `/swapfile`.

## 4. Kernel Config

- `make localmodconfig` is the primary method — it reacts to the live hardware detected in the VM.
- `LOCALVERSION` must always be `-kma-os-minimal` so `uname -r` is unambiguous.
- Target: < 300 `=y`/`=m` items in the final `.config`.
- Boot time target: < 10 seconds (measured by `systemd-analyze`).

## 5. Testing

- Every test script returns exit 0 on pass, non-zero on fail — no silent failures.
- VFS guard tests must verify both the negative (blocked) and positive (allowed) cases.
- Branding tests check `dmesg` output; note that the ring buffer has finite size; run branding tests immediately after boot.
