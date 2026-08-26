# Changelogs — Bé Ong

Toàn bộ lịch sử phát triển, nâng cấp tính năng, cải tiến giao diện và sửa lỗi của dự án **Bé Ong** (Flutter Mobile Client) được quản lý tập trung và chuẩn hoá theo quy chuẩn AIaC.

---

## v0.2.13+21 (2026-08-26) — Nâng Cấp Toàn Diện Màn Hình Parents, Quản Lý & Phân Tách Theo Từng Bé

### [NEW]
- **Quản Lý & Phân Định Phần Thưởng Theo Từng Bé**:
  - Gán phần thưởng đích danh cho từng bé hoặc dùng chung cho tất cả các con qua `targetMemberId` lưu trong `metaJson`.
  - Hiển thị badge avatar và tên bé kèm màu nhận diện trực quan trên thẻ phần thưởng `_RewardCard`.
  - Bổ sung thanh cuộn `FilterChip` lọc danh sách phần thưởng theo từng bé trên màn hình Phần thưởng của phụ huynh.
  - Phía con chỉ hiển thị các phần thưởng dùng chung hoặc được gán riêng cho chính bé đó.
- **Tuỳ Biến Tỷ Lệ Hũ Xu Theo Từng Bé (`jarSplitOverride`)**:
  - Hỗ trợ thiết lập tỷ lệ hũ riêng biệt phù hợp theo độ tuổi từng bé (bé nhỏ ưu tiên hũ Chi tiêu/Đồ chơi, bé lớn ưu tiên Tiết kiệm/Học tập).
  - Tích hợp RadioGroup và bộ slider điều chỉnh tỷ lệ hũ linh hoạt trong biểu mẫu hồ sơ bé.
- **Gán Việc Nhà Mẫu Hàng Loạt Khi Tạo / Sửa Hồ Sơ Con**:
  - Tích hợp danh sách việc mẫu `kTaskPresets` dạng FilterChip cho phép phụ huynh tích chọn nhanh nhiều việc cùng lúc để tự động tạo và sinh instance việc cho bé ngay trong ngày.
- **Bật / Tắt Mật Khẩu PIN Hồ Sơ Cho Từng Bé**:
  - Bổ sung công tắc `SwitchListTile` bật/tắt mật khẩu 4 chữ số bảo vệ hồ sơ bé, tích hợp hàm `boMatKhau` trong `MatKhauHoSo`.
- **Hiển Thị Rõ Ràng Danh Tính Bé Xin Đổi Thưởng**:
  - Hiển thị avatar tròn, nhãn tên bé và màu nhận diện riêng biệt trên từng thẻ yêu cầu đổi thưởng trong `RedemptionQueue`.

### [IMPROVE]
- **Trải Nghiệm Thao Tác & Nút Đóng / Huỷ Biểu Mẫu**:
  - Bổ sung nút `X` (Đóng/Huỷ) rõ ràng trên header của Form thêm/sửa phần thưởng (`_RewardEditorSheet`) và Form hồ sơ bé (`ChildProfileForm`).
  - Nâng cấp hiển thị trung thực yêu cầu kiểm tra hình ảnh chứng thực từ phụ huynh khi nhiệm vụ yêu cầu chụp ảnh.

### [FIX]
- Đảm bảo 100% test suite (523 tests) vượt qua thành công với 0 diagnostic issues.

---

## v0.2.12+20 (2026-08-26) — Tái Thiết Kế Toàn Diện UI Cho Bé Phong Cách Gamification & Benchmark Chore Rewards

### [NEW]
- **Tái Cấu Trúc Điều Hướng Chuẩn Hoá 4 Tab Phía Con (§14, §24)**:
  - Tinh gọn menu vai con xuống đúng 4 tab: `Home` (Trang chính), `Rewards` (Phần thưởng), `Awards` (Huy hiệu), `Journey` (Hành trình).
  - Ẩn hoàn toàn tab `Tasks` ở vai con vì màn hình Home đã thể hiện trực quan toàn bộ danh sách việc cần làm trong ngày.
  - Bổ sung nút tròn `+` ở góc trên bên phải màn hình con (`_ChildHeader`) mở sheet `_ChildTaskSheet` cho phép trẻ tự ghi nhận việc tự giác đã làm kèm số xu đề xuất và icon, tự động sinh instance và gửi bố mẹ duyệt khen thưởng.
