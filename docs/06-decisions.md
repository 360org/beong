# 06 — Các quyết định kiến trúc (ADR)

Mỗi mục ghi: bối cảnh → quyết định → hệ quả. Ghi lại để sau này không tranh luận lại từ đầu.

---

## ADR-001: Flutter cho cả mobile và desktop
**Bối cảnh:** cần iOS, Android và app desktop cho phụ huynh.
**Quyết định:** một codebase Flutter, không tách native.
**Hệ quả:** (+) chi phí thấp nhất, UI đồng nhất. (−) desktop Flutter còn thô ở menu bar,
file picker, cập nhật tự động → chấp nhận, giải quyết bằng plugin khi cần.
**Đã cân nhắc:** React Native (desktop yếu), Kotlin Multiplatform + Compose (iOS chưa chín),
native riêng từng nền tảng (gấp 3 chi phí).

---

## ADR-002: Offline-first, local là nguồn sự thật khi chạy
**Bối cảnh:** trẻ dùng app ở nhà, trên xe, chỗ sóng yếu. Mọi độ trễ đều phá vỡ cảm giác thưởng.
**Quyết định:** ghi Drift trước, UI đọc từ Drift, SyncEngine đẩy/kéo nền.
**Hệ quả:** (+) app luôn tức thì, dùng được offline. (−) phải tự xử lý xung đột, phức tạp hơn
đáng kể so với gọi API trực tiếp. Chi phí này nằm ở sprint backend & sync, mà theo ADR-021 sprint
đó đã đôn lên trước phần thưởng.

---

## ADR-003: Riverpod thay vì BLoC
**Quyết định:** Riverpod 3 + codegen.
**Lý do:** ít boilerplate hơn BLoC cho app cỡ này; provider tổ hợp tốt cho dữ liệu dẫn xuất
(số dư, tiến độ hôm nay); test không cần widget tree; không phụ thuộc `BuildContext` — hợp
với background sync.
**Hệ quả:** dev quen BLoC cần thời gian làm quen; đổi lại code ngắn hơn rõ rệt.

---

## ADR-004: Supabase thay vì Firebase
**Quyết định:** Supabase (Postgres + RLS + Auth + Realtime + Storage).
**Lý do:** mô hình dữ liệu quan hệ (ledger, instance, quan hệ nhiều-nhiều) hợp Postgres hơn
Firestore; RLS theo `family_id` đủ để cách ly dữ liệu mà không cần server code; truy vấn thống kê
làm bằng SQL; **self-host được** — quan trọng nếu yêu cầu pháp lý về dữ liệu trẻ em siết lại.
**Hệ quả:** (−) hệ sinh thái Flutter của Firebase trưởng thành hơn; vẫn dùng FCM riêng cho push.

---

## ADR-005: Điểm là sổ cái append-only, không phải một con số
**Bối cảnh:** nhiều thiết bị, offline, có duyệt/từ chối/hoàn điểm.
**Quyết định:** mọi thay đổi điểm là một dòng `point_transactions`. Số dư = SUM. `balance_cache`
chỉ để hiển thị nhanh.
**Hệ quả:** (+) không mất/nhân đôi điểm khi sync, có lịch sử đầy đủ để giải thích với trẻ,
xung đột biến mất vì chỉ có thêm dòng. (−) tốn dòng dữ liệu, cần đối soát cache định kỳ.

---

## ADR-006: Trẻ không có tài khoản đăng nhập
**Quyết định:** trẻ là `member` trong gia đình, không phải auth user; vào bằng chọn hồ sơ + PIN.
**Lý do:** giảm mạnh nghĩa vụ COPPA/GDPR-K (không thu thập email/PII của trẻ), onboarding
nhanh hơn nhiều, hợp thực tế thiết bị dùng chung.
**Hệ quả:** trẻ ở thiết bị riêng vẫn cần thiết bị được phụ huynh ghép cặp một lần bằng mã mời.

---

## ADR-007: `points_snapshot` trên instance
**Quyết định:** chốt điểm tại thời điểm sinh instance, không tra ngược `tasks.points`.
**Lý do:** phụ huynh đổi giá task không được làm thay đổi lịch sử đã hoàn thành — trẻ sẽ thấy bất công.
**Hệ quả:** đổi giá chỉ áp dụng cho instance sinh sau đó; cần nói rõ trong UI ("áp dụng từ ngày mai").

---

