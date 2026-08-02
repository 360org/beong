# 00 — Giá trị thương hiệu Bé Ong

Tài liệu này đứng trên mọi tài liệu khác. Khi có tranh luận về tính năng hay thiết kế,
quy chiếu về đây trước.

---

## Kim chỉ nam: **Độc lập — Tự lập**

Mục tiêu cuối cùng của Bé Ong là **đứa trẻ không cần Bé Ong nữa**.

Đây không phải khẩu hiệu. Nó là một ràng buộc thật, và nó mâu thuẫn trực tiếp với chỉ số
giữ chân người dùng mà mọi app đều đuổi theo. Ta chấp nhận mâu thuẫn đó: nếu một tính năng
làm trẻ phụ thuộc vào app để chịu làm việc nhà, tính năng đó sai — kể cả khi nó làm số liệu
đẹp lên.

**Phép thử:** *"Tính năng này giúp con tự làm được, hay khiến con cần app hơn?"*

---

## Bốn giá trị

### 1. Học tập
Trẻ học bằng cách **làm và chịu trách nhiệm**, không phải bằng cách được nhắc.

Hệ quả thiết kế:
- Cho phép thất bại. Bỏ lỡ một ngày không phải thảm họa — streak có ngày ân hạn (ADR-013)
- Không có "trừng phạt" mặc định. Trừ điểm là tùy chọn, mặc định tắt
- Task và mức điểm gợi ý theo độ tuổi: việc phải vừa sức thì trẻ mới học được điều gì đó

### 2. Tự lập
App là **giàn giáo**, không phải cái nạng. Giàn giáo được dựng lên để rồi tháo đi.

Hệ quả thiết kế:
- Bố mẹ giao việc và duyệt, **không làm thay**. Không có nút "đánh dấu hộ con" đặt ở chỗ dễ bấm
- Trẻ tự vào app bằng hồ sơ riêng, tự bấm hoàn thành, tự quyết định đổi thưởng gì
- Nhắc nhở tối đa 2 lần/ngày. Nhắc nhiều là cằn nhằn tự động — đúng thứ app sinh ra để thay thế
- Càng lớn càng ít can thiệp: đường hướng là mở dần quyền tự duyệt cho trẻ lớn

### 3. Minh bạch
Đứa trẻ phải **luôn kiểm chứng được** số điểm của mình đến từ đâu. Không có con số nào rơi
từ trên trời xuống, không có ai lặng lẽ sửa.

Hệ quả thiết kế:
- **Sổ cái append-only** (ADR-005): mọi thay đổi điểm là một dòng có ngày, lý do, ai duyệt.
  Số dư là tổng của sổ cái, không phải một con số bị ghi đè
- **Chốt giá lúc giao việc** (ADR-007): bố mẹ đổi giá task không làm thay đổi lịch sử con đã làm
- Màn **"Sổ của con"** xem được toàn bộ lịch sử, không giới hạn thời gian
- Phụ huynh điều chỉnh điểm thủ công **bắt buộc ghi lý do**, và lý do đó hiện cho trẻ thấy

> Minh bạch ở đây là **cam kết đạo đức với đứa trẻ**, không phải yêu cầu kỹ thuật.
> Một đứa trẻ bị sửa điểm không lý do sẽ học được đúng một bài: luật là thứ người lớn tùy tiện đổi.

### 4. Đồng hành
Con ong thợ tự bay đi tìm mật, rồi mang về tổ. Bố mẹ bay cùng, không bay hộ.

Hệ quả thiết kế:
- Duyệt việc là **khoảnh khắc gặp nhau**, không phải thủ tục hành chính. Cho phép kèm lời khen
- Không xếp hạng giữa các con trong nhà, không so sánh giữa các gia đình
- Thống kê cho phụ huynh là để **hiểu con**, không phải để chấm điểm con
- Nhiều phụ huynh/người chăm sóc cùng tham gia được

---

## Những điều Bé Ong không làm

| Không làm | Vì sao |
|---|---|
| Quảng cáo, tracking bên thứ ba | Người dùng là trẻ em (ADR-010) |
| Xếp hạng, bảng vàng, so sánh giữa các bé | Động lực phải đến từ bên trong, không từ việc thua bạn |
| Cưỡng chế khóa thiết bị | Kỷ luật bằng công nghệ không dạy được tự lập (ADR-012) |
| Thông báo dồn dập | Thay cằn nhằn của bố mẹ bằng cằn nhằn của máy thì vô nghĩa |
| Sửa điểm không dấu vết | Phá vỡ minh bạch |
| Cơ chế gây nghiện (chuỗi ép buộc, phần thưởng ngẫu nhiên) | Kim chỉ nam là để trẻ *rời được* app |

---

## Hình ảnh thương hiệu

**Bé Ong** — "chăm chỉ như ong" là thành ngữ ai cũng hiểu, không cần giải thích.

| Hình ảnh | Ánh xạ vào sản phẩm |
|---|---|
| Ong thợ bay đi tìm mật | Con tự làm việc — **tự lập** |
| Mang mật về tổ | **Đồng hành** — làm cho mình và cho cả nhà |
| Mật tích trong tổ | Hũ tiết kiệm — thành quả nhìn thấy được |
| Ô lục giác của tổ ong | Motif thiết kế: lưới nhiệm vụ, huy hiệu, biểu đồ |

Câu chuyện kể ở **con ong đang bay**, không ở cái tổ — nhấn vào cá nhân tự lập, tránh hàm ý
"làm vì tập thể" vốn ngược với kim chỉ nam.

**Giọng nói:** ấm, ngắn, không giáo điều. Nói với trẻ như nói với một người có khả năng,
không phải như ra lệnh. Không dùng chữ "phải", "bắt buộc" trong giao diện của trẻ.

**Tagline:** *Con tự bay, bố mẹ bay cùng.*