- **Nâng Cấp Tab Rewards Vai Con Trực Quan Hoá Tài Chính**:
  - Đưa thẻ tổng quan xu của con (`_ChildWalletJarsBanner`) lên trên cùng tab Rewards.
  - Hiển thị danh sách các hũ xu con đang tích luỹ (`_JarItemCard`) dạng lưới thẻ ngang cuộn mượt mà trước khi đến danh mục phần thưởng đổi xu và điều ước, giúp trẻ nắm rõ số dư xu có thể chi tiêu.
- **Tái Thiết Kế Tab Awards (Huy Hiệu) Phong Cách Gamification**:
  - Loại bỏ danh sách chữ dài, chuyển đổi sang thẻ tổng kết "ĐÃ THU THẬP X / Y" cùng lưới icon huy hiệu 3 cột trực quan (`_BadgeGridTile`) kèm vòng cung tiến độ tròn (`ProgressRing`).
  - Chạm vào từng ô huy hiệu để mở bảng bottom sheet chi tiết hiển thị trạng thái chinh phục và yêu cầu mở khoá.
- **Tái Thiết Kế Tab Journey Dạng Bản Đồ Leo Núi Nấc Thang Phiêu Lưu (§13)**:
  - Chuyển đổi toàn bộ màn hình thành bản đồ leo núi nấc thang zic-zac kết nối từ chân núi (0%) lên đỉnh vinh quang (100%).
  - Tích hợp linh vật Bé Ong động đứng trực tiếp tại trạm dừng hiện tại theo tiến độ xu tích luỹ được của trẻ.

### [FIX]
- Sửa triệt để các cảnh báo linter analyzer: loại bỏ unused import `dart:async`, giải quyết lỗi `discarded_futures` cho hiệu ứng chạm nảy linh vật `BeeMascot`, làm sạch định dạng eol.
- Đảm bảo 100% test suite (523 tests) vượt qua thành công với 0 diagnostic issues.

---

## v0.2.11+19 (2026-08-26) — Triệt tiêu Lỗi Analyzer `discarded_futures` & Ổn định Hoàn toàn Pipeline CI

### [FIX]
- **Sửa Triệt để Lỗi Bất đồng bộ Không Chờ (`discarded_futures`)**:
  - Bọc `unawaited(...)` cho các hiệu ứng hoạt ảnh cố ý không chặn:
    - `BeeMascot._syncAnimation` và `BeeMascot.onTap` (`lib/core/widgets/bee_mascot.dart`).
    - `ConfettiBurst._play` (`lib/core/widgets/celebration.dart`).
    - `OnboardingScreen._nextPage` (`lib/features/onboarding/onboarding_screen.dart`).
  - Thêm `import 'dart:async';` đảm bảo đúng thứ tự import và định dạng.

---

## v0.2.10+18 (2026-08-26) — Chuẩn hoá Ràng buộc Kiến trúc & Danh mục Icon Huy hiệu

### [FIX]
- **Chuẩn hoá Kiến trúc Tầng UI (`wish_sheet.dart`)**:
  - Tuân thủ nghiêm ngặt ranh giới Clean Architecture, nhập `RewardsCompanion` và các kiểu dữ liệu liên quan qua `reward_repository.dart`, loại bỏ import trực tiếp từ `package:beong/data/`.
- **Khớp Asset Icon Huy hiệu (`badge_def.dart`)**:
  - Đồng bộ các icon huy hiệu `streak_14` (`gem`) và `reward_10` (`star`) với bộ asset PNG hiện có.
  - Cập nhật số lượng kiểm thử 16 huy hiệu trong `test/unit/domain/badge_test.dart`.
