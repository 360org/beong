# 04 — Hệ thống thiết kế & UI

Tham chiếu thị giác lấy từ ảnh chụp ChoreReward, chỉnh lại cho dễ đọc hơn với trẻ và
mở rộng được cho desktop.

## 1. Màu

### Ba màu thương hiệu và cách chia vai

| Màu | Mã | Vai |
|---|---|---|
| Vàng mật Bé Ong | `#FFC53D` | Nhận diện, chiếm diện tích lớn: nút chính, xu, linh vật, danh hiệu |
| Xanh dương 360 Corp | `#0077CD` | Tương tác & cấu trúc: `primary`, viền, thanh tiến độ |
| Xanh lá 360 Corp | `#00CE2C` | Hoàn thành, duyệt |

Cách chia vai này **suy ra từ ràng buộc tương phản**, không phải sở thích:

| Cặp màu | Tỉ lệ | Kết luận |
|---|---|---|
| Vàng mật + chữ trắng | 1.58:1 | ✗ Không bao giờ dùng |
| Lá 360 + chữ trắng | 2.13:1 | ✗ Nền sáng phải hạ độ sáng thành `#00851C` (4.80:1) |
| Dương 360 + chữ trắng | 4.65:1 | ✓ Nên nó làm `primary` |
| Vàng mật + chữ đậm | **11.00:1** | ✓ Nút chính dùng cặp này |

Vì vậy **nút chính là vàng mật với chữ đậm**, không phải trắng-trên-`primary`: nút là khối màu
lớn nhất màn hình nên để vàng ở đó thì màu Bé Ong mới thật sự chủ đạo, và cặp này đạt 11.00:1
thay vì 4.65:1.

### Token

| Token | Light | Dark | Dùng cho |
|---|---|---|---|
| `primary` | `#0077CD` | `#3AA0E8` | Chip đang chọn, viền focus, thanh tiến độ |
| `onPrimary` | `#FFFFFF` | `#12082E` | Chữ trên `primary` |
| `primaryContainer` | `#E3F2FD` | `#10365C` | Chip preset, nền icon |
| `surface` | `#FFFFFF` | `#14102A` | Nền màn hình |
| `surfaceVariant` | `#F6F5FC` | `#1E1940` | Card, ô nhập |
| `onSurface` | `#1B1046` | `#F2F0FF` | Chữ chính |
| `onSurfaceMuted` | `#8E8AA8` | `#A7A2C4` | Nhãn phụ (`VIỆC CÓ SẴN`, `ĐIỂM`) |
| `success` | `#00851C` | `#00CE2C` | Đã duyệt, streak |
| `successBright` | `#00CE2C` | `#00CE2C` | Nền trang trí, **chỉ với nội dung đậm** |
| `warning` | `#B55800` | `#FF922B` | Chờ duyệt — cam, tách rõ khỏi vàng xu |
| `danger` | `#E31313` | `#F87171` | Xoá, từ chối, bỏ lỡ |
| `xu` | `#FFC53D` | `#FFD166` | **Nền** đồng xu |
| `xuText` | `#906500` | `#FFD166` | **Chữ số** xu |

`xu` và `xuText` phải tách làm hai token: nền badge xu là `xu` pha mờ 15% nên gần như trắng,
viết số bằng chính `xu` lên đó chỉ đạt 1.47:1 — đọc không được.

### Gradient thẻ Dashboard

Chạy `#0077CD` → `#00851C`, tức dùng đúng hai màu công ty làm nền, còn linh vật vàng đặt lên
trên — vàng và xanh là cặp bù màu nên con ong nổi hẳn. Mọi điểm dọc gradient đạt ≥ 4.65:1 với
chữ trắng, nên chữ trắng đặt ở đâu trên thẻ cũng đọc được. Dùng chung cho cả hai chế độ.

Thân ong màu vàng chỉ đạt 2.94:1 với gradient — dưới ngưỡng 3:1 mà WCAG 1.4.11 đòi cho hình
mang nghĩa (mặt ong chính là cách báo tiến độ cho trẻ chưa đọc số). Vì vậy linh vật có **viền
kem `#FFF6E2` kiểu sticker**; viền là thứ tiếp giáp nền và nó đạt ngưỡng.

### Màu hồ sơ trẻ

8 màu dùng cho avatar, viền card, biểu đồ:
`#0066B0 #E3004D #00851C #9E6606 #047D92 #9B3CF6 #E31313 #0E8074`.
Hai màu đầu và thứ ba lấy từ màu 360 (đã hạ độ sáng cho đủ tương phản).

