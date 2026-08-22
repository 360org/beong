# Nhật Ký Thay Đổi (Changelogs)

Toàn bộ các thay đổi và cột mốc phát triển của dự án **Bé Ong** (DailyChildren) được ghi nhận tại đây.

---

## [0.2.3] - 2026-08-22

**Hai lỗi nghiêm trọng của 0.2.2 đã sửa xong.** Ai đang dùng 0.2.2 nên cập nhật —
và nếu đã lỡ bấm ĐĂNG XUẤT thì bản này lấy lại được dữ liệu cũ.

### 🐛 Sửa Lỗi (Fixes)
- 🔴 **Khoá máy không còn làm mất đường vào dữ liệu cũ.** Có màn hình mới
  **"Ai đang dùng máy?"**: khoá xong là chọn lại người dùng, không rơi vào màn tạo nhà nữa.
  Máy nào đã lỡ dính lỗi ở 0.2.2 thì màn này liệt kê **cả hai nhà** — chọn nhà cũ là dữ liệu
  của con hiện lại đầy đủ, không mất gì.
- 🔴 **Quên PIN đã có lối thoát.** Màn nhập PIN có thêm **"Quên PIN?"**: xác nhận một lần rồi
  gỡ PIN và vào luôn. Không còn phải gỡ app, tức không còn mất dữ liệu vì quên bốn chữ số.
  Màn đặt PIN cũng nói trước điều này ngay từ đầu.
- **Dòng "PIN của bố mẹ" trong Cài đặt không còn nói sai.** Gỡ PIN xong nó vẫn ghi "Đang bật"
  dù PIN đã mất thật.
- **Ổ khoá trên thẻ "Bố mẹ"** chỉ hiện ở nhà thật sự có đặt PIN.

### 🛠️ Thay Đổi (Changes)
- **ĐĂNG XUẤT → KHOÁ LẠI.** Chữ cũ sai với việc nút làm: app không có tài khoản nào để xuất
  ra, nó chỉ hỏi lại ai đang dùng máy. Nút cũng bỏ màu đỏ và có thêm một dòng nói rõ dữ liệu
  vẫn còn nguyên.
- **Muốn làm lại từ đầu vẫn được**, qua "Tạo nhà mới" ở màn chọn người dùng — nhưng app sẽ
  hỏi lại một lần trước khi tạo, kèm tên nhà đang có.

### ⚠️ Còn lại
- **Chưa rõ**: báo cáo "tắt app rồi mở lại phải cấu hình từ đầu" vẫn chưa tái tạo được. Nếu
  gặp trên máy thật, xin báo lại kèm cách cài bản app.

### 📦 Trạng thái phát hành
- **iOS:** `0.2.3 (5)` **đã lên App Store Connect và xử lý xong** — dùng được cho
  TestFlight ngay. Chưa nộp duyệt được vì hồ sơ App Store còn thiếu ảnh chụp, mô tả,
  phân loại độ tuổi, giá và chính sách quyền riêng tư — không phải lỗi mã, xem
  `docs/08-release-cicd.md`.
- **Android:** chưa lên được, secret `PLAY_STORE_SERVICE_ACCOUNT_JSON` không hợp lệ.

Chi tiết, nguyên nhân gốc và cách kiểm: `docs/13-audit-luong-vao-app.md`.
Ảnh: `docs/screenshot/70`–`74`.

---

## [0.2.2] - 2026-08-22

Hai lỗi nghiêm trọng dưới đây **chưa được sửa**. Người dùng cần biết trước.

Build `+3` đã lên TestFlight ngày 22/08. Build `+4` là cùng mã nguồn đó, tăng số
build vì Apple không nhận hai lần nộp trùng `+build`.

### ⚠️ Lỗi đã biết, chưa sửa (Known Issues)
- 🔴 **Đăng xuất là mất đường vào dữ liệu cũ.** Bấm ĐĂNG XUẤT xong app quay về màn tạo nhà,
  không có chỗ vào lại. Làm lại onboarding sẽ sinh **gia đình thứ hai**; dữ liệu của bé cũ
  vẫn nằm trong máy nhưng không màn hình nào mở tới được. **Khi thử, đừng bấm ĐĂNG XUẤT.**
- 🔴 **Quên PIN là mất quyền bố mẹ vĩnh viễn.** Đường bỏ PIN nằm trong Cài đặt, mà Cài đặt lại
  nằm sau chính cái PIN đó. Chỉ gỡ app mới thoát, tức mất sạch dữ liệu. **Khi thử, nhớ kỹ PIN
  hoặc đừng đặt PIN.**
- ⚠️ **Chưa rõ**: có báo cáo "tắt app rồi mở lại phải cấu hình từ đầu". Chưa tái tạo được trên
  bản dựng thử nghiệm. Nếu gặp trên máy thật, xin báo lại kèm cách cài bản app.

