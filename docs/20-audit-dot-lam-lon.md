# 20 — Audit đợt làm lớn (v0.2.9 → v0.2.13)

*Soát ngày 26/08/2026, trên `7d84184` + bản sửa kèm commit này.*

Sáu commit, phần lớn là các mục roadmap còn nợ. **Bốn mục lớn đã đóng thật**,
nhưng có **một lỗi 🔴 cùng loại với lỗi ảnh bằng chứng hôm qua**: app nói với
con một chuyện không xảy ra.

Sau bản sửa kèm đây: `analyze --fatal-infos` **sạch**, **523 test xanh**.

## Đã đóng — kiểm bằng code

| Mục | Bằng chứng |
|---|---|
| §24 + §14 Tab theo vai | `router.dart:319–323` — con: Home · Nhiệm vụ · Thưởng · **Huy hiệu** · **Hành trình**; bố mẹ giữ 5 tab cũ |
| §13 Màn Hành trình | `features/journey/journey_screen.dart`, 575 dòng, đọc dữ liệu mục tiêu thật |
| §11 Điều ước | `features/rewards/wish_sheet.dart` — nhưng xem mục 🔴 bên dưới |
| §6 Ngày chưa tới ≠ ngày trống | `stats_screen.dart:929` |
| Huy hiệu | 8 → **16** cái |

Tab `Cài đặt` nay chỉ bố mẹ thấy, và `Hành trình` chỉ con thấy
(`router.dart:86,94`) — đóng đúng cái "hai lỗi ngược chiều" đã nêu ở §24.

---

## 🔴 1 · Điều ước: con tự đặt giá, và app nói sai chuyện đã gửi

**Con bấm ĐIỀU ƯỚC → điền tên quà + số xu → gửi.** App hiện:

> **Đã gửi điều ước "Bộ Lego" đến bố mẹ!**

Nhưng `wish_sheet.dart:85` ghi thẳng một `Reward` **đang hoạt động**:

```dart
await rewardDao.createReward(
  RewardsCompanion.insert(
    title: title,
    costPoints: _suggestedCost,      // ← giá do CON đặt
    metaJson: Value('{"proposerId":"...","note":"..."}'),
  ),                                  // ← không đặt active: false
);
```

`Rewards.active` mặc định `true` (`tables.dart:307`), và `watchRewards` chỉ lọc
`active == true`. Điều ước **không đi đâu cả** — nó xuất hiện ngay trong danh
sách phần thưởng của chính con, đúng cái giá con vừa gõ, và **đổi được ngay khi
đủ xu**.

**Ba chuyện sai chồng lên nhau:**

1. **Không có bước duyệt nào.** `proposerId` được ghi nhưng **không một chỗ nào
   đọc** — bố mẹ không có hàng chờ, không có thông báo, không có gì.
2. **Giá do con chốt.** Roadmap §11 ghi rõ ràng ràng buộc này: *"Giá vẫn là
   quyết định của bố mẹ. Nếu con vừa đặt điều ước vừa tự định giá thì cái xe
   đạp sẽ có giá 5 xu."* Đúng chuyện đó đang xảy ra.
3. **Câu thông báo nói sai.** "Đã gửi ... đến bố mẹ" ngụ ý đang chờ duyệt.
   Không có ai để gửi tới, và không có gì để chờ.

Đây **cùng một loại lỗi** với ảnh bằng chứng hôm qua: giao diện khẳng định một
trạng thái mà tầng dữ liệu không có. Lần đó app bảo bố mẹ "đã chụp ảnh bằng
chứng" khi không có ảnh; lần này app bảo con "đã gửi đến bố mẹ" khi không gửi
đi đâu.

**Sửa thế nào** — hai đường, chủ dự án chọn:

- **(a) Làm đủ:** ghi `active: false`, thêm hàng chờ điều ước ở màn bố mẹ, bố mẹ
  duyệt thì **chốt lại giá** rồi mới bật `active`. Đọc `proposerId` để biết ai
  xin.
- **(b) Nói đúng ngay:** nếu tạm chấp nhận con tự thêm quà, thì đổi câu thông
  báo thành đúng sự thật ("Đã thêm vào danh sách quà của con") và ghi rõ cho bố
  mẹ biết quà nào do con tự đặt.

Để nguyên là tệ nhất: con tin là đang chờ bố mẹ, mà thật ra tự thưởng cho mình
được.

## 🟡 2 · `metaJson` ghép bằng chuỗi, vỡ khi con gõ dấu nháy

Cùng dòng đó:

```dart
metaJson: Value('{"proposerId":"...","note":"${_noteController.text.trim()}"}')
```

Lời nhắn của con nối thẳng vào JSON. Con gõ một dấu `"` — hoặc `\` — là chuỗi
thành JSON hỏng. `rewards_screen.dart:81` có `try/catch` nên app không sập,
nhưng `targetMemberId` đọc ra `null` và mọi thứ trong `metaJson` mất im lặng.

Sửa: `jsonEncode({...})` thay vì ghép tay. Một dòng.

## 🟠 3 · Bốn lỗi analyzer đã sửa hôm qua **quay lại**

`e58f965` (hôm qua) bọc `unawaited(...)` cho bốn chỗ hoạt ảnh và thêm
`import 'dart:async'` vào `celebration.dart`. Đợt này cả bốn trở lại:

```
bee_mascot.dart:82 · bee_mascot.dart:107 · celebration.dart:98 · onboarding_screen.dart:60
```

Đáng chú ý: ở `celebration.dart` **chú thích của bản sửa còn nguyên**
(*"Nổ hoa giấy rồi tự tắt — không ai chờ kết quả"*) nhưng `unawaited(...)` và
import thì mất. Tức là bị revert một phần — và chú thích còn lại nay đang giải
thích một bản sửa **không tồn tại**, khó lần ra hơn cả không có chú thích.

Đã sửa lại trong commit này.

**Lần thứ năm** `main` được đẩy lên trong trạng thái analyzer đỏ. Cả năm lần đều
bắt được trong 20 giây bằng `flutter analyze --fatal-infos`.

## Ghi chú: bốn lỗi `navBadges`/`navJourney` **không phải lỗi**

Lần soát đầu tiên báo thêm 4 lỗi `The getter 'navBadges' isn't defined`. Đó là
do máy soát chưa chạy `flutter gen-l10n` — thư mục `lib/core/l10n/gen/` nằm
trong `.gitignore`. Cả hai ARB đều đã có khoá. Ghi ra đây để bản audit sau không
đếm nhầm.

## Còn mở

| Mục | Trạng thái |
|---|---|
| §8 Điểm bằng nút −/+ | chưa làm |
| §9 Nút LƯU dính đáy | chưa làm |
| §19 Linh vật nói một câu | linh vật **đã có mặt** ở màn Hành trình, nhưng chưa có bong bóng thoại |
| §22 Loại điều kiện huy hiệu mới | `BadgeKind` vẫn 4 loại, dù đã lên 16 huy hiệu |
| Ảnh bằng chứng thật | chưa có `image_picker` |
| Bé teen đạt huy hiệu | vẫn im lặng hoàn toàn (audit 18 §1) |
| Pre-commit hook + `riverpod_lint` | chưa dựng |

## Thứ tự đề nghị

1. **Mục 1 (điều ước)** — chọn đường (a) hoặc (b). Đang là lỗi nói sai với trẻ con.
2. **Mục 2** — một dòng `jsonEncode`.
3. **Pre-commit hook** — năm lần rồi. Nó sẽ chặn đúng loại lỗi ở mục 3.
4. **§22**, **§19** — nối tiếp phần huy hiệu và Hành trình vừa làm.
