### Epic: Hệ thống giấu tin bí mật qua kênh ẩn TCP/UDP (Covert Channel)

---

#### Giai đoạn 0: Setup Build System

**User Story 0: Chuẩn bị môi trường Build cho Kernel Module**

- **Là một** lập trình viên.
- **Tôi muốn** thiết lập đầy đủ `Makefile`, `Kbuild`, và đảm bảo môi trường đã cài đặt Linux Headers, `gcc`, `make` phù hợp với kernel version đang chạy.
- **Để** có thể biên dịch kernel module `.ko` bất kỳ lúc nào mà không gặp lỗi dependency.
- **Tiêu chí nghiệm thu:**
- `make` chạy thành công trên Ubuntu Server VM, tạo ra file `.ko`.
- `uname -r` khớp với version của kernel headers đã cài.
- `insmod`, `rmmod` hoạt động trên module test đơn giản.

---

#### Giai đoạn 1: Thiết lập nền tảng Kernel Module

**User Story 1: Tạo bộ khung LKM cơ bản**

- **Là một** lập trình viên.
- **Tôi muốn** viết và biên dịch thành công một Linux Kernel Module "Hello World".
- **Để** đảm bảo môi trường máy ảo Ubuntu Server của tôi đã cài đặt đủ Linux Headers và công cụ build (make, gcc) chính xác.
- **Tiêu chí nghiệm thu:**
- Lệnh `make` chạy thành công tạo ra file `.ko`.
- Lệnh `sudo insmod` tải module không báo lỗi.
- Lệnh `dmesg` hiển thị dòng log "Hello World" từ kernel.
- Lệnh `sudo rmmod` gỡ module an toàn.

**User Story 2: Đăng ký Netfilter Hook**

- **Là một** lập trình viên.
- **Tôi muốn** đăng ký một hook vào điểm `NF_INET_LOCAL_OUT` (hoặc `NF_INET_POST_ROUTING`) bằng Netfilter.
- **Để** module của tôi có thể chặn (intercept) tất cả các gói tin mạng trước khi chúng rời khỏi máy tính.
- **Tiêu chí nghiệm thu:**
- Module in ra log `dmesg` mỗi khi có một gói tin mạng đi qua (chỉ in IP đích để test, tránh spam log làm treo máy).
- Module không làm gián đoạn kết nối mạng bình thường (gói tin vẫn được trả về `NF_ACCEPT`).

**User Story 3: Cleanup Module khi unload (Bổ sung)**

- **Là một** lập trình viên kernel.
- **Tôi muốn** module tự động gọi `nf_unregister_net_hook()` khi bị unload và giải phóng mọi tài nguyên đã cấp phát.
- **Để** tránh leak bộ nhớ hoặc crash kernel khi chạy `rmmod`.
- **Tiêu chí nghiệm thu:**
- `rmmod` không gây warning trong `dmesg`.
- Kiểm tra `dmesg` sau unload không có dòng nào liên quan đến resource leak.
- Sau unload, hook không còn active — traffic đi qua không bị can thiệp.

**User Story 4: Module Parameters — cấu hình runtime (Bổ sung)**

- **Là một** người vận hành.
- **Tôi muốn** có thể truyền tham số cho module khi load (port mục tiêu, IP đích) qua `insmod` hoặc `MODULE_PARM`.
- **Để** không phải hardcode port/IP, giúp module linh hoạt trong test và vận hành.
- **Tiêu chí nghiệm thu:**
- `insmod covert.ko target_port=9999 target_ip="10.0.2.15"` hoạt động.
- Nếu không truyền tham số, sử dụng giá trị mặc định hợp lý.
- Giá trị tham số được in ra `dmesg` khi module load thành công.

---

#### Giai đoạn 2: Sender — Phân tích và can thiệp gói tin (`sk_buff`)

**User Story 5: Bóc tách cấu trúc `sk_buff` và lọc gói tin mục tiêu**

- **Là một** hệ thống giấu tin.
- **Tôi muốn** lấy thông tin IP Header và TCP/UDP Header từ con trỏ `sk_buff` và chỉ can thiệp vào các gói tin đi đến một Port cụ thể (đọc từ module parameter).
- **Để** tôi không làm xáo trộn các luồng traffic bình thường khác của hệ điều hành (như SSH port 22).
- **Tiêu chí nghiệm thu:**
- Trích xuất thành công `iphdr` và `tcphdr`/`udphdr`.
- Chỉ khi gửi gói tin đến IP/Port mục tiêu (test bằng `nc` hoặc `telnet`), kernel log mới báo "Target packet detected".
- Gói tin không phải mục tiêu vẫn đi qua bình thường.

**User Story 6: Nhúng dữ liệu bí mật vào Header — TCP**

- **Là một** người gửi tin.
- **Tôi muốn** ghi đè 1 byte dữ liệu từ thông điệp bí mật vào một trường trong TCP Header (ví dụ: TCP Sequence Number, hoặc TCP Options).
- **Để** dữ liệu được truyền đi ẩn trong luồng TCP hợp lệ.
- **Tiêu chí nghiệm thu:**
- Bitwise operation ghi 1 byte thành công vào trường được chọn.
- Wireshark/tcpdump xác nhận giá trị tại trường đã thay đổi đúng.
- Gói tin TCP hợp lệ, không bị máy nhận reject (RST/FIN).

**User Story 7: Nhúng dữ liệu bí mật vào Header — UDP**