Ràng buộc: mọi màu hồ sơ đạt contrast **≥ 4.8:1 với chữ trắng** khi làm nền đậm (ngưỡng WCAG AA
là 4.5, chừa biên an toàn). Giá trị được tính bằng cách **hạ độ sáng, giữ nguyên hue/saturation**
cho tới khi đạt ngưỡng.

Toàn bộ ràng buộc màu ở mục này được `test/unit/app_theme_test.dart` kiểm lại ở mỗi lần chạy CI —
đổi màu mà không chạy test là làm chữ không đọc được.

## 2. Chữ

Font: **Nunito** (bo tròn, thân thiện trẻ em, hỗ trợ đầy đủ tiếng Việt có dấu).
Fallback hệ thống: SF Pro / Roboto / Segoe UI.

| Style | Size / Weight / Line-height |
|---|---|
| `displayL` | 32 / 800 / 1.2 — số điểm lớn |
| `titleL` | 24 / 800 / 1.25 — tiêu đề màn hình ("Edit Task") |
| `titleM` | 18 / 700 / 1.3 — tên task trong danh sách |
| `body` | 16 / 500 / 1.5 — chữ thường |
| `label` | 13 / 700 / 1.2, letter-spacing 0.8, **VIẾT HOA** — nhãn nhóm |
| `caption` | 13 / 500 / 1.4 |

Giao diện trẻ dùng cỡ ≥ 16; tôn trọng `textScaleFactor` hệ thống, giới hạn trần 1.6 để không vỡ layout.

### Motif lục giác
Ô lục giác của tổ ong là dấu hiệu nhận diện của Bé Ong. Dùng có chừng mực, chỉ ở ba chỗ:

- **Huy hiệu** — khung lục giác thay vì tròn
- **Lưới nhiệm vụ trên desktop** — các thẻ xếp so le kiểu tổ ong ở breakpoint rộng
- **Hoa văn nền mờ** — opacity ≤ 4%, chỉ ở màn hình trống và màn ăn mừng

Không lục giác hoá nút bấm, avatar hay ô nhập — vùng chạm phải dễ đoán, hình lạ làm trẻ khựng lại.

## 3. Khoảng cách & hình khối

- Thang khoảng cách: `4, 8, 12, 16, 20, 24, 32, 40, 56`
- Lề màn hình: 20 (mobile), 32 (desktop)
- Bo góc: chip/nút = `999` (viên thuốc); card = `20`; ô nhập = `16`; bottom sheet = `28` (trên)
- Đổ bóng: chỉ 1 mức, `0 4 16 rgba(27,16,70,0.08)`. Không dùng bóng đậm.
- Vùng chạm tối thiểu 48×48.

## 4. Component chuẩn

| Component | Mô tả |
|---|---|
| `PresetChip` | Icon + nhãn, viên thuốc, nền `primaryContainer`; khi chọn → nền `primary`, chữ trắng |
| `PointStepper` | `−` / gem + số / `+`; nhấn giữ để tăng nhanh; bước 5; kèm nút `i` mở giải thích |
| `SegmentedPills` | Hàng 2–3 lựa chọn (Once/Daily/Custom, Morning/Afternoon/Evening) |
| `PrimaryButton` | Full-width, cao 56, bo tròn, chữ VIẾT HOA 16/800 |
| `TaskCard` | Icon tròn màu · tên · điểm · checkbox lớn; vuốt trái = sửa, phải = xong |
| `KidHeader` | Avatar + tên + số dư gem + vòng tiến độ ngày |
| `ApprovalCard` | Ảnh/tên task · trẻ · nút Duyệt / Từ chối |
| `RoutineCard` | Icon + tên routine + thanh tiến độ "2/4" + danh sách task con thu gọn được |
| `RoutineProgressRing` | Vòng tròn tiến độ routine; đầy 100% → hiệu ứng phát sáng + hiện điểm bonus |
| `RewardCard` | Icon theo `reward_type` + tên + giá gem; nếu chưa đủ điểm hiện "còn thiếu 30 💎" |
| `XuBadge` | Đồng xu vàng + số; nếu gia đình bật quy đổi thì hiện thêm `≈ 35.000đ` cỡ nhỏ |
| `JarTrio` | Các hũ của con, mỗi hũ một cột mật đầy dần. Số hũ là **dữ liệu**, không cố định 3 (ADR-024) — widget phải chịu được 1 hũ hoặc 6 hũ, và mỗi hũ hiện emoji của nó |
| `GoalCard` | Ảnh món con muốn + thanh tiến độ + "còn 120 xu nữa" |
| `StreakFlame` | Ngọn lửa + số ngày; xám khi streak = 0; nhấp nháy nhẹ khi hôm nay chưa đạt |
| `BadgeGrid` | Lưới huy hiệu, cái chưa đạt hiện dạng bóng mờ + điều kiện đạt |
| `VoucherCard` | Phiếu đã đổi: loại, nội dung, ngày, nút "Đã dùng" |
| `EmptyState` | Minh họa + 1 câu + 1 nút hành động |
| `ResponsiveScaffold` | 1 cột + bottom nav / 2 cột / 3 cột theo breakpoint |

