# Garmin Watch Face – Forerunner 55

Mặt đồng hồ tùy chỉnh cho Garmin Forerunner 55, viết bằng Monkey C.

## Tính năng

- ⏱️ Hiển thị giờ, phút, giây lớn ở trung tâm
- 📅 Ngày tháng (dương lịch) và **lịch âm** (thuật toán Hồ Ngọc Đức, múi giờ UTC+7)
- 🔋 Pin (thanh cung bên phải + phần trăm)
- 👣 Số bước chân + mục tiêu (thanh cung bên trái)
- ❤️ Nhịp tim
- 🌡️ Thời tiết (icon: nắng / mây / mưa)
- 📱 Trạng thái kết nối Bluetooth + số thông báo

---

## Yêu cầu cài đặt

### 1. Garmin Connect IQ SDK

Tải và cài SDK từ trang chính thức của Garmin:  
👉 https://developer.garmin.com/connect-iq/sdk/

Sau khi cài, mở **Connect IQ SDK Manager** và tải về:
- SDK phiên bản mới nhất (khuyến nghị ≥ 4.x)
- Device definition cho **Forerunner 55** (`fr55`)

### 2. Developer Key

Bạn cần tạo **Developer Key** của riêng mình để ký ứng dụng.  
> ⚠️ **Lưu ý:** File `developer_key.der` và `developer_key.pem` **KHÔNG** được đóng gói trong bản phân phối này vì lý do bảo mật.

**Cách tạo Developer Key:**
```powershell
# Tạo private key (PEM)
openssl genrsa -out developer_key.pem 4096

# Tạo public key dạng DER (dùng để ký .prg)
openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
```

Đặt cả hai file vào thư mục gốc của project (cùng cấp với `monkey.jungle`).

---

## Cấu trúc project

```
Garmin_Watch_Face/
├── source/
│   ├── GarminWatchFaceApp.mc      # Entry point
│   └── GarminWatchFaceView.mc     # Logic chính & vẽ giao diện
├── resources/
│   ├── drawables/                 # Icons PNG + drawables.xml
│   ├── layouts/                   # Layout XML
│   └── strings/                   # String resources
├── manifest.xml                   # Cấu hình app (ID, tên, thiết bị)
├── monkey.jungle                  # Build config
├── build_and_run.ps1              # Script build + chạy simulator
└── README.md
```

---

## Cách build

### Build thủ công (PowerShell)

```powershell
# 1. Tìm đường dẫn SDK (tự động lấy phiên bản mới nhất)
$sdkPath = (Get-ChildItem -Path "$env:APPDATA\Garmin\ConnectIQ\Sdks" -Directory | Select-Object -First 1).FullName
$env:PATH = "$sdkPath\bin;" + $env:PATH

# 2. Tạo thư mục output
New-Item -ItemType Directory -Force -Path bin

# 3. Build
monkeyc.bat -d fr55 -f monkey.jungle -o bin\GarminWatchFace.prg -y developer_key.der
```

### Build và chạy Simulator (script có sẵn)

```powershell
.\build_and_run.ps1
```

Script này sẽ tự động:
1. Tìm SDK Garmin đã cài
2. Build project
3. Khởi động simulator (nếu chưa chạy)
4. Deploy file `.prg` lên simulator Forerunner 55

> **Lưu ý:** Sửa đường dẫn trong `build_and_run.ps1` nếu project nằm ở vị trí khác.

---

## Cách cài lên đồng hồ thật

1. Build ra file `bin/GarminWatchFace.prg`
2. Dùng **Garmin Express** hoặc **Connect IQ Store** để sideload  
   Hoặc dùng lệnh:
   ```powershell
   monkeydo.bat bin\GarminWatchFace.prg fr55
   ```
   khi đồng hồ được kết nối qua Garmin Express Developer Mode.

---

## Lưu ý khi tùy chỉnh

- **Đổi thiết bị:** Sửa `id="fr55"` trong `manifest.xml` và tham số `-d fr55` trong lệnh build.
- **Đổi màu sắc:** Tìm biến `accentColor` trong `GarminWatchFaceView.mc`.
- **Múi giờ lịch âm:** Mặc định UTC+7 (Việt Nam). Tìm `var timeZone = 7.0;` để thay đổi.

---

## Tham khảo

- [Garmin Connect IQ Developer Docs](https://developer.garmin.com/connect-iq/overview/)
- [Monkey C Language Reference](https://developer.garmin.com/connect-iq/monkey-c/)
- Thuật toán lịch âm: [Hồ Ngọc Đức – amlich](https://www.informatik.uni-leipzig.de/~duc/amlich/)