- **Là một** người gửi tin.
- **Tôi muốn** ghi đè 1 byte dữ liệu từ thông điệp bí mật vào một trường trong UDP/IP Header (ví dụ: IP ID, UDP Checksum, hoặc UDP Length).
- **Để** dữ liệu được truyền đi ẩn trong gói UDP hợp lệ.
- **Tiêu chí nghiệm thu:**
- Bitwise operation ghi 1 byte thành công vào trường được chọn.
- Wireshark/tcpdump xác nhận giá trị đã thay đổi đúng.
- Gói UDP hợp lệ, không bị drop.

**User Story 8: Tính toán lại Checksum sau khi nhúng dữ liệu**

- **Là một** hệ thống giấu tin.
- **Tôi muốn** tự động tính toán và cập nhật lại IP Checksum và TCP/UDP Checksum ngay sau khi nhúng dữ liệu.
- **Để** gói tin vẫn hợp lệ và không bị các Router hoặc máy nhận vứt bỏ (Drop) do lỗi toàn vẹn dữ liệu.
- **Tiêu chí nghiệm thu:**
- Hàm kernel `csum_replace...` hoặc `csum_partial` được gọi đúng cách.
- Wireshark bắt gói tin và báo Checksum hợp lệ (không lỗi Bad Checksum).
- Gói tin thực sự đến được máy đích.

**User Story 9: Xử lý lỗi trong Hook (Bổ sung)**

- **Là một** lập trình viên kernel.
- **Tôi muốn** module xử lý lỗi an toàn trong hook callback: `pskb_may_pull` fail, `skb_header_pointer` trả về NULL, hoặc `skb_linearize` lỗi.
- **Để** tránh kernel panic hoặc undefined behavior khi gặp malformed packet.
- **Tiêu chí nghiệm thu:**
- Module trả về `NF_ACCEPT` (không can thiệp) khi không parse được header.
- Không có warning/error trong `dmesg` khi gặp malformed packet.
- `kprobe` hoặc `ftrace` xác nhận không có NULL pointer dereference.

---

#### Giai đoạn 3: Framing Protocol — Giao thức đóng gói dữ liệu

**User Story 10: Covert Channel Framing Protocol (Bổ sung — P0)**

- **Là một** người gửi tin.
- **Tôi muốn** sử dụng protocol đóng gói đơn giản với Start marker (`0xFF 0x00`) và End marker (`0xFF 0xFF`) để bọc thông điệp bí mật trước khi nhúng vào header.
- **Để** receiver biết khi nào một thông điệp bắt đầu và kết thúc, có thể ghép các byte đơn lẻ thành message có ý nghĩa.
- **Tiêu chí nghiệm thu:**
- Sender nhúng `0xFF 0x00` (start) → các byte dữ liệu → `0xFF 0xFF` (end) vào header của nhiều gói tin liên tiếp.
- Receiver nhận diện được start marker, đọc các byte dữ liệu, dừng tại end marker.
- Message "HELLO" gửi đi được receiver ghép lại đúng chuỗi "HELLO".

---

#### Giai đoạn 4: Receiver — Trích xuất thông điệp (Python/Scapy)

**User Story 11: TCP Receiver — Lắng nghe và trích xuất dữ liệu**

- **Là một** người nhận tin.
- **Tôi muốn** viết chương trình Python dùng Scapy lắng nghe trên port 9999, bắt các gói TCP, đọc trường đã bị thay đổi và trích xuất byte dữ liệu.
- **Để** nhận và giải mã thông điệp bí mật từ phía sender.
- **Tiêu chí nghiệm thu:**
- Chương trình bắt được gói TCP đến port 9999.
- Trích xuất đúng byte từ trường đã embed.
- Ghép byte thành chuỗi theo start/end markers: `0xFF 0x00` → data → `0xFF 0xFF`.
- In ra màn hình thông điệp bí mật hoàn chỉnh.
- Bỏ qua các gói tin không phải mục tiêu (không có marker).

**User Story 12: UDP Receiver — Lắng nghe và trích xuất dữ liệu (Bổ sung)**

- **Là một** người nhận tin.
- **Tôi muốn** viết chương trình Python dùng Scapy lắng nghe trên port 9999, bắt các gói UDP, đọc trường đã bị thay đổi và trích xuất byte dữ liệu.
- **Để** nhận và giải mã thông điệp bí mật từ UDP covert channel.
- **Tiêu chí nghiệm thu:**
- Chương trình bắt được gói UDP đến port 9999.
- Trích xuất đúng byte từ trường đã embed.
- Ghép byte thành chuỗi theo start/end markers.
- In ra màn hình thông điệp bí mật hoàn chỉnh.

---

#### Kịch bản End-to-End (Cross-phase Validation)

Sau khi hoàn thành tất cả giai đoạn, thực hiện test toàn hệ thống:

1. **TCP test:** `echo "SECRET" | nc <target_ip> 9999` → sender intercept → embed vào TCP header → receiver nhận được "SECRET".
2. **UDP test:** `echo "SECRET" | nc -u <target_ip> 9999` → sender intercept → embed vào UDP header → receiver nhận được "SECRET".
3. **Kiểm tra unaffected traffic:** SSH, HTTP vẫn hoạt động bình thường qua lại trên cùng hệ thống.
4. **Lifecycle test:** `insmod covert.ko` → `rmmod covert.ko` → không leak, không crash.

---
