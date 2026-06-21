# KMA OS Kernel

Nhân Linux tùy biến 7.0 được xây dựng cho máy ảo UTM/QEMU. Tạo ra một kernel tối giản với tên `kma-os-minimal`, tích hợp bảo vệ VFS qua LSM loadable module.

## Tổng quan

| Thành phần | Chi tiết |
|---|---|
| **Kernel gốc** | Linux mainline 7.0 (kernel.org tarball) |
| **LOCALVERSION** | `-kma-os-minimal` (hiển thị trong `uname -r`) |
| **Mục tiêu** | UTM trên macOS (Apple Silicon), virtio, headless, 8 GB RAM |
| **Yêu cầu** | Boot < 10s, số module loaded < 50, chặn `rm`/`mv` trên thư mục bảo vệ |

## Yêu cầu hệ thống

- macOS (Apple Silicon hoặc Intel)
- UTM (tải từ [getutm.app](https://getutm.app))
- Ubuntu 24.04+ ARM64 ISO (cho UTM)
- Ít nhất 8 GB RAM host

---

## Hướng dẫn Setup Chi tiết

### Bước 1: Tạo máy ảo UTM

1. Mở UTM → nhấn **+ Create New** → chọn **Virtualize**
2. Chọn **Linux** → tải Ubuntu Server ISO từ [ubuntu.com](https://ubuntu.com/download/server)
3. Cấu hình VM:
   - **CPU:** chọn tất cả core có sẵn
   - **RAM:** 8192 MB (8 GB)
   - **Disk:** 60 GB (qcow2)
   - **Network:** NAT (mặc định)
   - **Display:** None (headless, chỉ dùng SSH)
4. Hoàn tất, khởi động VM, cài đặt Ubuntu bình thường

### Bước 2: Cài đặt dependencies trên Guest (Ubuntu VM)

```bash
# Đăng nhập vào VM
ssh tobi@192.168.64.3

# Cài tất cả công cụ build kernel
sudo apt update
sudo apt install -y \
    build-essential libncurses-dev libssl-dev libelf-dev libdwarf-dev \
    flex bison dwarves pahole python3 cpio zstd rsync \
    bc git wget xz-utils openssh-server
```

> **Hoặc dùng script tự động** (chạy trong VM):

```bash
cd ~/projects/linux/KMA-OS
bash scripts/setup-vm.sh
```

Script sẽ tự động: cài dependencies, cấu hình SSH, tạo swap 8 GB.

### Bước 3: Sync source từ macOS Host sang VM

```bash
# Trên macOS host — chạy từ thư mục dự án
./scripts/sync-to-vm.sh
```

Hoặc sync thủ công:

```bash
rsync -avz --exclude='.git/' --exclude='build/' \
    ./ tobi@192.168.64.3:~/projects/linux/KMA-OS/
```

### Bước 4: Build kernel trên VM

> **QUAN TRỌNG:** Bước này phải chạy **trong Ubuntu VM**, không phải trên macOS host!

```bash
# SSH vào VM trước
ssh tobi@192.168.64.3

# Tải kernel source tarball
mkdir -p ~/kernel-src && cd ~/kernel-src
wget https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0.tar.xz
tar xf linux-7.0.tar.xz
cd linux-7.0

# Apply patch branding (banner + logo) vào kernel source TRƯỚC khi build.
# Build thẳng vào kernel image -> hiển thị mỗi lần boot, vĩnh viễn, không cần load module.
patch -p1 < ~/projects/linux/KMA-OS/patches/0002-kma-boot-branding.patch

# Đặt LOCALVERSION tùy biến
export LOCALVERSION="-kma-os-minimal"

# Tạo cấu hình tối giản dựa trên module đang chạy
make localmodconfig

# Disable DWARF5 debug info (kernel 7.0 cần libdwarf-dev, không cần cho production)
scripts/config --disable CONFIG_DEBUG_INFO_DWARF5

# Disable Ubuntu signing/revocation keys (trỏ tới debian/*.pem không có trong tarball kernel.org)
scripts/config --disable CONFIG_SYSTEM_REVOCATION_KEYS
scripts/config --disable CONFIG_SYSTEM_TRUSTED_KEYS
scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""
scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""

# Disable module signing (tránh lỗi sign-file khi modules_install)
scripts/config --disable CONFIG_MODULE_SIG
scripts/config --disable CONFIG_MODULE_SIG_ALL
scripts/config --disable CONFIG_MODULE_SIG_FORCE
scripts/config --set-str CONFIG_MODULE_SIG_KEY ""
yes "" | make olddefconfig

# Build kernel (tận dụng tất cả core CPU)
make -j$(nproc)

# Cài đặt modules
sudo make modules_install

# Cài đặt kernel
sudo make install

# Cập nhật GRUB
sudo update-grub

# QUAN TRỌNG: build xong reboot vẫn vào kernel gốc là chuyện BÌNH THƯỜNG, không phải lỗi build.
# GRUB mặc định GRUB_DEFAULT=0 = luôn boot entry ĐẦU TIÊN (kernel generic của Ubuntu).
# Kernel custom của ta bị xếp trong submenu "Advanced options", nên phải CHỌN nó làm default.
# GRUB chọn entry theo "id" (menuentry_id_option) chứ không theo tên — bền hơn dùng số thứ tự.

# 1) Cho phép GRUB nhớ lựa chọn đã lưu
sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
sudo update-grub

# 2) Lấy id của kernel mình (loại bản .old và recovery) + id submenu chứa nó, rồi pin vĩnh viễn
KREL=$(uname -r)   # hoặc: 7.0.0-kma-os-minimal
ENTRY_ID=$(grep "menuentry_id_option '" /boot/grub/grub.cfg | grep -- "$KREL" | grep -v 'recovery' | grep -v '\.old' | head -1 | sed -E "s/.*menuentry_id_option '([^']*)'.*/\1/")
SUBMENU_ID=$(grep "^submenu '" /boot/grub/grub.cfg | head -1 | sed -E "s/.*menuentry_id_option '([^']*)'.*/\1/")
sudo grub-set-default "${SUBMENU_ID}>${ENTRY_ID}"

# 3) Kiểm tra đã pin đúng
sudo grub-editenv list      # phải thấy: saved_entry=gnulinux-advanced...>gnulinux-7.0.0-kma-os-minimal-advanced...
```

> **Chỉ boot THỬ 1 lần** (không pin vĩnh viễn — kernel lỗi thì reboot sau tự về generic, an toàn nhất để kiểm tra trước):
>
> ```bash
> sudo grub-reboot "${SUBMENU_ID}>${ENTRY_ID}"   # dùng lại 2 biến ở trên
> sudo reboot
> ```

> **Hoặc dùng script tự động** (chạy trong VM):

```bash
ssh tobi@192.168.64.3
KMA_LOCALVERSION="-kma-os-minimal" \
    bash ~/projects/linux/KMA-OS/scripts/build-kernel.sh
```

### Bước 6: Khởi động lại vào kernel mới

```bash
sudo reboot
```

Sau khi reboot, kiểm tra:

```bash
# Kiểm tra phiên bản kernel
uname -r
# Kết quả mong đợi: 7.0.0-22-generic-kma-os-minimal

# Kiểm tra thời gian boot
systemd-analyze
# Kết quả mong đợi: < 10 giây

# Kiểm tra số module loaded
lsmod | wc -l
# Kết quả mong đợi: < 50
```

---

## Cài đặt Kernel Module

### kma-branding — Banner khởi động

In dòng chữ "Welcome to KMA OS" khi boot:

```bash
# Build module
cd kernel-modules/kma-branding
make

# Load module
sudo insmod kma-branding.ko

# Kiểm tra
dmesg | grep -i "welcome to kma"
journalctl -k | grep -A12 "Welcome to KMA"

# Tự load mỗi lần boot — thêm vào /etc/modules:
echo "kma-branding" | sudo tee -a /etc/modules
```

### kma-vfs-guard — Bảo vệ thư mục (built-in LSM)

Build thẳng vào kernel image — **luôn bật từ lúc boot, không cần insmod/rmmod**.
Chặn `unlink`/`rmdir`/`rename` trên các thư mục được chỉ định.

```bash
# Kiểm tra LSM đã loaded (từ boot):
dmesg | grep kma-vfs-guard
# Kết quả: "kma-vfs-guard: loaded"

# Kiểm tra sysfs tồn tại:
ls /sys/kernel/kma-vfs-guard/
# Kết quả: add_path  remove_path  stats

# Thêm/xóa path bảo vệ runtime:
echo "/home/tobi/projects" | sudo tee /sys/kernel/kma-vfs-guard/add_path    # Thêm
echo "/home/tobi/projects" | sudo tee /sys/kernel/kma-vfs-guard/remove_path  # Xóa
cat /sys/kernel/kma-vfs-guard/stats                                          # Thống kê

# Boot-time: bảo vệ paths qua kernel cmdline (GRUB):
# Thêm vào /etc/default/grub → GRUB_CMDLINE_LINUX: kma_vfs_guard.protected_paths="/etc"
# Hoặc thêm trực tiếp:
sudo sed -i 's/\("GRUB_CMDLINE_LINUX=".*\)"/\1 kma_vfs_guard.protected_paths="\/etc"/' /etc/default/grub
sudo update-grub

# Kiểm tra chặn rm:
sudo rm /etc/hostname
# Kết quả: "Operation not permitted"
```

---

## Chạy Tests

Tất cả tests chạy trên Guest sau khi kernel được cài đặt:

```bash
# Kiểm tra branding
./tests/test-branding.sh

# Kiểm tra boot time
./tests/test-boot.sh

# Kiểm tra VFS guard
./tests/test-vfs-guard.sh

# Chạy tất cả
for t in tests/test-*.sh; do bash "$t"; done
```

---

## Cấu trúc dự án

```
vm/
  kma-os-utm.toml              Cấu hình máy ảo UTM
scripts/
  setup-vm.sh                  Setup guest (dependencies, SSH, swap)
  sync-to-vm.sh                Đồng bộ source từ host sang guest
  build-kernel.sh              Clone + cấu hình + build kernel
  measure-boot.sh              Đo thời gian boot bằng systemd-analyze
patches/
  0002-kma-boot-branding.patch  Banner + logo ASCII trong init/main.c (build vào kernel)
  0003-kma-vfs-guard-lsm.patch  Built-in LSM bảo vệ VFS (security/kma-vfs-guard/)
kernel-modules/
  kma-branding/                Module loadable banner boot (TÙY CHỌN, không bắt buộc)
  kma-vfs-guard/               Source tham khảo LSM guard (patched vào kernel qua 0003)
tests/
  test-branding.sh             Kiểm tra branding (T3.x)
  test-boot.sh                 Kiểm tra boot time (T1.x, T2.x)
  test-vfs-guard.sh            Kiểm tra bảo vệ thư mục (T4.x)
docs/                          Tài liệu kỹ thuật
plans/                         Kế hoạch triển khai
```

---

## Thông tin Kernel

| Thông số | Giá trị |
|---|---|
| Nguồn | `https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0.tar.xz` (mainline) |
| Phiên bản | Linux 7.0 |
| LOCALVERSION | `-kma-os-minimal` |
| Phương thức cấu hình | `make localmodconfig` (~200 mục vs ~15.000 mặc định) |
| Cert keys | Disabled (DWARF5, SYSTEM_TRUSTED/REVOCATION_KEYS, MODULE_SIG_KEY) |
| Branding (banner + logo) | Build thẳng vào kernel qua `patches/0002-kma-boot-branding.patch` — in mỗi lần boot, vĩnh viễn. Kiểm tra: `dmesg \| grep "KMA OS"` |
| VFS Guard | Built-in LSM `kma_vfs_guard` — chặn unlink/rmdir/rename. Luôn bật từ boot. Kiểm tra: `ls /sys/kernel/kma-vfs-guard/` |

---

## Troubleshooting

| Vấn đề | Giải pháp |
|---|---|
| `make localmodconfig` lỗi | Chạy trong VM Ubuntu, đảm bảo `lsmod` có dữ liệu |
| boot time > 10s | Chạy `systemd-analyze blame` kiểm tra service nào chậm nhất |
| SSH không kết nối được | Kiểm tra VM IP: `ip addr show`, đảm bảo SSH server đang chạy |
| LSM guard không hoạt động | Kiểm tra `dmesg \| grep kma-vfs-guard` — nếu không thấy "loaded", chạy lại build-kernel.sh (CONFIG_SECURITY_KMA_VFS_GUARD=y phải được bật). Kiểm tra: `grep CONFIG_LSM /boot/config-$(uname -r)` phải chứa `kma_vfs_guard` |
| GRUB không thấy kernel mới | Chạy `sudo update-grub` rồi reboot lại |
| Reboot xong `uname -r` vẫn ra kernel cũ (`...-generic`) | GRUB mặc định `GRUB_DEFAULT=0` luôn boot entry đầu (generic). Đặt `GRUB_DEFAULT=saved` trong `/etc/default/grub`, `update-grub`, rồi `grub-set-default` vào entry chứa `kma-os-minimal`. Script đã tự làm bước này. Hoặc chọn thủ công trong menu GRUB lúc boot |
| Disk free < 10G | Chạy `sudo make clean` trong thư mục kernel source trước khi build |
| `make install` lỗi `zz-flash-kernel` / `dpkg-query: no packages found` | Hook flash-kernel chỉ dành cho board ARM nhúng, vô hại trên UTM/QEMU. Kernel + initrd đã cài xong trước đó. Script tự bỏ qua; kiểm tra `/boot/vmlinuz-7.0.0-kma-os-minimal` tồn tại là OK |
| `uname -r` ra `...minimal-...minimal` (nhân đôi) | Đừng vừa `export LOCALVERSION` vừa `scripts/config --set-str LOCALVERSION`. Chỉ dùng một cách |
