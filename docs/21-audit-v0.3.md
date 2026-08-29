# 21 — Audit v0.3.0 → v0.3.1

*Soát ngày 26/08/2026 trên `11c265b` + bản sửa kèm commit này.*

Sau bản sửa: `analyze --fatal-infos` **sạch**, **526 test xanh** (523 → 526,
thêm 3 test canh chốt chặn mới).

## 🟠 1 · Bốn lỗi analyzer bị revert — **lần thứ ba**

`8fbdc2f` (bản audit trước, cách đây vài giờ) bọc `unawaited(...)` cho bốn chỗ
hoạt ảnh và thêm `import 'dart:async'`. `7a6beeb` gỡ lại đúng những dòng đó:

```
-import 'dart:async';
-    unawaited(_controller.forward(from: 0));
+    _controller.forward(from: 0);
```

Và **giữ nguyên chú thích của bản sửa** — dòng *"Nổ hoa giấy rồi tự tắt — không
ai chờ kết quả"* vẫn nằm đó, nay giải thích một bản sửa không còn tồn tại. Đây
là lần thứ hai liên tiếp chuyện này xảy ra theo đúng kiểu ấy.

Lịch sử bốn lỗi này:

| Lần | Commit sửa | Commit gỡ |
|---|---|---|
| 1 | `e58f965` | `ccffe4e` / `d6c2648` |
| 2 | `8fbdc2f` | `7a6beeb` |
| 3 | commit này | — |

Sửa đi sửa lại ba lần thì vấn đề không còn nằm ở bốn dòng code. **Nên lần này
không chỉ sửa** — xem mục 3.

## 🔴 2 · Điều ước vẫn nguyên: con tự đặt giá, app vẫn nói sai

`20-audit-dot-lam-lon.md` §1 ghi mục này hôm qua. Soát lại hôm nay: **không có
gì thay đổi**.

- `wish_sheet.dart:85` vẫn `createReward(...)` **không đặt `active: false`** →
  `Rewards.active` mặc định `true` → điều ước lên thẳng danh sách quà của con.
- `costPoints: _suggestedCost` — giá **con** gõ.
- `proposerId` ghi vào `metaJson` nhưng **vẫn không một chỗ nào đọc**.
- `wish_sheet.dart:103` vẫn hiện **"Đã gửi điều ước ... đến bố mẹ!"**.
- `metaJson` vẫn ghép bằng nội suy chuỗi — con gõ một dấu nháy là JSON vỡ.

Nhắc lại vì sao đây là 🔴 chứ không phải chuyện nhỏ: app **nói với một đứa trẻ**
rằng điều ước của nó đang chờ bố mẹ, trong khi thật ra nó vừa tự cấp cho mình
một phần thưởng với giá tự đặt. Cùng loại lỗi với "Đã chụp ảnh bằng chứng" hôm
kia — giao diện khẳng định một trạng thái mà dữ liệu không có.

Hai đường sửa đã ghi ở `docs/20`, vẫn còn nguyên giá trị. Chọn một đường bất kỳ
cũng hơn để nguyên.

## ✅ 3 · Đã dựng chốt chặn — mục "cố ý hoãn" từ Sprint 0

Đề nghị này đã ghi ở `docs/17`, `docs/18`, `docs/19`. Nay làm luôn.

**`.githooks/pre-commit`** chạy `flutter analyze --fatal-infos` trước mỗi
commit. Cài một lần mỗi máy:

```bash
git config core.hooksPath .githooks
```

Hook tự bỏ qua (kèm lời nhắc) nếu máy không có `flutter` trong PATH, nên không
chặn nhầm ai. Cần bỏ qua thật thì `git commit --no-verify`.

**Và một test canh chính chốt chặn** — `test/unit/pre_commit_hook_test.dart`:
hook còn tồn tại, còn chạy `--fatal-infos`, và còn quyền thực thi. Lý do có test
thứ ba: hook mất bit `+x` thì git **bỏ qua trong im lặng** — trông như đang được
bảo vệ mà không, đúng loại hỏng tệ nhất.

Kiểm chứng test bắt đúng: xoá hook → đỏ ở dòng *"đã bị xoá"*; `chmod -x` → đỏ ở
dòng *"chmod +x"*; khôi phục → xanh.

Đây là cùng một nguyên tắc đã dùng cho build number (24/08) và alpha của icon
(25/08): **thứ gì con người sẽ quên thì giao cho máy canh.** Hai lần trước, từ
lúc giao cho máy là không lặp lại lần nào.

## Những gì v0.3.0/v0.3.1 thêm vào

91 file mới, phần lớn là **bộ icon** (`assets/icons/*.png` — water_bottle,
wrench, yo_yo...) đóng §7 của `docs/14` (icon việc nhà còn ít), cộng
`features/parent_home/child_history_sheet.dart` (437 dòng) cho bố mẹ xem lịch
sử từng bé.

Chưa soi được bằng ảnh chụp — cần chạy app thật để kiểm bộ icon mới có đúng quy
tắc *không dùng hình người* (giới tính và màu da) đã ghi ở `task_icons.dart`.
Ghi ra đây thay vì lặng lẽ bỏ bước.

## Còn mở

| Mục | Trạng thái |
|---|---|
| Điều ước (mục 2 ở trên) | 🔴 chưa động |
| Ảnh bằng chứng thật | chưa có `image_picker` |
| Bé teen đạt huy hiệu | vẫn im lặng hoàn toàn (`docs/18` §1) |
| §8 nút −/+ cho điểm · §9 nút LƯU dính đáy | chưa làm |
| §19 linh vật nói một câu | linh vật đã có mặt ở Hành trình, chưa có bong bóng thoại |
| §22 loại điều kiện huy hiệu mới | `BadgeKind` vẫn 4 loại, dù đã 16 huy hiệu |
| `riverpod_lint` | chưa bật |
| `SyncEngine` · `NotificationService` · `Rewards.requiresApproval` | vẫn chỉ có provider / không ai đọc |

## Thứ tự đề nghị

1. **Mục 2 (điều ước)** — đang nói sai với trẻ con, và mỗi ngày để lại là một
   ngày con có thể tự thưởng cho mình.
2. **Bật hook trên mọi máy**: `git config core.hooksPath .githooks`.
3. **`riverpod_lint`** — chốt chặn còn lại chưa dựng.
4. Ảnh chụp cho bộ icon mới.
