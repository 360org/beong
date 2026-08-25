# 16 — Lộ trình học từ ChoreReward (thiết kế, UX/UI, tính năng)

*Lập ngày 24/08/2026, từ 5 ảnh chụp ChoreReward do chủ dự án gửi.*

Đây **không phải** danh sách chép giao diện. Mỗi mục dưới đây đều đã đối chiếu với
code thật của Bé Ong trước khi ghi, kèm `file:dòng` để người sửa kiểm lại — vì
"app kia có, mình chưa có" nói bằng cảm giác thì một nửa sẽ sai.

Phần cải tiến giao diện nêu trước đó (icon, bảng chọn icon, cài đặt chia mục,
thống kê xếp theo ngày, banner xu chưa chia) nằm ở
`14-audit-tinh-nang-moi.md` §7–§12 — **bốn trong sáu mục đó đã làm xong**, nên
tài liệu này không nhắc lại. Ở đây chỉ có thứ chưa ai ghi.

## Tóm tắt

| # | Việc | Mức | Vì sao đáng làm |
|---|---|---|---|
| 1 | Màn mồi trước khi xin quyền thông báo | 🔴 | Hỏi nguội là mất quyền vĩnh viễn |
| 2 | Trạng thái ghép cặp hiện trên thẻ con | 🔴 | Đóng luôn §1 của docs/14 |
| 3 | Điều khoản / Riêng tư / Liên hệ trong Cài đặt | 🟠 | 2 trong 6 mục App Store đang đòi |
| 4 | Điều hướng tuần `‹ ›` ở Thống kê | 🟠 | Hiện không xem lại được tuần nào |
| 5 | Thẻ tổng đầu màn Thống kê | 🟠 | Số liệu đang nằm rải, không có chỗ đọc nhanh |
| 6 | Phân biệt "đã qua mà trống" với "chưa tới" | 🟡 | Trung thực về thứ chưa xảy ra |
| 7 | Buổi trong ngày cho việc nhà | 🟠 | Làm sống 2 cột chết `start_time`/`due_time` |
| 8 | Điểm bằng nút −/+ | 🟡 | Bàn phím số cho giá trị nhảy bước 5 là ma sát thừa |
| 9 | Nút LƯU dính đáy | 🟡 | Biểu mẫu dài, nút lưu trôi khỏi màn |

*Phần II bổ sung §10–§14 từ đợt ảnh thứ hai, Phần III bổ sung §15–§19 từ đợt thứ ba — bảng riêng ở mỗi phần.*

---

## Nhóm A — Chặn phát hành, hoặc đóng nợ cũ

### 1 · 🔴 Xin quyền thông báo phải có màn mồi trước

**Họ làm gì.** Trước khi hộp thoại của hệ điều hành hiện ra, app dựng một màn
riêng: chuông vàng, tiêu đề *"Don't miss what your kids do"*, ba dòng lợi ích cụ
thể (duyệt việc ngay khi con làm xong; trả lời yêu cầu đổi thưởng trước khi con
hết kiên nhẫn; biết tin mà không cần mở app), nút ALLOW to đùng, và **Skip** nhỏ
ở góc trên.

**Bé Ong đang thế nào.** Không xin quyền, không có màn nào cả.
`push_notification_service.dart:21` ghi chú `/// Khởi tạo và xin quyền thông báo`
nhưng thân hàm chỉ có đúng một dòng `debugPrint`.

**Vì sao phải có màn mồi.** iOS chỉ cho hỏi **một lần**. Người dùng bấm "Không
cho phép" là xong — muốn bật lại phải tự vào Cài đặt hệ thống, mà gần như không
ai làm. Nên hỏi nguội, ngay lúc mở app lần đầu, khi người ta chưa hiểu app này
để làm gì, là tự tay ném mất kênh thông báo vĩnh viễn. Màn mồi không xin gì cả —
nó chỉ giải thích; ai bấm "Để sau" thì lần sau hỏi lại được, vì hộp thoại thật
chưa hề bung ra.

**Làm gì.**
- Màn mồi riêng, hiện **sau** khi đã khai xong gia đình và con — lúc đó ba dòng
  lợi ích mới có nghĩa, vì người dùng đã biết "con" và "việc" là gì.
- Ba dòng lợi ích viết theo **việc người dùng sẽ nhận được**, không phải theo
  tính năng: "Con làm xong việc là bố mẹ biết ngay" chứ không phải "Bật push".
- "Để sau" phải là lối thoát thật, không phải nút mờ cho có.
- Chỉ khi bấm đồng ý mới gọi tới hộp thoại hệ thống.

