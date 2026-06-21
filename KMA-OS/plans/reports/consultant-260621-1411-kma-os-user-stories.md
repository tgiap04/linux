# Tư vấn: User Stories KMA OS

**Ngày:** 26/06/2026  
**Cấp:** CTO | **Mức:** medium  
**Trạng thái:** ✅ Đã chốt hướng

---

## Tổng quan

User stories mô tả một **hệ điều hành Linux tùy biến hoàn toàn** (KMA OS) với 4 nhóm yêu cầu: Host-Guest workflow, kernel tối giản, branding, và VFS protection.

Hiện tại repo chỉ có `user_stories.md`. Code cũ trong git history (sys-cli, package-hiding) là **tooling hỗ trợ**, chưa phải kernel.

---

## Quyết định đã chốt

| # | Câu hỏi | Trả lời |
|---|---------|---------|
| 1 | Kernel source version | **Linux 7.0.0-22-generic** (Ubuntu kernel tree) |
| 2 | Platform ảo hóa | **UTM** trên macOS (built on QEMU) |
| 3 | VFS Protection scope | **Chỉ chặn unlink** — chặn xóa file trong protected dirs |
| 4 | Thứ tự thực hiện | **Đúng thứ tự user stories** — tuần tự US1 → US2 → US3 → US4 |

---

## Phân tích từng nhóm User Story

### Group 1: Host-Guest Workflow (US1.1–1.3) — Nền tảng

**Nội dung:**
- US1.1: Viết code trên macOS host bằng VS Code
- US1.2: Sync code vào Ubuntu VM, build kernel trên guest
- US1.3: Tận dụng multi-core CPU host để build nhanh

**Cần làm:**
- Tạo UTM VM config (Ubuntu Server)
- Script sync NFS/rsync từ Host → Guest
- Build script chạy `make -j$(nproc)`
- Verifier workflow hoạt động smooth

**Kỹ thuật đề xuất:**
- UTM VM Ubuntu 24.04 LTS
- Shared folder (UTM built-in) hoặc rsync
- `make -j$(nproc)` trong VM

---

### Group 2: Minimalist Kernel (US2.1–2.3) — Tối giản

**Nội dung:**
- US2.1: Quét phần cứng, loại bỏ driver thừa
- US2.2: Boot siêu tốc bằng cách bỏ init thừa
- US2.3: Đo boot time bằng systemd-analyze

**Cần làm:**
- Clone kernel source Ubuntu (7.0.0-22-generic)
- `make localmodconfig` để auto-generate .config dựa trên hardware đang dùng
- Tối ưu boot: disable services thừa
- Benchmark systemd-analyze

**Kỹ thuật đề xuất:**
- Bước 1: `make tinyconfig` (kernel config tối thiểu)
- Bước 2: `make localmodconfig` (thêm driver cần thiết từ hardware hiện tại)
- Bước 3: Review `.config`, disable thêm nếu cần
- Boot optimization: disable Bluetooth, wireless, unused systemd services

---

### Group 3: Branding (US3.1–3.3) — Nhận diện

**Nội dung:**
- US3.1: `uname -r` trả về hậu tố `kma-os-minimal`
- US3.2: Banner "Welcome to KMA OS" in từ `init/main.c`
- US3.3: Thay logo Tux bằng ASCII art KMA OS

**Cần làm:**
- Sửa LOCALVERSION trong `.config`: `CONFIG_LOCALVERSION="-kma-os-minimal"`
- Modify `init/main.c` thêm printk banner
- Tạo ASCII art KMA OS, inject vào boot sequence

**Kỹ thuật đề xuất:**
- LOCALVERSION đơn giản nhất
- Banner: thêm `printk(KERN_INFO "Welcome to KMA OS\n")` trong `start_kernel()`
- Logo: dùng FRAMEBUFFER_CONSOLE + custom logo hoặc print ASCII via printk

---

### Group 4: VFS Protection (US4.1–4.3) — Bảo vệ (phức tạp nhất)

**Nội dung:**
- US4.1: Hook VFS giám sát unlink
- US4.2: Trả Permission Denied cho root khi xóa protected dirs
- US4.3: Thuật toán tra cứu phải optimize, không ảnh hưởng I/O

**Kỹ thuật đề xuất (chỉ unlink):**
- **Approach:** LSM (Linux Security Module) hook — đơn giản hơn và an toàn hơn so với kprobes
  - Implement `security_inode_unlink()` callback
  - Dùng path-based check: nếu path chứa protected dir → return -EPERM
  - Protected dirs: list paths trong module parameter
- **Approach thay thế:** kprobes trên `vfs_unlink` — linh hoạt hơn nhưng fragile hơn khi kernel update

**Hiệu năng:**
- Hash-based path prefix check hoặc radix tree cho protected paths
- Không traverse VFS cho mỗi unlink, chỉ check prefix

---

## Thứ tự implement đề xuất

```
Phase 1: Host-Guest Workflow (US1.1–1.3)
  └─ Tạo UTM VM + build scripts
  
Phase 2: Minimalist Kernel (US2.1–2.3)  
  └─ Clone kernel, optimize config, benchmark
  
Phase 3: Branding (US3.1–3.3)
  └─ Modify LOCALVERSION + init/main.c
  
Phase 4: VFS Protection (US4.1–4.3)
  └─ Implement kernel hook
  
Phase 5: Integration & Testing
  └─ Boot test toàn bộ pipeline
```

---

## Rủi ro

| Rủi ro | Mức | Mitigation |
|--------|-----|------------|
| Kernel 7.0.0-22-generic chưa tồn tại trên git.kernel.org | Cao | Xác nhận lại — dùng Ubuntu kernel tree hoặc version có sẵn |
| UTM VM setup mất thời gian | Trung bình | Tạo script reproducible |
| VFS hook gây deadlock nếu treo lock | Cao | Dùng LSM framework thay vì kprobes |
| Build kernel lần đầu mất 30-90 phút | Thấp | Bằng chứng benchmark thành công |

---

## Câu hỏi chưa giải quyết

1. **Kernel 7.0.0-22-generic**: Version này có chưa? Cần xác nhận Ubuntu kernel tree hoặc chọn version có sẵn trên git.kernel.org

---

## Kết luận

Hướng đi rõ ràng. Bắt đầu từ Phase 1 (UTM VM setup) là nền tảng cho tất cả. VFS Protection (Phase 4) là phần phức tạp nhất — dùng LSM framework sẽ an toàn hơn kprobes.
