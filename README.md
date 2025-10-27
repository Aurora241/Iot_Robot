🤖 IoT Robot Gesture & Dashboard Control System

Dự án này cho phép điều khiển xe robot sử dụng ESP32 bằng cử chỉ tay thông qua cảm biến gia tốc ADXL335, đồng thời hiển thị và điều khiển trạng thái xe qua ứng dụng Flutter Dashboard.
Dữ liệu được truyền qua MQTT Broker (EMQX / HiveMQ) và được lưu trữ vào PostgreSQL thông qua Node.js backend (Dockerized).
Website Dashboard được triển khai lên AWS S3 + CloudFront + Cloudflare DNS.

🧱 1. CẤU TRÚC HỆ THỐNG
ESP32 (phát - ADXL335)  → MQTT → ESP32 (thu - L298N, LCD)
                                   ↓
                              Node.js Backend (Docker)
                                   ↓
                           PostgreSQL + Adminer
                                   ↓
                             Flutter Dashboard (Web + App)

⚙️ 2. PHẦN CỨNG
| Thiết bị                  | Vai trò                        | Ghi chú                      |
| ------------------------- | ------------------------------ | ---------------------------- |
| ESP32 DevKit V1 (SL2)           | Bộ xử lý trung tâm             | Dùng cho cả mạch phát & thu  |
| ADXL335                   | Cảm biến gia tốc               | Điều khiển cử chỉ tay        |
| L298N                     | Driver điều khiển 2 động cơ DC | Nhận tín hiệu từ ESP32       |
| LCD 1602 (I2C)            | Hiển thị trạng thái xe         | Giao tiếp SDA/SCL            |
| 4 Động cơ DC              | Bánh xe robot                  | Nguồn riêng 7.4V             |
| Pin 7.4V + Buck Converter | Cấp nguồn                      | 7.4V cho motor, 5V cho ESP32 |
| Dây Dupont, Breadboard    | Kết nối mạch                   |                              |

⚡ 3. SƠ ĐỒ NỐI DÂY
🟢 Mạch Phát (ESP32 + ADXL335)
| ADXL335 | ESP32  |
| ------- | ------ |
| VCC     | 3V3    |
| GND     | GND    |
| X       | GPIO34 |
| Y       | GPIO35 |
| Z       | GPIO32 |
🔵 Mạch Thu (ESP32 + L298N + LCD 1602 I2C)
| L298N          | ESP32                              |
| -------------- | ---------------------------------- |
| IN1            | GPIO13                             |
| IN2            | GPIO14                             |
| IN3            | GPIO25                             |
| IN4            | GPIO26                             |
| ENA            | GPIO33                             |
| ENB            | GPIO27                             |
| VCC (12V)      | Pin 7.4V (pin motor)               |
| GND            | GND chung với ESP32                |
| 5V (EN jumper) | ⚠️ KHÔNG dùng khi đã cấp nguồn rời |

| LCD I2C | ESP32  |
| ------- | ------ |
| VCC     | 3V3    |
| GND     | GND    |
| SDA     | GPIO21 |
| SCL     | GPIO22 |

🧠 4. CODE TỪNG THÀNH PHẦN
🔸 ESP32 Mạch Phát (mach_phat.ino)
Đọc dữ liệu từ ADXL335.
Gửi lệnh MQTT: forward, backward, left, right, stop.

🔸 ESP32 Mạch Thu (mach_thu.ino)
Nhận lệnh MQTT và điều khiển motor qua L298N.
Gửi lại trạng thái (direction, voltage, led, m1..m4) về topic /iot/robot/state.
Hiển thị trạng thái trên LCD 1602 I²C.

🔸 Node.js Backend
Kết nối MQTT, lắng nghe /iot/robot/state.
Lưu dữ liệu vào PostgreSQL.
Có thể mở rộng thêm API REST để Flutter lấy dữ liệu lịch sử.

🧩 5. TRIỂN KHAI BACKEND (Docker)
📁 Cấu trúc thư mục
iot-backend/
├── Dockerfile
├── docker-compose.yml
├── .env
├── package.json
└── server.js
 
Khởi chạy: Di chuyển vào iot-backend bằng lệnh cd, sau đó dùng lệnh "docker-compose up -d --build", điều kiện tiên quyết là phải có Docker Desktop và đã được add vào Path của máy.