**Kiểm chứng.** Integration test: đi hết onboarding, khẳng định màn mồi hiện ra
và **chưa** có lời gọi xin quyền nào; bấm "Để sau" thì không gọi; bấm đồng ý thì
gọi đúng một lần.

### 2 · 🔴 Thẻ con phải nói thật nó đã ghép cặp hay chưa

**Họ làm gì.** Thẻ con ở đầu màn Cài đặt: avatar, tên *Simba*, ngay dưới tên là
**⚠ Not connected** màu đỏ, bên phải là hai nút — **Pair** (vàng) và **Delete**
(đỏ nhạt). Một thẻ, trả lời gọn ba câu: đây là ai, máy con đã nối chưa, làm gì
tiếp.

**Bé Ong đang thế nào.** `settings_screen.dart:349` chỉ có một nút biểu tượng
với tooltip `'Ghép cặp máy'`. Không có chỗ nào cho biết đã ghép hay chưa.

**Vì sao 🔴.** Đây chính là §1 của `14-audit-tinh-nang-moi.md` nhìn từ hướng
khác: luồng QR hiện hứa một chuyện chưa xảy ra. Hiện trạng thái thật ngay trên
thẻ con là cách sửa rẻ nhất — không cần backend chạy xong mới làm được, vì
"Chưa kết nối" là câu trả lời **đúng** cho tình trạng hiện tại.

**Làm gì.** Suy trạng thái từ dữ liệu thật (có `device_id` đã ghép hay chưa),
không vẽ cứng — đúng bài học ổ khoá PIN vẽ cứng ở `13-audit-luong-vao-app.md`.
Ba trạng thái: *Chưa kết nối* · *Đang chờ máy con quét* · *Đã kết nối · <tên máy>*.

**Điểm không lấy theo họ.** Họ đặt **Delete** đỏ ngay cạnh **Pair**, hai nút sát
nhau trên cùng một thẻ, mà một cái là xoá hồ sơ con. Bé Ong giữ đường xoá nằm
trong bảng sửa hồ sơ kèm bước xác nhận, không đôn lên cạnh nút dùng hằng ngày.

### 3 · 🟠 Mục "Thông tin" phải có Điều khoản, Chính sách riêng tư, Liên hệ

**Họ làm gì.** Nhóm INFORMATION ba dòng: Terms & Conditions · Privacy Policy ·
Contact Us (kèm địa chỉ hỗ trợ ngay dưới nhãn).

**Bé Ong đang thế nào.** Cài đặt đã chia mục rồi (`_SettingsSection`, ba nhóm:
Gia đình · Quy tắc xu · Thông tin), nhưng nhóm Thông tin chưa có ba dòng này.

**Vì sao gấp hơn vẻ ngoài của nó.** `15-audit-toan-repo.md` liệt kê sáu mục App
Store đang đòi trước khi cho nộp duyệt — **hai** trong số đó là
`privacyPolicyUrl` và `privacyPolicyText`. Nội dung đã có sẵn ở
`10-privacy-policy.md`; việc còn lại là đưa nó lên `beong.net` và trỏ từ trong
app ra. Làm mục này là gỡ luôn một phần chặn phát hành, không chỉ là thêm ba
dòng cho đẹp.

**Không lấy.** Dòng **Subscription / Upgrade to Premium** của họ. ADR-014 chốt
v1 miễn phí hoàn toàn; dựng chỗ ngồi cho gói trả phí bây giờ là dựng thứ chưa ai
dùng — đúng loại code chết dự án đã dọn nhiều lần. Dòng **Profile kèm email**
cũng vậy: Bé Ong chạy local-first, chưa có tài khoản email nào để hiện.

---

## Nhóm B — Màn Thống kê

Ba mục dưới đây nên làm **một lượt**, vì cùng đụng vào phần đầu của
`stats_screen.dart`.

### 4 · 🟠 Điều hướng tuần `‹ ›`

**Họ làm gì.** Tiêu đề "Statistics", dòng phụ "This week", và cặp mũi tên `‹ ›`
bên phải. Mũi tên phải **mờ đi** khi đang ở tuần hiện tại — không bấm được, và
nhìn là biết vì sao.

**Bé Ong đang thế nào.** Không có điều hướng kỳ nào. Thống kê chỉ hiện những gì
đang có, không xem lại được tuần trước.

**Vì sao đáng làm.** Bố mẹ hỏi "tháng này con khá hơn tháng trước không?" thì
phải so được. Mà chuỗi ngày (`Streak`) và huy hiệu chỉ có nghĩa khi nhìn được
quá trình — dữ liệu đã lưu đủ rồi, chỉ thiếu đường xem.