## 5. Icon & preset

24 preset MVP, mỗi cái có `preset_key`, emoji/illustration, điểm mặc định:

| key | Nhãn (vi) | Điểm |
|---|---|---|
| `brush_teeth` | Đánh răng | 10 |
| `make_bed` | Gấp chăn màn | 10 |
| `wash_hands` | Rửa tay | 5 |
| `tidy_room` | Dọn phòng | 25 |
| `put_away_toys` | Cất đồ chơi | 15 |
| `reading` | Đọc sách | 20 |
| `homework` | Làm bài tập | 25 |
| `pack_school_bag` | Soạn cặp sách | 10 |
| `practice_music` | Tập nhạc cụ | 25 |
| `clear_table` | Dọn bàn ăn | 15 |
| `dishwasher` | Rửa/xếp bát | 20 |
| `bedtime_routine` | Đi ngủ đúng giờ | 15 |
| `take_out_trash` | Đổ rác | 15 |
| `be_active` | Vận động | 20 |
| `no_screens` | Không dùng thiết bị | 25 |
| `water_plants` | Tưới cây | 10 |
| `feed_pets` | Cho thú cưng ăn | 10 |
| `walk_dog` | Dắt chó đi dạo | 20 |
| `mow_lawn` | Cắt cỏ | 40 |
| `clear_snow` | Dọn tuyết | 40 |
| `help_cooking` | Phụ nấu ăn | 25 |
| `fold_laundry` | Gấp quần áo | 20 |
| `wipe_floor` | Lau nhà | 30 |
| `kind_act` | Việc tử tế | 15 |

Bổ sung so với app gốc: `help_cooking`, `fold_laundry`, `wipe_floor`, `kind_act`.
Hiển thị 5 preset "gần đây/hay dùng" + nút **More** mở lưới đầy đủ (giữ đúng pattern app gốc,
nhưng 5 preset đầu được xếp theo tần suất dùng của gia đình thay vì danh sách cứng).

## 6. Màn hình chính

### 6.1 Onboarding (3 bước, < 3 phút)
1. Đặt tên gia đình + múi giờ (tự nhận)
2. Thêm trẻ: tên, tuổi, avatar, màu → có thể thêm nhiều
3. Chọn **routine dựng sẵn** (Buổi sáng / Sau giờ học / Trước khi ngủ) — mỗi cái đã có 3–4 task
   phù hợp độ tuổi, bỏ tick task nào không cần → xong, vào Home

> Chọn routine thay vì chọn từng task lẻ: nhanh hơn, và ngay từ phút đầu đã dạy người dùng
> khái niệm cốt lõi của sản phẩm là *thói quen*, không phải *danh sách việc*.

### 6.2 Parent Home
- Header: lời chào + ngày
- **Cần bạn duyệt** (n) — danh sách `ApprovalCard`, có nút "Duyệt tất cả"
- **Hôm nay** — mỗi trẻ 1 hàng: avatar, vòng tiến độ (3/5), điểm hôm nay
- FAB: **+ Task mới**
- Bottom nav: Home · Tasks · Rewards · Thống kê · Cài đặt

### 6.3 Child Home
- `KidHeader`: avatar to, "Chào An!", số gem, `StreakFlame`
- Tab theo buổi: Sáng / Chiều / Tối (chỉ hiện buổi có việc)
- Nội dung mỗi buổi: **`RoutineCard` trước, task lẻ sau**
- `TaskCard` với checkbox lớn; bấm xong → animation confetti + âm thanh + haptic
- `JarTrio` — các hũ của con (số lượng do bố mẹ đặt), bấm vào từng hũ xem chi tiết
- `GoalCard` — món con đang để dành, thanh tiến độ
- Nút **Đổi thưởng** · **Sổ của con** · **Huy hiệu của con**

