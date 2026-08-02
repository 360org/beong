# 01 — Đặc tả sản phẩm (PRD)

**Sản phẩm:** DailyChildren — app quản lý việc nhà & phần thưởng cho gia đình
**Nền tảng:** Flutter (iOS, Android, macOS, Windows) + web (tùy chọn giai đoạn sau)
**Trạng thái:** Bản kế hoạch v1 — chưa viết code

---

## 1. Bối cảnh

ChoreReward (Kidslox) là app giao việc nhà cho trẻ, cha mẹ tạo task → trẻ hoàn thành →
nhận điểm (gem) → đổi lấy phần thưởng. Từ ảnh chụp app và trang App Store của họ, luồng cốt lõi gồm:

- Màn hình **Edit Task**: chọn preset nhanh (Brush teeth, Make bed, Homework, Dishwasher…),
  chỉnh điểm bằng nút −/+, đặt tên task, chọn lặp lại (Once / Daily / Custom),
  chọn buổi trong ngày (Morning / Afternoon / Evening).
- Danh sách preset rút gọn 5 mục + nút "More" để mở toàn bộ ~20 preset.
- Điểm hiển thị dạng gem, mặc định theo preset (20, 25…).
- **Routines** — nhóm task thành thói quen (morning routine, bedtime routine, dọn nhà).
- Phần thưởng: **screen time, tiền tiêu vặt, phần thưởng tự định nghĩa**.
- Streaks, achievements, chore/behavior chart, weekly goals.
- Mô hình thuê bao, không quảng cáo.

Phân tích đối thủ đầy đủ: [`07-competitive-analysis.md`](07-competitive-analysis.md).

### Điểm yếu quan sát được (cơ hội cải tiến)

| Vấn đề | Cải tiến của DailyChildren |
|---|---|
| **Bắt buộc có Internet mới chạy được** (họ tự khai trong App Store listing) | **Offline-first** — dùng đầy đủ khi mất mạng, sync sau. Đây là điểm khác biệt số 1 |
| Chỉ có mobile | Thêm desktop (macOS/Windows) cho phụ huynh quản lý |
| Preset cứng, không học theo thói quen | Preset gợi ý theo lịch sử + theo độ tuổi |
| Không có bằng chứng hoàn thành | Ảnh/ghi chú xác nhận (tùy chọn theo task) |
| Phần thưởng không phân loại rõ | Phân loại + mục tiêu tiết kiệm điểm + phiếu thưởng in được |
| Một phụ huynh | Nhiều phụ huynh/người chăm sóc, phân quyền |
| Thống kê cơ bản | Dashboard tuần/tháng + xuất CSV/PDF |
| Không có tiếng Việt | vi + en ngay từ v1 |

---

## 2. Người dùng & vai trò

| Vai trò | Mô tả | Quyền |
|---|---|---|
| **Owner** | Phụ huynh tạo gia đình | Toàn quyền: mời thành viên, xóa gia đình, cấu hình |
| **Parent** | Phụ huynh/người chăm sóc được mời | Tạo/sửa/xóa task, duyệt hoàn thành, quản lý phần thưởng |
| **Child** | Trẻ, đăng nhập bằng PIN hoặc profile trên thiết bị chung | Xem task của mình, đánh dấu hoàn thành, đổi thưởng |

**Persona chính**
- *Anh Minh, 38t, bố 2 con (6 & 10 tuổi)*: muốn con tự giác, cần thiết lập nhanh dưới 3 phút, xem báo cáo cuối tuần.
- *Bé An, 8 tuổi*: cần giao diện to, ít chữ, nhiều biểu tượng, phản hồi vui (animation, âm thanh) khi hoàn thành.

---

## 3. Phạm vi

### MVP (v1.0)
1. Tạo gia đình, thêm hồ sơ trẻ (tên, avatar, tuổi, màu chủ đề)
2. Tạo task: preset hoặc tự nhập, điểm, lặp (Once/Daily/Custom theo thứ), buổi trong ngày
3. **Routines** — gom nhiều task thành một thói quen có thứ tự (Buổi sáng, Trước khi ngủ, Dọn nhà)
4. Gán task/routine cho một hoặc nhiều trẻ
5. Trẻ đánh dấu hoàn thành → trạng thái *chờ duyệt* hoặc *tự động duyệt* (tùy cấu hình task)
6. Phụ huynh duyệt/từ chối; điểm cộng vào ví của trẻ
7. Kho phần thưởng **có phân loại** (screen time / tiền tiêu vặt / trải nghiệm / đồ vật / tùy chỉnh);
   trẻ đổi → yêu cầu chờ duyệt