## ADR-008: Ngày bắt đầu lúc 4h sáng theo múi giờ gia đình
**Bối cảnh:** trẻ làm việc lúc 23h30 mà tính sang ngày mới thì hỏng streak; gia đình có thể ở
múi giờ khác server.
**Quyết định:** `families.timezone` + `day_rollover_hour` (mặc định 4). Mọi phép tính "hôm nay"
đi qua một hàm duy nhất `familyToday()`.
**Hệ quả:** không được dùng `DateTime.now().day` ở bất kỳ đâu — lint/review chặn.

---

## ADR-009: Mặc định cần phụ huynh duyệt
**Quyết định:** `approval_mode = manual` là mặc định khi tạo task; phụ huynh có thể chuyển `auto`.
**Lý do:** chống gian lận, giữ vai trò của phụ huynh trong vòng lặp động lực.
**Hệ quả:** phụ huynh quên duyệt sẽ chặn phần thưởng → bù bằng nhắc nhở cuối ngày + "Duyệt tất cả".
Xem lại chỉ số này sau beta; nếu tỷ lệ duyệt trễ cao, cân nhắc auto cho task ≤ 10 điểm.

---

## ADR-010: Không quảng cáo, không analytics bên thứ ba
**Quyết định:** không tích hợp SDK quảng cáo/attribution. Analytics (nếu có) là PostHog self-host,
opt-in, không log nội dung do người dùng nhập.
**Lý do:** đối tượng là trẻ em; đây cũng là điểm khác biệt marketing so với đối thủ.
**Hệ quả:** doanh thu không thể đến từ quảng cáo. Ở v1 thì không có doanh thu nào cả — xem ADR-014.

---

## ADR-011: Routine là thực thể bậc nhất, không phải nhãn dán lên task
**Bối cảnh:** ChoreReward bán "routines" (morning/bedtime routine) như luồng cốt lõi. Có thể làm
rẻ tiền bằng cách thêm trường `tag` vào task và nhóm khi hiển thị.
**Quyết định:** `routines` là bảng riêng, sở hữu lịch lặp và danh sách người được gán;
task con kế thừa, không tự đặt lịch.
**Lý do:** cái mang lại giá trị là **thưởng trọn bộ** và **tiến độ theo nhóm** — hai thứ cần
routine có danh tính riêng. Nếu chỉ là nhãn, sửa lịch một routine 5 task phải sửa 5 chỗ và
dễ lệch nhau.
**Hệ quả:** (+) mô hình đúng, UI kéo thả thứ tự tự nhiên. (−) bộ sinh instance phải rẽ nhánh
theo `routine_id`; thêm quy tắc "task trong routine bỏ qua lịch riêng" — phải test kỹ.

---

## ADR-012: Phần thưởng "screen time" là phiếu, không cưỡng chế kỹ thuật ở v1
**Bối cảnh:** ChoreReward cho đổi điểm lấy screen time. Họ làm được vì nhà phát triển là
**Kidslox** — một app parental control đã có sẵn hạ tầng khóa/mở thiết bị. Ta không có.
**Quyết định:** `reward_type = screen_time` chỉ tạo **phiếu** ("30 phút xem TV"); phụ huynh
duyệt rồi tự cho phép. App không khóa hay mở khóa gì.
**Lý do:** cưỡng chế thật đòi hỏi Family Controls / Screen Time API trên iOS (entitlement phải
xin riêng từ Apple, duyệt lâu, ràng buộc chặt) và Device Admin / UsageStats trên Android — cộng
lại là một sản phẩm riêng, không phải một tính năng. Đưa vào MVP sẽ nuốt trọn lộ trình.
**Hệ quả:** (−) yếu hơn họ đúng ở một điểm; bù lại nói thẳng trong UI để không hứa hão.
Nếu sau beta thấy đây là lý do chính người dùng bỏ đi → mở lại ở v2 như một dự án riêng.

---

## ADR-013: Streak có "ngày ân hạn", ngày không có task không làm đứt streak
**Bối cảnh:** streak là cơ chế giữ chân mạnh nhất, nhưng cũng dễ phản tác dụng — trẻ ốm một hôm,
mất chuỗi 40 ngày, rồi bỏ hẳn app.
**Quyết định:** ngày không có task nào đến hạn là **ngày trung tính** (không cộng, không đứt);
mỗi tháng có 1 **ngày ân hạn** tự động dùng khi hụt.
**Lý do:** mục tiêu sản phẩm là xây thói quen, không phải trừng phạt. Streak nên đo *xu hướng*,
không đo *sự hoàn hảo*.
**Hệ quả:** streak "dễ" hơn đối thủ — chấp nhận, vì con số đó dùng để động viên chứ không phải
để xếp hạng giữa các gia đình.

