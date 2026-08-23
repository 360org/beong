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

> **ĐÃ BỊ THAY THẾ bởi ADR-023.** Mặc định giờ là **không cần duyệt**. Giữ nguyên nội dung dưới đây
> để thấy lập luận cũ và vì sao nó bị lật — đừng đọc mục này như quy tắc đang có hiệu lực.

**Quyết định (cũ):** `approval_mode = manual` là mặc định khi tạo task; phụ huynh có thể chuyển `auto`.
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

## ADR-025: Đổi thưởng **luôn** cần bố mẹ duyệt, không cấu hình được

**Bối cảnh:** ADR-023 vừa làm cho việc duyệt **việc nhà** thành tuỳ chọn và mặc định tắt. Bảng
`rewards` có cột `requires_approval`, và service đọc nó: đặt `false` thì phiếu đổi thưởng thành
"dùng được ngay", bỏ hẳn bố mẹ ra khỏi luồng.

**Quyết định:** mọi lượt đổi thưởng vào trạng thái `pending` và **phải** có bố mẹ duyệt. Không có
cờ nào tắt được bước này.

**Lý do — và đây là chỗ dễ đọc lẫn với ADR-023:** hai việc trông giống nhau nhưng khác hẳn về hệ quả.

| | Làm xong việc nhà | Đổi thưởng |
|---|---|---|
| Kết quả | Một con số trong app tăng lên | Tiêu xu ra **thế giới thật** |
| Sai thì sao | Bố mẹ mở lại việc, trừ theo ADR-022 | Đã đi công viên rồi thì không rút lại được |
| Ai phải có mặt | Không nhất thiết | **Bắt buộc** có người lớn |

Phần thưởng là tiền thật, thời gian thật của bố mẹ, một chuyến đi thật. Không có "mở lại" cho những
thứ đó. Vì vậy chỗ này đi ngược hướng ADR-023 một cách có chủ ý, không phải vì quên.

**Cột `rewards.requires_approval` giữ lại nhưng không còn được đọc.** Xoá cột cần migration mà chẳng
được gì, và nếu sau này mở lại đường "tự duyệt thưởng nhỏ" thì đã có chỗ. Đã ghi ngay tại định nghĩa
cột rằng ai định đọc lại nó phải đọc ADR này trước — cột im lặng không dùng là chỗ dễ bị bật lại sau
mấy tháng mà không ai nhớ lý do.

**Hệ quả:**
- (+) Bố mẹ luôn biết con đang tiêu xu vào gì, đúng lúc nó xảy ra.
- (+) Một đường đi duy nhất, không có nhánh "tự duyệt" cần test riêng.
- (−) Bố mẹ quên mở app thì phiếu nằm chờ. Với việc nhà đây là lý do lật ADR-009, nhưng ở đây chấp
  nhận được: con vẫn kiếm xu bình thường, chỉ chưa dùng được — khác với bị chặn không kiếm được gì.
  Thông báo đẩy ở Sprint 5 sẽ giảm chỗ này.
- (−) Thưởng rất nhỏ (5 xu đổi một cái nhãn dán) cũng phải chờ. Nếu beta cho thấy đây là ma sát thật
  thì mở lại bằng một ADR mới, không phải bằng cách lặng lẽ đọc lại cột cũ.

**UI phải nói trước:** thẻ phần thưởng hiện dòng "Cần bố mẹ duyệt" ngay dưới giá, và snackbar sau
khi đổi nói rõ đang chờ. Xu đã trừ mà phần thưởng chưa dùng được là chỗ dễ hiểu lầm nhất trong app.

---

## ADR-024: Hũ do bố mẹ tự lập; con có thể tự chia xu

**Sửa ADR-016, không lật.** Ba hũ Tiêu / Để dành / Cho đi vẫn là **mặc định**, và chia-ngay-khi-kiếm
vẫn là chế độ mặc định. Thay đổi là: chúng thôi làm *giới hạn cứng*.