### 5 · 🟠 Thẻ tổng ở đầu màn

**Họ làm gì.** Một thẻ tím lớn: số việc đã xong dạng **X/Y** cỡ chữ to nhất màn,
thanh tiến độ dưới đó, rồi hai ô nhỏ chia đôi — 💎 điểm và 🎁 phần thưởng.

**Đáng học ở chỗ.** Một màn thống kê có ba câu hỏi người ta hỏi trước tiên: làm
được bao nhiêu, được bao nhiêu xu, đổi được gì. Thẻ này trả lời cả ba trước khi
người dùng phải cuộn. Bé Ong đang để các số đó rải trong các thẻ riêng.

**Lưu ý khả dụng.** Chữ trắng trên nền tím của họ chỉ vừa đủ tương phản. Bé Ong
có ngưỡng 4.5:1 và có cách đo — dựng xong phải đo, không ước lượng bằng mắt
(xem `flutter-8-buoc` Bước 2).

### 6 · 🟡 "Đã qua mà trống" khác "chưa tới"

**Chi tiết chỉ lộ ra khi so hai ảnh.** Ở tuần đã qua, **mọi** ngày ghi rõ
*"No activity"*. Ở tuần đang chạy, Thứ Hai ghi *"No activity"*, còn Thứ Ba tới
Chủ Nhật chỉ là **thanh xám trơ, không chữ**.

Khác biệt nhỏ mà đúng: ngày chưa tới thì chưa có gì để nói. Ghi "Không có hoạt
động" cho ngày mai là nói sai về một chuyện chưa xảy ra — và với app mà cả nhà
nhìn vào để đánh giá con, nói sai kiểu đó không vô hại.

---

## Nhóm C — Trình sửa việc

### 7 · 🟠 Buổi trong ngày (Sáng · Chiều · Tối), tuỳ chọn

**Họ làm gì.** Khối *TIME OF THE DAY (OPTIONAL)* — ba chip, được phép không
chọn cái nào, và nhãn nói thẳng là tuỳ chọn.

**Bé Ong đang thế nào.** Trình sửa việc có tám khối (Chọn nhanh · Điểm · Chọn
hình · Lặp lại · Giao cho · Cần bố mẹ duyệt · Yêu cầu bằng chứng · Bỏ việc thì
trừ) — không có buổi.

**Vì sao mục này đáng hơn vẻ ngoài.** `15-audit-toan-repo.md` §6 đã ghi
`start_time` và `due_time` là **cột chết**: có trong lược đồ, không ai đọc, không
ai ghi. Có đúng hai đường đi — dùng, hoặc xoá. Mục này là đường "dùng", và dùng
theo cách vừa với người dùng thật: bố mẹ nghĩ theo *buổi* ("đánh răng buổi tối"),
không nghĩ theo *giờ phút* ("20:30"). Một bộ ba chip đọc/ghi hai cột đó là đủ.

Nếu chốt không làm, thì phải xoá hai cột — để nguyên là giữ lại lời hứa suông
trong lược đồ, đúng loại lỗi lặp lại đã đếm được **mười** lần trong dự án này.

### 8 · 🟡 Điểm bằng nút −/+

**Họ làm gì.** `− 💎 25 +`, hai nút tròn to hai bên. Cạnh nhãn POINTS có một
chấm `(i)` mở phần giải thích điểm dùng để làm gì.

**Bé Ong đang thế nào.** `tasks_screen.dart:611` — một `TextField` với
`hintText: 'Điểm'`.

**Vì sao đổi.** Giá trị này gần như luôn nhảy theo bước 5 hoặc 10. Bật bàn phím
số lên để gõ "25" rồi phải tự tắt bàn phím đi là ba thao tác cho một việc đáng
lẽ một chạm. Giữ luôn đường gõ tay cho ai muốn số lẻ, nhưng đừng bắt mọi người
đi đường đó.

### 9 · 🟡 Nút LƯU dính đáy màn

**Họ làm gì.** Nút SAVE nằm cố định sát đáy, nội dung cuộn **phía dưới** nó.

**Bé Ong đang thế nào.** `tasks_screen.dart:748` — nút LƯU nằm cuối luồng cuộn.
Biểu mẫu tám khối thì nút lưu trôi khỏi tầm nhìn gần như suốt thời gian sửa.

---

## Thứ tự đề nghị

