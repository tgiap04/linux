# User Stories: Tối giản, Biên dịch và Tùy biến Nhân Hệ điều hành (KMA OS)

## 1. Môi trường Phát triển & Quy trình làm việc (Host-Guest Workflow)
* **US1.1:** Là một lập trình viên, tôi muốn có thể viết, chỉnh sửa mã nguồn C/C++ và file cấu hình trực tiếp trên môi trường macOS (Host) bằng các IDE quen thuộc (như VS Code) để tối ưu hóa tốc độ và trải nghiệm gõ code.
* **US1.2:** Là một kỹ sư hệ thống, tôi muốn toàn bộ mã nguồn được đồng bộ mượt mà vào máy ảo và quá trình biên dịch Kernel (chạy lệnh `make`) phải được thực thi hoàn toàn trên môi trường máy ảo Ubuntu (Guest) để đảm bảo tính tương thích tuyệt đối với lõi Linux.
* **US1.3:** Là một kỹ sư hệ thống, tôi muốn quá trình build nhân trên máy ảo có thể tận dụng tối đa số lượng nhân CPU được cấp phát từ máy Host (macOS) để rút ngắn tối đa thời gian chờ đợi khi biên dịch.

## 2. Tối giản triệt để & Khởi động siêu tốc (Minimalist Kernel)
* **US2.1:** Là một kỹ sư hệ thống, tôi muốn sử dụng công cụ quét phần cứng tự động để loại bỏ toàn bộ các driver và module không cần thiết ra khỏi mã nguồn Linux, giúp giảm thiểu tối đa dung lượng file cấu hình Kernel.
* **US2.2:** Là một kỹ sư hệ thống, tôi muốn hệ điều hành bỏ qua các tiến trình khởi tạo dư thừa nhằm đạt được thời gian boot (khởi động) ở mức vài giây, tối ưu hóa tài nguyên cho môi trường ảo hóa.
* **US2.3:** Là một quản trị viên, tôi muốn sử dụng lệnh `systemd-analyze` để có thể đo lường và hiển thị chính xác thời gian hệ thống khởi động, làm bằng chứng cho việc tối ưu hiệu năng thành công.

## 3. Nhận diện thương hiệu "KMA OS" (Branding & Custom Boot)
* **US3.1:** Là một người dùng hệ thống, tôi muốn lệnh `uname -r` trả về hậu tố mang tên `kma-os-minimal` thay vì `generic` mặc định, để xác nhận rằng hệ thống đang chạy trên một lõi nhân tự biên dịch độc quyền.
* **US3.2:** Là một người dùng hệ thống, tôi muốn nhìn thấy thông báo chào mừng tùy biến (ví dụ: "Welcome to KMA OS") được in ra trực tiếp từ mã nguồn `init/main.c` ngay khi nhân vừa nạp xong.
* **US3.3:** Là một người dùng hệ thống, tôi muốn logo chim cánh cụt Tux mặc định lúc khởi động được thay thế bằng một biểu tượng ASCII tối giản mang bản sắc riêng của KMA OS, tạo hiệu ứng thị giác chuyên nghiệp.

## 4. Khiên bảo vệ tầng VFS (Kernel File Protection)
* **US4.1:** Là một chuyên gia bảo mật, tôi muốn hệ điều hành có một đoạn mã (hook) cấy trực tiếp vào tầng Virtual File System (VFS) để giám sát liên tục mọi hành vi gọi hàm `unlink` (xóa) và `write` (ghi đè).
* **US4.2:** Là một chuyên gia bảo mật, tôi muốn Kernel tự động trả về lỗi `Permission Denied` chặn đứng mọi nỗ lực can thiệp vào các thư mục chứa mã nguồn quan trọng, ngay cả khi lệnh đó được thực thi bằng quyền `root` (sudo).
* **US4.3:** Là một chuyên gia bảo mật, tôi muốn thuật toán tra cứu đường dẫn chặn file phải được thiết kế tối ưu, không làm giảm tốc độ Đọc/Ghi chung của các tiến trình hệ thống khác đang chạy song song trên máy ảo.