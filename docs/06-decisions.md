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
đáng kể so với gọi API trực tiếp; chi phí này dồn vào Sprint 4.

---

## ADR-003: Riverpod thay vì BLoC
**Quyết định:** Riverpod 2 + codegen.
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
**Hệ quả:** doanh thu phải đến từ mua một lần hoặc thuê bao (quyết định ở bản sau).

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

## Câu hỏi còn mở

| # | Câu hỏi | Cần chốt trước |
|---|---|---|
| 2 | Có cho phép trừ điểm (penalty) không? Nhiều chuyên gia nuôi dạy phản đối | v1.1 |
| 4 | Tên & thương hiệu chính thức (DailyChildren chỉ là tên tạm) | Sprint 5 |
| 5 | Self-host Supabase ngay từ đầu hay dùng cloud rồi chuyển sau? | Sprint 4 |
| 6 | Tiền tiêu vặt: chỉ ghi sổ "bố mẹ nợ con", hay v2 nối ví điện tử (MoMo/ZaloPay)? Nối ví kéo theo KYC và quy định tài chính — nặng | v2 |
| 7 | Mô hình doanh thu cho bản sau v1 (nếu cần) — đã hoãn theo ADR-014 | sau v1 |

> Mục 1 và 3 đã chốt tại ADR-014: miễn phí hoàn toàn ở v1.