1. **§1 và §2** — cả hai đều 🔴, và cả hai đóng nợ đã ghi ở tài liệu khác
   (FCM chưa nối, ghép cặp nói dối). §1 nên làm **cùng lúc** với việc nối FCM
   thật, vì màn mồi mà không có thông báo đằng sau cũng là một lời hứa suông nữa.
2. **§3** — rẻ, và gỡ hai trong sáu mục App Store đang chặn.
3. **§4 + §5 + §6** — một lượt, cùng chạm phần đầu `stats_screen.dart`.
4. **§7** — kèm quyết định dứt khoát về `start_time`/`due_time`: dùng hoặc xoá.
5. **§8 + §9** — một lượt, cùng chạm biểu mẫu sửa việc.

## Ghi chú cho người sửa

- Mỗi mục phải trả lời được hai câu ở cuối `15-audit-toan-repo.md`: **ai gọi
  hàm này**, và **người dùng bật nó lên thì cái gì đổi**. Không trả lời được thì
  chưa xong, dù analyze sạch và test xanh.
- Ảnh chụp là **bắt buộc** cho mọi mục ở đây — cả chín mục đều là chuyện giao
  diện, mà giao diện thì test không nhìn thấy. Quy trình chụp ở
  `.claude/skills/flutter-8-buoc` Bước 6.
- Mọi chuỗi hiển thị phải nằm trong ARB, tiếng Việt.
- Ba mục 🟡 đừng gộp chung một commit với ba mục 🔴/🟠 — trộn vào là lúc cần lùi
  một cái phải lùi cả cụm.

---

# Phần II — 5 ảnh chụp đợt hai (24/08/2026)

Năm ảnh sau cho thấy những màn có **dữ liệu thật**, không phải màn rỗng — nên
lộ ra thứ đợt một không thấy. Cũng như Phần I: mỗi mục đối chiếu code trước khi
ghi.

| # | Việc | Mức | Vì sao đáng làm |
|---|---|---|---|
| 10 | Ảnh bằng chứng hiện ngay trên thẻ chờ duyệt, kèm Từ chối / Duyệt | 🔴 | Cho §1 của docs/15 một chỗ để đáp xuống |
| 11 | "Điều ước" — con tự đề xuất phần thưởng | 🟠 | Đảo chiều người đặt mục tiêu |
| 12 | Huy hiệu chia nhóm, và nhiều hơn 9 cái | 🟠 | Bảng huy hiệu hiện quá thưa để thành động lực |
| 13 | "Hành trình" — một chỗ nhìn thấy đích dài hạn | 🟡 | Mục tiêu đang là thanh tiến độ lẫn trong danh sách |
| 14 | Thanh điều hướng khác nhau theo vai | 🟡 | Con không bao giờ cần thứ dành cho bố mẹ |

## 10 · 🔴 Thẻ chờ duyệt phải hiện ảnh, và duyệt/từ chối được từng cái

**Họ làm gì.** Mỗi mục chờ duyệt là một thẻ đầy đủ: hình việc, chip **TASK**,
**💎 +10**, giờ nộp (07:07), tên việc, **ảnh con chụp hiện nguyên khổ ngay trong
thẻ**, rồi hai nút cuối thẻ — **✕ Reject** (đỏ nhạt) và **✓ Approve** (xanh
nhạt).

**Bé Ong đang thế nào.** `parent_home_screen.dart` có hàng chờ duyệt thật, có
đếm số, có **Duyệt tất cả**. Nhưng trong cả file **không có một chỗ nào** dựng
ảnh — không `Image`, không `proof`. Và không có nút từ chối cho từng mục; chỉ có
`_reopen` mở lại việc.

**Vì sao 🔴, và vì sao nó quan trọng hơn vẻ ngoài.** `15-audit-toan-repo.md` §1
đã ghi: nút "Chụp ảnh" không chụp gì, `proof_url` không bao giờ được ghi, và
hàng chờ duyệt không hiện gì. Ba mảnh của **cùng một** tính năng dở dang. Ảnh
này cho thấy mảnh thứ ba phải trông thế nào — và quan trọng hơn: **làm ảnh chụp
mà không có chỗ này thì vô nghĩa**. Bố mẹ chụp xong ảnh đi đâu? Nếu không ai
nhìn thấy nó, thì "yêu cầu bằng chứng" chỉ là bắt con thao tác thêm một bước
không dẫn tới đâu.

**Làm gì.** Làm **cả cụm** trong một đợt, đúng thứ tự: ghi được ảnh → hiện được
ảnh → duyệt/từ chối theo ảnh. Nút **Duyệt tất cả** giữ nguyên, nhưng khi có ảnh
thì nó thành thứ mâu thuẫn — duyệt hàng loạt tức là không xem ảnh nào cả. Cân
nhắc: có ảnh thì tách khỏi luồng "duyệt hết", hoặc hỏi lại rõ ràng.