8. **Streak ngày** + 8 huy hiệu cơ bản
9. Màn hình Home cho trẻ: task hôm nay theo routine, số điểm, streak
10. Màn hình Home cho phụ huynh: việc chờ duyệt, tiến độ hôm nay của từng trẻ
11. Offline-first + đồng bộ nhiều thiết bị
12. Thông báo "nhắc nhẹ, không cằn nhằn": nhắc task, có việc chờ duyệt, đổi thưởng
13. Đa ngôn ngữ: Tiếng Việt + English

> Mục 3, 7, 8 được đôn từ v1.1 lên MVP sau khi phân tích ChoreReward — đây là phần cốt lõi
> trong luồng của họ, thiếu thì sản phẩm bị nhìn nhận là kém hơn.

### v1.1 – v1.2
- Level, thêm huy hiệu, thử thách tuần (weekly goals)
- Mục tiêu tiết kiệm điểm cho phần thưởng lớn
- Bằng chứng hoàn thành (ảnh/ghi chú)
- Thống kê tuần/tháng, xuất PDF/CSV
- Bảng thành tích in được (chore chart treo tủ lạnh)
- Desktop layout tối ưu (bảng điều khiển đa cột)
- Trừ điểm (penalty) cho task bỏ lỡ — tùy chọn, mặc định tắt

### Ngoài phạm vi (v1)
- **Mọi thứ liên quan đến thu tiền**: thuê bao, mua trong app, paywall, giới hạn tính năng.
  v1 miễn phí hoàn toàn, không giới hạn số trẻ/task/routine — xem ADR-014
- **Cưỡng chế screen time bằng kỹ thuật** (khóa/mở app trên máy trẻ). Phần thưởng "screen time"
  ở v1 chỉ là *phiếu*: phụ huynh duyệt rồi tự cho phép. Xem ADR-012 để biết vì sao
- Xử lý thanh toán thật cho tiền tiêu vặt (chỉ ghi nhận "bố mẹ nợ con 50k", không chuyển tiền)
- Mạng xã hội, so sánh giữa các gia đình
- Web app

---

## 4. Yêu cầu chức năng chi tiết

### 4.1 Task
- **Nguồn tạo:** preset (~24 mục có icon) hoặc tự nhập tên + chọn icon
- **Điểm:** 5 → 500, bước 5; mặc định theo preset
- **Lặp lại:** `once` (kèm ngày), `daily`, `custom` (chọn các thứ trong tuần)
- **Buổi:** `morning` / `afternoon` / `evening` / không đặt (tùy chọn)
- **Deadline:** giờ cụ thể (tùy chọn) → dùng cho nhắc nhở
- **Duyệt:** `auto` (hoàn thành là cộng điểm) hoặc `manual` (chờ phụ huynh)
- **Bằng chứng:** none / photo / note (v1.1)
- **Gán:** 1..n trẻ. Task gán nhiều trẻ sinh ra nhiều *instance* độc lập mỗi ngày.

### 4.2 Routine
Một routine là **nhóm task có thứ tự**, chạy cùng một lịch. Ví dụ "Buổi sáng" = Đánh răng →
Gấp chăn màn → Soạn cặp sách.

- Thuộc tính: tên, icon, buổi trong ngày, lịch lặp, danh sách task (có `order_index`), gán cho trẻ nào
- Task trong routine **kế thừa lịch của routine**, không đặt lịch riêng
- Giao diện trẻ: hiện dạng checklist theo thứ tự, có thanh tiến độ "2/4"
- **Thưởng hoàn thành trọn bộ (bonus):** làm hết cả routine trong ngày → thưởng thêm điểm
  (mặc định +10). Đây là cơ chế biến routine thành thói quen thay vì các task rời rạc
- 3 routine dựng sẵn khi onboarding: **Buổi sáng**, **Sau giờ học**, **Trước khi ngủ**

### 4.3 Vòng đời một task instance
```
scheduled → (trẻ bấm xong) → pending_review → (parent duyệt) → approved → điểm cộng ví
                            ↘ (auto-approve)  → approved
                            ↘ (parent từ chối) → rejected → quay lại scheduled
        → (hết ngày chưa làm) → missed
```

Task thuộc routine: khi **mọi** instance của routine trong ngày đạt `approved` → ghi thêm một
giao dịch `routine_bonus` (idempotent theo `(routine_id, member_id, due_date)`).

### 4.4 Điểm & ví
- Ví theo từng trẻ, số dư = tổng `approved` − tổng đã đổi thưởng
- Mọi thay đổi số dư ghi vào **sổ cái (ledger)**, không sửa số dư trực tiếp
- Loại giao dịch: `task_approved`, `routine_bonus`, `streak_bonus`, `reward_redeemed`,
  `reward_refund`, `manual_adjust`, `penalty`, `bonus`

