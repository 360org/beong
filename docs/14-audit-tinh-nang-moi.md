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

> ## Soát lại 23/08 chiều — bản `0.2.6+13`, commit `707d007`
>
> Bốn trong sáu mục đã đóng, một mục xử lý đúng cách nhưng chưa nối, một chưa động tới.
>
> | # | Vấn đề | Trạng thái |
> |---|---|---|
> | 1 | Ghép cặp QR nói dối | ✅ **Đóng** — câu đổi thành "Tính năng đồng bộ qua mạng đang được hoàn thiện" |
> | 2 | `proof_mode` không ai đọc | ✅ **Đóng** — nối vào `TaskReviewService.complete`, có 2 test |
> | 3 | `SyncEngine` / `NotificationService` | 🟡 **Xử lý đúng cách, chưa nối** — roadmap bỏ ✅ trơn, ghi rõ "chờ tích hợp client Supabase". Code vẫn chỉ có provider, và điều đó nay **đã được nói đúng** |
> | 4 | ADR-027 ngược code | ✅ **Đóng** — ADR viết lại: "Bố mẹ bắt buộc, Bé tuỳ chọn", kèm bảng đối chiếu ba mốc |
> | 5 | CI đỏ | ✅ **Đóng** — #148, #149, #150 xanh liên tiếp |
> | 6 | Không có ảnh chụp | ❌ **Chưa** — vẫn dừng ở ảnh 80 (`v0.2.4`) |
>
> **Đóng thêm ngoài danh sách:** mục cuối còn mở của audit trước
> ([`13`](13-audit-luong-vao-app.md) §1) — dấu vết chẩn đoán lúc khởi động — nay
> đã có, `main.dart` ghi ba chỗ vào `NhatKyLoi`.
>
> **Còn một khe hở nhỏ chưa lấp:** không test nào canh *onboarding truyền
> `batBuoc: true` cho hồ sơ bố mẹ*. Test hiện có canh **sheet** cư xử đúng với
> cờ đó, không canh **chỗ gọi** truyền đúng cờ. Ai đó đổi thành `false` thì
> không gì đỏ — đúng cách mà quy tắc "bé bắt buộc" đã lặng lẽ trôi lần trước.

# Phần I — Đúng/sai (23/08 sáng)

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

---

## Phụ lục — soi bằng ảnh chụp, 23/08 tối (bản `0.2.6+13`)

§6 đã đóng: chụp thêm **10 ảnh** cho các màn mới, `docs/screenshot/81`–`90`.
Chín tính năng của Sprint 3 & 5 nay đã có người nhìn.

### Kiểm chứng §2 trên app thật, không chỉ bằng test

Tạo việc "Làm bài tập" 25 xu, đặt **Yêu cầu bằng chứng = Chụp ảnh**, đổi sang
vai con, bấm xong. Đọc thẳng file dữ liệu ngay sau đó:

```
trạng thái : pendingReview     ← không phải approved
xu         : 0                 ← không cộng
```

Nhà đang **tắt** duyệt. Trước bản sửa, việc này sẽ approved và cộng 25 xu ngay.
Đây là bằng chứng chạy thật, bổ sung cho hai unit test.

### Những thứ nhìn ra được mà đọc code không thấy

- **Mật khẩu bé tuỳ chọn nhìn rất rõ ràng** (`83`): sheet của bố mẹ không có nút
  HUỶ, sheet của bé có. Người dùng phân biệt được ngay, không cần đọc tài liệu.
- **Cài đặt đang dày lên nhanh** (`85`): 12 dòng, và sẽ còn thêm khi Sprint 3
  xong. Chưa tới mức phải chia nhóm, nhưng đáng để mắt.
- **Khung camera đen** (`81`) là do máy dựng ảnh không có camera, không phải
  lỗi. Trên máy thật cần kiểm lại — đây là màn duy nhất trong bộ 90 ảnh **chưa
  ai xác nhận trên thiết bị thật**.

### Một quan sát, chưa xếp là lỗi

Tạo một việc lặp hằng ngày thì app sinh sẵn lượt cho **8 ngày** (23/08 → 30/08),
đều đặn 10 lượt/ngày. Nhất quán nên trông là cố ý, không phải trùng lặp. Ghi lại
vì hai lý do: số dòng lớn dần theo thời gian, và luồng trừ xu khi bỏ lỡ
(`ADR-022`) nay phải đúng với cả lượt **tương lai** chứ không chỉ hôm nay. Nếu
đó là chủ ý thì nên có một dòng trong `03-data-model.md` nói rõ.

---