**Từ chối cần một câu.** Họ bấm Reject là xong. Với trẻ con thì bị từ chối mà
không biết vì sao là chuyện tổn thương thật — nên kèm một dòng lý do ngắn (chọn
nhanh hoặc gõ), và con phải đọc được nó.

## 11 · 🟠 "Điều ước" — con tự đề xuất phần thưởng

**Họ làm gì.** Màn *New wish* cho con: **WHAT DO YOU WANT?** (ô chữ, gợi ý
"e.g. New bike") · **ADDITIONAL INFO** (mô tả, đường dẫn) · **HOW MANY POINTS?**
(nút −/+) · nút **SEND TO PARENT** nằm đáy, **mờ và không bấm được** cho tới khi
điền đủ.

**Bé Ong đang thế nào.** Không có khái niệm này. Tìm khắp `lib/` không ra chỗ
nào cho con đề xuất phần thưởng — mọi phần thưởng đều do bố mẹ tạo.

**Vì sao đáng làm.** Nó đảo chiều người đặt mục tiêu. Một danh sách phần thưởng
do bố mẹ viết hết là danh sách **những gì bố mẹ nghĩ con muốn** — mà hai thứ đó
lệch nhau nhiều hơn người lớn tưởng. Cho con nói ra điều mình muốn là cách rẻ
nhất để phần thưởng thật sự có sức kéo. Nó cũng nối thẳng vào mục tiêu tiết
kiệm đã có (`features/goals/`): điều ước được duyệt thì thành đích để dành.

**Ràng buộc phải giữ.** **Giá vẫn là quyết định của bố mẹ.** Nếu con vừa đặt
điều ước vừa tự định giá thì cái xe đạp sẽ có giá 5 xu. Ô "bao nhiêu điểm" của
con nên đọc là **đề nghị**, và bố mẹ chốt lại khi duyệt.

**Chi tiết nhỏ đáng lấy.** Nút gửi mờ cho tới khi hợp lệ — hứa đúng thứ làm được,
thay vì cho bấm rồi mới báo lỗi.

## 12 · 🟠 Huy hiệu: chia nhóm, và nhiều hơn 9 cái

**Họ làm gì.** Bảng huy hiệu chia nhóm có tiêu đề — **PHOTOS** (Say Cheese ·
Photographer · Proof Pro), **WISHES** (sáu cái), **SPECIAL** (Perfect Day · Goal
Getter) — và còn nhóm nữa ở trên (First Treat · Big Spender · Dream Chaser). Cái
chưa đạt hiện dạng huy hiệu xám có dấu **?**, **nhưng vẫn ghi rõ tên**.

**Bé Ong đang thế nào.**
- Hiện huy hiệu chưa đạt: **đã làm rồi** — `badges_screen.dart:116` mờ đi
  `opacity: 0.35`, vẫn ghi tên và điều kiện. Phần này không cần đụng.
- Chia nhóm: **chưa có**. `BadgeDef` không có trường nhóm nào
  (`badge_def.dart:6–12`), màn hình đổ ra một danh sách phẳng.
- Số lượng: **9 huy hiệu**, tất cả. Riêng ba nhóm nhìn thấy trong một ảnh của họ
  đã hơn con số đó.

**Làm gì.** Thêm trường nhóm vào `BadgeDef` và chia theo **tính năng của Bé
Ong**, không chép nhóm của họ: việc nhà · xu & hũ · chuỗi ngày · mục tiêu. Rồi
mới thêm huy hiệu cho đủ mỗi nhóm có ba bậc — một nhóm chỉ có một huy hiệu thì
chia nhóm còn rối hơn để phẳng.

**Cảnh báo.** `key` của huy hiệu đi thẳng vào `badges_earned.badge_key`, và
`badge_def.dart` đã ghi sẵn: đổi khoá là **mất huy hiệu đã trao**. Thêm thì
thoải mái, đổi thì không.

## 13 · 🟡 "Hành trình" — một chỗ nhìn thấy đích dài hạn

**Họ làm gì.** Cả một tab riêng: núi tuyết, khinh khí cầu bay lên từ trong mây,
các mốc là vòng tròn trắng gắn trên sườn núi (túi tiền gần đỉnh, điện thoại thấp
hơn), số xu ở góc trái. Không có chữ nào. Khinh khí cầu lên cao dần theo số xu.