**Bối cảnh:** ADR-016 hoá thân thành `enum Jar { spend, save, give }` trong code. Nhà nào muốn dạy
một giá trị khác — "Sách", "Quỹ đi chơi", "Từ thiện" — thì không có đường. Và bản thân việc *chia*
là bài học lớn nhất trong ba hũ, nhưng app đang chia hộ, nên đứa trẻ không bao giờ phải quyết định.

**Quyết định:**

1. **Hũ thành bảng `jars`**, mỗi hũ có `title`, `emoji`, `pct`, `order_index`. Bố mẹ thêm/sửa/nghỉ
   dùng. Tổng `pct` của các hũ đang dùng phải bằng 100.
2. **`families.allocation_mode`**: `auto` (mặc định, chia ngay theo tỷ lệ — đúng ADR-016) hoặc
   `manual` (xu vào **hũ chờ**, con tự chia sang các hũ).
3. Hũ phải có **emoji**, không phải tuỳ chọn: trẻ chưa đọc thông nhận hũ bằng mặt, không bằng chữ.

**`key` là thứ đi vào sổ cái, không phải `id`.** Ba hũ mặc định dùng đúng khoá cũ
(`spend`/`save`/`give`), nên **toàn bộ `point_transactions` đã ghi vẫn đọc được** và bước migration
v4→v5 không sửa một dòng ledger nào.

**Hũ chỉ được "nghỉ dùng", không được xoá.** Sổ cái là append-only (ADR-005); xoá hũ thì lịch sử trỏ
vào một hũ không tồn tại. Hũ nghỉ dùng không nhận xu mới nhưng số dư và lịch sử vẫn còn.

**Hũ chờ (`inbox`) không phải hũ thật.** Nó không nằm trong bảng `jars` và không tính vào tổng 100%:
nó là nơi trung chuyển, không phải một giá trị gia đình muốn dạy. Con chia xu = hai dòng sổ cái
(trừ ở hũ chờ, cộng ở hũ đích) với lý do `jarTransfer` — vẫn append-only, không sửa dòng cũ.

**Hệ quả:**
- (+) Gia đình dạy được giá trị của riêng mình, không bị bó vào ba hũ của người khác.
- (+) Chế độ `manual` biến việc chia xu thành bài học thật: con phải tự quyết định.
- (−) Chế độ `manual` cần con **chủ động**. Hũ chờ đầy lên mà không ai chia thì xu nằm im, không
  sinh mục tiêu tiết kiệm nào — đúng cái ADR-016 muốn tránh. Vì vậy `auto` vẫn là mặc định, và app
  phải nhắc khi hũ chờ có xu.
- (−) Thứ tự hũ giờ là dữ liệu, không phải hằng số. Khoản trừ xu (ADR-022) lấy theo `order_index`
  tăng dần, nên bố mẹ đổi thứ tự là đổi luôn hũ nào bị trừ trước — phải nói rõ trong UI.
- (−) Bố mẹ đổi tỷ lệ không hồi tố: xu đã chia rồi thì nằm ở hũ cũ. Đúng tinh thần ADR-007.

**Đã cân nhắc:** giữ ba hũ cứng và chỉ cho đổi tên (không đủ — nhà muốn bốn hũ thì vẫn tắc); cho
xoá hũ thật (làm hỏng lịch sử); để con tự chia là mặc định (đa số gia đình sẽ thấy hũ chờ đầy xu
không ai chia).

---

## ADR-016: Ba hũ Tiêu / Để dành / Cho đi, chia tự động ngay khi kiếm được

> **ĐÃ ĐƯỢC SỬA bởi ADR-024.** Ba hũ này vẫn là mặc định và chia-ngay vẫn là chế độ mặc định, nhưng
> chúng không còn là giới hạn cứng: bố mẹ lập được hũ khác, và con có thể tự chia.

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
quyền. *(**ADR-027 sửa vế "không cần khoá bằng PIN"**: nay vào hồ sơ nào cũng qua pass của hồ sơ
đó — nhưng để **định danh ai đang dùng**, không phải để cấp quyền. Phần cốt lõi của ADR này —
vai local không cấp quyền — giữ nguyên.)* (+) mất/mượn máy con cũng không thành máy bố mẹ. (−) phải cẩn thận không bao giờ để logic
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