# Phần II — Cải tiến giao diện (chủ dự án nêu, 23/08 tối)

Sáu điểm dưới đây **không phải lỗi** — code chạy đúng như thiết kế hiện tại.
Đây là yêu cầu nâng chất lượng trải nghiệm, ghi tách khỏi Phần I để không lẫn
"sai" với "chưa đủ tốt".

Chủ dự án gửi kèm 5 ảnh của **ChoreReward** (`support@chorereward.net`) làm mẫu
tham chiếu — app đối chiếu đã phân tích ở
[`07-competitive-analysis.md`](07-competitive-analysis.md). Ảnh của họ, không
phải của Bé Ong; dùng để so cách bố trí, không phải để chép.

## Tóm tắt

| # | Yêu cầu | Hiện trạng đo được | Mức |
|---|---|---|---|
| 7 | Thêm icon cho việc nhà | **30 icon** (`kTaskIconKeys`) | 🟡 |
| 8 | Bảng chọn icon phải thu gọn, có nút "Xem thêm" | Đổ hết 30 icon cùng lúc, chiếm ~5 hàng | 🟡 |
| 9 | Giao diện cho bé thân thiện, ngộ nghĩnh hơn | Đang dùng chung ngôn ngữ thị giác với vai bố mẹ | 🟠 |
| 10 | Cài đặt chia nhóm cho khoa học | **11 dòng trong một khối phẳng**, không tiêu đề nhóm | 🟠 |
| 11 | Thống kê xếp theo ngày, bấm mới sổ ra | Lịch sử là một danh sách phẳng, không nhóm theo ngày | 🟠 |
| 12 | Xu chưa chia làm **banner trên cùng**, hũ nằm dưới | "Chờ chia" đang là **ô thứ tư nằm cùng hàng** với ba hũ thật | 🟠 |

## 7 · 🟡 Icon việc nhà còn ít

Đang có **30 icon** cho việc nhà và 12 avatar con vật. Bảng preset có 20 việc
mẫu, tức phần lớn icon đã bị các preset dùng hết — nhà nào tự đặt việc riêng
("Tưới cây ban công", "Tập đàn", "Cho mèo ăn") sẽ nhanh hết thứ để chọn và phải
dùng lại icon của việc khác.

**Đề xuất:** nâng lên 60–80 icon, chia nhóm theo ngữ cảnh (nhà cửa · học tập ·
vệ sinh · thể chất · thú cưng · giúp đỡ). Ràng buộc phải giữ: mọi icon **nằm
trong bundle**, không tải mạng (ADR-002 offline-first), và mỗi icon phải nhận
ra được ở cỡ 28px — bé chưa đọc chữ thì icon là nội dung duy nhất.

## 8 · 🟡 Bảng chọn icon đổ hết ra một lúc

Hiện đổ cả 30 icon thành lưới 6 cột × 5 hàng ngay trong biểu mẫu (ảnh `88`).
Thêm icon theo mục 7 thì lưới này thành 12–14 hàng, đẩy mọi thứ phía dưới —
lịch lặp, giao cho ai, chế độ duyệt, yêu cầu bằng chứng — ra khỏi màn hình.

**Đề xuất:** mặc định hiện **một hàng** (6–8 icon hay dùng nhất, hoặc icon của
preset vừa chọn), kèm nút **"Xem thêm ▾"** mở ra phần còn lại. ChoreReward làm
đúng kiểu này ở khối preset. Nút phải nói rõ còn bao nhiêu ("Xem thêm 52 hình")
— nút "More" trơn không cho biết bấm vào được gì.

## 9 · 🟠 Giao diện vai con chưa đủ ngộ nghĩnh

Đây là điểm **đáng giá nhất trong sáu điểm**, vì nó chạm thẳng vào kim chỉ nam
của sản phẩm: app phải khiến đứa trẻ *muốn* quay lại.

Hiện vai con và vai bố mẹ dùng **chung một ngôn ngữ thị giác**: cùng kiểu thẻ,
cùng bo góc, cùng kiểu chữ, cùng cách xếp danh sách. Khác biệt duy nhất là
`KidScale` (cỡ chữ, cỡ icon, vùng chạm) và linh vật Bé Ong ở đầu màn.

Nói cách khác: **màn của con hiện là màn của người lớn, phóng to.**

**Đề xuất, xếp theo tỷ lệ hiệu quả trên công sức:**

1. **Phản hồi khi chạm** — hiện chỉ có ô tròn tích và hoa giấy. Thêm nảy nhẹ,
   rung, và một âm thanh ngắn (tắt được). Đây là thứ trẻ nhỏ phản ứng mạnh nhất
   và rẻ nhất để làm.