**Bé Ong đang thế nào.** Mục tiêu tiết kiệm **đã chạy thật** — `GoalSection`
được dùng ở cả `child_home_screen.dart:244` và `stats_screen.dart:194,272`.
Nhưng nó là **thanh tiến độ nằm lẫn trong danh sách**, cùng cỡ với mọi thứ khác
trên màn.

**Cái đáng học không phải quả núi.** Là chuyện: đích dài hạn cần **một chỗ riêng
và một hình ảnh**, vì với trẻ con thì "còn 340 xu nữa" là con số trừu tượng, còn
"cái khinh khí cầu đã lên tới đây" thì không.

**Đừng làm bản đắt trước.** Tranh minh hoạ nhiều lớp là thứ tốn tiền và dễ sai
gu. Bản rẻ làm trước: một màn, dùng đúng dữ liệu mục tiêu đã có, một đường dọc
với các mốc và một dấu chỉ vị trí hiện tại. Đẹp hơn thì thay tranh sau — dữ liệu
không đổi.

## 14 · 🟡 Thanh điều hướng nên khác nhau theo vai

**Họ làm gì.** Máy bố mẹ: Activity · Tasks · Rewards · Stats. Máy con: Tasks ·
Rewards · **Awards** · **Journey**. Bốn tab mỗi bên, **không phải cùng bốn tab**.

**Bé Ong đang thế nào.** Một bộ 5 tab dùng chung (`router.dart:249–277`), Cài
đặt bị chặn cho vai con bằng redirect ở router.

**Đáng nghĩ lại.** Chặn bằng redirect là đúng về an toàn, nhưng con vẫn phải
nhìn thấy tab rồi bị đá ra. Và ngược lại: huy hiệu với hành trình là thứ **của
con**, mà đang nằm chung chỗ với thống kê của bố mẹ. Việc này nên làm **sau**
§12 và §13 — lúc đó mới biết con thật sự cần mấy tab.

## Bổ sung cho §5 — dòng ngày trong Thống kê

Ảnh có dữ liệu cho thấy một dòng ngày gồm ba thứ: thanh tiến độ vàng, **2/3**
bên phải, và chip **💎 +35** xuống dòng dưới. Ngày trống thì chỉ có chữ "No
activity", không có thanh — tức là ba mức hiển thị khác nhau cho ba tình trạng
(có hoạt động · đã qua mà trống · chưa tới), đúng mạch §6.

## Không lấy — banner "Get Premium" trên Trang chính

Họ chèn một banner cam to đùng ngay giữa thẻ Dashboard và hàng việc chờ duyệt,
đẩy **đúng phần việc phải làm** xuống dưới. Bé Ong miễn phí hoàn toàn ở v1
(ADR-014) nên chuyện này không đặt ra — nhưng ghi lại làm mốc: chỗ ngay dưới
thẻ tổng là chỗ đắt nhất màn hình, đừng để thứ gì không phải việc cần làm chiếm
nó.

## Thứ tự đề nghị cho Phần II

1. **§10** — 🔴, và làm trọn cụm ảnh bằng chứng (ghi → hiện → duyệt/từ chối).
   Đừng làm nửa cụm: nửa cụm thì vẫn là tính năng nói dối, chỉ dối chỗ khác.
2. **§12** — rẻ, và làm ngay được vì huy hiệu đã có sẵn máy móc trao/hiện.
3. **§11** — tính năng mới, cần bàn kỹ chuyện ai chốt giá trước khi viết code.
4. **§13**, rồi **§14** — cả hai đều cần §12 xong mới cân được.

---

# Phần III — Đợt ảnh thứ ba (24/08/2026)

Đợt này là các màn của **vai con**, có dữ liệu và có cả khoảnh khắc ăn mừng —
thứ hai đợt trước chưa thấy.

| # | Việc | Mức | Vì sao đáng làm |
|---|---|---|---|
| 15 | Vòng cung tiến độ trên huy hiệu chưa đạt | 🟠 | Biết còn bao xa mới là động lực; biết mình chưa có thì không |
| 16 | Nút Đổi mờ đi khi chưa đủ xu | 🟠 | Nói trước, đừng để bấm xong mới báo hỏng |
| 17 | Chọn mục tiêu **từ danh sách phần thưởng** | 🟠 | Nối phần thưởng với Hành trình bằng một cơ chế, không phải hai màn rời |
| 18 | Ăn mừng huy hiệu bằng một màn, không phải SnackBar | 🟡 | Thứ trôi mất sau 4 giây thì không phải phần thưởng |
| 19 | Cho linh vật nói một câu | 🟡 | Linh vật đã có sẵn, chỉ thiếu tiếng nói |