## ADR-023: Mặc định "làm xong là xong"; duyệt là tính năng bố mẹ tự bật

**Thay thế ADR-009.**

**Bối cảnh:** ADR-009 đặt `manual` làm mặc định để chống gian lận và giữ bố mẹ trong vòng lặp động
lực. Chính nó đã ghi sẵn rủi ro: *"phụ huynh quên duyệt sẽ chặn phần thưởng"*. Đó là rủi ro nặng
hơn dự tính — với mặc định cũ, mọi việc con làm đều **đứng lại chờ** một người trưởng thành mở app.
Con làm xong mà xu không nhúc nhích thì phản hồi tức thì biến mất, mà phản hồi tức thì là toàn bộ
cơ chế của app này.

**Quyết định:** `families.require_approval`, **mặc định `false`**.

| Trạng thái | Con bấm xong | Bố mẹ |
|---|---|---|
| Tắt (mặc định) | `approved` ngay, **xu cộng ngay** | Mở lại việc nếu thấy chưa làm thật |
| Bật | `pending_review` | Duyệt từng việc, hoặc **Duyệt tất cả** |

Thứ tự ưu tiên hai tầng: nhà tắt duyệt → mọi việc xong luôn, không đọc tới `tasks.approval_mode`.
Nhà bật duyệt → tôn trọng cấu hình từng task (mặc định của task vẫn là `manual`). Quy tắc này nằm
ở **một** hàm thuần `needsApproval` để hai chỗ không lệch nhau.

**Lý do đổi mặc định thay vì chỉ thêm công tắc:** mặc định là thứ 90% gia đình sẽ dùng. Đặt mặc
định ở "phải duyệt" là chọn thay cho họ cái phương án có điểm gãy là sự chú ý của người lớn.

**Chống gian lận vẫn còn, chỉ đổi hướng:** thay vì chặn trước, app cho bố mẹ **mở lại** việc (ADR-022).
Sai sót được sửa sau, không phải chặn trước — và trẻ vẫn nhận phản hồi tức thì trong trường hợp
thường gặp, tức là khi con làm thật.

**Một lỗi thật lộ ra khi làm quyết định này:** việc cộng xu đang nằm **trong nút duyệt ở UI**. Đường
tự động duyệt (đã có sẵn cho task đặt `auto`) đổi trạng thái sang `approved` mà **không cộng xu cho
ai**. Lỗi này không lộ khi mặc định là phải duyệt, nhưng đổi mặc định mà không sửa thì con bấm xong
được 0 xu. Đã dồn toàn bộ quy tắc cộng xu vào `TaskReviewService`; UI không gọi `WalletDao.credit`
cho việc nhà nữa.

**Hệ quả:**
- (+) Con nhận xu ngay khi làm xong — đúng cơ chế app hứa.
- (+) Bố mẹ quên mở app không còn chặn động lực của con.
- (+) Cộng xu chỉ còn một đường đi, thay vì hai đường mà một đường bị hỏng.
- (−) Gia đình đang dùng bản cũ nâng cấp lên sẽ **đổi hành vi**: trước đây mọi việc phải duyệt, giờ
  xong là xong. Đây là đổi có chủ ý, có test migration chốt, và cần nói rõ trong ghi chú phát hành.
- (−) `reviewed_by` để trống khi không ai duyệt. Đúng với thực tế, nhưng mọi báo cáo về sau phải
  chịu được cột này rỗng.
- (−) Cần một chỗ để bố mẹ mở lại việc **ngoài** hàng đợi duyệt, vì khi tắt duyệt thì không có hàng
  đợi. Đã thêm danh sách "Đã xong hôm nay" trong thẻ mỗi con ở Trang chính.

**Đã cân nhắc:** giữ mặc định `manual` và chỉ thêm nút "Duyệt tất cả" — vẫn để điểm gãy ở sự chú ý
của người lớn. Bỏ hẳn tính năng duyệt — mất công cụ cho gia đình thật sự cần nó.

---

## ADR-022: Trừ xu là tính năng bố mẹ tự bật, mặc định tắt

