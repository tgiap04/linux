# 🕵️ Covert Channel — Ẩn tin bí mật qua kênh TCP/UDP

Hệ thống giấu dữ liệu bí mật trong header của gói tin mạng TCP/UDP sử dụng Linux Kernel Module (Netfilter Hook).

---

## Tổng quan kiến trúc

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MÁY GỬI (Sender)                            │
│                                                                     │
│  1. App gửi data thường ──► nc 10.0.2.15 9999                      │
│           │                                                         │
│           ▼                                                         │
│  2. Kernel Module (covert.ko) bắt gói tại NF_INET_LOCAL_OUT       │
│           │                                                         │
│           ▼                                                         │
│  3. Lọc: chỉ can thiệp gói đến port 9999                          │
│           │                                                         │
│           ▼                                                         │
│  4. Framing: 0xFF 0x00 [dữ liệu] 0xFF 0xFF                        │
│           │                                                         │
│           ▼                                                         │
│  5. Embed: ghi 1 byte vào TCP Seq# (TCP) hoặc IP ID (UDP)          │
│           │                                                         │
│           ▼                                                         │
│  6. Tính lại Checksum ──► Gói tin hợp lệ rời máy                  │
│                                                                     │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │  MẠNG (LAN) │
                    │  Gói thường │
                    └──────┬──────┘
                           │
┌──────────────────────────▼──────────────────────────────────────────┐
│                        MÁY NHẬN (Receiver)                         │
│                                                                     │
│  7. Python/Scapy bắt gói TCP/UDP tại port 9999                    │
│           │                                                         │
│           ▼                                                         │
│  8. Đọc byte ẩn từ TCP Seq# (hoặc IP ID)                          │
│           │                                                         │
│           ▼                                                         │
│  9. Detect start marker 0xFF 0x00 ──► bắt đầu đọc data            │
│           │                                                         │
│           ▼                                                         │
│ 10. Detect end marker 0xFF 0xFF ──► dừng, in thông điệp            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Luồng dữ liệu chi tiết

### Giai đoạn 1: Gửi tin (Sender)

```
Tin nhắn "HELLO"
       │
       ▼
┌─────────────────────────────┐
│ Framing Protocol            │
│ ┌──────┬──────┬─┬─┬─┬─┬──────┐
│ │ 0xFF │ 0x00 │H│E│L│L│O│ 0xFF │ 0xFF │
│ └──────┴──────┴─┴─┴─┴─┴──────┘
└─────────────────────────────┘
       │
       │ Mỗi byte = 1 gói tin
       ▼
┌─────────────────────────────────────────────┐
│ Gói 1: 0xFF → embed vào TCP Seq# bit 0-7    │
│ Gói 2: 0x00 → embed vào TCP Seq# bit 0-7    │
│ Gói 3: 'H'  → embed vào TCP Seq# bit 0-7    │
│ Gói 4: 'E'  → embed vào TCP Seq# bit 0-7    │
│ ...                                          │
│ Gói 8: 0xFF → embed vào TCP Seq# bit 0-7    │
│ Gói 9: 0xFF → embed vào TCP Seq# bit 0-7    │
└─────────────────────────────────────────────┘
```

### Giai đoạn 2: Nhận tin (Receiver)

```
Scapy bắt gói TCP/UDP port 9999
       │
       ▼
Đọc byte ẩn: seq & 0xFF  (hoặc ip_id & 0xFF)
       │
       ▼
┌──────────────────────────────────────┐
│ State Machine:                       │
│                                      │
│  IDLE ──0xFF──► START_B1            │
│                      │               │
│                   0x00               │
│                      ▼               │
│  ◄── BẮT ĐẦU ĐỌC DATA ◄──         │
│                      │               │
│              [đọc byte data]        │
│                      │               │
│                   0xFF               │
│                      ▼               │
│               END_B1                │
│                      │               │
│                   0xFF               │
│                      ▼               │
│           IN RA THÔNG ĐIỆP         │
└──────────────────────────────────────┘
```

### Chi tiết Embedding

**TCP — nhúng vào TCP Sequence Number:**
```
TCP Seq# gốc:     0xABCD1234
                  10101011 11001101 00010010 00110100
                                              ^^^^^^^^
                                         8 bit thấp nhất
TCP Seq# đã modify: 0xABCD1248  (byte 0x48 = 'H' được nhúng vào)
```

**UDP — nhúng vào IP Identification:**
```
IP ID gốc:     0x3F00
               00111111 00000000
                       ^^^^^^^^
                  8 bit thấp nhất
IP ID đã modify: 0x3F48  (byte 0x48 = 'H' được nhúng vào)
```