## Đính chính cho §11 — ô "Con muốn gì" đã có, nhưng con không mở được

Phần II ghi "Bé Ong không có khái niệm điều ước". Chính xác hơn — và tệ hơn:
`goal_sheet.dart:137` có sẵn ô nhãn **"Con muốn gì"**, gợi ý *"Ví dụ: Bộ Lego
cảnh sát"*, ngay cạnh ô "Cần bao nhiêu xu".

Nhưng `showGoalSheet` chỉ được gọi từ **một** chỗ: `stats_screen.dart:135`,
trong `_ChildStatsCard` — tức thẻ của **bố mẹ** xem từng con. Con nhìn thấy
`GoalSection` trên trang chính của mình nhưng **không có đường nào mở bảng đó**.

Nói cách khác: app đang hỏi "Con muốn gì" rồi bắt bố mẹ trả lời hộ. §11 vì thế
không phải thêm tính năng mới từ đầu — phần lớn máy móc đã có, thiếu đúng cái
đường cho con nói và đường gửi cho bố mẹ duyệt.

## 15 · 🟠 Vòng cung tiến độ trên huy hiệu chưa đạt

**Họ làm gì.** Huy hiệu chưa đạt là vòng tròn xám dấu **?**, nhưng viền ngoài có
một **cung tròn tím** vẽ đúng phần trăm đã đi được — cái sắp đạt thì cung gần
khép kín, cái mới bắt đầu chỉ là một vạch ngắn. Trên đầu màn: **"Đã có 4 trên
29"** kèm huy chương lớn và hoa giấy.

Nhóm MY CHORES của họ xếp **theo bậc ba**: First Step → Helper → Chore Champion;
Spark → On Fire → Unstoppable; On Time → Schedule Keeper → Timing Master.

**Bé Ong đang thế nào.**
- Câu tổng: **đã có** — `badges_screen.dart:78` ghi "Con đã có X trên Y huy hiệu".
- Huy hiệu chưa đạt mờ đi kèm tên và điều kiện: **đã có**.
- Vòng cung tiến độ: **chưa có**.
- Số lượng: **9**, so với 29 của họ.

**Vì sao cung tròn quan trọng hơn nó trông.** "Con chưa có huy hiệu Chăm chỉ"
là một câu đóng — không nói được nên làm gì tiếp. "Con đã đi được hai phần ba
chặng" là một câu mở. Với trẻ con thì khoảng cách nhìn thấy được mới kéo được,
còn một danh sách những thứ mình không có thì chỉ làm nản.

**Làm gì.** Mục này chồng lên §12 — làm **một lượt**: thêm trường nhóm, xếp theo
bậc ba, rồi vẽ cung tiến độ. Điều kiện đạt đã là con số ngưỡng
(`BadgeDef.threshold`), nên phần trăm tính được ngay, không cần dữ liệu mới.

## 16 · 🟠 Nút Đổi phải mờ đi khi chưa đủ xu

**Họ làm gì.** Hai thẻ phần thưởng, con có 55 xu: *Screen time* giá 50 — nút
**Claim** tím đậm, bấm được. *Pocket money* giá 100 — nút Claim **mờ hẳn**,
không bấm được. Nhìn một cái là biết cái nào với tới được.

**Bé Ong đang thế nào.** `rewards_screen.dart:350` — `FilledButton.tonal` với
`onPressed: _redeem`, **luôn bấm được**. Không đủ xu thì service ném lỗi và màn
hình hiện SnackBar báo hỏng.

**Vì sao đổi.** Đây là nói sau thay vì nói trước. Con bấm vào thứ mình tưởng
lấy được, rồi bị từ chối — với trẻ nhỏ thì đó là một cú hụt không cần thiết, và
lặp lại mỗi lần con nhìn vào danh sách.

**Đừng chỉ làm mờ.** Một nút xám không lý do là cái bẫy khác: con không biết vì
sao. Thay nhãn thành **"Còn thiếu 45 xu"** — vừa nói được tình trạng, vừa nói
được còn bao xa, và vẫn giữ đúng nguyên tắc không dùng mỗi màu làm kênh thông tin.

## 17 · 🟠 Mục tiêu chọn **từ danh sách phần thưởng đã có**

**Họ làm gì.** Trên trang Phần thưởng của con có một nút viền **"Chọn mục
tiêu"** đặt ngay dưới thẻ tổng. Bấm vào mở bảng trượt *"Đặt mục tiêu và theo dõi
tiến độ"*, liệt kê **chính các phần thưởng đang có** để chọn (Pocket money —
Mục tiêu: 100 xu). Nút xác nhận mờ cho tới khi chọn xong.

