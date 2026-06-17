# User Stories: System Management Shell Script (sys-manager)

## 1. Quản lý File và Thư mục
* **US1.1:** Là một quản trị viên hệ thống, tôi muốn script có thể tự động tạo, xóa, và di chuyển file/thư mục hàng loạt để không phải thực hiện các thao tác tay lặp đi lặp lại.
* **US1.2:** Là một quản trị viên hệ thống, tôi muốn có tính năng tìm kiếm các file có dung lượng lớn hơn mức chỉ định, sau đó tự động nén hoặc dọn dẹp chúng để tối ưu hóa không gian lưu trữ.
* **US1.3:** Là một quản trị viên, tôi muốn script cấp quyền (chmod/chown) tự động cho một nhóm file cụ thể để đảm bảo bảo mật đúng quy chuẩn.

## 2. Lập lịch tác vụ (Cron Jobs)
* **US2.1:** Là một kỹ sư vận hành, tôi muốn script cung cấp menu để thêm một tác vụ mới vào `crontab` một cách trực quan, giúp tôi không cần nhớ cú pháp phức tạp của cron.
* **US2.2:** Là một kỹ sư vận hành, tôi muốn có thể liệt kê và xóa các cron job đang chạy thông qua script để dễ dàng quản lý các tiến trình tự động.
* **US2.3:** Là một kỹ sư vận hành, tôi muốn thiết lập lịch tự động backup một thư mục quan trọng mỗi ngày vào lúc nửa đêm để đảm bảo an toàn dữ liệu.

## 3. Thiết lập thời gian hệ thống
* **US3.1:** Là một quản trị viên, tôi muốn xem thời gian và múi giờ hiện tại của hệ thống để kiểm tra tính chính xác của log.
* **US3.2:** Là một quản trị viên, tôi muốn có thể thay đổi múi giờ (Timezone) của server (ví dụ: sang `Asia/Ho_Chi_Minh`) thông qua script một cách nhanh chóng.
* **US3.3:** Là một quản trị viên, tôi muốn script có khả năng kích hoạt đồng bộ hóa thời gian mạng (NTP/chrony) để server luôn giữ giờ chuẩn xác.

## 4. Quản lý phần mềm (Packages)
* **US4.1:** Là một nhà phát triển, tôi muốn dùng script để cài đặt tự động các gói phần mềm cần thiết (ví dụ: `git`, `curl`, `nginx`) chỉ bằng một phím bấm, giúp thiết lập môi trường (provisioning) nhanh hơn.
* **US4.2:** Là một nhà phát triển, tôi muốn script có thể gỡ bỏ sạch sẽ (purge) một ứng dụng và dọn dẹp các thư viện thừa (autoremove) để hệ thống luôn nhẹ nhàng.
* **US4.3:** Là một nhà phát triển, tôi muốn có tùy chọn cập nhật toàn bộ hệ thống (`apt update && apt upgrade`) tự động thông qua menu của script.