### 4.5 Phần thưởng
- Phụ huynh tạo: tên, icon, **loại**, giá điểm, số lượng còn (tùy chọn), có cần duyệt không
- Trẻ đổi → `redemption` trạng thái `pending` → phụ huynh `fulfilled` / `rejected` (hoàn điểm)

**Phân loại (`reward_type`)** — quyết định UI và cách phụ huynh thực hiện:

| Loại | Ví dụ | Trường riêng | Ghi chú |
|---|---|---|---|
| `screen_time` | 30 phút xem TV | `minutes` | v1: **phiếu**, phụ huynh tự cho phép. Không khóa máy — xem ADR-012 |
| `pocket_money` | 20.000đ | `amount`, `currency` | Chỉ ghi sổ "bố mẹ nợ con", không chuyển tiền thật |
| `experience` | Đi công viên, chọn phim tối nay | — | Không có tồn kho |
| `item` | Đồ chơi, sách | `stock` | Có tồn kho |
| `custom` | Bất kỳ | — | Mặc định |

Sau khi `fulfilled`, phiếu vào **"Phiếu của con"** — trẻ xem lại được, có nút "Đã dùng".

### 4.6 Streak & huy hiệu (MVP)
- **Streak ngày** tính theo trẻ: một ngày được tính khi hoàn thành ≥ 80% task đến hạn hôm đó
  (ngưỡng cấu hình được). Không có task nào đến hạn → ngày trung tính, **không làm đứt streak**
- **Bảo vệ streak:** cho phép 1 "ngày nghỉ" mỗi tháng, tự động dùng. Mục tiêu là xây thói quen,
  không phải trừng phạt trẻ vì ốm hay đi chơi
- 8 huy hiệu MVP: streak 3/7/30 ngày, 10/50/100 task, routine trọn bộ 7 ngày, đổi thưởng đầu tiên

### 4.7 Thông báo — nguyên tắc "nhắc nhẹ, không cằn nhằn"
Nguyên tắc bắt buộc: **tối đa 2 thông báo/ngày cho trẻ**, gộp lại nếu nhiều sự kiện; không lặp
lại cùng một nhắc nhở; không thông báo mang giọng trách móc; không gửi sau giờ đi ngủ đã đặt.

| Sự kiện | Người nhận |
|---|---|
| Nhắc routine (1 lần/routine, trước giờ 15 phút) | Trẻ |
| Task có deadline sắp đến hạn (trước 30 phút) | Trẻ |
| Task hoàn thành chờ duyệt (gộp, tối đa 1 lần/giờ) | Phụ huynh |
| Task được duyệt / từ chối | Trẻ |
| Yêu cầu đổi thưởng | Phụ huynh |
| Tổng kết cuối ngày | Phụ huynh |
| Sắp mất streak (chỉ khi còn ≥ 1 task chưa làm, gửi 1 lần) | Trẻ |

---

## 5. Yêu cầu phi chức năng

- **Hiệu năng:** khởi động lạnh < 2s; mọi thao tác trong app phản hồi tức thì (ghi local trước, sync sau)
- **Offline:** dùng được đầy đủ khi mất mạng; sync tự động khi có lại
- **Bảo mật:** dữ liệu trẻ em — không quảng cáo, không tracking bên thứ ba. Tuân thủ COPPA/GDPR-K
- **Riêng tư:** hồ sơ trẻ không cần email/số điện thoại; chỉ tài khoản phụ huynh có định danh
- **Khả dụng:** font tối thiểu 16sp cho giao diện trẻ, vùng chạm ≥ 48dp, hỗ trợ TalkBack/VoiceOver
- **Kích thước:** APK/IPA < 40MB

---

## 6. Chỉ số thành công

| Chỉ số | Mục tiêu 3 tháng |
|---|---|
| Thời gian thiết lập lần đầu | < 3 phút (P50) |
| Tỷ lệ task hoàn thành/tuần | > 60% |
| Gia đình còn hoạt động ngày 30 | > 35% |
| Crash-free sessions | > 99.5% |

---

## 7. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Trẻ gian lận (đánh dấu xong mà chưa làm) | Mặc định `manual` cho task điểm cao; bằng chứng ảnh ở v1.1 |
| Phụ huynh quên duyệt → mất động lực | Nhắc nhở tổng kết cuối ngày; nút "duyệt tất cả" |
| Sync xung đột nhiều thiết bị | Ledger append-only + LWW theo trường, xem `03-data-model.md` |
| Quy định về dữ liệu trẻ em | Không thu thập PII của trẻ; xem mục 5 |
