# 14 — Audit tính năng mới (Sprint 3 & 5)

**Ngày:** 23/08/2026 · **Bản kiểm:** `0.2.6+12`, commit `f87ee31` ·
**Cách kiểm:** kéo code về, biên dịch, chạy toàn bộ test, rồi **lần theo từng
tuyên bố trong roadmap ngược về code** — hàm nào tuyên bố là xong thì tìm xem
có ai gọi nó không.

Nhắc lại loại lỗi dự án này dính đi dính lại, vì audit lần này bắt được **ba
ca mới** của đúng loại đó:

> **Thứ có trong code mà không ai đọc, hoặc không bao giờ chạy.**
> Trước đây: `jars`, `badges_earned`, `calculateStreak`, `KidScale.celebrateOnTap`,
> `savings_goals`, `day_rollover_hour`, `TaskCard.isPending`, `tasks.proof_mode`.

---

## Tóm tắt

| # | Vấn đề | Mức |
|---|---|---|
| 1 | Ghép cặp QR **nói với người dùng là đang tải dữ liệu**, rồi không làm gì | 🔴 |
| 2 | `proof_mode` ghi được nhưng **không ai đọc** — bố mẹ bật, con không bị hỏi ảnh | 🔴 |
| 3 | `SyncEngine` và `NotificationService` **chỉ có provider, không ai gọi** | 🔴 |
| 4 | Code và **ADR-027 nói ngược nhau** về mật khẩu của bé | 🟠 |
| 5 | CI đang bị dùng thay cho trình biên dịch — `main` đỏ, 8/16 lượt gần nhất hỏng | 🟠 |
| 6 | Không có ảnh chụp nào cho tính năng mới | 🟡 |

Mục 5 đã sửa (commit `c99c400`): `main` biên dịch lại được, 521 test + 4
integration test xanh.

---

## 1. 🔴 Ghép cặp QR nói dối người dùng

`lib/features/onboarding/onboarding_screen.dart` — quét mã xong:

```dart
final code = await showScanPairingDialog(context);
if (code != null && context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Đã nhận mã: ... Đang tải dữ liệu.')),
  );
}
```

**Hết.** Không tải gì cả. Không có bước nào sau đó.

Và không thể có, vì **trong app chưa có một dòng nào nói chuyện với Supabase**:

```
grep -rn "supabase" lib/ pubspec.yaml   →  không có kết quả
```

Migration SQL có thật và trông đầy đủ (11 bảng + RLS), nhưng đó là phía máy
chủ. Phía app chưa có client, chưa có gọi mạng, chưa có gì.

**Vì sao xếp 🔴 chứ không phải "làm dở":** làm dở thì nút chưa có, người dùng
không mất gì. Đây là nút **có**, bấm được, và **nói rằng nó đang làm việc**.
Bố mẹ sẽ ngồi đợi hồ sơ con hiện ra. Roadmap thì tick ✅ cho mục này.

