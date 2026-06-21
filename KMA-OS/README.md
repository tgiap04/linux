# KMA OS Kernel

Nhân Linux tùy biến 7.0 được xây dựng cho máy ảo UTM/QEMU. Tạo ra một kernel tối giản với tên `kma-os-minimal`, tích hợp bảo vệ VFS qua LSM loadable module.

## Tổng quan

| Thành phần | Chi tiết |
|---|---|
| **Kernel gốc** | Ubuntu Linux `oracular`, tag `Ubuntu-7.0.0-22.22` |
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

> **Hoặc import trực tiếp từ file cấu hình có sẵn:**

```bash
# Copy file cấu hình vào thư mục UTM
cp vm/kma-os-utm.toml ~/Library/Containers/com.utmapp.UTM/Data/Documents/
# Mở UTM và import
```

### Bước 2: Cài đặt dependencies trên Guest (Ubuntu VM)

```bash
# Đăng nhập vào VM qua SSH hoặc UTM display
# Cài đặt tất cả công cụ cần thiết để build kernel:
sudo apt update
sudo apt install -y \
    build-essential libncurses-dev libssl-dev libelf-dev \
    flex bison dwarves pahole python3 cpio zstd rsync \
    bc git wget xz-utils openssh-server
```

> **Hoặc dùng script tự động:**

```bash
# Nếu source đã sync vào VM qua shared folder:
bash /mnt/shared/scripts/setup-vm.sh
```

Script sẽ tự động:
- Cài dependencies
- Cấu hình SSH server
- Tạo swap 8 GB
- Mount shared folder

### Bước 3: Cấu hình SSH (để truy cập từ macOS host)

```bash
# Trong VM: kiểm tra IP
ip addr show

# Trên macOS host: kết nối SSH
ssh kma@<IP_CUA_VM>
```

> **Mẹo:** Lưu SSH config trong `~/.ssh/config` trên macOS để kết nối nhanh:

```
Host kma-vm
    HostName 10.0.2.15
    User kma
```

### Bước 4: Sync source từ Host sang Guest

```bash
# Trên macOS host (thư mục dự án):
rsync -avz --exclude='.git/' --exclude='build/' \
    ./ kma-vm:/home/kma/kernel-src/
```

> **Hoặc dùng script:**

```bash
KMA_VM_SSH="kma@10.0.2.15" ./scripts/sync-to-vm.sh
```

### Bước 5: Clone và build kernel trên Guest

```bash
# Đăng nhập vào VM qua SSH
ssh kma-vm

# Clone kernel source Ubuntu (lần đầu mất vài phút)
git clone --depth=1 --branch Ubuntu-7.0.0-22.22 \
    git://kernel.ubuntu.com/ubuntu/ubuntu-oracular.git \
    ~/kernel-src/ubuntu-kernel

cd ~/kernel-src/ubuntu-kernel

# Đặt LOCALVERSION tùy biến
export LOCALVERSION="-kma-os-minimal"

# Tạo cấu hình tối giản dựa trên module đang chạy
make localmodconfig

# Build kernel (tận dụng tất cả core CPU)
make -j$(nproc)

# Cài đặt modules
sudo make modules_install

# Cài đặt kernel
sudo make install

# Cập nhật GRUB
sudo update-grub
```

> **Hoặc dùng script tự động:**

```bash
KMA_KERNEL_TAG="Ubuntu-7.0.0-22.22" \
KMA_LOCALVERSION="-kma-os-minimal" \
    bash ~/kernel-src/scripts/build-kernel.sh
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

# Tự load mỗi lần boot — thêm vào /etc/modules:
echo "kma-branding" | sudo tee -a /etc/modules
```

### kma-vfs-guard — Bảo vệ thư mục

Chặn `unlink`/`rmdir`/`rename` trên các thư mục được chỉ định:

```bash
# Build module
cd kernel-modules/kma-vfs-guard
make

# Load module với danh sách thư mục bảo vệ
sudo insmod kma-vfs-guard.ko protected_paths="/home/kma/src:/etc"

# Kiểm tra hiệu lực
sudo rm /home/kma/src/testfile
# Kết quả: "Operation not permitted"

# Quản lý qua sysfs tại runtime:
echo "/home/kma/src" | sudo tee /sys/kernel/kma-vfs-guard/add_path    # Thêm
echo "/home/kma/src" | sudo tee /sys/kernel/kma-vfs-guard/remove_path  # Xóa
cat /sys/kernel/kma-vfs-guard/stats                                     # Thống kê

# Gỡ module
sudo rmmod kma-vfs-guard
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
  0002-kma-boot-banner.patch   Banner "Welcome to KMA OS" trong init/main.c
  0003-kma-boot-logo.patch     Logo ASCII trong init/main.c
kernel-modules/
  kma-branding/                Module loadable in banner boot
  kma-vfs-guard/               Module LSM bảo vệ VFS
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
| Repository | `git://kernel.ubuntu.com/ubuntu/ubuntu-oracular.git` |
| Tag | `Ubuntu-7.0.0-22.22` |
| LOCALVERSION | `-kma-os-minimal` |
| Phương thức cấu hình | `make localmodconfig` (~200 mục vs ~15.000 mặc định) |

---

## Troubleshooting

| Vấn đề | Giải pháp |
|---|---|
| `make localmodconfig` lỗi | Chạy trong VM Ubuntu, đảm bảo `lsmod` có dữ liệu |
| boot time > 10s | Chạy `systemd-analyze blame` kiểm tra service nào chậm nhất |
| SSH không kết nối được | Kiểm tra VM IP: `ip addr show`, đảm bảo SSH server đang chạy |
| Module load fail | Kiểm tra `dmesg \| tail`, đảm bảo kernel headers khớp phiên bản |
| GRUB không thấy kernel mới | Chạy `sudo update-grub` rồi reboot lại |