2. **Linh vật tham gia vào việc**, không chỉ ngồi trên đầu màn — reo khi con
   xong việc, buồn ngủ khi chưa có gì, nhảy khi đủ mốc huy hiệu.
3. **Tiến độ dạng vật thể** thay vì vòng tròn phần trăm: tổ ong đầy dần, cây
   lớn lên. Trẻ 5 tuổi đọc "7/12" chậm hơn nhiều so với nhìn một cái tổ gần đầy.
4. **Nền và thẻ mềm hơn ở vai con** — bo góc lớn hơn, màu ấm hơn, tách hẳn khỏi
   bảng màu nghiêm túc của vai bố mẹ.

**Ràng buộc không được phá:** tương phản 4.5:1 và WCAG 1.4.1 (không dùng riêng
màu để truyền nghĩa) vẫn phải giữ — xem `test/unit/kha_dung_test.dart`. Ngộ
nghĩnh không phải lý do để hạ ngưỡng khả dụng.

## 10 · 🟠 Cài đặt là một khối phẳng 11 dòng

Đo được: một `_SettingsSection` duy nhất chứa Giao diện · Mật khẩu hồ sơ · Cần
bố mẹ duyệt · Con tự chia xu · Các hũ · Trừ xu · Múi giờ · Giờ đổi ngày · Quy
đổi tiền thật · Báo lỗi · Phiên bản. Không tiêu đề nhóm nào (ảnh `85`).

Sprint 3 xong sẽ thêm tài khoản, đồng bộ, thiết bị đã ghép — danh sách này sẽ
qua 15 dòng.

**Đề xuất chia bốn nhóm**, mỗi nhóm một tiêu đề chữ nhỏ như ChoreReward:

| Nhóm | Gồm |
|---|---|
| **Gia đình** | Thành viên, Thêm bé, Ghép cặp máy con, Múi giờ, Giờ đổi ngày |
| **Quy tắc xu** | Cần bố mẹ duyệt, Con tự chia xu, Các hũ, Trừ xu, Quy đổi tiền thật |
| **Ứng dụng** | Giao diện, Mật khẩu hồ sơ |
| **Thông tin** | Báo lỗi, Phiên bản, Quyền riêng tư, Điều khoản |

Đặt **Khoá lại** tách hẳn dưới cùng, giữ nguyên như hiện tại.

## 11 · 🟠 Thống kê chưa xếp theo ngày

"Sổ của con" hiện đổ **một danh sách phẳng** mọi giao dịch, mới nhất trước
(`watchGroupedHistory`). Đã gộp theo giao dịch — một việc là một dòng, không
phải ba dòng theo hũ — nhưng chưa nhóm theo ngày.

Hệ quả: sau một tuần là vài chục dòng liền mạch, không có mốc để bám. Câu hỏi
tự nhiên nhất của bố mẹ — *"hôm qua con làm được gì?"* — phải cuộn tay mà đếm.

**Đề xuất:** nhóm theo ngày, mỗi ngày **một dòng tóm tắt gập lại** (thứ + ngày,
số việc xong, tổng xu), bấm mới sổ ra chi tiết. Ngày hôm nay mở sẵn. Ngày không
có gì vẫn hiện nhưng ghi "Chưa có hoạt động" — khoảng trống trong chuỗi cũng là
thông tin, và đó chính là cách ChoreReward làm ở màn Statistics.

## 12 · 🟠 Xu chưa chia đang nằm lẫn với các hũ

Trong "Sổ của con", **"Chờ chia" là ô thứ tư nằm cùng hàng** với Tiêu · Để dành
· Cho đi. Code có ghi rõ nó khác (`pending: true`, viền vàng, và có chú thích
giải thích đúng nguy cơ này), nhưng **vị trí vẫn nói ngược lại**: cùng hàng,
cùng cỡ, cùng hình dạng thì mắt đọc nó là hũ thứ tư.

Đây không phải hũ. Đó là số xu **chưa vào hũ nào**, và là một **việc cần làm**.

**Đề xuất:** đưa lên thành **banner riêng phía trên**, chiếm hết chiều ngang,
kèm nút hành động ("Chia ngay") — hàng hũ nằm dưới, chỉ còn đúng những hũ thật.
Hết xu chưa chia thì banner biến mất, hàng hũ trở về ba ô.

Cách này cũng làm màn chia xu (`89`, `90`) nhất quán với sổ: cả hai đều đặt
"còn bao nhiêu chưa chia" ở trên cùng.

## Thứ tự đề nghị cho Phần II