---

## ADR-014: v1 miễn phí hoàn toàn, không giới hạn tính năng
**Bối cảnh:** ChoreReward bán thuê bao tự gia hạn. Câu hỏi doanh thu (mục 1, 3 trong danh sách
mở trước đây) đã được chốt.
**Quyết định:** **v1 miễn phí toàn bộ.** Không thuê bao, không mua trong app, không quảng cáo,
không giới hạn số trẻ / số task / số routine. Chuyện tính phí để sau, quyết định riêng ở bản sau.
**Lý do:** ChoreReward còn rất mới và chưa có product-market fit rõ (chưa đủ rating). Miễn phí
hoàn toàn là cách nhanh nhất để lấy người dùng và học từ thực tế, đồng thời là điểm khác biệt
sắc bén khi đối thủ trực tiếp thu tiền.
**Hệ quả:**
- (+) Không phải làm StoreKit / Google Play Billing, không màn hình paywall, không quản lý
  gói/hoá đơn/khôi phục mua hàng → **tiết kiệm ~1 tuần trong MVP**.
- (+) Không có logic "tính năng khoá" rải khắp code.
- (−) Chi phí hạ tầng do ta chịu → phải theo dõi chi phí Supabase theo số gia đình hoạt động;
  kiến trúc offline-first giúp giảm mạnh lượng gọi server, đây là lợi thế thật về chi phí.
- **Ràng buộc bắt buộc cho code:** không đưa bất kỳ khái niệm `isPremium`, `plan`, `entitlement`
  nào vào domain hay database ở v1. Khi nào tính phí thì thêm mới, không để lại "chỗ trống"
  nửa vời gây nợ kỹ thuật.

---

## ADR-015: Đơn vị điểm gọi là "xu", không phải "điểm" hay "gem"
**Bối cảnh:** ChoreReward dùng gem (đá quý). Mục tiêu của Bé Ong có thêm trụ giáo dục tài chính.
**Quyết định:** đơn vị trong app là **xu**, hiển thị kèm quy đổi ra tiền thật nếu gia đình bật.
**Lý do:** đá quý là đồ chơi, không dạy được gì về tiền. Xu là thứ trẻ hiểu được là có giá trị,
để dành được, tiêu hết được. Đơn vị phải khớp với bài học.
**Hệ quả:** phải cẩn thận về ranh giới — app **không** chạm vào tiền thật, không ví điện tử,
không KYC. Tiền tiêu vặt chỉ là ghi sổ giữa bố mẹ và con.

---

## ADR-016: Ba hũ Tiêu / Để dành / Cho đi, chia tự động ngay khi kiếm được
**Bối cảnh:** cách dạy tài chính cho trẻ phổ biến nhất là chia thu nhập thành nhiều phần ngay
khi nhận, thay vì tiêu trước rồi để dành phần còn lại.
**Quyết định:** mỗi lần duyệt task, xu chia vào ba hũ theo tỷ lệ (mặc định 50/40/10) — sinh
ba dòng ledger, không phải một. Hũ **Để dành** không tiêu được cho đồ vặt.
**Lý do:** chia sau thì hũ Để dành luôn rỗng — đó là lý do người lớn cũng không tiết kiệm được.
Ràng buộc "không tiêu được" chính là chỗ dạy dỗ, bỏ nó đi thì ba hũ chỉ còn là trang trí.
**Hệ quả:** (−) mô hình ledger phức tạp hơn: mọi truy vấn số dư phải theo hũ, mọi giao dịch
phải khai báo hũ. (+) Đổi lại có sẵn nền cho mục tiêu tiết kiệm và lãi tượng trưng.
Trẻ lớn được tự đặt tỷ lệ — một bước của tự lập.

---

## ADR-017: Quy đổi ra tiền thật là tùy chọn, mặc định tắt
**Bối cảnh:** gắn việc nhà với tiền là chủ đề gây tranh cãi trong nuôi dạy con. Nhiều chuyên gia
cho rằng trả tiền cho việc nhà cơ bản làm mất động lực nội tại — trẻ ngừng giúp đỡ khi không
được trả.
**Quyết định:** `exchange_rate_xu` mặc định NULL (tắt). Gia đình nào muốn thì tự bật.
**Lý do:** ta không đứng về phía nào trong tranh luận nuôi dạy con. Nhưng mặc định là một lời
khuyên ngầm, nên mặc định phải là phương án an toàn hơn.
**Hệ quả:** trụ giáo dục tài chính vẫn chạy khi tắt quy đổi — ba hũ, mục tiêu tiết kiệm và sổ
chi tiêu đều hoạt động với xu thuần, không cần tiền thật.