- **Cập nhật Cẩm nang Kỹ thuật (`flutter-8-buoc`)**:
  - Bổ sung quy tắc phòng ngừa lỗi kiến trúc và kiểm tra asset icon vào `references/lint-thuong-gap.md`.

---

## v0.2.9+17 (2026-08-26) — Hoàn thiện Toàn diện Trải nghiệm Gamification, Điều hướng theo Vai, Điều ước & Hành trình

### [NEW]
- **Điều hướng Chuẩn hoá theo Vai trò (§14, §24)**:
  - Phân tách thanh điều hướng độc lập dựa trên vai trò:
    - **Bố mẹ (5 tabs)**: Trang chính (`Home`), Nhiệm vụ (`Tasks`), Phần thưởng (`Rewards`), Thống kê (`Stats`), Cài đặt (`Settings`).
    - **Con (5 tabs)**: Trang chính (`Home`), Nhiệm vụ (`Tasks`), Phần thưởng (`Rewards`), Huy hiệu (`Badges`), Hành trình (`Journey`).
  - Trẻ có tab **Huy hiệu** và **Hành trình** riêng biệt, loại bỏ tình trạng bị redirect chặn khi truy cập nhầm Cài đặt.
- **Màn hình Bản đồ Hành trình Mục tiêu (§13)**:
  - Màn hình `JourneyScreen` trực quan hoá con đường chinh phục mục tiêu tiết kiệm dài hạn của con qua các cột mốc tiến độ dọc (25%, 50%, 75%, 100%) kết nối linh hoạt với hũ Để dành.
- **Tính năng Điều ước do Con Tự Đề Xuất (§11)**:
  - Cho phép trẻ tự đề xuất mong muốn phần thưởng (`_WishSheet` / `showWishSheet`) kèm số xu gợi ý để bố mẹ xem xét, phê duyệt và định giá chính thức.
- **Mở rộng Hệ thống Huy hiệu & Cột mốc Đa tầng (§22)**:
  - Mở rộng bộ huy hiệu lên 16 huy hiệu chia đều trên 4 danh mục (`streak`, `tasksDone`, `routinePerfectDays`, `redemptions`), bổ sung các mốc 14 ngày, 25 việc, 3 phần thưởng và 10 phần thưởng.
- **Bộ Nhận diện & App Icon Chính thức**:
  - Cập nhật đồng bộ bộ App Icon hoàn toàn mới từ `docs/icons/app-icon.png` cho toàn bộ các nền tảng: iOS (AppIcon xcassets 20x20..1024x1024), Android (mipmap mdpi..xxxhdpi), macOS (16x16..1024x1024), Web (favicon, apple-touch-icon, logo) và tài liệu.
- **Hệ thống Ăn mừng & Vinh danh Huy hiệu Đa tầng (§18, §20)**:
  - Dialog vinh danh `_BadgeCelebrationDialog` xuất hiện khi con đạt thành tựu mới, hỗ trợ lật mở từng huy hiệu kèm chấm phân trang khi nhận nhiều danh hiệu cùng lúc thay vì SnackBar trôi mất sau 4s.
  - Phân loại 4 nhóm danh mục huy hiệu chuẩn mực (`BadgeCategory`: Chuỗi kiên trì, Việc nhà chăm chỉ, Thói quen vững vàng, Phần thưởng & Tiết kiệm).
  - Đổi tên huy hiệu thành danh hiệu phẩm chất và câu mô tả truyền cảm hứng cho trẻ (§21).
- **Trải nghiệm Thao tác & Thiết kế Trình soạn thảo Nhiệm vụ (§7, §8, §9)**:
  - Bổ sung chọn Buổi trong ngày (Sáng / Chiều / Tối) tối ưu thực tế cho phụ huynh.
  - Điều chỉnh điểm thưởng bằng bộ nút tròn `− / +` bước nhảy 5 xu tiện dụng.
  - Cố định nút `LƯU` dính đáy màn hình (Sticky Bottom) chống trôi khi cuộn form.
- **Tiếng nói Linh vật Ong (§19)**:
  - Tích hợp thoại tương tác cho `BeeMascot` tại Dashboard vai con, phản hồi trực tiếp theo tiến độ hoàn thành công việc trong ngày.

