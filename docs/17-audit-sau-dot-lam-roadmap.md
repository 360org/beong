# 17 — Audit sau đợt làm roadmap ChoreReward

*Soát ngày 24/08/2026, trên `8f9f4db`. Đối chiếu bằng code, không tin commit
message.*

`flutter analyze --fatal-infos` sạch · **523 test xanh** · không còn commit nào
mới sau bản sửa biên dịch.

## 13 trên 23 mục đã đóng thật

Kiểm bằng `grep` vào đúng chỗ, không tick theo mô tả commit:

| Mục | Bằng chứng |
|---|---|
| §1 Màn mồi thông báo | `onboarding_screen.dart:225`; `main.dart:15` gọi `initialize()` |
| §2 Trạng thái ghép cặp | `settings_screen.dart:412` — "Chưa kết nối máy" |
| §3 Điều khoản · Liên hệ | `settings_screen.dart:205,229` |
| §4 Điều hướng tuần | `onPrevWeek`/`onNextWeek`, 8 chỗ |
| §5 Thẻ tổng Thống kê | `stats_screen.dart:106` — "TỔNG KẾT TUẦN" |
| §7 Buổi trong ngày | `tasks_screen.dart:507,672` — Sáng/Chiều/Tối, ghi rõ tuỳ chọn |
| §12 Huy hiệu chia nhóm | `_CategoryHeader`, nhóm theo `kind` |
| §15 Cung tiến độ | `_BadgeTile(current: progress?.valueFor(...))` |
| §16 Nút Đổi mờ khi thiếu xu | `rewards_screen.dart:359` — `onPressed: null` |
| §17 Mục tiêu từ phần thưởng | `goal_sheet.dart:108` `_selectReward`, `:142` đọc danh sách thưởng |
| §18 Màn ăn mừng huy hiệu | `_BadgeCelebrationDialog` |
| §20 Lật từng huy hiệu | `_currentIndex` · `total` · `isLast` — đúng như mô tả |
| §21 Tên là danh hiệu | "Khởi đầu kiên trì" · "Chiến binh bất bại" · "Bậc thầy việc nhà" |

Ngoài roadmap, `CHANGELOGS.md` ở gốc đã xoá — đóng luôn §4 của
`15-audit-toan-repo.md`.

---

## 🔴 1 · Ảnh bằng chứng: chưa xong, và giờ app **nói sai**

Đây là mục nghiêm trọng nhất trong cả bản audit, và nó **nặng hơn lần trước**.

Luồng hiện tại:

1. `pubspec.yaml` **không có** `image_picker`, không có `camera`.
2. Con bấm xong việc cần ảnh → hiện hộp thoại: *"Việc này yêu cầu chụp ảnh xác
   nhận. Hãy đưa bố mẹ kiểm tra sau khi bấm xong nhé!"* — tức là bảo con đi
   khoe tận nơi.
3. `child_home_screen.dart:154` ghi thẳng một chuỗi bịa:

   ```dart
   proofUrl = 'local_captured_${DateTime.now().millisecondsSinceEpoch}';
   ```

4. `parent_home_screen.dart:518` hiện ra cho bố mẹ:

   > **Đã chụp ảnh bằng chứng: local_captured_1756...**

Bố mẹ đọc dòng đó thì kết luận hợp lý là **có một tấm ảnh**. Không có tấm nào.

**Vì sao đây là bước lùi, không phải tiến bộ nửa vời.** Trước đây nút chụp
không làm gì — người dùng thấy vô dụng rồi bỏ qua, và cái giá là một tính năng
chết. Bây giờ app **khẳng định một điều không đúng** với đúng người đang dựa
vào nó để quyết định duyệt việc cho con. Cái giá không còn là một tính năng
chết, mà là niềm tin vào mọi thứ khác app nói.

Đây vẫn là bệnh cũ của dự án — thứ hiện ra mà không có gì đứng sau — nhưng lần
này nó không còn là *code chết* mà thành *code nói sai*.

**Hai đường đi, và đây là quyết định của chủ dự án:**

- **(a) Làm cho xong thật** — thêm `image_picker`, lưu file vào thư mục app,
  ghi đường dẫn thật vào `proof_url`, và dựng `Image.file` trong thẻ chờ duyệt.
- **(b) Ngừng nói sai trong mười phút** — bỏ dòng ghi `proofUrl` giả, đổi lời
  thoại thành đúng thứ đang xảy ra ("Nhớ đưa bố mẹ xem nhé"), và bỏ dòng "Đã
  chụp ảnh bằng chứng" ở màn duyệt.

