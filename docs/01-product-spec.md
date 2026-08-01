# 01 — Đặc tả sản phẩm (PRD)

**Sản phẩm:** DailyChildren — app quản lý việc nhà & phần thưởng cho gia đình
**Nền tảng:** Flutter (iOS, Android, macOS, Windows) + web (tùy chọn giai đoạn sau)
**Trạng thái:** Bản kế hoạch v1 — chưa viết code

---

## 1. Bối cảnh

ChoreReward (Kidslox) là app giao việc nhà cho trẻ, cha mẹ tạo task → trẻ hoàn thành →
nhận điểm (gem) → đổi lấy phần thưởng. Từ ảnh chụp app hiện tại, luồng cốt lõi gồm:

- Màn hình **Edit Task**: chọn preset nhanh (Brush teeth, Make bed, Homework, Dishwasher…),
  chỉnh điểm bằng nút −/+, đặt tên task, chọn lặp lại (Once / Daily / Custom),
  chọn buổi trong ngày (Morning / Afternoon / Evening).
- Danh sách preset rút gọn 5 mục + nút "More" để mở toàn bộ ~20 preset.
- Điểm hiển thị dạng gem, mặc định theo preset (20, 25…).

### Điểm yếu quan sát được (cơ hội cải tiến)

| Vấn đề | Cải tiến của DailyChildren |
|---|---|
| Chỉ có mobile | Thêm desktop (macOS/Windows) cho phụ huynh quản lý |
| Không có chế độ offline rõ ràng | Offline-first, đồng bộ khi có mạng |
| Preset cứng, không học theo thói quen | Preset gợi ý theo lịch sử + theo độ tuổi |
| Không có bằng chứng hoàn thành | Ảnh/ghi chú xác nhận (tùy chọn theo task) |
| Phần thưởng đơn điệu | Kho phần thưởng tự định nghĩa + mục tiêu tiết kiệm điểm |
| Thiếu động lực dài hạn | Streak, huy hiệu, level, thử thách tuần |
| Một phụ huynh | Nhiều phụ huynh/người chăm sóc, phân quyền |
| Không nhìn được tiến độ | Dashboard thống kê tuần/tháng cho cha mẹ |

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
3. Gán task cho một hoặc nhiều trẻ
4. Trẻ đánh dấu hoàn thành → trạng thái *chờ duyệt* hoặc *tự động duyệt* (tùy cấu hình task)
5. Phụ huynh duyệt/từ chối; điểm cộng vào ví của trẻ
6. Kho phần thưởng: phụ huynh tạo phần thưởng (giá bằng điểm), trẻ đổi → yêu cầu chờ duyệt
7. Màn hình Home cho trẻ: task hôm nay, số điểm, streak
8. Màn hình Home cho phụ huynh: việc chờ duyệt, tiến độ hôm nay của từng trẻ
9. Offline-first + đồng bộ nhiều thiết bị
10. Thông báo đẩy: nhắc task, có việc chờ duyệt, đổi thưởng
11. Đa ngôn ngữ: Tiếng Việt + English

### v1.1 – v1.2
- Streak, huy hiệu, level
- Thử thách tuần (weekly challenge) & mục tiêu tiết kiệm điểm
- Bằng chứng hoàn thành (ảnh/ghi chú)
- Thống kê tuần/tháng, xuất PDF/CSV
- Desktop layout tối ưu (bảng điều khiển đa cột)
- Trừ điểm (penalty) cho task bỏ lỡ — tùy chọn, mặc định tắt

### Ngoài phạm vi (v1)
- Quy đổi điểm sang tiền thật / thanh toán
- Quản lý thời gian dùng thiết bị (screen time)
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

### 4.2 Vòng đời một task instance
```
scheduled → (trẻ bấm xong) → pending_review → (parent duyệt) → approved → điểm cộng ví
                            ↘ (auto-approve)  → approved
                            ↘ (parent từ chối) → rejected → quay lại scheduled
        → (hết ngày chưa làm) → missed
```

### 4.3 Điểm & ví
- Ví theo từng trẻ, số dư = tổng `approved` − tổng đã đổi thưởng
- Mọi thay đổi số dư ghi vào **sổ cái (ledger)**, không sửa số dư trực tiếp
- Loại giao dịch: `task_approved`, `reward_redeemed`, `manual_adjust`, `penalty`, `bonus`

### 4.4 Phần thưởng
- Phụ huynh tạo: tên, icon, giá điểm, số lượng còn (tùy chọn), có cần duyệt không
- Trẻ đổi → `redemption` trạng thái `pending` → phụ huynh `fulfilled` / `rejected` (hoàn điểm)

### 4.5 Thông báo
| Sự kiện | Người nhận |
|---|---|
| Task sắp đến hạn (trước 30 phút) | Trẻ |
| Task hoàn thành chờ duyệt | Phụ huynh |
| Task được duyệt / từ chối | Trẻ |
| Yêu cầu đổi thưởng | Phụ huynh |
| Tổng kết cuối ngày | Phụ huynh |

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
