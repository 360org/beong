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