---

## Cách chạy thử nghiệm

### Yêu cầu

- Ubuntu Server VM (22.04+)
- Kernel headers: `sudo apt install linux-headers-$(uname -r)`
- Build tools: `sudo apt install build-essential`
- Python 3.10+ và Scapy: `pip3 install scapy`

### Bước 1: Build Kernel Module

```bash
cd src/covert
make
# Tạo ra covert.ko
```

### Bước 2: Load Module

```bash
# Load với tham số mặc định (port 9999, IP 10.0.2.15)
sudo insmod covert.ko

# Hoặc tuỳ chỉnh
sudo insmod covert.ko target_port=8080 target_ip="192.168.1.100"

# Kiểm tra
lsmod | grep covert
dmesg | tail -5
```

### Bước 3: Chạy Receiver (máy nhận — có thể là cùng VM)

```bash
# Terminal 2: Lắng nghe TCP
cd src/receiver
sudo python3 tcp_receiver.py --port 9999 --verbose

# Hoặc UDP
sudo python3 udp_receiver.py --port 9999 --verbose
```

### Bước 4: Gửi dữ liệu test

```bash
# Terminal 3: Gửi tin nhắn
echo "HELLO" | nc 127.0.0.1 9999

# Hoặc UDP
echo "HELLO" | nc -u 127.0.0.1 9999

# Hoặc lặp lại nhiều lần để test
for i in $(seq 1 5); do echo "MSG $i" | nc 127.0.0.1 9999; sleep 1; done
```

### Bước 5: Kiểm tra kết quả

```bash
# Kiểm tra log sender
dmesg | grep covert | tail -20

# Kiểm tra Wireshark (chế độ verbose)
# Mở Wireshark → filter: tcp.port == 9999
# Nhìn vào TCP Sequence Number — 8 bit cuối thay đổi mỗi gói
```

### Bước 6: Unload Module

```bash
sudo rmmod covert
dmesg | tail -3  # Xác nhận "hooks removed"
```

---

## Cấu trúc thư mục

```
package-hiding/
├── README.md                              ← Bạn đang đọc
├── user_stories.md                        ← 12 User Stories (4 giai đoạn)
├── src/
│   ├── covert/                            ← Kernel Module (C)
│   │   ├── Makefile                       ← Build system
│   │   ├── covert_main.c                  ← Init/exit, hooks, params
│   │   ├── packet_parser.c/.h             ← Parse sk_buff
│   │   ├── tcp_embed.c/.h                 ← TCP embedding + checksum
│   │   ├── udp_embed.c/.h                 ← UDP embedding + checksum
│   │   ├── framing.c/.h                   ← Start/End markers protocol
│   │   ├── error_handler.h                ← Safe skb parsing
│   │   └── README.md                      ← Hướng dẫn build chi tiết
│   └── receiver/                          ← Python/Scapy Receiver
│       ├── tcp_receiver.py                ← Lắng nghe TCP port 9999
│       └── udp_receiver.py                ← Lắng nghe UDP port 9999
└── plans/                                 ← Kế hoạch implement
```

---

## Module Parameters

| Parameter | Kiểu | Mặc định | Mô tả |
|-----------|------|----------|-------|
| `target_port` | int | 9999 | Port đích cần can thiệp |
| `target_ip` | charp | "10.0.2.15" | IP đích (0 hoặc để trống = mọi IP) |

---

## Troubleshooting

| Vấn đề | Giải pháp |
|--------|-----------|
| `insmod: ERROR: could not insert module` | Kiểm tra `dmesg` — thường do sai kernel headers |
| `make: *** /lib/modules/.../build: No such file` | Cài `linux-headers-$(uname -r)` |
| Receiver không nhận được data | Kiểm tra `dmesg` có "target packet detected" không |
| Checksum lỗi trong Wireshark | Kiểm tra `covert_tcp_recalc_checksum()` có được gọi |
| `rmmod: ERROR: Module covert is in use` | Không có hook nào đang giữ module — thử `lsmod` |
| Receiver cần root | `sudo python3 tcp_receiver.py` (Scapy cần raw socket) |

---

## Hạn chế hiện tại

- **Chưa có sysfs interface** — tin nhắn cần hardcode trong module hoặc load từ file
- **Chỉ embed 1 byte/gói** — tốc độ truyền tin chậm
- **Chưa có encryption** — dữ liệu ẩn nhưng không mã hoá
- **Không có retransmission** — nếu gói tin mất, byte đó bị mất
- **Chỉ hỗ trợ IPv4** — chưa có IPv6