**Bối cảnh:** câu hỏi mở #2 hỏi có cho phép trừ điểm hay không, và ghi rằng nhiều chuyên gia nuôi
dạy phản đối. Chủ dự án yêu cầu có tính năng này với hai tình huống cụ thể: hết ngày mà việc chưa
làm, và con bấm xong nhưng thực tế chưa làm rồi bố mẹ phát hiện.

**Quyết định:** làm, nhưng **mặc định tắt** và bố mẹ phải tự bật với cảnh báo hiện trước các lựa
chọn. Hai mức, cấu hình ở cấp gia đình, tính theo **phần trăm điểm của việc** chứ không phải số xu
cố định:

| Mức | Khi nào | Mặc định |
|---|---|---|
| `missedPenaltyPct` | Hết ngày, việc vẫn `scheduled` → chuyển `missed` | 0 (tắt) |
| `reopenPenaltyPct` | Bố mẹ mở lại việc con đã bấm xong, **mỗi lần** mở lại | 0 (tắt) |

**Lý do phần trăm chứ không phải số xu:** việc rửa bát 20 xu và việc gấp quần áo 5 xu không nên
chịu cùng một khoản trừ. Phần trăm giữ được tỷ lệ giữa các việc mà bố mẹ đã tự cân.

**Bảy quyết định nhỏ đi kèm, đều là chỗ dễ làm sai:**

1. **Việc bị mở lại vẫn được tính xu đầy đủ khi cuối cùng làm xong.** Thu hồi xu *và* trừ phạt là
   trừ hai lần cho một lỗi. `clientOpId` của khoản cộng gắn với lượt việc nên duyệt lần hai không
   cộng thêm — việc đó cuối cùng vẫn chỉ đáng đúng số xu của nó, cộng một khoản trừ cho lần làm lại.
2. **Không bao giờ để số dư âm.** Trừ tối đa đến 0 rồi thôi. Trẻ nhìn thấy số âm không hiểu chuyện
   gì xảy ra, và app này không dạy nợ. Hệ quả phải biết: đứa trẻ đang 0 xu thì trừ bao nhiêu cũng
   như nhau — tính năng mất tác dụng đúng lúc nó dễ gây tổn thương nhất.
3. **Thứ tự hũ khi trừ: Tiêu → Để dành → Cho đi.** Không chia theo tỷ lệ ba hũ như khi cộng. Chia
   theo tỷ lệ nghe công bằng nhưng nó lấy cả xu con đã tự nguyện dành để tặng, biến hũ Cho đi thành
   công cụ trừng phạt. Hũ Để dành cũng cần được bảo vệ vì nó gắn với mục tiêu dài hạn app đang dạy.
4. **Làm tròn xuống.** 50% của 15 xu ra 7, không phải 8. Chỗ nào phải chọn thì chọn bên không làm
   trẻ cảm thấy bị xử ép.
5. **Không trừ hồi tố.** Lượt việc bỏ được đánh dấu đã xử lý ngay cả khi chính sách đang tắt. Nếu
   không, ngày bố mẹ bật tính năng lên là toàn bộ việc bỏ từ trước bị trừ một lượt — phạt cho hành
   vi xảy ra khi luật chưa có.
