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

| # | Việc | Mức |
|---|---|---|
| 1 | **Bé teen đạt huy hiệu → app im lặng hoàn toàn** | 🟠 Mất luôn cả SnackBar, không chỉ hoa giấy |
| 2 | `ref.watch` gọi từ trong event handler | 🟡 Không nổ, nhưng tạo phụ thuộc ẩn |
| 3 | `.watchMember().first` trong khi State đã memo hoá sẵn luồng đó | 🟡 Chen round-trip DB vào đúng lúc cần nhanh |
| 4 | Nhánh hiện ảnh ở màn duyệt là code chết | 🟡 **Không gỡ** — chỗ đặt sẵn cho `Image.file`, đã ghi chú |

### D · Từ `16-roadmap-hoc-tu-chorereward.md` — 9 mục chưa làm

`§6` ngày chưa tới ≠ ngày trống · `§8` điểm bằng nút −/+ · `§9` nút LƯU dính đáy
· `§11` điều ước do con đề xuất · `§13` màn Hành trình · `§14` điều hướng theo
vai · `§19` linh vật nói một câu · `§22` loại điều kiện huy hiệu mới · `§23`
chạm huy hiệu mở màn chi tiết.

Mười bốn mục còn lại của roadmap **đã đóng** — xem `17` và `18`.

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