### [FIX]
- **Tối ưu Trải nghiệm Tuổi Teen & Hoạt ảnh (Audit 18 C-1)**:
  - Nhóm trẻ teen (13–15) nhận thông báo huy hiệu mới qua SnackBar kèm biểu tượng và tên huy hiệu rõ ràng, tôn trọng sở thích không bị chen ngang bởi dialog pop-up.
- **Sửa Lỗi Bằng chứng Ảnh & Trung thực Trạng thái (Audit 15 §1, Audit 17 §1)**:
  - Loại bỏ chuỗi giả `local_captured_...` khi con hoàn thành việc yêu cầu ảnh. Đổi thông điệp thoại thành trung thực ("Cần bố mẹ xem").
  - Màn hình duyệt của bố mẹ hiển thị đúng yêu cầu kiểm tra trực tiếp thay vì ghi đã có ảnh chụp giả.
- **Hoàn thiện Câu Động viên Huy hiệu (Roadmap §21, Audit 17 §3)**:
  - Bổ sung đầy đủ vế thứ hai — lời động viên xưng "con" cho toàn bộ huy hiệu.
- **Loại bỏ Emoji Người trong Preset (Audit 15 §8)**:
  - Đổi icon preset `exercise` từ `run` (🏃) sang `soccer` (⚽) để đảm bảo tính trung tính cho mọi bé.
- **Bổ sung Chú thích 5 Cột Schema Chưa Nối (Audit 15 §6)**:
  - Chú thích rõ ràng trạng thái và lý do bảo lưu trong `tables.dart` cho `currency`, `userId`, `startTime`, `dueTime`, `proofUrl`.
  - Nút `Đổi` trong `RewardsScreen` hiển thị trạng thái và tính toán số xu còn thiếu (`Thiếu X xu`) khi chưa đủ điều kiện đổi thưởng.
  - `GoalSheet` cho phép chọn nhanh các phần thưởng có sẵn trong gia đình để tự động điền mục tiêu tiết kiệm.
  - Trẻ có thể mở `GoalSheet` và tự đặt/đề xuất mục tiêu tiết kiệm trực tiếp từ màn hình chính của mình.
- **Nâng cấp Giao diện Huy hiệu & Thống kê Tuần (§4, §5, §6, §12, §15)**:
  - Vẽ vòng cung tiến độ (`ProgressRing`) ôm quanh icon huy hiệu hiển thị trực quan tỷ lệ % đã đạt được.
  - Bổ sung điều hướng tuần `‹ ›` và thẻ tổng kết tuần trực quan tại đầu màn hình Thống kê `StatsScreen`.
  - Phân biệt rõ ràng giữa ngày trống không hoạt động trong quá khứ và các ngày chưa tới trong tuần.

---

## v0.2.7+15 (2026-08-25) — Hoàn thiện Bằng chứng Việc nhà, Pháp lý Store & Trạng thái Ghép cặp

### [NEW]
- **Hoàn thiện luồng Bằng chứng Việc nhà (`proof_mode`)**:
  - Tích hợp ghi chú / chụp ảnh khi con bấm hoàn thành nhiệm vụ có yêu cầu bằng chứng (`ProofMode.note`, `ProofMode.photo`).
  - Hàng đợi duyệt của Bố Mẹ hiển thị đầy đủ ghi chú và bằng chứng kèm theo để duyệt/từ chối chính xác.
- **Màn mồi xin quyền Push Notification (Pre-permission Flow)**:
  - Hiển thị màn mồi giải thích lợi ích sau Onboarding trước khi kích hoạt dialog xin quyền push của OS, tránh bị từ chối mất quyền vĩnh viễn trên iOS.
  - Khởi tạo `PushNotificationService` trong `main.dart`.