**Đây là mắt xích em bỏ sót ở §13.** Nó trả lời câu "các mốc trên núi ở đâu ra":
mốc **chính là phần thưởng**. Không phải hai hệ thống rời nhau — một hệ thống,
nhìn từ hai chỗ.

**Bé Ong đang thế nào.** Mục tiêu là ô chữ tự do, không liên quan gì tới danh
sách phần thưởng. Nên một nhà có thể có "Bộ Lego cảnh sát" ở mục tiêu và "Bộ
Lego" ở phần thưởng — hai bản ghi cho cùng một thứ, hai lần phải sửa.

**Làm gì.** Cho chọn từ danh sách phần thưởng làm đường chính, giữ ô tự do làm
đường phụ (con muốn thứ chưa có trong danh sách — và đó chính là §11). Thêm nút
"Chọn mục tiêu" hiện rõ khi chưa đặt mục tiêu nào.

## 18 · 🟡 Ăn mừng huy hiệu bằng một màn, không phải SnackBar

**Họ làm gì.** Huy hiệu mới nổ ra thành một hộp giữa màn: hoa giấy, hình huy
hiệu lớn, chip **HUY HIỆU MỚI**, tên, một câu mô tả điều kiện, **chấm phân
trang** khi nhận nhiều cái một lúc, và một nút to để đóng.

**Bé Ong đang thế nào — và chỗ này đã nghĩ đúng một nửa rồi.**
`child_home_screen.dart:112` có sẵn ghi chú: *"Nổ hoa giấy **và** hiện tên huy
hiệu: hoa giấy một mình thì con tưởng là hiệu ứng của việc vừa bấm, không biết
mình vừa đạt được thứ gì."* Cách giải hiện tại là hoa giấy + SnackBar có nút XEM.

**Vì sao đi tiếp một bước.** SnackBar trôi mất sau bốn giây và nằm ở mép dưới
màn — đúng chỗ ngón tay vừa rời khỏi. Một thứ con phải *kịp đọc* thì không phải
phần thưởng. Huy hiệu là đỉnh của cả vòng động lực; nó xứng đáng chiếm màn hình
một lúc.

**Giữ nguyên một ràng buộc đã có.** `celebrateOnTap` tắt với tuổi teen — hoa
giấy với bé 14 tuổi là rườm rà. Màn ăn mừng phải theo đúng quy tắc đó, không
làm ngoại lệ.

## 19 · 🟡 Cho linh vật nói một câu

**Họ làm gì.** Ở màn Hành trình, linh vật đứng góc dưới trái với bong bóng
thoại: *"Cuộc sống như leo núi. Có lúc vất vả, nhưng đáng lắm! Làm xong việc mỗi
ngày để leo dần tới mục tiêu của con."* Đóng được bằng dấu ✕.

**Bé Ong đang thế nào.** Linh vật **đã có sẵn và đã có cảm xúc**: `BeeMascot`
với `BeeMood`, dùng ở ba chỗ — trang chính của con (`BeeMood.fromProgress`, tức
tâm trạng đổi theo tiến độ), màn vào app, và onboarding. Thiếu đúng một thứ:
**tiếng nói**.

**Vì sao rẻ mà đáng.** Toàn bộ phần khó — hình, cảm xúc, chỗ đặt — đã xong. Thêm
một bong bóng thoại là việc nhỏ, mà nó biến con ong từ hình trang trí thành nhân
vật có mặt cùng con.

**Hai ràng buộc.** Câu nói phải **đổi theo tình trạng thật** (chưa có mục tiêu ·
sắp tới đích · vừa hụt chuỗi ngày) — lặp một câu mãi thì lần thứ ba đã thành
nhiễu. Và phải **đóng được**, đóng rồi thì đừng hiện lại ngay trong ngày.

## Thứ tự đề nghị cho Phần III

1. **§15 gộp vào §12** — cùng một màn, cùng một cấu trúc dữ liệu. Đừng làm hai lượt.
2. **§16** — nhỏ nhất trong cả tài liệu, và sửa được một cú hụt lặp đi lặp lại.
3. **§17 trước §13** — biết mốc lấy từ đâu rồi mới dựng được màn Hành trình.
   Cũng nên làm **cùng đợt với §11**, vì hai mục dùng chung một bảng.
4. **§18**, rồi **§19** — cả hai là phần thưởng cảm xúc, làm sau khi phần cơ chế đứng vững.