---

## ADR-018: Vai (bố mẹ / con) được ghi nhớ ở local nhưng không cấp quyền

**Bối cảnh:** luồng ở `09-onboarding-pairing.md` bắt đầu bằng việc chọn vai ngay lần mở app đầu.
Nếu quyền suy ra từ lựa chọn đó thì trẻ chỉ cần vào Cài đặt đổi vai là thành bố mẹ.

**Quyết định:** vai lưu ở local **chỉ để biết mở màn hình nào**. Mọi quyền suy ra từ credential:
thiết bị bố mẹ có session auth user, thiết bị con có credential phạm vi hẹp gắn với đúng một
`member_id`.

**Hệ quả:** (+) đổi vai là thao tác vô hại, không cần khoá bằng PIN, không tạo đường leo thang
quyền. (+) mất/mượn máy con cũng không thành máy bố mẹ. (−) phải cẩn thận không bao giờ để logic
nghiệp vụ đọc cờ vai local thay vì đọc credential — dễ sai khi code nhanh.

---

## ADR-019: QR ghép cặp chỉ chứa mã dùng một lần, không chứa dữ liệu

**Bối cảnh:** thiết bị con cần biết nó thuộc gia đình nào và là bé nào. Cách gọn nhất là nhét
`family_id` + `member_id` + tên vào QR.

**Quyết định:** QR chỉ chứa một mã ngẫu nhiên 128 bit, hạn 10 phút, dùng một lần
(`beong://pair?v=1&c=<code>`). Server lưu hash của mã. Mọi dữ liệu đi qua server sau khi mã được
xác thực, và server cấp credential phạm vi hẹp chứ không phải session đầy đủ.

**Lý do:** QR bị chụp lại là chuyện thường (ảnh chụp màn hình, camera người khác). Nếu QR mang dữ
liệu thì thông tin của trẻ rò rỉ **vĩnh viễn** và không có đường thu hồi — ảnh đã chụp thì không
rút lại được. Mã vô nghĩa sau 10 phút thì ảnh chụp cũng vô giá trị.

**Hệ quả:** (−) **ghép cặp bắt buộc cần backend**, không có cách nào làm local-only cho ra sản
phẩm thật; điều này đôn Supabase lên trước trong lộ trình (xem `09` §8). (+) thu hồi được: xoá
thiết bị là credential vô hiệu.

**Đã cân nhắc:** ghép qua LAN/Bluetooth — hỏng ngay khi hai máy không cùng mạng, mà đó là trường
hợp thường gặp (bố mẹ ở cơ quan, con ở nhà).

---

## ADR-020: Server chỉ giữ nhóm tuổi của trẻ, không giữ năm sinh

**Bối cảnh:** `members.birthYear` dùng để chọn nhóm tuổi giao diện (`domain/services/age_band.dart`
— 5–8 / 9–12 / 13–15). Giao diện chỉ cần **nhóm**, không cần năm chính xác.

**Quyết định:** đồng bộ nhóm tuổi (`little` / `middle` / `teen`); năm sinh chính xác chỉ nằm ở
local máy bố mẹ, không lên server.

**Lý do:** năm sinh là dữ liệu cá nhân của trẻ vị thành niên. Không thu thập lên server thì giảm
được nghĩa vụ COPPA/GDPR-K đáng kể, mà mất gần như không có gì — cùng lý do với ADR-006.

**Hệ quả:** (+) bề mặt dữ liệu trẻ em trên server nhỏ hơn. (−) đổi ranh giới nhóm tuổi sau này thì
thiết bị đã ghép cặp không tự xếp lại được, phải bố mẹ nhập lại năm sinh.

---

## ADR-021: Cấu hình gia đình sống trên tài khoản bố mẹ; máy con là bản sao đồng bộ

**Bối cảnh:** câu hỏi mở #8 hỏi có đôn backend lên trước Sprint 3 hay ra v1.0 một-thiết-bị rồi
ghép cặp ở v1.1. Câu hỏi thật nằm dưới nó: **nơi cư trú của cấu hình** (gia đình, hồ sơ con, task,
phần thưởng) là máy bố mẹ hay là tài khoản bố mẹ.