1. **§12** — nhỏ nhất, sửa một chỗ bố trí, và gỡ một hiểu nhầm về tiền của con.
2. **§10** — chia nhóm Cài đặt, làm trước khi Sprint 3 đổ thêm dòng vào.
3. **§11** — nhóm thống kê theo ngày.
4. **§8** rồi **§7** — thu gọn bảng chọn trước, rồi mới thêm icon. Làm ngược
   thứ tự thì biểu mẫu vỡ ngay khi thêm icon.
5. **§9** — làm theo bốn bước nhỏ ở trên, đo lại bằng ảnh chụp sau mỗi bước.

**Ghi cho người làm §9:** đây là mục duy nhất trong sáu mục **không kiểm được
bằng test**. Cách duy nhất biết nó có tác dụng là đưa cho một đứa trẻ thật dùng
và ngồi nhìn. Ràng buộc khả dụng thì test canh được, còn "ngộ nghĩnh" thì không.

---

# Phần III — Vì sao release hỏng (24/08)

**Câu trả lời ngắn: code không biên dịch được.** Release #24 (`v0.2.6`), #25 và
#26 (`v0.2.7`) đều hỏng ở **bước build**, không phải bước đẩy lên store — khác
hẳn nguyên nhân của đợt 22/08.

```
Android · Build App Bundle   ✗   →  các bước đẩy Play: skipped
iOS     · Build IPA          ✗   →  các bước đẩy App Store: skipped
```

## Bốn lỗi biên dịch

Trớ trêu là chúng đến từ chính commit tên **`fix(linter): resolve analyzer
warnings`** (`bdf074e`) — commit nhằm dọn cảnh báo lại làm hỏng bản dựng.

| Chỗ | Lỗi |
|---|---|
| `stats_screen.dart:590, 593, 600` | `_JarCard` dùng `pending` nhưng trường đó **đã bị xoá** khi tách banner (§12). Ba chỗ dùng còn sót |
| `task_card.dart:80` | `unawaited(HapticFeedback...)` nhưng file **thiếu `import 'dart:async'`** |

Dựng lại được ở local trong **19 giây**: `flutter analyze --fatal-infos` ra đúng
bốn lỗi đó, không cần chạy CI.

## Hai test đỏ nữa, và cả hai đang làm đúng việc

- **`kPhienBanApp` = `0.2.6` trong khi pubspec đã `0.2.7+14`.** Đây là **lần thứ
  ba** cùng một drift. Test này tồn tại đúng vì lý do đó: báo cáo lỗi ghi sai
  phiên bản thì mọi kết luận từ nó sai theo.
- **`'run'` (🏃) được thêm vào bộ hình bố mẹ chọn** — vi phạm một quy tắc đã có
  từ lâu: *"Hình người luôn mang theo giới tính và màu da, mà đây là bộ hình
  dùng chung cho mọi bé."*

  Đã gỡ `'run'` khỏi danh sách chọn và ghi lý do ngay cạnh, để lần sau ai định
  thêm lại thì đọc được. Việc vận động vẫn có `'soccer'` ⚽ và `'bike'` 🚲.

  **Chưa đụng tới:** preset `exercise` **vẫn** dùng `iconKey: 'run'`, tức 🏃 vẫn
  hiện trên thẻ việc của bé. Về nguyên tắc đó là cùng một vấn đề, chỉ là chưa
  test nào canh. Đổi hình của preset là quyết định thiết kế, để chủ dự án chốt.

## Điều đáng nói hơn cả bốn lỗi

Tag `v0.2.7` được đẩy lên **trong khi `main` không biên dịch được**. Nghĩa là
chuỗi kiểm trước khi phát hành đã bị bỏ qua — `analyze` mất 19 giây, một vòng
release mất 4–5 phút và tiêu một build number mỗi lần.

Đây là **mục §5 của Phần I quay lại**, ở dạng nặng hơn: lần trước là đẩy code đỏ
lên `main`, lần này là **gắn tag phát hành lên code đỏ**.

Đề nghị lặp lại, và lần này cụ thể hơn: **chốt chặn trước khi tag** — không tag
nếu `flutter analyze --fatal-infos && flutter test` chưa xanh ở local. Mục
"pre-commit hook" trong Sprint 0 vẫn để trống; đây là lần thứ hai nó đáng làm.

## Trạng thái sau bản sửa

`analyze --fatal-infos` sạch · **523 test + 4 integration test xanh** · phiên bản
đồng bộ `0.2.7`. Cần **tag lại** (hoặc chạy tay Release) trên commit đã sửa —
tag `v0.2.7` hiện đang trỏ vào code hỏng.