🌐 6. TRIỂN KHAI FLUTTER DASHBOARD
🧭 Cấu trúc app
lib/
 ├── main.dart
 ├── mqtt_service.dart
 ├── dashboard_page.dart
 └── control_panel.dart

 ⚙️ Chức năng
Kết nối MQTT để gửi lệnh (forward, backward, left, right, stop, toggle_led)
Hiển thị tình trạng xe: tốc độ, hướng, điện áp, trạng thái LED, kết nối MQTT/device.

Ở phần này, MỞ FOLDER NÀY BẰNG ANDROI STUDIO, CHỌN MÁY THẬT RỒI BẤM RUN ĐỂ CÀI, KHÔNG CẦN LÀM GÌ THÊM

📊 7. BẢNG TỔNG HỢP NỐI DÂY
| Thành phần | ESP32 | Ghi chú        |
| ---------- | ----- | -------------- |
| ADXL335 X  | 34    | Analog         |
| ADXL335 Y  | 35    | Analog         |
| ADXL335 Z  | 32    | Analog         |
| L298N IN1  | 13    | Motor trái     |
| L298N IN2  | 14    | Motor trái     |
| L298N IN3  | 25    | Motor phải     |
| L298N IN4  | 26    | Motor phải     |
| ENA        | 33    | PWM motor trái |
| ENB        | 27    | PWM motor phải |
| LCD SDA    | 21    | I²C            |
| LCD SCL    | 22    | I²C            |
| LED        | 2     | Trạng thái     |
| VOLTAGE    | 34    | Đo điện áp     |

8. Mở rộng
Nếu biết về AWS (Điện toán đám mây của Amazon), có thể triển khai Dashboard lên S3 Bucket và cấp Domain cho nó hoạt động
Dưới đây là hướng dẫn từng bước để up dashboard web tĩnh lên Amazon S3. Nói thẳng: không quanh co, làm theo là xong.

✅ Các bước triển khai

a. Chuẩn bị file dashboard
- Đảm bảo thư mục chứa index.html + các file CSS/JS/ảnh đã sẵn sàng.
- Kiểm tra trên máy local là chạy ổn (mở index.html bằng browser).

b. Đăng nhập AWS S3
- Vào AWS Console → Services → S3.

c. Tạo bucket mới
- Chọn Create bucket.
- Đặt tên bucket duy nhất toàn AWS (ví dụ robot-dashboard-ngocanh).
- Chọn Region gần bạn.
- Giữ các setting default hoặc theo nhu cầu.

d. Cấu hình bucket để host web tĩnh
- Vào bucket → tab Properties → Static website hosting → Edit → chọn “Use this bucket to host a website”.
- Nhập Index document là index.html. (Nếu có file lỗi thì nhập Error document).

e. Cho phép truy cập công khai
- Vào tab Permissions → Block public access (bucket settings) → Edit → Clear các lựa chọn “Block all public access” (chủ ý là mở public).
- Sau đó vào Bucket policy → Edit → thêm nội dung:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::BUCKET_NAME/*"]
    }
  ]
}
Thay BUCKET_NAME bằng tên thực của bạn.

f. Upload các file website
- Vào bucket → tab Objects → chọn Upload → chọn file/folder website của bạn → Upload.

g. Kiểm tra website\
- Vào Properties → phần Static website hosting → copy Endpoint (ví dụ http://BUCKET_NAME.s3-website-region.amazonaws.com)
- Mở link trong browser xem chạy đúng.

i. Gắn domain tùy chọn + HTTPS (nếu cần)
- Nếu bạn muốn dùng domain riêng (dashboard.ngocanh648.id.vn chẳng hạn):
- Dùng Amazon CloudFront tạo distribution trỏ origin tới bucket.
- Dùng Amazon Route 53 hoặc Cloudflare để trỏ A/CNAME tới CloudFront.
- Hoặc đơn giản: dùng bucket tên giống domain rồi trỏ CNAME từ domain → endpoint S3 (nhược điểm không HTTPS).

🔍 Lưu ý quan trọng
Nếu bucket đặt public → ai cũng truy cập được. Đảm bảo không chứa file nhạy cảm.
S3 static website endpoint hỗ trợ HTTP, nếu muốn HTTPS nên dùng CloudFront.
Tên bucket thường đặt giống domain nếu muốn trỏ trực tiếp.
