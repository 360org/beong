# 18 — Audit sau bản sửa audit 17

*Soát ngày 24/08/2026, trên `a4af4cb`. Đối chiếu bằng code.*

`flutter analyze --fatal-infos` **sạch** · **523 test xanh**.

Điều đáng ghi trước tiên: đây là **lần đầu sau bốn lần liên tiếp** `main` được
đẩy lên trong trạng thái biên dịch được. Chuỗi lỗi lặp đã dừng.

## Bốn mục của audit 17 — đã sửa đủ cả bốn

| Mục | Kiểm chứng |
|---|---|
| 🔴 §10 app nói sai | Chuỗi bịa `local_captured_*` **đã gỡ hẳn** |
| 🟠 Ăn mừng bỏ qua tuổi teen | `child_home_screen.dart:187` — `if (!scale.celebrateOnTap) return;` |
| 🟠 §21 mô tả huy hiệu | Đã có câu nói với con |
| 🟡 Cột chết chưa chú thích | `tables.dart:209` — chú thích rõ lý do và cách nâng cấp |

**§10 giờ đã trung thực.** Lời thoại cho con đổi từ *"Việc này yêu cầu chụp ảnh
xác nhận"* thành *"Việc này cần bố mẹ kiểm tra. Nhớ đưa bố mẹ xem kết quả
nhé!"*. Màn duyệt đổi từ *"Đã chụp ảnh bằng chứng: local_captured_..."* thành
*"Việc này yêu cầu bố mẹ kiểm tra trực tiếp"*. Không còn chỗ nào khẳng định có
ảnh khi không có. Đường (b) của audit 17 — làm đúng và làm gọn.

**§21 mô tả** nay đủ hai phần như roadmap yêu cầu:

> "Làm hết việc 30 ngày liên tiếp — **con là chiến binh thực thụ rồi đó!**"
> "Hoàn thành 50 việc nhà — **bàn tay con nay thật khéo léo!**"

---

## 🟠 1 · Bé tuổi teen đạt huy hiệu giờ **không nhận được gì cả**

Bản sửa chặn đúng chỗ, nhưng chặn hết:

```dart
if (!scale.celebrateOnTap) return;   // dòng 187 — return TRƯỚC _khoeHuyHieu
```

`return` nằm **trước** `_khoeHuyHieu`, nên với bé 14 tuổi thì không hoa giấy,
không dialog, và **cũng không cả SnackBar**. Con đạt huy hiệu, app im lặng
tuyệt đối.

**So sánh ba đời:**

| Bản | Bé nhỏ | Bé teen |
|---|---|---|
| Trước 7a5a7bc | hoa giấy + SnackBar | hoa giấy + SnackBar |
| a4af4cb (nay) | hoa giấy + dialog | **không gì cả** |

Đây là **bước lùi cho nhóm teen**, và phải nói rõ: **lỗi diễn đạt của bản audit
17 là của tôi**. Câu "bọc `showDialog` trong cùng điều kiện `celebrateOnTap`"
đọc theo nghĩa đen thì ra đúng cái đang có. Ý định là "*hạ xuống một dạng nhẹ
hơn*", không phải "bỏ hẳn".

**Sửa đúng:** teen vẫn phải biết mình vừa đạt được gì — trả lại SnackBar kèm
nút XEM cho nhánh `!celebrateOnTap`, chỉ bỏ hoa giấy và dialog chặn màn hình.
Huy hiệu không phải hiệu ứng; nó là thông tin.

## 🟡 2 · `ref.watch` gọi từ trong callback bất đồng bộ

`child_home_screen.dart:180`:

```dart
(ref.watch(familyClockProvider(session.familyId)).value ?? fallbackFamilyClock())
```

Chỗ này nằm trong `_hoanThanhViec` — một event handler, không phải `build`.

**Không nổ**: Riverpod 3 chỉ `assert` cho `ref.listen`, không assert `ref.watch`
(kiểm trong `flutter_riverpod-3.3.2/lib/src/core/consumer.dart:532`). Nhưng nó
**đăng ký một phụ thuộc từ trong event handler**, nên từ đó về sau màn hình
dựng lại mỗi khi đồng hồ gia đình đổi — một phụ thuộc không ai cố ý tạo ra và
không ai đọc được từ `build`.