### [IMPROVE]
- **Bổ sung Thông tin Pháp lý & Hỗ trợ trong Cài đặt**:
  - Thêm mục Chính sách quyền riêng tư (`beong.net/quyen-rieng-tu.html`), Điều khoản sử dụng (`beong.net/dieu-khoan.html`) và Email hỗ trợ (`info@beong.net`) đáp ứng quy định kiểm duyệt của App Store & Google Play.
- **Hiện trạng thái kết nối máy con trong Cài đặt**:
  - Thẻ thành viên trẻ hiển thị trạng thái kết nối thực tế (`Chưa kết nối máy`).
- **Dọn dẹp & Chuẩn hoá Repository**:
  - Xoá file `CHANGELOGS.md` trùng lặp ở root.
  - Chuẩn hoá quy tắc duyệt phần thưởng theo ADR-025.

---

## v0.2.7+14 (2026-08-24) — Tích hợp Push Notification (Supabase + FCM) & Cải tiến Giao diện (Audit Phần II)

### [NEW]
- **Kiến trúc Push Notification (Supabase Edge Function + Google FCM v1)**:
  - Bảng cơ sở dữ liệu `device_tokens` lưu định danh thiết bị kèm cơ chế phân quyền Row Level Security (RLS) theo từng gia đình (`supabase/migrations/20260824000000_device_tokens_and_push.sql`).
  - Supabase Edge Function `notify-fcm` (`supabase/functions/notify-fcm/index.ts`) xử lý xác thực Google OAuth2 JWT và phát thông báo đa nền tảng (Android notification channel + iOS APNs badge/sound) hoàn toàn miễn phí 0đ.
  - Tích hợp `PushNotificationService` (`lib/core/services/push_notification_service.dart`) hỗ trợ đồng bộ token và gửi thông báo từ xa 2 chiều giữa Bố Mẹ và Con.
  - Cấu hình Firebase gốc `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) cho bundle ID `net.beong.app`.

### [IMPROVE]
- **Tách banner "Chờ chia" trong Sổ của con (§12)**:
  - Tách ô "Chờ chia" ra khỏi lưới hiển thị hũ tại `StatsScreen`, đưa lên thành `_UnallocatedBanner` nổi bật trên cùng chiếm trọn chiều ngang kèm nút **"Chia ngay"** mở trực tiếp `AllocateXuSheet`.
  - Lưới hũ bên dưới chỉ còn hiển thị các hũ tích luỹ thật (`Tiêu`, `Để dành`, `Cho đi`...).
  - Tự động ẩn banner khi số xu chờ chia bằng 0 (`inbox == 0`).
- **Tái cấu trúc màn hình Cài đặt thành 4 nhóm khoa học (§10)**:
  - Chia toàn bộ 11 mục cài đặt phẳng trước đây thành 4 khối `_SettingsSection` có tiêu đề phân nhóm rõ ràng:
    1. **Gia đình**: Danh sách thành viên, Thêm bé, Múi giờ (`_TimezoneTile`), Giờ đổi ngày (`_RolloverTile`).
    2. **Quy tắc xu**: Cần bố mẹ duyệt (`_ApprovalTile`), Con tự chia xu (`_AllocationTile`), Các hũ (`_JarsTile`), Trừ xu (`_PenaltyTile`), Quy đổi tiền thật (`_ExchangeRateTile`).
    3. **Ứng dụng**: Giao diện sáng/tối (`_ThemeTile`), Mật khẩu hồ sơ (`_MatKhauTile`).
    4. **Thông tin**: Báo lỗi (`_SettingsTile`), Phiên bản ứng dụng (`_SettingsTile`).
- **Nhóm lịch sử giao dịch theo ngày lịch (§11)**:
  - Tái cấu trúc danh sách giao dịch phẳng trong `StatsScreen` thành từng nhóm theo ngày (`_DailyHistoryList`, `_DayHistoryGroup`).
  - Mỗi ngày là một khối thẻ gập/mở gọn gàng hiển thị tóm tắt `Thứ, ngày/tháng · X việc xong · ±xu`.
  - Mặc định mở sẵn các giao dịch của ngày hôm nay (`isExpandedByDefault`), các ngày trước đó được gập lại để phụ huynh dễ theo dõi.
- **Thu gọn bảng chọn Icon việc nhà & phần thưởng (§8)**:
  - Nâng cấp `IconPickerGrid` thành `StatefulWidget`: mặc định chỉ hiển thị 1 hàng (6 icon đầu tiên, đảm bảo luôn kèm icon đang chọn).
  - Tích hợp nút toggle **"Xem thêm (N hình)"** / **"Thu gọn"** để mở rộng/thu nhỏ lưới icon linh hoạt, không đẩy tràn biểu mẫu nhập liệu.
- **Mở rộng bộ khoá Icon việc nhà (§7)**:
  - Bổ sung các icon từ bundle Fluent Emoji 3D asset (`clipboard`, `gem`, `party`, `warning`, `bee`, `run`, `eye_off`...) vào `kTaskIconKeys`.
- **Tăng cường tương tác & Phản hồi xúc giác vai con (§9)**:
  - Tích hợp rung xúc giác nhẹ (`HapticFeedback.lightImpact()`) khi con chạm tích hoàn thành nhiệm vụ trên `TaskCard`.
  - Bổ sung tương tác chạm vào linh vật Bé Ong (`BeeMascot`) để kích hoạt chuyển động nảy vui nhộn.

---

## v0.2.6+13 (2026-08-23) — Sửa lỗi Luồng Chạy & Đồng bộ Tài liệu (Audit Phần I)

### [FIX]
- **Sửa thông điệp ghép cặp QR**: Cập nhật câu thông báo sau khi quét mã QR sang *"Tính năng đồng bộ qua mạng đang được hoàn thiện"*, phản ánh trung thực trạng thái tính năng.
- **Kích hoạt chế độ kiểm tra bằng chứng (`proof_mode`)**: Nối trường `proof_mode` vào quy trình hoàn thành nhiệm vụ tại `TaskReviewService.complete`. Khi việc yêu cầu chụp ảnh, bắt buộc chuyển trạng thái sang `pendingReview` để bố mẹ duyệt bất kể cấu hình chung của gia đình.
- **Đồng bộ tài liệu ADR-027**: Chuẩn hoá quy định mật khẩu hồ sơ (Bố mẹ bắt buộc, Bé tuỳ chọn).
- **Kiểm chứng giao diện thực tế**: Chụp bổ sung 10 ảnh kiểm chứng các màn hình mới (`docs/screenshot/81`–`90`).

---

## v0.2.6 (2026-08-23) — Universal Link QR, Quản lý Gia đình & Supabase Schema

### [NEW]
- **Ghép cặp thiết bị bằng Camera native & Universal Link**:
  - Hỗ trợ quét mã ghép cặp QR trực tiếp bằng ứng dụng Camera mặc định của điện thoại thông qua Universal Link / App Link (`https://beong.net/pair?code=...`).
  - Tích hợp `mobile_scanner` quét mã QR trực tiếp trong app và hiển thị vector QR bằng `qr_flutter`.
