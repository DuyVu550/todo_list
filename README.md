# Todo List App (Pro Version)

Một ứng dụng Quản lý công việc (Todo List) hiện đại, nhanh chóng và mượt mà được xây dựng bằng **Flutter**. Ứng dụng cung cấp các tính năng quản lý cá nhân nâng cao với giao diện đẹp mắt, hỗ trợ linh hoạt Chế độ Sáng/Tối.

## 🚀 Các tính năng nổi bật (Features)

*   **Quản lý Công việc (Tasks):** Thêm mới, chỉnh sửa, xóa công việc. Hỗ trợ đặt thời hạn (Due Date) cho từng task.
*   **Quản lý Danh mục (Categories):** Tự do tạo, sửa, xóa các danh mục công việc với bảng màu tùy biến, giúp phân loại công việc một cách trực quan.
*   **Tìm kiếm & Lọc (Search & Filter):** 
    *   Tìm kiếm công việc theo từ khóa.
    *   Lọc theo trạng thái: Tất cả, Đã hoàn thành, Chưa hoàn thành.
    *   Lọc nhanh theo Danh mục yêu thích.
*   **Sắp xếp thông minh (Sorting):** Sắp xếp công việc theo thời gian tạo mới nhất hoặc theo hạn chót (Due Date).
*   **Thống kê trực quan (Dashboard):** Màn hình Dashboard cung cấp biểu đồ tròn hiển thị tiến độ hoàn thành, cùng với các số liệu thống kê chi tiết theo từng danh mục.
*   **Chế độ Sáng/Tối (Dark Mode):** Giao diện linh hoạt tự động tương thích và chuyển đổi mượt mà giữa chế độ Sáng (Light) và Tối (Dark).
*   **Thông báo nhắc nhở (Local Notifications):** Nhắc nhở công việc trực tiếp trên thiết bị (Local) khi tới hạn.
*   **Lưu trữ Offline cực nhanh:** Tích hợp cơ sở dữ liệu **Isar** cho tốc độ truy xuất siêu tốc mà không cần Internet.

## 🛠 Công nghệ & Thư viện sử dụng (Tech Stack)

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
*   **Database:** [Isar Database](https://isar.dev/) (`isar`, `isar_flutter_libs`)
*   **Giao diện (UI/UX):** Material 3 Design, `google_fonts` (Font Inter)
*   **Thông báo (Notifications):** `flutter_local_notifications`, `timezone`
*   **Lưu trữ tùy chọn:** `shared_preferences` (Lưu trạng thái Dark Mode)

## 📦 Cài đặt và Khởi chạy (Installation)

1. **Yêu cầu hệ thống:**
   * Flutter SDK đã được cài đặt.
   * Android Studio (với Android SDK) hoặc Xcode (nếu build cho iOS).

2. **Clone project và cài đặt thư viện:**
   ```bash
   git clone <repository_url>
   cd todo_list
   flutter pub get
   ```

3. **Build Code Generation (cho Isar và các model):**
   *Ứng dụng sử dụng `build_runner` để generate các Schema cho Isar.*
   ```bash
   dart run build_runner build -d
   ```

4. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```
   *(Lưu ý: Đối với Android, ứng dụng đã bật tính năng Core Library Desugaring phiên bản 2.1.5 để tương thích với Local Notifications).*

## 🏗 Kiến trúc (Architecture)
Ứng dụng được thiết kế theo mô hình phân tầng gọn nhẹ, tối ưu hóa việc quản lý trạng thái qua Riverpod:
*   `lib/core/`: Chứa các cấu hình cốt lõi (Database, Theme, Services).
*   `lib/features/`: Chứa các module tính năng (TaskList, Categories, Dashboard).
    *   `data/`: Các model Isar và logic lưu trữ.
    *   `presentation/`: UI (Screens), Widgets, và Notifiers/Providers.

---
*Phát triển bởi [Tên của bạn/Đội ngũ của bạn].*