`ref.read` là thứ đúng ở đây. Repo cũng không bật `riverpod_lint`/`custom_lint`
nên analyzer không bắt được loại này — đáng cân nhắc bật.

## 🟡 3 · Tạo luồng mới trong khi State đã giữ sẵn

Cùng chỗ đó:

```dart
final member = await ref.read(memberRepositoryProvider)
    .watchMember(session.activeMemberId).first;
```

Mà `_luongThanhVien` (dòng 69, gán ở dòng 91) **chính là luồng đó**, đã memo
hoá sẵn trong State. Đây đúng bài học của bản sửa giật cục 0.2.5: luồng mới mỗi
lần gọi là luồng Drift mới, đăng ký mới, một vòng truy vấn mới.

Hệ quả thực tế: thêm một round-trip DB **chen giữa** lúc con bấm xong việc và
lúc hoa giấy nổ — đúng khoảnh khắc đang cần nhanh nhất.

Sửa: đọc `birthYear` từ luồng đã có, hoặc giữ `KidScale` trong State vì `build`
đã tính sẵn nó rồi (dòng 265).

## 🟡 4 · Nhánh hiện ảnh giờ là code chết

`parent_home_screen.dart:505` vẫn còn:

```dart
if (proofUrl != null && proofUrl.isNotEmpty) ...[ ... ]
```

Nhưng `proofUrl` **không còn được ghi ở đâu nữa** — biến khai báo ở
`child_home_screen.dart:103` rồi truyền thẳng vào `complete()` mà không bao giờ
được gán (dòng 157 ghi rõ: *"Không ghi proofUrl — chưa có ảnh thật thì không
nói có"*). Nhánh đó vĩnh viễn không chạy.

Đây lại đúng bệnh lặp lại của dự án — thứ tồn tại mà không ai gọi tới. **Lần
này vô hại và có chú thích tử tế**, nên không đề nghị gỡ: nó là chỗ đặt sẵn cho
`Image.file` khi §10 làm xong thật. Ghi vào đây để bản audit sau không đếm nhầm
nó là lỗi mới.

---

## Chín mục roadmap vẫn chưa làm

Kiểm lại từng cái, không mục nào nhúc nhích so với audit 17:

| Mục | Kiểm |
|---|---|
| §6 Ngày chưa tới ≠ ngày trống | không có nhánh phân biệt |
| §8 Điểm bằng nút −/+ | vẫn `hintText: 'Điểm'` |
| §9 Nút LƯU dính đáy | không có `bottomNavigationBar`/`persistentFooter` |
| §11 Điều ước do con đề xuất | không có |
| §13 Màn Hành trình | không có |
| §14 Điều hướng theo vai | không có |
| §19 Linh vật nói một câu | không có |
| §22 Loại điều kiện huy hiệu mới | `BadgeKind` vẫn 4 loại |
| §23 Chạm huy hiệu mở chi tiết | 0 chỗ `onTap` |

## Nợ kỹ thuật — một mục đóng, một mục vẫn mở

**Đã tốt hơn:** chuỗi bốn lần đẩy code không biên dịch được đã dừng.

**Vẫn mở:** pre-commit hook chạy `flutter analyze --fatal-infos`. Mục này ghi
"cố ý hoãn" từ Sprint 0. Bốn lần hỏng vừa rồi đều bắt được trong 20 giây bằng
đúng lệnh đó. Thêm đề nghị mới: bật `riverpod_lint` — mục 🟡 2 ở trên là loại
lỗi analyzer mặc định không thấy.

## Thứ tự đề nghị

1. **Mục 1 (teen im lặng)** — trả lại SnackBar. Mười phút, và nó đang là bước
   lùi thật với một nhóm người dùng.
2. **Mục 2 và 3** — cùng một hàm, sửa một lượt.
3. **§23 · §22 · §6** — nối tiếp phần huy hiệu và thống kê vừa làm xong.
4. **Pre-commit hook + `riverpod_lint`**.