Chi tiết, nguyên nhân gốc và phương án: `docs/13-audit-luong-vao-app.md`.

### 🛠️ Thay Đổi (Changes)
- [FIX] **Tag không còn phát hành ra store công khai.** Trước đây `git push --tags` chạy lane
  `release` + track `production`, tức nộp duyệt App Store **và tự phát hành**. Nay tag trỏ tới
  TestFlight + Play internal; muốn ra công khai phải bấm tay trong tab Actions.
- [DOCS] **Audit luồng vào app** (`docs/13-audit-luong-vao-app.md`): ba hiện tượng được dựng
  lại trên app thật và đọc thẳng file dữ liệu, kèm phương án đánh số và test phải có.
- [FEAT] **Website 3 trang** với header/footer đầy đủ, có menu điện thoại, và trang chính sách
  quyền riêng tư cho người dùng — gỡ một nút chặn nộp store.

---

## [0.2.1] - 2026-08-20

### 🛠️ Cải Tiến & Sửa Lỗi (Refactor & Fixes)
- [FIX] **CI/CD & iOS Code Signing**: Chuẩn hoá cấu hình ký `Apple Distribution`, thiết lập default-keychain trên GitHub runner và nâng cấp actions runner lên `actions/checkout@v5`.
- [FIX] **Landing Page & Docs**: Sửa tỷ lệ khung hình ảnh (`img { height: auto }`) chống méo hình trên các breakpoint (`site/index.html`).
- [FIX] **Log Xu & Duyệt Việc**: Không trả xu hai lần cho một lượt việc, làm rõ trạng thái việc đang chờ duyệt.
- [FIX] **Huy Hiệu & Điều Hướng**: Nhận huy hiệu có hiệu ứng pháo hoa ăn mừng, router không mở màn hình trống.
- [IMPROVE] **Dọn Dẹp Phụ Thuộc**: Loại bỏ 6 dependencies thừa trước khi đóng gói release.
- [IMPROVE] **Kiến Trúc Repository**: Hoàn thiện mặt cắt tầng repository đáp ứng chính xác nhu cầu `lib/features`.
- [DOCS] Cập nhật hướng dẫn sử dụng cho phụ huynh (`docs/12-huong-dan-su-dung.md`) và bộ 68 ảnh chụp màn hình hoàn chỉnh (`docs/screenshot/README.md`).

---

## [0.2.0] - 2026-08-16

### ✨ Tính Năng Mới (Features)
- **Bảo Mật Phụ Huynh**:
  - Tích hợp `ParentPinService` với mã PIN 4 chữ số băm SHA-256 bảo vệ vai bố mẹ trên thiết bị dùng chung.
  - Giao diện `parent_pin_sheet.dart` chặn thao tác đổi vai và yêu cầu nhập PIN.
- **Quản Lý Thói Quen & Nhiệm Vụ (Routines & Tasks)**:
  - Trình biên tập `RoutineEditorScreen` hỗ trợ kéo thả sắp xếp thứ tự các việc trong Routine.
  - Tích hợp bộ chọn biểu tượng `IconPickerGrid` 3D Fluent Emoji cho toàn bộ nhiệm vụ và phần thưởng.
  - Cấu hình mức phạt xu riêng cho từng đầu việc khi trẻ bỏ lỡ.
  - Cho phép thiết lập chế độ "cần duyệt" riêng cho từng việc.
- **Tài Chính Giáo Dục & Mục Tiêu (Goals & Finance)**:
  - Bố mẹ đặt mục tiêu tiết kiệm cho con (`GoalService`, `GoalCard`, `goal_sheet.dart`) kèm thanh tiến độ.
  - Cho phép bố mẹ điều chỉnh số dư xu thủ công (`adjust_xu_sheet.dart`) bắt buộc ghi lý do vào sổ cái.
  - Hỗ trợ quy đổi xu ra tiền thật (`MoneyExchange`) theo đơn vị nghìn đồng (mặc định tắt theo ADR-017).
  - Phân tách giao diện hũ "Chờ chia" (`Jar.inbox`) và các hũ mục tiêu (Tiết kiệm, Tiêu dùng, Chia sẻ).
- **Huy Hiệu & Thành Tích (Badges & Streaks)**:
  - Tích hợp 8 loại huy hiệu MVP (`BadgeDao`, `BadgesScreen`).
  - Kết nối ngọn lửa Streak vào dữ liệu thực tế hằng ngày của trẻ.
  - Thêm hiệu ứng pháo hoa giấy ăn mừng (`ConfettiBurst`) khi trẻ tick xong việc.
- **Diagnostics & Báo Lỗi**:
  - Tích hợp hệ thống ghi nhật ký lỗi (`NhatKyLoi`), chụp màn hình (`chupManHinh`) và gửi báo cáo lỗi về máy chủ (`BaoLoiScreen`) — cần dựng endpoint trước khi dùng được.
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
