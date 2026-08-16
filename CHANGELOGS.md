# Nhật Ký Thay Đổi (Changelogs)

Toàn bộ các thay đổi và cột mốc phát triển của dự án **Bé Ong** (DailyChildren) được ghi nhận tại đây.

---

## [0.2.0] - 2026-08-16

### ✨ Tính Năng Mới (Features)
- **Bảo Mật Phụ Huynh**:
  - Tích hợp `ParentPinService` với mã PIN 4 chữ số băm SHA-256 bảo vệ vai bố mẹ trên thiết bị dùng chung.
  - Giao diện `ParentPinSheet` chặn thao tác đổi vai và yêu cầu nhập PIN.
- **Quản Lý Thói Quen & Nhiệm Vụ (Routines & Tasks)**:
  - Trình biên tập `RoutineEditorScreen` hỗ trợ kéo thả sắp xếp thứ tự các việc trong Routine.
  - Tích hợp bộ chọn biểu tượng `IconPicker` 3D Fluent Emoji cho toàn bộ nhiệm vụ và phần thưởng.
  - Cấu hình mức phạt xu riêng cho từng đầu việc khi trẻ bỏ lỡ.
  - Cho phép thiết lập chế độ "cần duyệt" riêng cho từng việc.
- **Tài Chính Giáo Dục & Mục Tiêu (Goals & Finance)**:
  - Hỗ trợ trẻ tự đặt mục tiêu tiết kiệm (`GoalService`, `GoalSheet`, `GoalCard`) kèm thanh tiến độ.
  - Cho phép bố mẹ điều chỉnh số dư xu thủ công (`AdjustXuSheet`) bắt buộc ghi lý do vào sổ cái.
  - Hỗ trợ quy đổi xu ra tiền thật (`MoneyExchange`) theo đơn vị nghìn đồng (mặc định tắt theo ADR-017).
  - Phân tách giao diện hũ "Chờ chia" (`Jar.inbox`) và các hũ mục tiêu (Tiết kiệm, Tiêu dùng, Chia sẻ).
- **Huy Hiệu & Thành Tích (Badges & Streaks)**:
  - Tích hợp 8 loại huy hiệu MVP (`BadgeDao`, `BadgesScreen`).
  - Kết nối ngọn lửa Streak vào dữ liệu thực tế hằng ngày của trẻ.
  - Thêm hiệu ứng pháo hoa giấy ăn mừng (`CelebrationOverlay`) khi trẻ tick xong việc hoặc nhận huy hiệu.
- **Diagnostics & Báo Lỗi**:
  - Tích hợp hệ thống ghi nhật ký lỗi (`NhatKyLoi`), chụp màn hình tự động (`ChupManHinh`) và gửi báo cáo lỗi về máy chủ (`BaoLoiScreen`).
- **Giao Diện & Khả Dụng**:
  - Hỗ trợ chuyển đổi chế độ Sáng / Tối (`ThemeModeProvider`).
  - Đồng bộ giờ bắt đầu ngày mới cho cả gia đình qua `FamilyClockProvider`.

### 🛠️ Cải Tiến & Sửa Lỗi (Refactor & Fixes)
- Loại bỏ ép kiểu bang operator `!` trong định tuyến GoRouter (`lib/app/router.dart`).
- Đảm bảo kiểm tra `mounted` an toàn sau khi thực hiện các tác vụ bất đồng bộ trong các BottomSheet.
- Bổ sung tài liệu chính sách quyền riêng tư (`docs/10-privacy-policy.md`) và đặc tả endpoint báo lỗi (`docs/11-bao-loi-endpoint.md`).

---

## [0.1.0] - 2026-08-02

### ✨ Khởi Tạo Sprint 0 (Sprint 0 Baseline)
- Khởi tạo dự án Flutter đa nền tảng (iOS, Android, macOS, Windows, Linux).
- Thiết lập hệ thống `ResponsiveScaffold` tự động co giãn theo 3 breakpoint (Mobile, Tablet, Desktop).
- Cấu hình bảng màu Light/Dark, font chữ Nunito, thang khoảng cách chuẩn và giới hạn text scale 1.6.
- Định tuyến `GoRouter` với `StatefulShellRoute` giữ trạng thái các tab điều hướng.
- Hỗ trợ đa ngôn ngữ i18n (Tiếng Việt & Tiếng Anh).
- Thiết lập quy trình CI GitHub Actions phân tích tĩnh, chạy test và build bản chạy thử trên 5 nền tảng.