**Nên làm:** hoặc nối thật, hoặc đổi câu thành sự thật ("Đã nhận mã. Tính năng
đồng bộ đang được hoàn thiện") và bỏ dấu ✅ trong roadmap. Câu hiện tại là thứ
duy nhất không được để lại.

## 2. 🔴 `proof_mode` — giờ tệ hơn hồi còn là cột chết

Trước đây `tasks.proof_mode` là cột không ai đọc cũng không ai ghi. Roadmap ghi
rõ và cảnh báo. Nay Task Editor **ghi** vào nó:

```dart
proofMode: Value(_proofMode.name),     // tasks_screen.dart:528
```

Nhưng lần theo cả `lib/` thì **chỉ có Task Editor** nhắc tới `proofMode`. Luồng
con bấm xong việc (`TaskReviewService.complete`) không hỏi tới nó một lần nào.

Nghĩa là: bố mẹ mở Task Editor, bật **"cần chụp ảnh làm bằng chứng"**, lưu — và
con vẫn bấm xong việc bình thường, không ai hỏi ảnh, xu vẫn cộng ngay.

Cột chết thì chỉ tốn chỗ. **Cái công tắc bật được mà không điều khiển gì thì là
một lời hứa sai** — và bố mẹ chỉ phát hiện ra khi đã tin nó vài ngày.

**Nên làm:** nối vào `TaskReviewService.complete` — `proofMode != none` thì bắt
buộc đi qua duyệt bất kể cấu hình nhà; hoặc gỡ khối đó khỏi editor tới khi làm
xong. Đừng để nguyên.

## 3. 🔴 `SyncEngine` và `NotificationService` chưa từng chạy

Lần theo cả `lib/`, mỗi lớp chỉ xuất hiện đúng **một** chỗ ngoài chính file của
nó — dòng khai báo provider:

```
lib/core/providers/database_provider.dart:143  SyncEngine syncEngine(...)
lib/core/providers/database_provider.dart:148  NotificationService notificationService(...)
```

Không màn hình nào, không service nào gọi tới. Hệ quả cụ thể:

- **Bảng `outbox` không bao giờ có dòng nào.** Chỉ `SyncEngine` ghi vào nó, mà
  `SyncEngine` không ai gọi. Nên "Outbox + retry/backoff + idempotency ✅" thực
  chất là một hàng đợi rỗng vĩnh viễn.
- **Không thông báo nào được gửi.** App cũng chưa có FCM, nên phần "điều tiết
  tối đa 2 thông báo/ngày" chưa có gì để điều tiết.

Cả hai **có unit test** và test xanh. Đó là chỗ dễ nhầm nhất: test xanh chứng
minh *hàm chạy đúng khi được gọi*, không chứng minh *có ai gọi*.

**Nên làm:** roadmap ghi rõ hai lớp này là "đã viết, chưa nối", đừng để ✅ trơn.

## 4. 🟠 Code và ADR-027 nói ngược nhau

`ADR-027` (chưa sửa dòng nào) ghi:

> Onboarding **bắt buộc** đặt pass cho mọi hồ sơ vừa tạo; thêm bé về sau cũng
> phải đặt pass cho bé đó. **Không có hồ sơ nào không có pass.**

Code hiện tại: bố mẹ vẫn `batBuoc: true`, còn bé thì bỏ qua được — cả ở
onboarding lẫn "Thêm bé", kèm lời nhắc *"(tuỳ chọn) … bấm HUỶ nếu không cần"*.

**Đổi thế này có lý** — chính báo cáo ADR-027 đã cảnh báo bé 5 tuổi phải nhớ mật
khẩu là rào thật. Nhưng theo quy ước của dự án, đổi nguyên tắc phải là **một
hành động riêng, tường minh**, không phải tác dụng phụ của một commit tính năng.
Hiện tài liệu đang nói một đằng, app làm một nẻo.

Và **không test nào canh tính bắt buộc** — kể cả hồi còn bắt buộc thật. Integration
test gõ mật khẩu vào cả hai sheet nên xanh ở cả hai cấu hình.

**Nên làm:** chọn một, rồi sửa phía còn lại. Nếu giữ "bé tuỳ chọn" thì sửa
ADR-027 và ghi lý do; nếu giữ ADR thì trả `batBuoc: true`. Kèm test canh.

## 5. 🟠 CI đang bị dùng thay cho trình biên dịch

Lịch sử CI từ commit xanh gần nhất (`85211dd`, run #132):

```
#133 ✅  #134 ✅  #135 ✅  #136 ❌  #137 ❌  #138 ❌  #139 ❌  #140 ❌
#141 ✅  #142 ✅  #143 ❌  #144 ❌  #145 ✅  #146 ❌  #147 ❌
```

**8 trên 16 lượt đỏ**, và `main` để đỏ qua đêm. Các commit `fix(linter)`,
`fix(domain): tuân thủ strict linter`, `fix(ci,a11y)` cho thấy vòng lặp
đẩy-lên-xem-CI-đỏ-sửa-đẩy-lại.

`flutter analyze --fatal-infos` chạy **15 giây** ở máy local. Một vòng CI mất
**3–8 phút**. Chưa kể `main` đỏ thì không ai khác build được.

**Nên làm:** chạy `flutter analyze --fatal-infos && flutter test` trước khi đẩy.
Repo có sẵn quy trình ở `.claude/skills/flutter-8-buoc`; mục "pre-commit hook"
trong Sprint 0 vẫn để trống — đây là lúc nó đáng làm.

## 6. 🟡 Không có ảnh chụp nào cho tính năng mới

`docs/screenshot/` dừng ở ảnh 80, tức bản `v0.2.4`. Từ đó tới nay đã thêm: sửa
hồ sơ con, xoá gia đình, xoá hồ sơ, múi giờ, proof mode, CRUD phần thưởng, hai
màn ghép cặp QR, chia xu dở dang.

Bước 6 của quy trình dự án ("chạy app thật và *nhìn* ảnh chụp") là bước bắt được
nhiều lỗi nhất — hai lỗi 🔴 nặng nhất tháng này đều lộ ra ở đúng bước đó, không
phải từ test. Chín tính năng mới chưa ai nhìn.

---

## Thứ tự đề nghị

1. **§1** — sửa câu nói dối. Một dòng chữ, và nó là thứ người dùng chạm vào.
2. **§2** — nối `proof_mode` hoặc gỡ khối đó khỏi editor.
3. **§4** — chọn một phía, sửa phía còn lại, thêm test.
4. **§5** — chạy analyze trước khi đẩy; cân nhắc pre-commit hook.
5. **§3** — sửa chữ trong roadmap cho khớp thực tế (việc nối thật thuộc Sprint 3).
6. **§6** — chụp lại khi các mục trên yên.

## Ghi chú cho người sửa

Ba trong sáu mục trên (**§1, §2, §3**) là **cùng một lỗi**: thứ tồn tại trong
code nhưng không nằm trên đường chạy nào. Đây là lần thứ **chín** dự án gặp nó.

Cách duy nhất bắt được nó không phải là test — cả ba đều có test xanh. Là hai
câu hỏi này, hỏi trước khi tick ✅:

- **Ai gọi hàm này?** Nếu câu trả lời chỉ là "provider của chính nó" thì nó chưa
  chạy.
- **Người dùng bật nó lên thì cái gì đổi?** Nếu không trả lời được bằng một câu
  cụ thể thì nó chưa xong.
