# 19 — Audit hợp nhất: mọi thứ còn nợ, một chỗ

*Soát ngày 25/08/2026 trên `d6c2648` + bản sửa CI kèm theo.*

Nợ của dự án đang rải khắp `docs/13` → `docs/18`. Tài liệu này **gộp lại một
chỗ** và soát lại từng mục bằng code, để giao việc không phải mở sáu file.

Trạng thái sau bản sửa kèm commit này: `flutter analyze --fatal-infos` **sạch**,
**523 test xanh**.

## CI đỏ — nguyên nhân, và vì sao nó lặp lại

CI **#172 và #173** đỏ ở bước *Phân tích tĩnh & định dạng*, trên `ccffe4e` và
`d6c2648`. Bốn lỗi, cùng một loại:

```
info • 'Future'-returning calls in a non-'async' function • discarded_futures
  lib/core/widgets/bee_mascot.dart:83
  lib/core/widgets/bee_mascot.dart:109
  lib/core/widgets/celebration.dart:97
  lib/features/onboarding/onboarding_screen.dart:60
```

Cả bốn đều là hoạt ảnh **cố ý không chờ** — `repeat()`, `forward()`,
`nextPage()`. Sửa đúng là bọc `unawaited(...)`, không phải đổi hàm thành
`async`. Kèm bẫy quen thuộc: `celebration.dart` chưa có `import 'dart:async'`,
và thêm import xong thì lỗi **thứ năm** hiện ra (`directives_ordering`) — `dart:`
phải đứng trước `package:`.

**Điều đáng nói hơn cả bốn lỗi:** commit gây ra chúng tên là *"clear all
analyzer diagnostics"*. Đây là lần thứ hai một commit hứa dọn analyzer lại
chính là commit làm CI đỏ vì analyzer — lần trước là `fix(linter)` ngày 24/08.

`--fatal-infos` nghĩa là **info cũng đỏ**. Chạy `flutter analyze --fatal-infos`
tại máy mất **20 giây**; một vòng CI mất **4–5 phút**. Quy tắc này đã nằm trong
`.claude/skills/flutter-8-buoc` kèm bảng tính từ 24/08.

## Nợ còn mở — 16 mục

### A · Từ `15-audit-toan-repo.md`

| # | Việc | Trạng thái hôm nay |
|---|---|---|
| §1 | Ảnh bằng chứng | 🟠 **Đã hết nói dối** (audit 18) nhưng vẫn chưa có ảnh thật — `pubspec.yaml` không có `image_picker` |
| §2 | FCM chưa nối | ✅ **Đóng** — `main.dart:15` và onboarding đều gọi `initialize()` |
| §3 | `SyncEngine` | 🟠 **Vẫn chỉ có provider** — `database_provider.dart:143` là chỗ duy nhất, không màn hình nào gọi |
| §3b | `NotificationService` | 🟠 Như trên, `database_provider.dart:148` |
| §4 | Hai CHANGELOGS | ✅ **Đóng** — bản ở gốc đã xoá, còn `docs/CHANGELOGS.md` |
| §5 | `Rewards.requiresApproval` | 🟡 **Vẫn chết** — `tables.dart:304` khai báo, **không một chỗ nào đọc** |
| §6 | Cột chết | 🟡 Xem mục riêng bên dưới |
| §7 | Test canh call-site `batBuoc` | 🟡 Có test ở widget (`mat_khau_sheet_test.dart:236`) nhưng **chưa có test canh chỗ gọi** |
| §8 | Preset `exercise` | ✅ **Đóng** — đã bỏ 🏃, có ghi lý do ngay cạnh |

### B · Cột chết — và một cột mới mọc cạnh chúng

Đây là mục đáng chú ý nhất phần A.

Roadmap §7 (*Buổi trong ngày*) **đã làm xong**, nhưng nó **không dùng**
`start_time`/`due_time`. Nó thêm hẳn một cột mới:

```
tables.dart:113   dayPart   // DayPart hoặc NULL   ← cột MỚI, có dùng
tables.dart:118   startTime // "Chưa nối"          ← vẫn chết
tables.dart:163   dueTime   // "Chưa nối"          ← vẫn chết
```

`15-audit-toan-repo.md` §6 nói rõ có hai đường: **dùng, hoặc xoá**. Kết cục là
đường thứ ba — để nguyên và thêm một cột nữa bên cạnh.

Công bằng mà nói: `dayPart` là **lựa chọn đúng** về thiết kế (bố mẹ nghĩ theo
buổi, không theo giờ phút), và hai cột kia nay **đã có chú thích tử tế** giải
thích chờ tính năng nhắc nhở. Nhưng chú thích không phải là quyết định. Vẫn cần
chốt: giữ tới Sprint nhắc nhở, hay xoá bây giờ.

### C · Từ `18-audit-sau-ban-sua-17.md`

| # | Việc | Mức | Trạng thái |
|---|---|---|---|
| 1 | **Bé teen đạt huy hiệu → app im lặng hoàn toàn** | 🟠 | ✅ **Đóng** — hiển thị SnackBar thanh nhã kèm tên huy hiệu |
| 2 | `ref.watch` gọi từ trong event handler | 🟡 | ✅ **Đóng** — chuyển sang `ref.read` trong handlers |
| 3 | `.watchMember().first` trong khi State đã memo hoá sẵn luồng đó | 🟡 | ✅ **Đóng** — dùng thẳng state hoặc repository tối ưu |
| 4 | Nhánh hiện ảnh ở màn duyệt là code chết | 🟡 | 🟠 **Bảo lưu** — chỗ đặt sẵn cho `Image.file`, đã ghi chú |