### 6.3b Routine Editor (phụ huynh)
1. Tên + icon
2. Buổi trong ngày + giờ bắt đầu (dùng để nhắc)
3. Lịch lặp (Daily / Custom)
4. **Danh sách task** — kéo thả đổi thứ tự, thêm từ preset, sửa điểm ngay tại chỗ
5. Điểm thưởng trọn bộ (mặc định 10, đặt 0 để tắt)
6. Gán cho trẻ nào

### 6.4 Task Editor (kế thừa Edit Task của app gốc)
Thứ tự khối, từ trên xuống:
1. `QUICK PRESETS` — 5 chip + More
2. `POINTS` — `PointStepper`
3. `TASK NAME` — ô nhập, tự điền theo preset
4. `REPEAT` — Once / Daily / Custom (Custom mở hàng chọn T2–CN)
5. `TIME OF THE DAY (OPTIONAL)` — Morning / Afternoon / Evening
6. **[Mới] GÁN CHO** — hàng avatar các trẻ, chọn nhiều
7. **[Mới] DUYỆT** — Tự động / Cần bố mẹ duyệt
8. Nút `SAVE` cố định đáy; icon thùng rác ở header khi đang sửa

### 6.5 Rewards
- Lưới `RewardCard`, **nhóm theo `reward_type`** với icon + màu riêng:
  📺 Thời gian giải trí · 💰 Tiền tiêu vặt · 🎡 Trải nghiệm · 🎁 Đồ vật · ⭐ Khác
- Nút "Đổi" mờ nếu chưa đủ điểm — **vẫn hiện thẻ** để tạo động lực, kèm "còn thiếu 30 💎"
- Tab **Phiếu của con**: `VoucherCard` các phần thưởng đã được duyệt, nút "Đã dùng"
- Phụ huynh: thêm/sửa phần thưởng, xử lý yêu cầu đổi (hiện rõ số dư còn lại của trẻ sau khi trừ)

> Phần thưởng `screen_time` hiển thị kèm dòng nhỏ *"Bố mẹ sẽ bật cho con"* — nói rõ đây là
> thỏa thuận giữa người với người, app không tự khóa/mở máy (xem ADR-012).

### 6.5b Sổ của con
Hiện thân của giá trị **minh bạch** (`00-brand-values.md`). Danh sách giao dịch theo thời gian:

- Mỗi dòng: ngày · việc gì · vào hũ nào · +/- bao nhiêu xu · ai duyệt
- Lọc theo hũ, theo tháng. **Không giới hạn thời gian** — con xem lại được từ ngày đầu
- Giao dịch `manual_adjust` **luôn hiện lý do bố mẹ ghi**. Không có lý do thì không lưu được
- Không có nút xóa. Sổ cái là append-only (ADR-005), sửa sai bằng cách ghi một dòng bù

### 6.6 Thống kê (phụ huynh)
- Biểu đồ cột 7 ngày: task hoàn thành theo trẻ
- Tỷ lệ hoàn thành theo task (task nào hay bị bỏ)
- Điểm kiếm được vs. đã tiêu
- Xuất CSV/PDF (v1.2)

## 7. Chuyển động & phản hồi

| Sự kiện | Phản hồi |
|---|---|
| Hoàn thành task | Checkbox nảy (scale 1→1.2→1), confetti 1.2s, haptic `mediumImpact`, tiếng "ting" |
| Được duyệt | Gem bay từ card vào ví, số dư đếm tăng |
| Xong task cuối của routine | Vòng tiến độ đầy → phát sáng → banner "+10 💎 trọn bộ!" |
| Đủ điểm đổi thưởng | Thẻ phần thưởng phát sáng nhẹ |
| Đạt streak 7 ngày | Full-screen badge |
| Nhận huy hiệu mới | Huy hiệu lật từ bóng mờ sang màu, 1 lần |

Thời lượng chuẩn: 150ms (chuyển trạng thái nhỏ), 250ms (chuyển màn), 1200ms (ăn mừng).
Tôn trọng `MediaQuery.disableAnimations` / Reduce Motion → tắt confetti, giữ haptic.

## 8. Khả dụng

- Contrast text ≥ 4.5:1, nhãn muted ≥ 3:1 (chỉ dùng cho chữ ≥ 13/700)
- Mọi icon-only button có `Semantics(label:)`
- Không truyền tải thông tin **chỉ** bằng màu (trạng thái task luôn kèm icon + chữ)
- Hỗ trợ điều hướng bàn phím đầy đủ trên desktop; focus ring rõ 2px `primary`
