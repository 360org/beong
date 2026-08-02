# 07 — Phân tích đối thủ: ChoreReward

Nguồn: trang App Store của **ChoreReward** (nhà phát triển **Kidslox inc**), chụp 2026-08.

---

## 1. Định vị của họ

> "Turn daily chores into a system that actually works. Kids stay motivated, parents stay calm,
> and routines finally stick."

Đau khổ họ nhắm tới: *"You ask, remind, repeat… and still end up in daily conflicts over chores,
homework, and screen time."* — bán **sự bình yên cho phụ huynh**, không bán "app quản lý task".
Bài học: copy cách định vị này, đừng mô tả sản phẩm bằng tính năng.

## 2. Luồng 5 bước họ công bố

| Bước | Nội dung | Ta đã có? |
|---|---|---|
| 1. Create tasks **and routines** | Chore, daily task, và **routine** (morning routine, bedtime routine, cleaning the house) | ❌ **thiếu routine** |
| 2. Assign and schedule | Lịch lặp, task định kỳ | ✅ |
| 3. Kids complete tasks | Checklist hằng ngày | ✅ |
| 4. Earn points and rewards | Đổi **screen time, pocket money, custom rewards** | ⚠️ chỉ có custom |
| 5. Track progress | Chore tracker, progress tracker, reward tracker, streaks, achievements | ⚠️ để ở v1.1–v1.2 |

## 3. Tính năng họ liệt kê

- Chore chart & chore list
- Daily checklist & **routines**
- **Smart reminders & notifications** — "gentle prompts without nagging"
- Points system & rewards — earn, unlock, redeem
- Progress & **streaks**
- **Custom rewards**
- **Family coordination** — nhiều trẻ, task dùng chung
- **Behavior & responsibility charts** — positive reinforcement
- Weekly goals for kids

## 4. Mô hình kinh doanh

- **Thuê bao tự động gia hạn** qua iTunes (không nêu giá trên trang mô tả)
- **Không quảng cáo** — họ nói rõ trong listing
- Chưa đủ đánh giá để hiển thị rating → app còn **rất mới**, thị phần chưa chốt

## 5. Điểm yếu khai thác được

### 5.1 ⭐ "ChoreReward requires an internet connection to operate."

Họ **tự khai trong App Store listing**. Đây là điểm yếu lớn nhất và trực tiếp xác nhận
[ADR-002 (offline-first)](06-decisions.md) của ta.

Với đúng đối tượng người dùng — trẻ em, thiết bị cũ, wifi nhà chập chờn, đi ô tô, đi du lịch —
"mất mạng là app chết" phá vỡ toàn bộ vòng lặp động lực: trẻ làm xong mà không tick được thì
lần sau không buồn làm nữa.

→ **Thông điệp marketing chính của DailyChildren: "Hoạt động cả khi mất mạng."**

### 5.2 Chỉ có mobile
Không có bản desktop. Phụ huynh thiết lập tuần và xem báo cáo trên máy tính thoải mái hơn nhiều.

### 5.3 Phụ thuộc hệ sinh thái Kidslox cho screen time
Kidslox là app parental control (chặn app, giới hạn giờ dùng máy). Phần thưởng "screen time"
của ChoreReward gần như chắc chắn dựa vào hạ tầng đó. Ta **không có** lợi thế này —
xem [ADR-012](06-decisions.md) về cách xử lý.

### 5.4 Không có bằng chứng hoàn thành
Không thấy nhắc tới ảnh/ghi chú xác nhận. Trẻ có thể tick bừa.

### 5.5 Thị trường chưa chốt
Chưa đủ rating → còn kịp để vào. Nhưng cũng nghĩa là **chưa có bằng chứng product-market fit**;
đừng sao chép mù quáng mọi quyết định của họ.

## 6. Bảng đối chiếu

| | ChoreReward | DailyChildren (kế hoạch) |
|---|---|---|
| Nền tảng | iOS (+Android) | iOS, Android, **macOS, Windows** |
| Mất mạng | **Không dùng được** | **Dùng đầy đủ, sync sau** |
| Routine | ✅ | ✅ (bổ sung sau phân tích này) |
| Screen time reward | ✅ (nhờ Kidslox) | ⚠️ dạng phiếu, không cưỡng chế kỹ thuật ở v1 |
| Tiền tiêu vặt | ✅ | ✅ (theo dõi, không xử lý thanh toán) |
| Bằng chứng hoàn thành | ❌ | ✅ v1.1 (ảnh/ghi chú) |
| Nhiều phụ huynh | ? | ✅ |
| Thống kê cho phụ huynh | Cơ bản | ✅ + xuất CSV/PDF |
| Tiếng Việt | ❌ | ✅ |
| Quảng cáo | Không | Không |
| Doanh thu | Thuê bao tự gia hạn | **Miễn phí hoàn toàn ở v1** (ADR-014) |

## 7. Việc phải làm rút ra từ phân tích này

1. **Thêm Routines vào MVP** — luồng cốt lõi của họ, ta thiếu thì thua rõ. → `01`, `03`, `05`
2. **Phân loại phần thưởng** (screen time / tiền tiêu vặt / trải nghiệm / đồ vật / tùy chỉnh) → `03`, `04`
3. **Đôn streaks + huy hiệu lên MVP** — họ quảng cáo mạnh, và đây là thứ giữ chân trẻ. → `05`
4. **Weekly goals** vào v1.1
5. **"Nhắc nhở nhẹ nhàng, không cằn nhằn"** thành nguyên tắc thiết kế thông báo, không chỉ là tính năng
6. **Offline-first thành thông điệp marketing số một**, không chỉ là quyết định kỹ thuật