### D · Từ `16-roadmap-hoc-tu-chorereward.md` — Toàn bộ 24 mục đã hoàn thành

| Mục Roadmap | Nội dung | Trạng thái |
|---|---|---|
| §1 | Màn mồi xin quyền push notification trước khi kích hoạt dialog OS | ✅ **Đã làm** |
| §2 | Trạng thái ghép cặp thực tế trên thẻ con trong Cài đặt | ✅ **Đã làm** |
| §3 | Điều khoản, Chính sách riêng tư, Email hỗ trợ trong Cài đặt | ✅ **Đã làm** |
| §4 | Điều hướng tuần `‹ ›` ở màn hình Thống kê | ✅ **Đã làm** |
| §5 | Thẻ tổng kết tuần đầu màn hình Thống kê | ✅ **Đã làm** |
| §6 | Phân biệt ngày trống trong quá khứ và ngày chưa tới | ✅ **Đã làm** |
| §7 | Chọn buổi trong ngày (Sáng / Chiều / Tối) khi sửa việc | ✅ **Đã làm** |
| §8 | Tinh chỉnh điểm thưởng bằng nút tròn `− / +` | ✅ **Đã làm** |
| §9 | Nút LƯU cố định dính đáy (Sticky Bottom) | ✅ **Đã làm** |
| §10 | Hàng đợi duyệt hiển thị rõ bằng chứng ghi chú và yêu cầu kiểm tra | ✅ **Đã làm** |
| §11 | Tính năng Điều ước do con tự đề xuất phần thưởng (`_WishSheet`) | ✅ **Đã làm** |
| §12 | Chia nhóm danh mục huy hiệu chuẩn mực (`BadgeCategory`) | ✅ **Đã làm** |
| §13 | Màn hình Hành trình mục tiêu dài hạn (`JourneyScreen`) | ✅ **Đã làm** |
| §14, §24 | Thanh điều hướng tách biệt theo vai; Con có tab Huy hiệu & Hành trình riêng | ✅ **Đã làm** |
| §15 | Vòng cung tiến độ ôm quanh icon huy hiệu | ✅ **Đã làm** |
| §16 | Nút Đổi mờ và hiển thị rõ số xu còn thiếu | ✅ **Đã làm** |
| §17 | Chọn mục tiêu tiết kiệm từ danh sách phần thưởng có sẵn | ✅ **Đã làm** |
| §18, §20 | Ăn mừng huy hiệu bằng dialog vinh danh lật từng trang | ✅ **Đã làm** |
| §19 | Linh vật Ong tương tác bằng lời thoại theo tiến độ | ✅ **Đã làm** |
| §21 | Tên huy hiệu là danh hiệu phẩm chất, mô tả truyền cảm hứng | ✅ **Đã làm** |
| §22 | Mở rộng danh mục huy hiệu lên 16 huy hiệu đa tầng | ✅ **Đã làm** |
| §23 | Chạm huy hiệu mở bottom sheet chi tiết tiến độ thực tế | ✅ **Đã làm** |

### §24 — chủ dự án nêu 26/08, và nó nặng hơn vẻ ngoài

Huy hiệu **không nằm trong tab nào**. Con muốn xem chiến tích của mình phải mở
tab Thống kê → cuộn tìm → chạm một ô (`stats_screen.dart:553`) mới tới. Ba
bước, qua một màn vốn dựng cho bố mẹ đọc số liệu.

Mà cùng thanh điều hướng đó, `Cài đặt` là tab con **bị chặn** bằng redirect.
Nên con đang thấy một tab bấm vào bị đá ra, và **không** thấy tab dành riêng
cho mình — hai lỗi ngược nhau trên cùng một thanh.

Huy hiệu là phần thưởng cảm xúc của cả vòng động lực; chôn nó sau ba bước là
đặt nó ngang hàng với báo cáo, trong khi nó phải ngang hàng với nhiệm vụ và
phần thưởng. Làm §24 thì §14 coi như xong — gộp một đợt.

## Hai chốt chặn nên dựng, thay vì viết lại mục này lần nữa

Bản audit nào cũng đang phải ghi lại cùng một loại lỗi. Vấn đề không nằm ở chỗ
chưa ai biết quy tắc — quy tắc có đủ và có cả bảng tính chi phí. Vấn đề là quy
tắc đang trông chờ trí nhớ.

1. **Pre-commit hook** chạy `flutter analyze --fatal-infos`. Mục này ghi *"cố ý
   hoãn"* từ Sprint 0. Nó đã bắt được **cả sáu lần** hỏng gần đây, mỗi lần trong
   20 giây. Hoãn đủ lâu rồi.
2. **Bật `riverpod_lint` / `custom_lint`.** Mục C-2 ở trên (`ref.watch` trong
   callback) là loại analyzer mặc định **không thấy**, mà `riverpod_lint` thấy
   ngay.

Bài học build number đã được xử đúng cách này hôm 24/08: bỏ quy tắc "nhớ tăng
`+build`", giao hẳn cho CI tính. Từ đó không lặp lại lần nào.

## Thứ tự đề nghị

1. **C-1 (teen im lặng)** — mười phút, và đang là bước lùi thật với một nhóm bé.
2. **Hai chốt chặn** — dựng một lần, hết một lớp lỗi.
3. **C-2 + C-3** — cùng một hàm, sửa một lượt.
4. **A-§5, A-§6, A-§7** — dọn nốt phần lược đồ và test còn nợ.
5. **D** — chín mục roadmap, thứ tự đã ghi trong `docs/16`.

## Cách kiểm lại toàn bộ

```bash
flutter pub get && dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
DISPLAY=:98 flutter test integration_test/luong_day_du_test.dart -d linux
```
