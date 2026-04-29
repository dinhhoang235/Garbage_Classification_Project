# 🌿 Eco Sort - Garbage Classification App

Ứng dụng phân loại rác thải vì một tương lai xanh. Ứng dụng giúp người dùng nhận diện, phân loại rác và theo dõi các điểm thu gom rác tái chế.

## 🚀 Các lệnh quan trọng (Important Commands)

Dưới đây là danh sách các lệnh thường dùng để phát triển và vận hành dự án:

### 1. Chạy ứng dụng
```bash
flutter run
```
*Gợi ý: Nhấn `r` để Hot Reload, `R` để Hot Restart.*

### 2. Cài đặt thư viện mới
```bash
flutter pub get
```

### 3. Dọn dẹp dự án (Khi gặp lỗi build hoặc cache)
```bash
flutter clean
flutter pub get
```

### 4. Cập nhật App Icon và Tên ứng dụng
Nếu bạn thay đổi file `assets/images/icon.png` hoặc cấu hình trong `pubspec.yaml`, hãy chạy lệnh:
```bash
dart run flutter_launcher_icons
```

### 5. Kiểm tra lỗi Code (Lints)
```bash
flutter analyze
```

## 🎨 Hệ thống thiết kế (Design System)

*   **Font chữ:** Be Vietnam Pro
*   **Màu sắc chủ đạo:**
    *   Primary Green: `#22C55E`
    *   Blue: `#0EA5E9`
    *   Orange: `#F59E0B`
*   **Thư viện Icon:** Lucide Icons

## 📂 Cấu trúc thư mục chính

*   `lib/core/theme/`: Cấu hình màu sắc và font chữ toàn cục.
*   `lib/features/`: Mã nguồn của các màn hình chức năng.
*   `lib/widgets/`: Các thành phần giao diện dùng chung (reusable widgets).
*   `assets/images/`: Chứa icon và hình ảnh của ứng dụng.

---
*Phát triển bởi Eco Sort Team 🌍*
