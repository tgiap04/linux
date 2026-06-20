# User Stories: System Management Shell Script (sys-manager)

## 1. Quản lý File và Thư mục

- **US1.1:** Là một quản trị viên hệ thống, tôi muốn script có thể tự động tạo, xóa, và di chuyển file/thư mục hàng loạt để không phải thực hiện các thao tác tay lặp đi lặp lại.
- **US1.2:** Là một quản trị viên hệ thống, tôi muốn có tính năng tìm kiếm các file có dung lượng lớn hơn mức chỉ định, sau đó tự động nén hoặc dọn dẹp chúng để tối ưu hóa không gian lưu trữ.
- **US1.3:** Là một quản trị viên, tôi muốn script cấp quyền (chmod/chown) tự động cho một nhóm file cụ thể để đảm bảo bảo mật đúng quy chuẩn.

## 2. Lập lịch tác vụ (Cron Jobs)

- **US2.1:** Là một kỹ sư vận hành, tôi muốn script cung cấp menu để thêm một tác vụ mới vào `crontab` một cách trực quan, giúp tôi không cần nhớ cú pháp phức tạp của cron.
- **US2.2:** Là một kỹ sư vận hành, tôi muốn có thể liệt kê và xóa các cron job đang chạy thông qua script để dễ dàng quản lý các tiến trình tự động.
- **US2.3:** Là một kỹ sư vận hành, tôi muốn thiết lập lịch tự động backup một thư mục quan trọng mỗi ngày vào lúc nửa đêm để đảm bảo an toàn dữ liệu.

## 3. Thiết lập thời gian hệ thống

- **US3.1:** Là một quản trị viên, tôi muốn xem thời gian và múi giờ hiện tại của hệ thống để kiểm tra tính chính xác của log.
- **US3.2:** Là một quản trị viên, tôi muốn có thể thay đổi múi giờ (Timezone) của server (ví dụ: sang `Asia/Ho_Chi_Minh`) thông qua script một cách nhanh chóng.
- **US3.3:** Là một quản trị viên, tôi muốn script có khả năng kích hoạt đồng bộ hóa thời gian mạng (NTP/chrony) để server luôn giữ giờ chuẩn xác.

## 4. Quản lý phần mềm (Packages)

- **US4.1:** Là một nhà phát triển, tôi muốn dùng script để cài đặt tự động các gói phần mềm cần thiết (ví dụ: `git`, `curl`, `nginx`) chỉ bằng một phím bấm, giúp thiết lập môi trường (provisioning) nhanh hơn.
- **US4.2:** Là một nhà phát triển, tôi muốn script có thể gỡ bỏ sạch sẽ (purge) một ứng dụng và dọn dẹp các thư viện thừa (autoremove) để hệ thống luôn nhẹ nhàng.
- **US4.3:** Là một nhà phát triển, tôi muốn có tùy chọn cập nhật toàn bộ hệ thống (`apt update && apt upgrade`) tự động thông qua menu của script.

## 5. Tường lửa Lõi Nhân Linux (ubuntu_firewall)

### 5.1 Quản lý Vòng đời Module (Module Lifecycle)

- **US5.1.1:** Là một quản trị viên hệ thống, tôi muốn nạp (insmod) và gỡ bỏ (rmmod) module `ubuntu_firewall.ko` vào nhân Linux mà không cần khởi động lại máy chủ.
- **US5.1.2:** Là một quản trị viên hệ thống, khi module được bật hoặc tắt, nó phải in thông báo trạng thái (ví dụ: "ubuntu_firewall: Activated") vào kernel ring buffer (`dmesg`) để tôi xác nhận trạng thái qua `dmesg | tail`.

### 5.2 Kiểm soát Luồng Mạng (Traffic Filtering)

- **US5.2.1:** Là một kỹ sư bảo mật, tôi muốn module tự động phát hiện và drop mọi gói ICMP (ping) từ bên ngoài vào, nhằm ẩn hệ thống khỏi các công cụ quét mạng tự động.
- **US5.2.2:** Là một kỹ sư vận hành, tôi muốn module accept các gói TCP/UDP thông thường (SSH port 22, Web port 3000) để đảm bảo dịch vụ của tôi không bị chặn nhầm.
- **US5.2.3 (Nâng cao):** Là một kỹ sư bảo mật, tôi muốn cấu hình được danh sách port TCP cần reject (ví dụ: port 21 FTP) qua sysfs interface, mà không cần recompile module.

### 5.3 Ghi log và Giám sát (Auditing & Logging)

- **US5.3.1:** Là một nhà phân tích bảo mật, mỗi khi module drop/reject một gói tin, nó phải log sự kiện (kèm protocol: ICMP/TCP/UDP) vào kernel ring buffer qua `printk`.
- **US5.3.2:** Là một nhà phân tích bảo mật, tôi muốn xem log blocked packets theo thời gian thực bằng `dmesg | grep ubuntu_firewall`.
- **US5.3.3 (Web Dashboard):** Là một quản trị viên, tôi muốn Web Dashboard hiển thị trực quan danh sách các "nỗ lực tấn công" bị chặn (đọc từ dmesg/syslog), kèm thời gian, protocol, và nguồn IP nếu có.

### 5.4 Giao diện Quản lý (CLI & Web)

- **US5.4.1:** Là một quản trị viên, tôi muốn menu riêng trong sys-cli.sh để insmod, rmmod, enable/disable, xem trạng thái và cấu hình module tường lửa.
- **US5.4.2:** Là một quản trị viên, tôi muốn Web Dashboard có trang riêng cho firewall: toggle enable/drop_icmp, điền port cần reject, xem bảng blocked events.
- **US5.4.3:** Trạng thái và cấu hình tường lửa được expose qua sysfs tại `/sys/firewall/{enabled,drop_icmp,reject_ports,status}` — CLI và Web đều thao tác qua đây.