**Quyết định:** cấu hình cư trú trên **tài khoản bố mẹ** ở server. Bố mẹ cấu hình xong thì cấu
hình thuộc về tài khoản, không thuộc về cái máy đã nhập nó. Máy con quét QR → tải về **hồ sơ của
đúng bé đó** → từ đó đồng bộ hai chiều với tài khoản bố mẹ.

Hệ quả về thứ tự: **backend + auth lên trước phần thưởng/streak** (chọn hướng A của `09` §8).

**Lý do:** đây là điều kiện của ba thứ đã hứa ở chỗ khác và không thể làm local-only:
- Ghép cặp bằng QR (ADR-019 — QR không mang dữ liệu, nên dữ liệu phải tới từ server).
- "Mỗi bé một máy" — điểm bán chính, chứ không phải tính năng phụ.
- Đổi/mất máy bố mẹ mà không mất cả nhà. Nếu cấu hình chỉ nằm ở máy bố mẹ thì mất máy là mất
  toàn bộ lịch sử xu của con — hỏng đúng thứ app hứa giữ.

**Điều này không lật ADR-002.** Hai câu nói về hai thứ khác nhau, và đừng để chúng bị đọc lẫn:

| | Nguồn sự thật | Vì sao |
|---|---|---|
| **Cấu hình** (gia đình, hồ sơ con, task, phần thưởng, tỷ giá) | Tài khoản bố mẹ trên server | Phải sống lâu hơn cái máy, phải tới được máy con |
| **Hoạt động lúc chạy** (tick việc, cộng xu, tiến độ) | Drift local trên chính máy đó | Bé tick lúc mất mạng phải được cộng xu **ngay** (ADR-002) |

Nghĩa là máy con vẫn ghi Drift trước rồi đẩy lên sau, đúng như ADR-002; nó chỉ không còn là nơi
**khai sinh** cấu hình.

**Hệ quả:**
- (+) Câu hỏi mở #8 đóng lại; `05-roadmap.md` đảo thứ tự Sprint 3 ↔ Sprint 4.
- (+) Máy con cài lại app vẫn lấy lại được dữ liệu bằng cách ghép lại — không mất lịch sử.
- (−) Không còn đường ra hàng "một thiết bị, không cần tài khoản". v1.0 **bắt buộc** có auth, nên
  ngày phát hành lùi lại và phần thưởng/streak (Sprint 3 cũ) đi sau.
- (−) Bắt buộc phải có mạng ở hai thời điểm: bố mẹ đăng ký, và máy con quét QR một lần.
- (−) Sinh ra nghĩa vụ dữ liệu trẻ em thật sự (không còn "mọi thứ chỉ ở local nên không phải lo") —
  ADR-020 (server chỉ giữ nhóm tuổi) và ADR-010 (không analytics bên thứ ba) từ chỗ là lựa chọn
  tốt trở thành **ràng buộc phải giữ**.

**Đã cân nhắc:** hướng B — v1.0 một-thiết-bị, ghép cặp ở v1.1. Bỏ vì nó hoãn đúng điểm bán chính,
và vì đổi nơi cư trú của cấu hình **sau khi** đã có người dùng thật là việc di trú dữ liệu đau hơn
nhiều so với làm đúng từ đầu.

---

## Câu hỏi còn mở

| # | Câu hỏi | Cần chốt trước |
|---|---|---|
| 2 | Có cho phép trừ điểm (penalty) không? Nhiều chuyên gia nuôi dạy phản đối | v1.1 |
| 4 | Tên & thương hiệu chính thức (Bé Ong chỉ là tên tạm) | Sprint 5 |
| 5 | Self-host Supabase ngay từ đầu hay dùng cloud rồi chuyển sau? | Sprint 3 (sprint backend, đã đôn lên — ADR-021) |
| 6 | Tiền tiêu vặt: chỉ ghi sổ "bố mẹ nợ con", hay v2 nối ví điện tử (MoMo/ZaloPay)? Nối ví kéo theo KYC và quy định tài chính — nặng | v2 |
| 7 | Mô hình doanh thu cho bản sau v1 (nếu cần) — đã hoãn theo ADR-014 | sau v1 |

> Mục 1 và 3 đã chốt tại ADR-014: miễn phí hoàn toàn ở v1.
> Mục 8 đã chốt tại ADR-021: cấu hình sống trên tài khoản bố mẹ, backend lên trước phần thưởng.