6. **Nâng cấp app không tự bật.** Cột mới có default 0, và có test migration khẳng định điều đó.
7. **Mỗi lần trừ đều có dòng sổ cái với lý do đọc được** ("Hết ngày chưa làm", "Bố mẹ mở lại việc —
   làm lại lần 2"). Xu biến mất mà không ai giải thích là đúng thứ làm trẻ mất niềm tin. Tuân ADR-005:
   sổ cái append-only, không sửa dòng cũ.

**Hệ quả:** (+) gia đình muốn thì có, gia đình không muốn thì không bao giờ gặp. (+) sổ cái vẫn là
nguồn sự thật duy nhất về xu. (−) thêm bề mặt cấu hình mà bố mẹ phải hiểu, nên trang cấu hình có
phần "Thử một ngày" tự tính bằng số thật thay vì để bố mẹ tự hình dung phần trăm ra bao nhiêu xu.
(−) đây là tính năng dễ dùng sai nhất trong app; nếu phản hồi beta cho thấy nó gây hại, đường lùi
là ẩn nó đi, không phải bỏ dữ liệu.

**Đã cân nhắc:** trừ theo số xu cố định (mất tỷ lệ giữa các việc); trừ theo tỷ lệ ba hũ (lấy xu hũ
Cho đi); thu hồi xu khi mở lại (trừ hai lần); cho số dư âm (không dạy nợ).

---

## ADR-026: Bundle ID / application ID là `net.beong.app`, đóng băng từ đây

**Bối cảnh:** giá trị này được đặt lúc đổi tên dự án sang "Bé Ong" (commit `5dda80e`, 2/8) và
được dùng nhất quán ở 22 chỗ: `namespace` + `applicationId` bên Android, thư mục và `package` của
`MainActivity.kt`, `PRODUCT_BUNDLE_IDENTIFIER` của iOS và macOS, hai `Appfile` của Fastlane, và
`ExportOptions.plist.template`.

Nhưng nó **chưa từng được ghi lại ở đâu và cũng chưa từng được chủ dự án chốt** — người viết code
tự suy ra từ tên thương hiệu rồi tự quyết. Đúng loại quyết định phải có ADR mà lại không có: khi
được hỏi lại "có phải `com.mobile.beong` không?", không ai trả lời được mà không đi grep cả repo.

**Quyết định:** giữ **`net.beong.app`**, và coi đây là giá trị đã đóng băng.

**Vì sao chốt bây giờ:** cả hai store coi ID này là danh tính vĩnh viễn của app — đổi sau khi phát
hành nghĩa là một app khác, mất toàn bộ người dùng, đánh giá và lịch sử cài đặt. Trước lần tạo App
ID đầu tiên thì đổi chỉ là một commit; sau đó thì không đổi được nữa. Cửa sổ để chọn đóng lại đúng
lúc tạo App ID trên developer.apple.com và app trên Play Console.

**Không chọn `com.beong.app`** dù `com.` phổ biến hơn: giá trị đang có đã nhất quán khắp 5 nền
tảng, và đổi tiền tố chỉ vì thói quen đặt tên thì được một chút thẩm mỹ mà phải sửa 22 chỗ cùng
thư mục package Kotlin. Cả hai store không phân biệt tiền tố — chúng chỉ cần một tên miền ngược,
duy nhất, không đổi.

**Hệ quả:** mọi tài liệu hướng dẫn phát hành (`08-release-cicd.md`) dùng đúng chuỗi này; ai tạo App
ID hay app trên Play Console phải gõ **chính xác** `net.beong.app`, gõ khác đi thì `upload_to_*` báo
"App not found" mà không nói vì sao.

**Đổi được, đổi không được:**

| Thứ | Đổi sau khi phát hành? |
|---|---|
| Bundle ID / application ID (`net.beong.app`) | **Không.** Đóng băng từ ADR này |
| Tên hiển thị dưới icon (`CFBundleDisplayName` = "Bé Ong") | Được, bất cứ lúc nào |
| Tên trên store, mô tả, ảnh chụp, icon | Được, bất cứ lúc nào |
| Tên gói Dart (`beong` trong `pubspec.yaml`) | Được, chỉ là chuyện nội bộ |

Nghĩa là chốt ID **không** khoá luôn thương hiệu: câu hỏi mở #4 vẫn mở, đổi tên hiển thị về sau
không ảnh hưởng gì tới ID.

---

---

## ADR-027: Mỗi hồ sơ một mật khẩu riêng, đặt bắt buộc ngay từ onboarding

**Bối cảnh:** luồng vào app do chủ dự án chốt ngày 23/08/2026:

```
Cài app → khai báo gia đình → khai báo con cái → đặt pass cho từng hồ sơ → dùng
Khoá lại → chọn nhà → chọn vai (phụ huynh / con) → chọn hồ sơ → điền pass → vào đúng hồ sơ
```

**Quyết định:** mỗi `member` — cả bố mẹ lẫn từng bé — có `pin_hash` của riêng mình.
Onboarding **bắt buộc** đặt pass cho mọi hồ sơ vừa tạo; thêm bé về sau cũng phải đặt
pass cho bé đó. Không có hồ sơ nào không có pass.

**Đây là quyết định ngược lại hai điều đã ghi trước đó**, ghi ra để không ai
tưởng mình đọc nhầm tài liệu:

| Trước | Nay |
|---|---|
| Một PIN **chung cho cả nhà**, chỉ đặt trên hồ sơ bố mẹ. Lý do cũ: "mục đích là ngăn *trẻ con*, không phải phân quyền giữa bố và mẹ. Hai PIN khác nhau chỉ tạo thêm thứ để quên." | Mỗi hồ sơ một pass |
| PIN **tuỳ chọn** — "bật PIN là lựa chọn của bố mẹ, không phải thứ áp lên mọi nhà" | Bắt buộc, từ onboarding |
| ADR-018: "đổi vai là thao tác vô hại, **không cần khoá bằng PIN**" | Vào bất kỳ hồ sơ nào cũng qua pass |

**Lý do:** pass ở đây không còn chỉ để ngăn trẻ vào Cài đặt. Nó trở thành cách
**định danh ai đang dùng máy** — bước "điền pass → load đúng hồ sơ" của luồng
trên. Trên một máy dùng chung, đó cũng là thứ giữ sổ xu của bé này khỏi tay bé
kia.

**Điều ADR-018 vẫn giữ nguyên:** vai lưu ở local **không cấp quyền**. Pass chọn
xem mở hồ sơ nào, không phải thứ chứng minh quyền với máy chủ. Khi có backend,
quyền vẫn suy ra từ credential. Đừng để logic nghiệp vụ đọc "đã qua pass" thay
cho credential.

**Hệ quả phải bù, nếu không là tự dựng lại đúng cái bẫy vừa gỡ:**

- **Bé cũng phải nhớ mật khẩu.** Với bé 5 tuổi thì đây là rào thật, không phải
  giả thiết. Bù bằng: **bố mẹ đặt lại pass cho con** được từ Cài đặt, không cần
  biết pass cũ.
- **"Quên pass?" giờ phải *đổi* pass, không phải *gỡ*.** Gỡ sẽ để lại hồ sơ
  không pass, tức vi phạm chính ADR này. Luồng thoát: xác nhận → đặt pass mới
  ngay → vào.
- **Không thêm câu hỏi bí mật hay email khôi phục** (giữ nguyên lập luận cũ):
  app không có tài khoản, và thêm hai thứ đó là thêm dữ liệu cá nhân vào một app
  trẻ em.

**Mức bảo đảm không đổi:** vẫn là 4 chữ số băm SHA-256 không muối, vẫn **không
phải bảo mật thật** — ai cầm được file dữ liệu thì dò ra trong tích tắc. Nó chặn
người trong nhà bấm nhầm hồ sơ của nhau, không chặn kẻ tấn công.


## Câu hỏi còn mở

| # | Câu hỏi | Cần chốt trước |
|---|---|---|
| 4 | Tên & thương hiệu chính thức (Bé Ong chỉ là tên tạm) — **chỉ còn là tên hiển thị**, vì định danh kỹ thuật đã đóng băng ở ADR-026; đổi tên hiển thị về sau không phải sửa code | Sprint 5 |
| 5 | Self-host Supabase ngay từ đầu hay dùng cloud rồi chuyển sau? | Sprint 3 (sprint backend, đã đôn lên — ADR-021) |
| 6 | Tiền tiêu vặt: chỉ ghi sổ "bố mẹ nợ con", hay v2 nối ví điện tử (MoMo/ZaloPay)? Nối ví kéo theo KYC và quy định tài chính — nặng | v2 |
| 7 | Mô hình doanh thu cho bản sau v1 (nếu cần) — đã hoãn theo ADR-014 | sau v1 |

> Mục 1 và 3 đã chốt tại ADR-014: miễn phí hoàn toàn ở v1.
> Mục 8 đã chốt tại ADR-021: cấu hình sống trên tài khoản bố mẹ, backend lên trước phần thưởng.
> Mục 2 đã chốt tại ADR-022: có trừ xu, nhưng mặc định tắt và bố mẹ tự bật.