Đường (b) không đóng được §10, nhưng nó **rẻ và lập tức hết dối**. Để nguyên
như hiện nay là lựa chọn tệ nhất trong ba.

## 🟠 2 · Màn ăn mừng bỏ qua ràng buộc tuổi teen

`_khoeHuyHieu` (`child_home_screen.dart:170`) bung dialog **vô điều kiện**.
Trong khi ngay cùng file, dòng 1008 vẫn giữ nguyên quy tắc cũ:

```dart
// `celebrateOnTap` tắt với tuổi teen: hoa giấy với bé 14 tuổi là rườm rà.
if (scale.celebrateOnTap) onCompleted();
```

Hoa giấy thì tôn trọng bé 14 tuổi, còn hộp thoại chặn cả màn hình kèm chữ "HUY
HIỆU MỚI!" thì không. Hộp thoại **xâm phạm hơn** hoa giấy, nên nếu có ngoại lệ
thì phải ngược lại.

Sửa: bọc `showDialog` trong cùng điều kiện `scale.celebrateOnTap`, hoặc với
teen thì hạ xuống một dạng nhẹ hơn.

## 🟠 3 · §21 mới xong một nửa

**Tên đã sửa xong** và sửa tốt — "Khởi đầu kiên trì", "Tay làm thoăn thoắt",
"Chiến binh bất bại", "Nhà sưu tầm quà". Không còn cái nào là con số.

**Mô tả thì chưa động tới:**

| Mô tả hiện tại | Còn thiếu |
|---|---|
| "Làm hết việc 3 ngày liên tiếp" | một câu nói với con |
| "Hoàn thành 10 việc nhà" | một câu nói với con |

Roadmap §21 nói rõ mô tả gồm **hai phần**: điều kiện, rồi một câu động viên
xưng "con". Hiện mới có phần đầu. Đây vẫn là mục rẻ nhất trong tài liệu — chỉ
là chuỗi, không đụng lược đồ.

## Chưa làm — 9 mục

| Mục | Trạng thái kiểm |
|---|---|
| §6 Ngày chưa tới khác ngày trống | không thấy nhánh nào phân biệt |
| §8 Điểm bằng nút −/+ | `tasks_screen.dart:657` vẫn `hintText: 'Điểm'` |
| §9 Nút LƯU dính đáy | không có `bottomNavigationBar`/`persistentFooter` |
| §11 Điều ước do con đề xuất | không có |
| §13 Màn Hành trình | không có |
| §14 Điều hướng theo vai | không có |
| §19 Linh vật nói một câu | không có |
| §22 Loại điều kiện mới | `BadgeKind` vẫn đúng 4 loại |
| §23 Chạm huy hiệu mở chi tiết | 0 chỗ `onTap` trong `badges_screen.dart` |

## Nợ kỹ thuật lặp lại — đáng lo hơn từng lỗi riêng lẻ

Bản pull này là **lần thứ tư** `main` được đẩy lên trong trạng thái không biên
dịch được, và **lần thứ tư** `kPhienBanApp` lệch `pubspec.yaml`.

Cả bốn lần đều phát hiện được trong **20 giây** bằng `flutter analyze
--fatal-infos` chạy tại máy. Quy tắc này đã nằm trong
`.claude/skills/flutter-8-buoc` từ 24/08, có bảng tính rõ 20 giây đổi lấy 4–5
phút CI cộng một build number vĩnh viễn. Quy tắc có rồi mà vẫn lặp thì vấn đề
không nằm ở chỗ chưa biết.

Đề nghị chuyển từ quy tắc sang **chốt chặn máy móc**: pre-commit hook chạy
`flutter analyze --fatal-infos` — đúng cái mục đã ghi "cố ý hoãn" ở Sprint 0
của `05-roadmap.md`. Hoãn đủ lâu rồi.

## Thứ tự đề nghị

1. **Quyết chuyện §10** — (a) làm xong hoặc (b) ngừng nói sai. Không để nguyên.
2. **§21 nửa còn lại** và **mục 2 (teen)** — cả hai đều dưới một giờ.
3. **§23**, **§22**, **§6** — nối tiếp phần huy hiệu và thống kê vừa làm.
4. **Pre-commit hook** — để không phải viết lại mục "nợ kỹ thuật" ở bản audit sau.