- **Quản lý Hồ sơ Con & Xoá Gia đình**:
  - Thêm tính năng sửa thông tin con (tên, avatar, màu đại diện, ngày sinh/năm sinh).
  - Hỗ trợ xoá toàn bộ dữ liệu gia đình kèm cơ chế xác thực mật khẩu phụ huynh và cảnh báo nguy hiểm.
- **Múi giờ & Giờ đổi ngày linh hoạt**:
  - Cho phép chọn múi giờ (`Asia/Ho_Chi_Minh`, `Asia/Tokyo`, `America/New_York`...) độc lập với múi giờ thiết bị.
  - Cho phép cấu hình giờ đổi ngày (`day_rollover_hour`) từ 0h đến 6h sáng để tính toán streak và nhiệm vụ chính xác theo lịch sinh hoạt.
- **Chế độ Bằng chứng hình ảnh (`proof_mode`)**: Bổ sung tuỳ chọn yêu cầu chụp ảnh khi tạo/sửa việc trong Task Editor.
- **CRUD Quản lý Phần thưởng**: Cho phép bố mẹ tạo mới, chỉnh sửa tên, icon, giá xu và xóa phần thưởng.
- **Backend Schema & RLS Policies (Sprint 3)**: Hoàn thiện 11 bảng cơ sở dữ liệu PostgreSQL + Supabase Row Level Security tại `supabase/migrations/`.

### [FIX]
- Nâng deployment target iOS lên 15.5 tương thích thư viện `mobile_scanner`.
- Sửa 13 lỗi strict linter và warning liên quan đến `discarded_futures` và unawaited async.

---

## v0.2.5 (2026-08-23) — Bảo mật Hồ sơ ADR-027 & Tối ưu Trải nghiệm Con

### [NEW]
- **Mật khẩu bảo vệ từng hồ sơ (ADR-027)**:
  - Cơ chế mã hoá và băm mật khẩu hồ sơ bằng SHA-256 (`crypto`).
  - Hộp thoại nhập mật khẩu (`MatKhauSheet`, `hoiMatKhau`) khi chuyển đổi giữa các vai hoặc mở các tính năng nhạy cảm.
- **Khung pháp lý & Quyền riêng tư**:
  - Bổ sung `PrivacyInfo.xcprivacy` cho hệ sinh thái Apple iOS.
  - Cập nhật chính sách quyền riêng tư (`10-privacy-policy.md`) và điều khoản bản quyền EULA 360 CORP.

### [IMPROVE]
- **Khắc phục triệt để hiện tượng giật danh sách việc**:
  - Tối ưu hoá luồng dữ liệu `StreamBuilder` tại `ChildHomeScreen`, lưu trữ stream trong State để tránh huỷ/đăng ký lại stream khi `setState` nổ hoa giấy.

---

## v0.2.3 & v0.2.4 (2026-08-22) — Bảo vệ Phiên làm việc & Tự động hoá CI/CD Release

### [NEW]
- **Cơ chế Khoá lại (Lock App)**: Nút "KHOÁ LẠI" thay cho nút Đăng xuất cũ, giúp phụ huynh đưa máy cho con mà không lo mất dữ liệu.
- **Lối thoát khi quên PIN/Mật khẩu**: Cơ chế xác thực an toàn giúp phụ huynh lấy lại quyền quản trị khi quên mật khẩu.

### [IMPROVE]
- Tự động hoá kiểm tra và xác thực chứng chỉ Play Console / App Store Distribution trước khi build release trong GitHub Actions.

---

## v0.2.1 & v0.2.2 (2026-08-17 – 2026-08-20) — Tách lớp Clean Architecture (Tầng Repository)

### [NEW]
- **Tầng Repository chuẩn Clean Architecture**:
  - Đóng gói 7 abstract interfaces tại `lib/domain/repositories/` (`MemberRepository`, `TaskRepository`, `WalletRepository`, `RewardRepository`, `JarRepository`, `GoalRepository`, `BadgeRepository`).
  - Tách biệt hoàn toàn tầng UI (`lib/features/`) khỏi tầng dữ liệu trực tiếp SQLite DAO (`lib/data/`).
  - Bổ sung bộ kiểm thử kiến trúc `kien_truc_test.dart` ngăn chặn vi phạm layer boundaries.

### [FIX]
- Khắc phục lỗi cộng xu 2 lần cho cùng một lượt việc.
- Sửa lỗi hiển thị trạng thái chờ duyệt của phiếu đổi thưởng.
- Dọn dẹp loại bỏ 6 thư viện dependency không sử dụng để giảm kích thước bundle.

---

## v0.2.0 (2026-08-15 – 2026-08-16) — Hệ thống Tài chính, Thói quen & Báo lỗi Chẩn đoán

### [NEW]
- **Mục tiêu Tiết kiệm (`SavingsGoal`)**: Cho phép trẻ đặt mục tiêu để dành xu kèm thanh tiến độ trực quan.
- **Hệ thống 8 Huy hiệu (`Badges`) & Chuỗi ngày liên tiếp (`Streaks`)**: Tự động tính streak có ngày ân hạn và trao huy hiệu danh dự khi đạt các mốc thành tích.
- **Trình chỉnh sửa Thói quen (`RoutineEditor`)**: Hỗ trợ kéo thả sắp xếp thứ tự nhiệm vụ trong bộ thói quen và tuỳ chỉnh mức thưởng trọn bộ.
- **Quy đổi Xu ra Tiền thật (ADR-017)**: Hỗ trợ phụ huynh cấu hình tỷ lệ quy đổi hiển thị (ví dụ 1 xu = 1.000đ), mặc định tắt.
- **Bộ Icon 3D Fluent Emoji (MIT)**: Chuyển đổi toàn bộ icon sang asset PNG 3D chất lượng cao, đồng nhất trên tất cả các nền tảng (iOS, Android, Desktop).
- **Hệ thống Báo lỗi Chẩn đoán trong App (`NhatKyLoi`)**: Tự động thu thập log, thông số thiết bị và gửi issue chẩn đoán trực tiếp cho đội ngũ phát triển.
- **Điều chỉnh Xu thủ công**: Cho phép bố mẹ cộng/trừ xu tay kèm bắt buộc nhập lý do điều chỉnh để minh bạch sổ cái.

---

## v0.1.0 (2026-08-08 – 2026-08-10) — Quy tắc 3 Hũ Xu, Trừ Xu & Giao diện 5 Tab

### [NEW]
- **Mô hình 3 Hũ Tài chính (ADR-024)**:
  - Thiết kế bảng `jars` với 3 hũ mặc định: `Tiêu`, `Để dành`, `Cho đi`.
  - Hỗ trợ tạo thêm các hũ tuỳ chỉnh riêng của từng gia đình.
  - Cơ chế con tự chia xu từ hũ chờ (`inbox`) vào các hũ theo tỷ lệ mong muốn.
- **Cơ chế Trừ Xu vi phạm & Duyệt việc (ADR-022, ADR-023)**:
  - Hỗ trợ thiết lập mức phạt trừ xu khi bỏ lỡ nhiệm vụ.
  - Cơ chế duyệt nhiệm vụ linh hoạt: mặc định "làm xong là xong", tuỳ chọn duyệt theo từng việc hoặc theo gia đình.
- **Quy trình Đổi thưởng & Duyệt thưởng (ADR-025)**: Hệ thống quà tặng, phiếu đổi thưởng và hoàn xu tự động khi bị từ chối.
- **Giao diện Trẻ em Thích ứng theo Nhóm tuổi (`KidScale`)**: Tự động căn chỉnh kích thước nút bấm, font chữ, khoảng cách theo nhóm tuổi (5–8 tuổi vs 9–15 tuổi).
- **Linh vật Bé Ong (`BeeMascot`)**: Vẽ bằng CustomPainter với các biểu cảm sinh động theo tiến độ trong ngày (`sleepy`, `happy`, `celebrating`).

---

## v0.0.1 (2026-08-01 – 2026-08-04) — Khởi tạo Nền tảng Đa nền tảng (Sprint 0)

### [NEW]
- **Khởi tạo mã nguồn dự án**: Dựng nền tảng Flutter đa nền tảng (iOS, Android, macOS, Windows, Linux).
- **Cơ sở dữ liệu Local Offline-First**: Thiết lập Drift SQLite ORM với đầy đủ bảng dữ liệu ban đầu và sổ cái ví xu (`wallet_ledger`).
- **State Management & Routing**: Tích hợp Riverpod (`StateNotifier`, `Provider`) và `go_router` với `StatefulShellRoute`.
- **Hệ thống Thiết kế & Đa ngôn ngữ**:
  - Design tokens, typography font Nunito, theme màu vàng nhận diện Bé Ong kết hợp xanh 360 CORP.
  - Hỗ trợ song ngữ Tiếng Việt và Tiếng Anh (`app_vi.arb`, `app_en.arb`).
- **Quy trình CI/CD**: Thiết lập GitHub Actions tự động kiểm tra code (`analyze --fatal-infos`), format, chạy unit test và build đa nền tảng.
