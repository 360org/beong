# Changelogs — Bé Ong

Toàn bộ lịch sử phát triển, nâng cấp tính năng, cải tiến giao diện và sửa lỗi của dự án **Bé Ong** (Flutter Mobile Client) được quản lý tập trung và chuẩn hoá theo quy chuẩn AIaC.

---

## v0.7.12+46 (2026-08-30) — Chọn hũ cho bé mới, và thêm được ông bà

Hai việc chủ dự án nêu 30/08/2026.

### Chọn bé mới dùng những hũ nào

*"Khi tạo profile cho trẻ phải có option để chọn bao nhiêu hũ — ví dụ tổng hũ
đã tạo có 8 hũ, chọn 3 hũ cho profile cần tạo."*

Bảng **Thêm bé** nay liệt kê toàn bộ hũ của nhà kèm ô tick. Bỏ bớt hũ bé chưa
cần thì phần trăm của các hũ còn lại **tự chia cho đủ 100%**, xem trước được
từng con số trước khi lưu. Nhà có 8 hũ cho bé lớn thì bé ba tuổi không cần cả
8 — 8 ô hũ trên màn của bé chỉ làm loãng thứ bé thật sự hiểu.

Giữ nguyên cả bộ thì **không** tách bộ riêng: bé dùng chung bộ của nhà, đúng
như trước. Ô cuối cùng bị khoá lại — phải còn ít nhất một hũ, nếu không xu của
bé không có chỗ nào chứa.

### Thêm người lớn cùng quản lý

*"Có thể tạo thêm profile cùng quản lý parent, ví dụ: bố / mẹ / ông / bà."*

**Cài đặt → Thêm người lớn**, đứng ngay cạnh "Thêm bé". Có sẵn chip điền nhanh
Bố / Mẹ / Ông / Bà, và gõ tay được cho nhà gọi khác đi ("Bà ngoại", "Cậu").

Mọi hồ sơ người lớn có **cùng quyền** — không có bậc "chủ nhà". Phân quyền
giữa những người lớn trong cùng một nhà là thứ app này không nên đứng ra phân
xử. Hồ sơ người lớn bắt buộc có mật khẩu (ADR-027): nó duyệt việc và cộng xu
được, nên để trống là mở cửa cho bất kỳ ai cầm máy — kể cả chính đứa trẻ đang
chờ được duyệt.

---

## v0.7.11+45 (2026-08-30) — Gán buổi cho bé thì bé có việc ngay

Chủ dự án: *"trong tab tasks đã chọn session cho tất cả rồi nhưng trong
profile của bé mới vẫn empty."*

Gán một buổi cho thêm một bé thì **toàn bộ việc trong buổi đó** về tay bé,
hiện ngay trên hồ sơ — không phải chờ tới hôm sau nữa.

Gốc không nằm ở chỗ ghi người nhận: chỗ đó vẫn ghi đúng, và màn Nhiệm vụ hiện
"Tất cả" cũng đúng. Nó nằm ở chỗ bộ sinh lượt việc chạy **một lần mỗi ngày**.
Đổi người nhận giữa ngày thì bé mới không có lượt nào cho tới hôm sau, trong
khi màn Nhiệm vụ đã ghi tên bé vào buổi rồi — hai màn nói ngược nhau và bố mẹ
không có cách nào biết ai đúng.

Việc này cũng vá luôn cảnh cũ hơn: bé được gán vào buổi từ trước nhưng chưa
từng có lượt nào sinh ra. Chạy thử trên dữ liệu thật, một bé đang "0 / 0 việc
hôm nay" nhận đủ 8 việc ngay sau khi lưu.

---

## v0.7.10+44 (2026-08-30) — Tổng xu của con nằm ngay cạnh tên

Chủ dự án: *"phần thống kê trên header profile nên show total xu."*

Nay tổng xu đứng ngay sau tên bé ở màn **Thống kê**, cập nhật cùng lúc với
các ô hũ.

Đi tìm thì hoá ra tổng **đã có** — nhưng nằm chung một dòng với giá trị quy
đổi tiền, và cả dòng ấy ẩn đi khi nhà tắt quy đổi. Quy đổi mặc định tắt, nên
với hầu hết các nhà tổng xu không hiện ở đâu cả: muốn biết con có bao nhiêu
thì phải tự cộng nhẩm năm ô hũ. Nay tổng luôn hiện; giá trị tiền mới là phần
tuỳ chọn đi kèm, không phải cái quyết định tổng có được thấy hay không.

Việc này cũng vá luôn màn **Sổ của con**: chính con cũng không thấy được tổng
xu của mình khi nhà chưa bật quy đổi.

Ở màn bố mẹ, dòng tổng dưới các ô hũ được bỏ đi vì tổng đã nằm trên đầu — cùng
một con số in hai lần cách nhau nửa gang tay thì người đọc phải dừng lại kiểm
xem có phải hai thứ khác nhau không.

---

## v0.7.9+43 (2026-08-30) — Hàng chờ duyệt nói rõ là việc của bé nào

Chủ dự án: *"phần approve công việc không hiển thị là duyệt cho profile
nào?"*

Nhà hai bé mà thẻ chờ duyệt chỉ ghi *"Cất đồ chơi +5 xu"* thì bố mẹ đang duyệt
mù — cộng xu cho một đứa trẻ mà không có cách nào biết là đứa nào. Nay tên và
hình đại diện của bé đứng **trên** tên việc: câu hỏi đầu tiên khi nhìn hàng chờ
là "của đứa nào", trả lời nó rồi mới tới "việc gì".

Nhà chỉ có một bé thì không hiện tên — nó lặp lại một điều đã hiển nhiên, và
một dòng chữ không mang tin nào là một dòng người đọc học cách bỏ qua.

Sửa kèm cùng lỗ hổng ở chỗ nguy hơn: nút **Duyệt hết** cộng xu cho nhiều bé
cùng lúc và không có hoàn tác, nhưng câu xác nhận chỉ ghi *"5 việc sẽ được
duyệt và cộng xu cho con"*. Nay nó gọi tên đúng những bé đang có việc chờ —
và chỉ những bé đó, không gọi tên bé không làm gì.

---

## v0.7.8+42 (2026-08-30) — Link điều khoản / quyền riêng tư bấm được

Chủ dự án: *"link điều khoản / riêng tư không click được."*

Đúng vậy — địa chỉ trong hai hộp thoại ấy chỉ là **chữ nằm lẫn trong đoạn
văn**: trông như link, đọc như link, bấm vào không có gì xảy ra. Với một địa
chỉ dài kiểu `beong.net/quyen-rieng-tu.html` thì không ai chép tay sang trình
duyệt, nghĩa là hai trang đó coi như không tồn tại với người dùng.

Nay mỗi hộp thoại có một dòng riêng — gạch chân, mũi tên chéo, cao đủ 48dp —
bấm vào là mở trình duyệt. Dòng **Liên hệ hỗ trợ** cũng vậy: trước đây
`info@beong.net` hiện ra rồi bấm không ra gì, nay mở thẳng app thư.

Mở hụt thì app **nói ra**, kèm nguyên địa chỉ và chép sẵn vào bộ nhớ tạm. Máy
không có trình duyệt mặc định, hoặc không có app thư nào, là chuyện có thật;
bấm mà không thấy gì thì người dùng bấm lại vài lần rồi kết luận app hỏng.

---

## v0.7.7+41 (2026-08-30) — Tự nhập tỷ giá quy đổi xu

Chủ dự án: *"chỗ quy đổi xu phải có option cho người dùng chọn nhập số quy
đổi."*

Bảng **Quy đổi tiền thật** trước đây chỉ có sáu mức đóng: 1, 2, 5, 10, 20, 50
xu ăn 1.000 đ. Nhà nào đặt 3, 15 hay 100 thì không có cách nào nói ra con số
của mình. Nay cuối bảng có dòng **Tự nhập số khác** — gõ thẳng con số, và
trước khi lưu app cho xem *"con có 100 xu thì ≈ bao nhiêu đồng"*, để bố mẹ
thấy tỷ giá mình vừa đặt nghĩa là gì chứ không phải đoán.

Số gõ vào được kiểm trước khi lưu: nhận số có dấu chấm ngăn nghìn theo lối
viết tiếng Việt (`1.000`), từ chối số 0, số âm, chữ và số vượt 100.000. Riêng
số 0 là quan trọng nhất — tỷ giá nằm dưới mẫu của phép chia, nên một số 0 lọt
qua làm hỏng mọi màn có hiện tiền.

Sửa kèm: mức đang đặt mà không nằm trong sáu lối tắt thì bảng chọn không đánh
dấu ở đâu cả, trông như nhà này chưa đặt gì trong khi tỷ giá vẫn đang chạy.
Nay nó hiện ngay trên dòng tự nhập, kèm dấu tích.

---

## v0.7.6+40 (2026-08-30) — Bỏ màn quản lý hũ trong Cài đặt

Chủ dự án: *"phần cấu hình các hũ trong Cài đặt → Các hũ bỏ đi vì đã cấu hình
ngay trong màn hình Thống kê rồi."*

Cả việc thêm, sửa tên, đổi hình, chỉnh tỷ lệ và ngừng dùng hũ nay chỉ còn một
chỗ: màn **Thống kê**. Bấm thẳng vào hũ để sửa, nút **THÊM HŨ** để thêm. Bộ hũ
ở đó là bộ **riêng của từng bé**, đúng thứ bố mẹ đang nhìn khi bấm vào.

Vì sao bỏ hẳn chứ không để cả hai: màn cũ làm việc với bộ hũ **chung của cả
nhà**, còn màn Thống kê làm việc với bộ của từng bé. Hai màn tên giống nhau,
sửa hai thứ khác nhau, không màn nào nói ra điều đó — sửa ở màn này rồi không
thấy đổi ở màn kia là chuyện sớm muộn.

Bảng "Thêm hũ mới" bỏ theo lựa chọn **"Tự chỉnh"**: nó tạo hũ 0% rồi mở màn
quản lý hũ để bố mẹ tự phân, mà màn đó nay không còn — để lại thì nó tạo ra
một hũ 0% không có chỗ nào sửa. Hũ mới luôn nhận phần trăm chọn trên thanh
trượt và các hũ khác tự trừ theo tỷ lệ, có bảng xem trước; muốn tỷ lệ khác thì
sửa từng hũ, mỗi lần sửa cũng tự cân lại về đúng 100%.

---

## v0.7.5+39 (2026-08-30) — Hai vạch kéo/thả chỉ hiện lúc đang kéo

Màn Nhiệm vụ: mỗi thẻ buổi trước đây đeo sẵn một cái tay kéo ở mép phải, lúc
nào cũng có. Nay danh sách ở trạng thái nghỉ sạch hoàn toàn — hai vạch chỉ
hiện ra **trong lúc bố mẹ giữ và kéo** một buổi, rồi mờ đi khi thả.

Kéo vẫn dễ hơn trước chứ không khó hơn: giữ lâu ở **bất cứ đâu trên thẻ** là
nhấc được, không phải ngắm trúng một cái tay nhỏ ở mép. Chạm nhanh vẫn rơi
xuống các nút trong thẻ như thường, nên bấm +/− không thành kéo nhầm.

Thẻ đang kéo nhấc nhẹ lên 3% kèm bóng đổ, đủ để thấy nó rời khỏi danh sách mà
không che mất hai thẻ hàng xóm — chỗ bố mẹ đang nhắm để thả vào.

---

## v0.7.4+38 (2026-08-30) — Sửa lỗi đổi tên hũ không lưu được

Đổi tên một hũ rồi bấm LƯU, tên cũ quay lại. Không có thông báo lỗi nào — bảng
đóng lại như thể đã lưu xong.

**Nguyên nhân:** bé chưa có bộ hũ riêng thì cái hũ bố mẹ đang nhìn là hàng
**chung của cả nhà**, trong khi lệnh ghi lại tìm hàng thuộc riêng bé đó. Không
có hàng nào khớp, nên lệnh ghi thành công vào... không gì cả. Im lặng — kiểu
hỏng khó nhận ra nhất, vì mọi thứ trông như đã chạy.

Nay lần đầu sửa hũ cho một bé, cả bộ chung được sao chép sang cho bé đó rồi
mới sửa — đúng như khi thêm hũ mới. Bảng sửa nói *"Hũ của NEO, các bé khác
không đổi"*, và giờ nó đúng như vậy thật.

Cùng lỗi ấy cũng làm nút **Ngừng dùng hũ** không ăn ở lần bấm đầu; đã sửa
chung.

---

## v0.7.3+37 (2026-08-30) — Trả việc lại cho con, ngay trên hàng của nó

Con bấm xong nhưng chưa xong thật — nay bố mẹ xử lý ngay tại hàng việc đó,
không phải đi lên hàng đợi ở đầu màn hình.

Có **hai** đường, và hậu quả về xu khác hẳn nhau:

- **Trả lại** một việc đang *chờ duyệt*: chưa cộng xu nên **không trừ gì**.
  App nói thẳng điều đó ra sau khi bấm.
- **Cho làm lại** một việc *đã duyệt*: xu đã vào túi con rồi, nên có trừ theo
  mức gia đình đặt trong Cài đặt → Trừ xu. Mặc định là 0% — không nhà nào bị
  bật tính năng trừ xu mà không tự chọn.

### Đã kiểm những gì

Bảy bài kiểm mới đi qua đúng cái cửa mà nút bấm gọi, không phải gọi tắt xuống
tầng dưới:

- trả lại việc chờ duyệt **không** trừ xu, kể cả khi mức trừ đang bật 50%;
- bật 50% thì cho làm lại một việc 20 xu mất đúng 10;
- trừ theo số xu **của lượt đó**, không theo giá việc hiện tại — tăng giá một
  việc không được trừ ngược vào xu con đã kiếm;
- làm lại hai lần thì trừ hai lần;
- **không bao giờ trừ xuống âm**: số dư âm là thứ không giải thích được cho
  một đứa trẻ.

---

## v0.7.2+36 (2026-08-30) — Mỗi buổi nói rõ đang giao cho bé nào

Thẻ buổi ở tab Nhiệm vụ nay có một dòng dưới tên: *"Sau giờ học · Tất cả"*,
*"Buổi sáng · NEO"*.

Không có dòng đó thì hai buổi trông y hệt nhau trong khi một buổi chỉ của một
bé và buổi kia của cả nhà. Tệ hơn: buổi **chưa giao cho ai** cũng trông y hệt,
dù không bé nào nhìn thấy việc trong đó — nay nó hiện *"Chưa giao cho bé nào"*
bằng màu cảnh báo.

Nhà chỉ có một bé thì không hiện dòng này: cùng một cái tên lặp trên mọi thẻ
mà không nói thêm được gì.

---

## v0.7.1+35 (2026-08-30) — Kéo thả để sắp xếp buổi thói quen

Ở tab Nhiệm vụ, giữ và kéo một buổi để đổi chỗ. Thứ tự được ghi lại và giữ
nguyên qua những lần mở app sau.

Trước đây thứ tự là thứ tự bản ghi trong cơ sở dữ liệu — tức thứ tự tạo, gần
như ngẫu nhiên với người dùng: chủ dự án thấy *"Trước khi ngủ"* đứng trên
*"Sau giờ học"*.

Nhà đang dùng bản cũ nâng lên **không thấy một mớ lộn xộn**: các buổi được xếp
sẵn theo giờ trong ngày (sáng → trưa/chiều → tối → buổi không đặt giờ), cùng
hạng thì theo tên. Đó là thứ tự người ta mong đợi thấy lần đầu; kéo lại được
ngay nếu không ưng.

Buổi tạo mới xuống **cuối** danh sách, không chen lên đầu — chen lên đầu thì
mỗi lần thêm một buổi là thứ tự vừa xếp bị xáo.

---

## v0.7.0+34 (2026-08-30) — Thẻ con ở Trang chính chính là màn lịch sử

Mở một thẻ con ở Trang chính, bố mẹ nay thấy **đúng thứ** màn lịch sử chi tiết
vẫn hiện: thẻ tóm tắt *Tổng việc / Đã hoàn thành / Tỷ lệ*, rồi việc chia theo
Buổi Sáng, Buổi Trưa / Chiều, Buổi Tối, Cả Ngày & Thói Quen.

Không phải "trông giống" — hai chỗ nay dùng **chung một** thành phần. Dựng lại
cùng một bố cục bằng hai đoạn mã khác nhau là cách chắc chắn để chúng lệch
nhau sau vài lần sửa, và bố mẹ thì phải học hai giao diện cho cùng một thứ.

### Vuốt trái / phải để đi giữa các ngày

Vuốt phải lùi về hôm qua, vuốt trái quay lại. Nội dung ngày cũ trượt ra, ngày
mới trượt vào **từ đúng phía ngón tay vừa đi tới** rồi hiện dần — một cú hé
sang ngày bên cạnh, không phải một cú chuyển màn. Không có hoạt ảnh thì nội
dung nhảy một cái và người dùng không kịp nhận ra mình vừa sang ngày khác hay
app vừa tải lại.

Nút mở lại một việc đã xong chuyển vào đúng hàng của việc đó, thay cho mục
"Đã xong hôm nay" gập lại ở cuối thẻ — mục đó đi cùng bố cục cũ, giữ lại là
hiện việc đã xong hai lần trên cùng một thẻ.

---

## v0.6.3+33 (2026-08-30) — Màn hình của con chia việc theo buổi

Con đang thấy một danh sách phẳng: *"Cần làm 22"* rồi 22 thẻ nối nhau, không
đầu không cuối. Bố mẹ nhìn cùng một ngày ở Trang chính thì đã thấy việc nhóm
theo buổi từ lâu.

Nay việc của con cũng chia theo buổi, xếp đúng thứ tự trong ngày: sáng, trưa /
chiều, tối, rồi tới các buổi không đặt giờ, cuối cùng là việc chưa thuộc buổi
nào. Mỗi buổi có tên, hình và số việc **của riêng buổi đó**.

Lý do không chỉ là gọn mắt: với đứa trẻ chưa đọc trôi chảy, *"còn 22 việc"* là
một con số làm nản, còn *"buổi sáng còn 3 việc"* là một việc làm được.

Nhà chỉ có đúng một buổi thì không hiện tiêu đề buổi — nó chỉ lặp lại chữ
"Cần làm" ngay phía trên.

---

## v0.6.2+32 (2026-08-30) — Sửa và ngừng dùng hũ ngay trên màn Thống kê

Bấm vào một thẻ hũ ở màn Thống kê để đổi tên, đổi hình, đổi tỷ lệ, hoặc ngừng
dùng hũ đó. Trước đây không có đường nào: màn quản lý hũ ở Cài đặt vẫn còn,
nhưng nó làm việc với bộ hũ **chung của cả nhà** — mà từ bản 0.5.0 mỗi bé có
bộ riêng, nên nó không với tới được cái hũ bố mẹ đang nhìn.

Chỉ bố mẹ bấm được. Con xem được số dư của mình nhưng không tự đổi luật chia
xu.

### Tổng luôn được giữ đúng 100%

Đây là ràng buộc chi phối cả màn này, vì tổng khác 100% thì tầng chia xu lặng
lẽ quay về tỷ lệ mặc định và mọi con số bố mẹ vừa đặt biến mất không một lời
báo.

- Đổi tỷ lệ hũ này ⇒ các hũ còn lại tự chia nhau phần thiếu, kèm bảng
  "trước → sau" và một dòng tổng để bố mẹ thấy con số tự đổi chứ không phải
  đoán.
- Ngừng dùng hũ ⇒ phần trăm của nó chia lại cho các hũ còn lại. Không trả về
  đâu cả là để lại một lỗ thủng đúng bằng tỷ lệ nó từng giữ.
- Hũ cuối cùng không ngừng dùng được, và thanh tỷ lệ của nó bị khoá: không còn
  ai nhận phần còn lại.

Hũ chỉ **ngừng dùng**, không xoá — số xu đang có và lịch sử vẫn còn nguyên.

---

## v0.6.1+31 (2026-08-30) — Vuốt ngang đổi ngày ngay trên thẻ

Vuốt ngang trên thẻ con ở Trang chính trước đây mở một **hộp thoại** phủ lên
màn hình. Đó vẫn là rời khỏi màn hình đang xem, chỉ khác cách mở.

Nay vuốt sang phải là thẻ **đổi ngay nội dung** sang hôm qua, vuốt tiếp là lùi
thêm một ngày, vuốt trái quay lại. Có một dòng nhỏ ghi rõ đang xem ngày nào —
cú vuốt là cử chỉ không nhìn thấy được, vuốt nhầm mà không có dòng đó thì bố
mẹ đọc số liệu cũ tưởng là hôm nay. Kèm nút "Về hôm nay" cho ai lỡ vuốt xa, và
nút "Chi tiết" mở bảng thống kê theo tuần — phần đó chỉ có ở bảng đầy đủ.

### 🐛 Sửa: việc bỏ lỡ bị đếm là đã xong

Lỗi này lộ ra ngay khi xem được ngày cũ: một ngày con **không làm gì cả** hiện
"5/5" kèm dấu tích xanh, trong khi dòng đầu thẻ ghi "0/12 việc" — hai con số
mâu thuẫn trên cùng một thẻ.

Thẻ đang lấy "khác *chưa tới lượt*" làm "đã xong", nên việc **bỏ lỡ** và việc
**bị từ chối** cũng được tính là xong. Lỗi nằm im chừng nào thẻ chỉ hiện hôm
nay, vì việc hôm nay chưa kịp bị đánh dấu bỏ lỡ.

Nay chỉ việc đã duyệt hoặc đang chờ duyệt mới tính là xong. Việc bỏ lỡ mang
dấu ✗ đỏ, không phải dấu tích xanh.

---

## v0.6.0+30 (2026-08-30) — Không còn việc trùng tên trong một buổi

Buổi "nữa đêm" của một bé đang có **"Mặc đồ ngủ" hai lần**: hai việc y hệt,
con phải bấm hai lần, và xu cộng gấp đôi cho cùng một hành động. Bản này chặn
cả hai đầu.

### Chặn từ chỗ tạo

Tạo một việc trùng tên với việc đã có **trong cùng buổi** sẽ bị từ chối, kèm
câu nói rõ lý do — không im lặng đóng bảng, vì im lặng thì bố mẹ tưởng đã tạo
xong, đi tìm không thấy, rồi tạo lại lần nữa.

Chặn nằm ở tầng dữ liệu chứ không ở từng màn hình: app có **bốn** đường tạo
việc, vá từng chỗ thì chỗ thứ năm lại quên. So tên bỏ qua hoa thường và khoảng
trắng thừa — "Mặc đồ ngủ" và " mặc đồ ngủ " là một việc.

Chỉ xét trong cùng một buổi: hai bé cùng phải đánh răng ở hai buổi khác nhau
là hai việc khác nhau, không phải bản sao.

### Dọn đống đã có

Mỗi lần mở app, việc trùng tên trong cùng một buổi được tắt bớt, **giữ cái tạo
trước** — lượt việc và các dòng trong "Sổ của con" đã trỏ vào nó lâu hơn. Bản
trùng bị **tắt chứ không xoá**: xoá đi thì lịch sử mất tên việc, con nhìn lại
chỉ thấy một dòng cộng xu không rõ từ đâu.

---

## v0.5.4+29 (2026-08-30) — Nút "+" mở thẳng bảng thêm việc

Bấm "+" ở tab Nhiệm vụ trước đây hỏi *"Thêm gì?"* — thêm việc hay thêm buổi.
Câu hỏi đó có lý khi nút này là đường duy nhất tạo được cả hai. Nay đường tạo
buổi đã có chỗ riêng ở cuối danh sách buổi, nên hỏi lại là bắt bố mẹ trả lời
một câu họ vừa trả lời bằng chính cú bấm của mình.

Nút "+" giờ mở thẳng bảng thêm việc. Tạo buổi vẫn ở dòng "Tạo thêm thói quen"
cuối danh sách.

---

## v0.5.3+28 (2026-08-30) — Sửa buổi thói quen: giao cho bé, và ngừng dùng

Bảng "Sửa thói quen" trước đây chỉ đổi được tên, hình và mức thưởng trọn bộ.
Hai việc bố mẹ cần nhất lại không có:

- **Giao buổi cho bé nào.** Buổi tạo xong là cố định người nhận; muốn đổi thì
  không có đường nào. Nay chọn ngay trong bảng, và có cảnh báo rõ khi bỏ chọn
  hết: buổi không giao cho ai thì **không bé nào nhìn thấy việc trong đó**.
- **Ngừng dùng buổi.** Đường này vốn đã có, nhưng nằm ở một biểu tượng không
  nhãn trên thanh tiêu đề — không ai tìm ra. Nay có thêm nút chữ rõ ràng ngay
  dưới nút LƯU.

Câu xác nhận khi ngừng dùng cũng được sửa cho đúng hành vi hiện tại: việc bên
trong chuyển sang buổi "Việc khác", chứ không còn thành việc lẻ trôi nổi như
mô tả cũ.

---

## v0.5.2+27 (2026-08-30) — Vuốt ngang xem lịch sử, lần này vuốt thật sự ăn

Tính năng "vuốt ngang trên thẻ con để xem lịch sử" đã được báo là làm xong ở
bản 0.5.0, nhưng trên máy thật **vuốt không ăn**. Hai nguyên nhân, cả hai đều
là lỗi của cách làm chứ không phải của ý tưởng:

- **Cử chỉ chỉ gắn vào dải chữ tên con** — một dải cao chừng 40px. Vuốt qua
  thân thẻ, nơi có danh sách việc và chiếm gần hết diện tích, thì không chỗ
  nào nhận. Nay cả thẻ nhận cú vuốt.
- **Chỉ nhận cú vẩy nhanh.** Vuốt chậm mà dứt khoát — kéo từ từ sang phải rồi
  nhấc tay — bị bỏ qua. Nay nhận *hoặc* đi đủ xa *hoặc* vẩy đủ nhanh.

Ngưỡng vẫn đủ cao để cuộn danh sách hơi chéo tay không làm bật lịch sử lên;
điều đó có bài kiểm riêng, vì ngưỡng quá thấp còn phiền hơn là thiếu tính
năng.

### Ghi lại cho lần sau

Phần "cử chỉ gắn nhầm chỗ" **không bài kiểm tự động nào bắt được** — nó chỉ
lộ ra khi vuốt trên app thật. Phần ngưỡng thì kiểm được, và nay đã có 6 bài
kiểm. Lần này đã vuốt thử trên app thật ở cả hai kiểu: vuốt chậm giữa thân
thẻ (mở đúng lịch sử) và cuộn dọc hơi chéo tay (không bật gì).

---

## v0.5.1+26 (2026-08-30) — Sửa màn hình trắng khi nâng cấp từ bản cũ

**Bản 0.5.0 không mở được trên máy đã cài bản trước đó.** Máy cài mới thì chạy
bình thường, nên lỗi lọt qua toàn bộ khâu kiểm.

### Chuyện gì xảy ra

Bản 0.5.0 đổi cấu trúc bảng hũ để mỗi bé có bộ riêng. Bước nâng cấp cơ sở dữ
liệu bảo hệ thống chép dữ liệu cũ sang bảng mới — nhưng chép **cả cột vừa mới
thêm**, cột chưa từng tồn tại ở bản cũ. Cơ sở dữ liệu từ chối, app chết ngay
lúc mở, trước khi kịp vẽ bất cứ thứ gì. Người dùng thấy một màn hình trắng
không có lấy một dòng thông báo.

### Vì sao khâu kiểm không bắt được

Hàm dựng "cơ sở dữ liệu phiên bản cũ" trong bộ kiểm thử thiếu đúng một bước:
nó không gỡ cột mới xuống, nên bảng "phiên bản cũ" giả vẫn có sẵn cột đó. Câu
lệnh chép chạy được trong phòng thí nghiệm và chỉ hỏng ngoài đời. Bộ kiểm thử
nay dựng lại đúng bảng của bản cũ, và có thêm hai bài kiểm riêng cho đúng bước
nâng cấp này — đã thử gỡ bản sửa ra để chắc chúng đỏ thật.

Dữ liệu **không mất**: lỗi xảy ra trước khi ghi bất cứ thứ gì. Cài đè bản này
lên là mở lại được như cũ.

---

## v0.5.0+25 (2026-08-30) — Mỗi bé một bộ hũ, và những lối ra bị bịt

Bản này gỡ đúng những chỗ người dùng bị **kẹt**: bảng trượt không có nút tắt,
thông báo nằm lì che nội dung, nút LƯU bị đẩy khỏi màn hình. Cộng thêm một
tính năng đã hứa từ v0.4.0 mà lúc đó chưa làm được.

### ✨ Mới

- **Mỗi bé một bộ hũ riêng.** Bảng "Thêm hũ mới" có mục *"Hũ này của ai"* —
  Cả nhà, hoặc một bé cụ thể. Một bé để dành mua xe đạp trong khi bé kia để
  dành mua sách; ép cả nhà dùng chung một bộ hũ là ép hai đứa trẻ tiết kiệm
  cho cùng một thứ. (Schema v9. Đây là giới hạn đã ghi rõ trong changelog
  v0.4.0 là *chưa làm được, cần chủ dự án chốt hướng*.)
- **Dòng "Tạo thêm thói quen"** ở cuối danh sách buổi trong tab Nhiệm vụ. Bảng
  tạo buổi nay **thêm việc được luôn** — tên, hình, xu — thay vì tạo buổi
  trống rồi đi tìm chỗ khác để thêm việc.
- **Chạm tên con ở Trang chính để gập/mở danh sách việc.** Thẻ một bé có thể
  dài tới 37 việc; nhân với số con thì phần "chờ duyệt" ở trên bị đẩy khỏi
  tầm mắt.

### 🔧 Đổi

- **Mọi bảng trượt lên đều có nút tắt.** 30 chỗ, 21 file, mỗi chỗ trước đây tự
  dựng đầu trang một kiểu. Nay đi chung qua một `SheetHeader`. Ngoại lệ duy
  nhất: đặt mật khẩu lần đầu ở onboarding — ADR-027 nói không hồ sơ nào được
  để trống mật khẩu.
- **Thông báo tự tắt sau 3 giây** thay vì 4, và thông báo mới đẩy cái cũ đi
  thay vì xếp hàng. Bấm nhanh ba nút mà xếp hàng thì thanh cuối còn nằm đó sau
  chín giây.
- **Vuốt ngang trên thẻ con để xem lịch sử**; bỏ biểu tượng lịch.
- Bỏ mục "Chưa xếp buổi" khỏi tab Nhiệm vụ. Việc rơi ra khỏi buổi giờ được tự
  nhận về buổi "Việc khác" mỗi lần mở app.
- Nhiều bảng chọn ở Cài đặt lần đầu có tiêu đề ("Giờ đổi ngày", "Múi giờ",
  "Giao diện", "Chọn hồ sơ") — trước chỉ có một đoạn mô tả trôi nổi.

### 🐛 Sửa

- **Nút LƯU ở "Sửa thói quen" không bấm được.** Kho 125 hình đổ thẳng vào một
  cột không cuộn, đẩy nút xuống dưới mép màn hình. Sửa xong không có cách nào
  lưu. Bảng nay cuộn được, nút dính đáy, lưới hình rút gọn.
- **Bỏ một việc khỏi thói quen làm việc đó mất người nhận.** Việc trong buổi
  lấy người nhận từ buổi; tách ra mà không chép sang thì nó thành việc không
  giao cho ai — không sinh lượt cho bé nào và không màn hình nào hiện ra.
- CI đỏ bảy lần liền vì một dòng dài quá 80 cột: máy lập trình analyze sạch
  nhưng CI format trước rồi mới analyze. Hook pre-commit nay làm đúng thứ tự
  của CI.

### 🛡️ Chốt chặn mới

Ba ràng buộc trên đều có test canh, vì rà tay một lượt thì được, giữ đúng qua
từng màn hình mới thì không: mọi bảng trượt phải đi qua `SheetHeader`; không
file nào tự dựng `SnackBar`; hook pre-commit phải format trước khi analyze.

---

## v0.4.0+24 (2026-08-29) — Việc nhà về đúng một chỗ

Bản này sửa gốc một chuyện đã âm thầm làm hỏng trải nghiệm: **cùng một việc bị
tạo hai lần**. Trên máy thử, một bé có 36 việc trong ngày, "Đánh răng buổi
sáng" hiện hai lần, và xu cộng gấp đôi cho cùng một hành động.

### Nguyên nhân

Việc nhà sinh ra từ hai đường không biết nhau: onboarding tạo buổi thói quen
kèm việc bên trong, còn *Cài đặt → hồ sơ bé → gán việc mẫu* tạo việc rời. Không
ai kiểm trùng. Và sau onboarding thì **không có đường nào tạo thêm buổi**, nên
bố mẹ buộc phải dùng đường thứ hai.

### ✨ Mới

- **Tạo buổi thói quen ngay ở tab Nhiệm vụ** (Buổi sáng, Sau giờ học, Buổi
  tối...), chọn được **nhiều bé** cùng lúc. Gán cho bé nào thì bé đó thấy.
- **Sửa việc đã tạo**: tên, hình, xu, và đổi buổi. Trước đây việc tạo xong là
  không sửa được gì.
- **Chỉnh xu ngay tại dòng việc** bằng nút −/+, bước 5.
- **Nút thêm hũ** ở màn Thống kê, với hai cách chia lại tỷ lệ: trừ đều các hũ
  khác theo tỷ lệ hiện có, hoặc tự chỉnh. Luôn về đúng 100%.
- **Vuốt ngang trên thẻ của con** để xem lịch sử ngày/tuần.

### 🔧 Đổi

- **Mọi việc đều thuộc một buổi.** Khái niệm "việc lẻ" bỏ đi; bảng thêm việc nay
  hỏi "Xếp vào buổi" thay cho "Giao cho" — người nhận lấy từ buổi.
- **Thẻ con trên Trang chính nhóm theo buổi**, mỗi nhóm hiện *đã xong / tổng*,
  liệt kê cả việc đã xong lẫn chưa xong. Buổi xong hết thì tự gập lại.
- Bỏ phần gán việc mẫu khỏi hồ sơ bé — đó chính là đường sinh ra việc trùng.
- Việc và buổi giờ đọc **một lần cho cả danh sách** thay vì mỗi dòng một truy
  vấn.

### 🩹 Sửa

- Dọn tự động việc bị tạo hai lần khi mở app: giữ bản trong buổi, **tắt** bản
  trùng chứ không xoá — sổ cái trỏ tới việc, xoá đi là "Sổ của con" mất tên.
- Bốn cảnh báo `discarded_futures` ở hoạt ảnh quay lại lần thứ ba, sửa dứt điểm.

### 🛡️ Chốt chặn

- **Hook pre-commit** chạy `flutter analyze --fatal-infos`, chặn commit khi đỏ.
  Cài: `git config core.hooksPath .githooks`.
- Test canh icon iOS không có kênh alpha (Apple từ chối lỗi 90717).
- Test canh chính hook: còn tồn tại, còn đúng lệnh, còn quyền chạy.

### ⚠️ Còn lại

Hũ tuỳ chỉnh **chưa gán riêng cho từng bé được**: mô hình hũ đang có hai cách
biểu diễn song song, và bé có tỷ lệ riêng thì mọi hũ tuỳ chỉnh biến mất với bé
đó. Chi tiết ở `docs/22`.

---

## v0.3.1+23 (2026-08-27) — Hotfix Audit Release v0.3.0

### [FIX]
- Đồng bộ phiên bản báo lỗi trong `BaoLoiScreen` lên `0.3.1` để khớp `pubspec.yaml`.
- Bổ sung `tooltip: 'Đóng'` cho các nút đóng còn thiếu trong modal chọn icon, lịch sử con và xem ảnh chứng thực để đạt checklist accessibility.

### [IMPROVE]
- Bổ sung báo cáo audit release tại `/Volumes/DATA/DEV/MOBILES/beong/docs/AUDIT_RELEASE_V0.3.0_FIX_REPORT.md`.

---

## v0.3.0+22 (2026-08-27) — Nâng Cấp Toàn Diện Trải Nghiệm Profile Bé, Kho Icon 110+, Hũ Xu Cá Nhân Hoá, Chứng Thực Hình Ảnh & Journey Leo Núi

### [NEW]
- **Tái Cấu Trúc Biểu Mẫu Cấu Hình Profile Bé (`ChildProfileForm`)**:
  - Phân nhóm danh sách việc mẫu theo 4 buổi rõ ràng: `🌅 Sáng`, `☀️ Trưa / Chiều`, `🌙 Tối`, `🔄 Thói quen / Cả ngày`.
  - Tích hợp nút `Xem thêm / Thu gọn` thông minh cho từng buổi giúp màn hình gọn gàng.
  - Bộ điều khiển `[-] [Số xu] [+]` tuỳ chỉnh điểm thưởng xu riêng cho từng đầu việc mẫu đã chọn.
  - Lưu và nhớ chính xác trạng thái các việc đã chọn trước đó khi mở lại hoặc chỉnh sửa hồ sơ.
- **Mở Rộng Kho Icon Chuẩn 110+ Fluent 3D Emoji & Phân Loại 6 Tabs**:
  - Mở rộng toàn diện bộ icon việc nhà, danh hiệu và phần thưởng lên hơn 110 icon 3D sinh động.
  - Phân loại trực quan thành 6 danh mục: `🧹 Việc nhà`, `📚 Học tập`, `🏃 Sức khoẻ`, `☀️ Buổi & Lịch`, `⭐ Động lực`, `❤️ Thói quen & Chia sẻ`.
  - Hỗ trợ tìm kiếm icon theo tên tiếng Anh / từ khoá thời gian thực và modal chọn icon toàn màn hình.
- **Tuỳ Chỉnh Hũ Xu Riêng & Thanh Slider Thông Minh Có Chốt Khoá**:
  - Bố mẹ có thể chọn số lượng hũ áp dụng riêng cho từng bé và cấu hình tỷ lệ hũ riêng biệt (`jarSplitOverride`).
  - Thanh slider thông minh có chốt khoá (Lock toggle): khi người dùng khoá một hoặc hai hũ và điều chỉnh hũ còn lại, hệ thống tự động cân bằng các hũ chưa khoá để tổng luôn đúng 100%.
  - Đưa tuỳ chọn "Con tự chia xu" vào cấu hình riêng của từng bé thay vì áp dụng chung cả nhà.
  - Minh bạch số dư hiện tại và số xu cộng dồn `+X xu → tổng mới` trong modal chia xu của con (`AllocateXuSheet`).
- **Chứng Thực Hình Ảnh Khi Hoàn Thành Nhiệm Vụ**:
  - Tích hợp chọn chụp ảnh trực tiếp từ Camera hoặc chọn từ thư viện ảnh (`image_picker`) khi con bấm hoàn thành nhiệm vụ có yêu cầu hình ảnh chứng thực.
  - Bố mẹ có thể xem ảnh bằng chứng phóng to, tương tác zoom (`InteractiveViewer`) trong hàng đợi duyệt việc.
- **Thống Kê (Stats) & Lịch Sử Vuốt Ngang Theo Ngày/Tuần Tại Home Bố Mẹ**:
  - Phân định rõ ràng: bấm Avatar con để chuyển đổi vai xem của bé, bấm Tên/Header để mở modal `ChildHistoryModal`.
  - Hỗ trợ thanh điều hướng chọn ngày vuốt ngang `[<] [Hôm nay/Ngày...] [>]`, tóm tắt tỷ lệ hoàn thành và phân nhóm chi tiết công việc theo 4 buổi trong ngày.
- **Tái Thiết Kế Tab Journey Phong Cách "Bản Đồ Leo Núi Chinh Phục Đỉnh Cao"**:
  - Trực quan hoá lộ trình rèn luyện thành bản đồ leo núi 5 trạm thử thách (Xuất phát, Vượt dốc, Lưng chừng núi, Chạm mây, Đỉnh vinh quang).
  - Tích hợp thanh tiến độ, đếm streak ngày liên tiếp, linh vật Bé Ong động và phần thưởng mốc trạm.
- **Tinh Gọn Màn Hình Tasks Bố Mẹ**:
  - Khối chọn việc mẫu nhanh (`_QuickPresetPicker`) được rút gọn còn 8 việc kèm nút `Xem thêm` mở rộng mượt mà.

### [IMPROVE]
- Khai báo đầy đủ các quyền `NSCameraUsageDescription` và `NSPhotoLibraryUsageDescription` trong `ios/Runner/Info.plist`.
- Chuẩn hoá màu sắc ngữ nghĩa và Material 3 tokens, tương thích hoàn toàn với nền tảng iOS và Android.

### [FIX]
- Vượt qua 100% kiểm tra phân tích tĩnh `flutter analyze` với 0 lỗi / cảnh báo.
- Đảm bảo toàn bộ test suites vượt qua thành công.

---

## v0.2.13+21 (2026-08-26) — Nâng Cấp Toàn Diện Màn Hình Parents, Quản Lý & Phân Tách Theo Từng Bé

### [NEW]
- **Quản Lý & Phân Định Phần Thưởng Theo Từng Bé**:
  - Gán phần thưởng đích danh cho từng bé hoặc dùng chung cho tất cả các con qua `targetMemberId` lưu trong `metaJson`.
  - Hiển thị badge avatar và tên bé kèm màu nhận diện trực quan trên thẻ phần thưởng `_RewardCard`.
  - Bổ sung thanh cuộn `FilterChip` lọc danh sách phần thưởng theo từng bé trên màn hình Phần thưởng của phụ huynh.
  - Phía con chỉ hiển thị các phần thưởng dùng chung hoặc được gán riêng cho chính bé đó.
- **Tuỳ Biến Tỷ Lệ Hũ Xu Theo Từng Bé (`jarSplitOverride`)**:
  - Hỗ trợ thiết lập tỷ lệ hũ riêng biệt phù hợp theo độ tuổi từng bé (bé nhỏ ưu tiên hũ Chi tiêu/Đồ chơi, bé lớn ưu tiên Tiết kiệm/Học tập).
  - Tích hợp RadioGroup và bộ slider điều chỉnh tỷ lệ hũ linh hoạt trong biểu mẫu hồ sơ bé.
- **Gán Việc Nhà Mẫu Hàng Loạt Khi Tạo / Sửa Hồ Sơ Con**:
  - Tích hợp danh sách việc mẫu `kTaskPresets` dạng FilterChip cho phép phụ huynh tích chọn nhanh nhiều việc cùng lúc để tự động tạo và sinh instance việc cho bé ngay trong ngày.
- **Bật / Tắt Mật Khẩu PIN Hồ Sơ Cho Từng Bé**:
  - Bổ sung công tắc `SwitchListTile` bật/tắt mật khẩu 4 chữ số bảo vệ hồ sơ bé, tích hợp hàm `boMatKhau` trong `MatKhauHoSo`.
- **Hiển Thị Rõ Ràng Danh Tính Bé Xin Đổi Thưởng**:
  - Hiển thị avatar tròn, nhãn tên bé và màu nhận diện riêng biệt trên từng thẻ yêu cầu đổi thưởng trong `RedemptionQueue`.

### [IMPROVE]
- **Trải Nghiệm Thao Tác & Nút Đóng / Huỷ Biểu Mẫu**:
  - Bổ sung nút `X` (Đóng/Huỷ) rõ ràng trên header của Form thêm/sửa phần thưởng (`_RewardEditorSheet`) và Form hồ sơ bé (`ChildProfileForm`).
  - Nâng cấp hiển thị trung thực yêu cầu kiểm tra hình ảnh chứng thực từ phụ huynh khi nhiệm vụ yêu cầu chụp ảnh.

### [FIX]
- Đảm bảo 100% test suite (523 tests) vượt qua thành công với 0 diagnostic issues.

---

## v0.2.12+20 (2026-08-26) — Tái Thiết Kế Toàn Diện UI Cho Bé Phong Cách Gamification & Benchmark Chore Rewards

### [NEW]
- **Tái Cấu Trúc Điều Hướng Chuẩn Hoá 4 Tab Phía Con (§14, §24)**:
  - Tinh gọn menu vai con xuống đúng 4 tab: `Home` (Trang chính), `Rewards` (Phần thưởng), `Awards` (Huy hiệu), `Journey` (Hành trình).
  - Ẩn hoàn toàn tab `Tasks` ở vai con vì màn hình Home đã thể hiện trực quan toàn bộ danh sách việc cần làm trong ngày.
  - Bổ sung nút tròn `+` ở góc trên bên phải màn hình con (`_ChildHeader`) mở sheet `_ChildTaskSheet` cho phép trẻ tự ghi nhận việc tự giác đã làm kèm số xu đề xuất và icon, tự động sinh instance và gửi bố mẹ duyệt khen thưởng.
- **Nâng Cấp Tab Rewards Vai Con Trực Quan Hoá Tài Chính**:
  - Đưa thẻ tổng quan xu của con (`_ChildWalletJarsBanner`) lên trên cùng tab Rewards.
  - Hiển thị danh sách các hũ xu con đang tích luỹ (`_JarItemCard`) dạng lưới thẻ ngang cuộn mượt mà trước khi đến danh mục phần thưởng đổi xu và điều ước, giúp trẻ nắm rõ số dư xu có thể chi tiêu.
- **Tái Thiết Kế Tab Awards (Huy Hiệu) Phong Cách Gamification**:
  - Loại bỏ danh sách chữ dài, chuyển đổi sang thẻ tổng kết "ĐÃ THU THẬP X / Y" cùng lưới icon huy hiệu 3 cột trực quan (`_BadgeGridTile`) kèm vòng cung tiến độ tròn (`ProgressRing`).
  - Chạm vào từng ô huy hiệu để mở bảng bottom sheet chi tiết hiển thị trạng thái chinh phục và yêu cầu mở khoá.
- **Tái Thiết Kế Tab Journey Dạng Bản Đồ Leo Núi Nấc Thang Phiêu Lưu (§13)**:
  - Chuyển đổi toàn bộ màn hình thành bản đồ leo núi nấc thang zic-zac kết nối từ chân núi (0%) lên đỉnh vinh quang (100%).
  - Tích hợp linh vật Bé Ong động đứng trực tiếp tại trạm dừng hiện tại theo tiến độ xu tích luỹ được của trẻ.

### [FIX]
- Sửa triệt để các cảnh báo linter analyzer: loại bỏ unused import `dart:async`, giải quyết lỗi `discarded_futures` cho hiệu ứng chạm nảy linh vật `BeeMascot`, làm sạch định dạng eol.
- Đảm bảo 100% test suite (523 tests) vượt qua thành công với 0 diagnostic issues.

---

## v0.2.11+19 (2026-08-26) — Triệt tiêu Lỗi Analyzer `discarded_futures` & Ổn định Hoàn toàn Pipeline CI

### [FIX]
- **Sửa Triệt để Lỗi Bất đồng bộ Không Chờ (`discarded_futures`)**:
  - Bọc `unawaited(...)` cho các hiệu ứng hoạt ảnh cố ý không chặn:
    - `BeeMascot._syncAnimation` và `BeeMascot.onTap` (`lib/core/widgets/bee_mascot.dart`).
    - `ConfettiBurst._play` (`lib/core/widgets/celebration.dart`).
    - `OnboardingScreen._nextPage` (`lib/features/onboarding/onboarding_screen.dart`).
  - Thêm `import 'dart:async';` đảm bảo đúng thứ tự import và định dạng.

---

## v0.2.10+18 (2026-08-26) — Chuẩn hoá Ràng buộc Kiến trúc & Danh mục Icon Huy hiệu

### [FIX]
- **Chuẩn hoá Kiến trúc Tầng UI (`wish_sheet.dart`)**:
  - Tuân thủ nghiêm ngặt ranh giới Clean Architecture, nhập `RewardsCompanion` và các kiểu dữ liệu liên quan qua `reward_repository.dart`, loại bỏ import trực tiếp từ `package:beong/data/`.
- **Khớp Asset Icon Huy hiệu (`badge_def.dart`)**:
  - Đồng bộ các icon huy hiệu `streak_14` (`gem`) và `reward_10` (`star`) với bộ asset PNG hiện có.
  - Cập nhật số lượng kiểm thử 16 huy hiệu trong `test/unit/domain/badge_test.dart`.
- **Cập nhật Cẩm nang Kỹ thuật (`flutter-8-buoc`)**:
  - Bổ sung quy tắc phòng ngừa lỗi kiến trúc và kiểm tra asset icon vào `references/lint-thuong-gap.md`.

---

## v0.2.9+17 (2026-08-26) — Hoàn thiện Toàn diện Trải nghiệm Gamification, Điều hướng theo Vai, Điều ước & Hành trình

### [NEW]
- **Điều hướng Chuẩn hoá theo Vai trò (§14, §24)**:
  - Phân tách thanh điều hướng độc lập dựa trên vai trò:
    - **Bố mẹ (5 tabs)**: Trang chính (`Home`), Nhiệm vụ (`Tasks`), Phần thưởng (`Rewards`), Thống kê (`Stats`), Cài đặt (`Settings`).
    - **Con (5 tabs)**: Trang chính (`Home`), Nhiệm vụ (`Tasks`), Phần thưởng (`Rewards`), Huy hiệu (`Badges`), Hành trình (`Journey`).
  - Trẻ có tab **Huy hiệu** và **Hành trình** riêng biệt, loại bỏ tình trạng bị redirect chặn khi truy cập nhầm Cài đặt.
- **Màn hình Bản đồ Hành trình Mục tiêu (§13)**:
  - Màn hình `JourneyScreen` trực quan hoá con đường chinh phục mục tiêu tiết kiệm dài hạn của con qua các cột mốc tiến độ dọc (25%, 50%, 75%, 100%) kết nối linh hoạt với hũ Để dành.
- **Tính năng Điều ước do Con Tự Đề Xuất (§11)**:
  - Cho phép trẻ tự đề xuất mong muốn phần thưởng (`_WishSheet` / `showWishSheet`) kèm số xu gợi ý để bố mẹ xem xét, phê duyệt và định giá chính thức.
- **Mở rộng Hệ thống Huy hiệu & Cột mốc Đa tầng (§22)**:
  - Mở rộng bộ huy hiệu lên 16 huy hiệu chia đều trên 4 danh mục (`streak`, `tasksDone`, `routinePerfectDays`, `redemptions`), bổ sung các mốc 14 ngày, 25 việc, 3 phần thưởng và 10 phần thưởng.
- **Bộ Nhận diện & App Icon Chính thức**:
  - Cập nhật đồng bộ bộ App Icon hoàn toàn mới từ `docs/icons/app-icon.png` cho toàn bộ các nền tảng: iOS (AppIcon xcassets 20x20..1024x1024), Android (mipmap mdpi..xxxhdpi), macOS (16x16..1024x1024), Web (favicon, apple-touch-icon, logo) và tài liệu.
- **Hệ thống Ăn mừng & Vinh danh Huy hiệu Đa tầng (§18, §20)**:
  - Dialog vinh danh `_BadgeCelebrationDialog` xuất hiện khi con đạt thành tựu mới, hỗ trợ lật mở từng huy hiệu kèm chấm phân trang khi nhận nhiều danh hiệu cùng lúc thay vì SnackBar trôi mất sau 4s.
  - Phân loại 4 nhóm danh mục huy hiệu chuẩn mực (`BadgeCategory`: Chuỗi kiên trì, Việc nhà chăm chỉ, Thói quen vững vàng, Phần thưởng & Tiết kiệm).
  - Đổi tên huy hiệu thành danh hiệu phẩm chất và câu mô tả truyền cảm hứng cho trẻ (§21).
- **Trải nghiệm Thao tác & Thiết kế Trình soạn thảo Nhiệm vụ (§7, §8, §9)**:
  - Bổ sung chọn Buổi trong ngày (Sáng / Chiều / Tối) tối ưu thực tế cho phụ huynh.
  - Điều chỉnh điểm thưởng bằng bộ nút tròn `− / +` bước nhảy 5 xu tiện dụng.
  - Cố định nút `LƯU` dính đáy màn hình (Sticky Bottom) chống trôi khi cuộn form.
- **Tiếng nói Linh vật Ong (§19)**:
  - Tích hợp thoại tương tác cho `BeeMascot` tại Dashboard vai con, phản hồi trực tiếp theo tiến độ hoàn thành công việc trong ngày.

### [FIX]
- **Tối ưu Trải nghiệm Tuổi Teen & Hoạt ảnh (Audit 18 C-1)**:
  - Nhóm trẻ teen (13–15) nhận thông báo huy hiệu mới qua SnackBar kèm biểu tượng và tên huy hiệu rõ ràng, tôn trọng sở thích không bị chen ngang bởi dialog pop-up.
- **Sửa Lỗi Bằng chứng Ảnh & Trung thực Trạng thái (Audit 15 §1, Audit 17 §1)**:
  - Loại bỏ chuỗi giả `local_captured_...` khi con hoàn thành việc yêu cầu ảnh. Đổi thông điệp thoại thành trung thực ("Cần bố mẹ xem").
  - Màn hình duyệt của bố mẹ hiển thị đúng yêu cầu kiểm tra trực tiếp thay vì ghi đã có ảnh chụp giả.
- **Hoàn thiện Câu Động viên Huy hiệu (Roadmap §21, Audit 17 §3)**:
  - Bổ sung đầy đủ vế thứ hai — lời động viên xưng "con" cho toàn bộ huy hiệu.
- **Loại bỏ Emoji Người trong Preset (Audit 15 §8)**:
  - Đổi icon preset `exercise` từ `run` (🏃) sang `soccer` (⚽) để đảm bảo tính trung tính cho mọi bé.
- **Bổ sung Chú thích 5 Cột Schema Chưa Nối (Audit 15 §6)**:
  - Chú thích rõ ràng trạng thái và lý do bảo lưu trong `tables.dart` cho `currency`, `userId`, `startTime`, `dueTime`, `proofUrl`.
  - Nút `Đổi` trong `RewardsScreen` hiển thị trạng thái và tính toán số xu còn thiếu (`Thiếu X xu`) khi chưa đủ điều kiện đổi thưởng.
  - `GoalSheet` cho phép chọn nhanh các phần thưởng có sẵn trong gia đình để tự động điền mục tiêu tiết kiệm.
  - Trẻ có thể mở `GoalSheet` và tự đặt/đề xuất mục tiêu tiết kiệm trực tiếp từ màn hình chính của mình.
- **Nâng cấp Giao diện Huy hiệu & Thống kê Tuần (§4, §5, §6, §12, §15)**:
  - Vẽ vòng cung tiến độ (`ProgressRing`) ôm quanh icon huy hiệu hiển thị trực quan tỷ lệ % đã đạt được.
  - Bổ sung điều hướng tuần `‹ ›` và thẻ tổng kết tuần trực quan tại đầu màn hình Thống kê `StatsScreen`.
  - Phân biệt rõ ràng giữa ngày trống không hoạt động trong quá khứ và các ngày chưa tới trong tuần.

---

## v0.2.7+15 (2026-08-25) — Hoàn thiện Bằng chứng Việc nhà, Pháp lý Store & Trạng thái Ghép cặp

### [NEW]
- **Hoàn thiện luồng Bằng chứng Việc nhà (`proof_mode`)**:
  - Tích hợp ghi chú / chụp ảnh khi con bấm hoàn thành nhiệm vụ có yêu cầu bằng chứng (`ProofMode.note`, `ProofMode.photo`).
  - Hàng đợi duyệt của Bố Mẹ hiển thị đầy đủ ghi chú và bằng chứng kèm theo để duyệt/từ chối chính xác.
- **Màn mồi xin quyền Push Notification (Pre-permission Flow)**:
  - Hiển thị màn mồi giải thích lợi ích sau Onboarding trước khi kích hoạt dialog xin quyền push của OS, tránh bị từ chối mất quyền vĩnh viễn trên iOS.
  - Khởi tạo `PushNotificationService` trong `main.dart`.

### [IMPROVE]
- **Bổ sung Thông tin Pháp lý & Hỗ trợ trong Cài đặt**:
  - Thêm mục Chính sách quyền riêng tư (`beong.net/quyen-rieng-tu.html`), Điều khoản sử dụng (`beong.net/dieu-khoan.html`) và Email hỗ trợ (`info@beong.net`) đáp ứng quy định kiểm duyệt của App Store & Google Play.
- **Hiện trạng thái kết nối máy con trong Cài đặt**:
  - Thẻ thành viên trẻ hiển thị trạng thái kết nối thực tế (`Chưa kết nối máy`).
- **Dọn dẹp & Chuẩn hoá Repository**:
  - Xoá file `CHANGELOGS.md` trùng lặp ở root.
  - Chuẩn hoá quy tắc duyệt phần thưởng theo ADR-025.

---

## v0.2.7+14 (2026-08-24) — Tích hợp Push Notification (Supabase + FCM) & Cải tiến Giao diện (Audit Phần II)

### [NEW]
- **Kiến trúc Push Notification (Supabase Edge Function + Google FCM v1)**:
  - Bảng cơ sở dữ liệu `device_tokens` lưu định danh thiết bị kèm cơ chế phân quyền Row Level Security (RLS) theo từng gia đình (`supabase/migrations/20260824000000_device_tokens_and_push.sql`).
  - Supabase Edge Function `notify-fcm` (`supabase/functions/notify-fcm/index.ts`) xử lý xác thực Google OAuth2 JWT và phát thông báo đa nền tảng (Android notification channel + iOS APNs badge/sound) hoàn toàn miễn phí 0đ.
  - Tích hợp `PushNotificationService` (`lib/core/services/push_notification_service.dart`) hỗ trợ đồng bộ token và gửi thông báo từ xa 2 chiều giữa Bố Mẹ và Con.
  - Cấu hình Firebase gốc `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) cho bundle ID `net.beong.app`.

### [IMPROVE]
- **Tách banner "Chờ chia" trong Sổ của con (§12)**:
  - Tách ô "Chờ chia" ra khỏi lưới hiển thị hũ tại `StatsScreen`, đưa lên thành `_UnallocatedBanner` nổi bật trên cùng chiếm trọn chiều ngang kèm nút **"Chia ngay"** mở trực tiếp `AllocateXuSheet`.
  - Lưới hũ bên dưới chỉ còn hiển thị các hũ tích luỹ thật (`Tiêu`, `Để dành`, `Cho đi`...).
  - Tự động ẩn banner khi số xu chờ chia bằng 0 (`inbox == 0`).
- **Tái cấu trúc màn hình Cài đặt thành 4 nhóm khoa học (§10)**:
  - Chia toàn bộ 11 mục cài đặt phẳng trước đây thành 4 khối `_SettingsSection` có tiêu đề phân nhóm rõ ràng:
    1. **Gia đình**: Danh sách thành viên, Thêm bé, Múi giờ (`_TimezoneTile`), Giờ đổi ngày (`_RolloverTile`).
    2. **Quy tắc xu**: Cần bố mẹ duyệt (`_ApprovalTile`), Con tự chia xu (`_AllocationTile`), Các hũ (`_JarsTile`), Trừ xu (`_PenaltyTile`), Quy đổi tiền thật (`_ExchangeRateTile`).
    3. **Ứng dụng**: Giao diện sáng/tối (`_ThemeTile`), Mật khẩu hồ sơ (`_MatKhauTile`).
    4. **Thông tin**: Báo lỗi (`_SettingsTile`), Phiên bản ứng dụng (`_SettingsTile`).
- **Nhóm lịch sử giao dịch theo ngày lịch (§11)**:
  - Tái cấu trúc danh sách giao dịch phẳng trong `StatsScreen` thành từng nhóm theo ngày (`_DailyHistoryList`, `_DayHistoryGroup`).
  - Mỗi ngày là một khối thẻ gập/mở gọn gàng hiển thị tóm tắt `Thứ, ngày/tháng · X việc xong · ±xu`.
  - Mặc định mở sẵn các giao dịch của ngày hôm nay (`isExpandedByDefault`), các ngày trước đó được gập lại để phụ huynh dễ theo dõi.
- **Thu gọn bảng chọn Icon việc nhà & phần thưởng (§8)**:
  - Nâng cấp `IconPickerGrid` thành `StatefulWidget`: mặc định chỉ hiển thị 1 hàng (6 icon đầu tiên, đảm bảo luôn kèm icon đang chọn).
  - Tích hợp nút toggle **"Xem thêm (N hình)"** / **"Thu gọn"** để mở rộng/thu nhỏ lưới icon linh hoạt, không đẩy tràn biểu mẫu nhập liệu.
- **Mở rộng bộ khoá Icon việc nhà (§7)**:
  - Bổ sung các icon từ bundle Fluent Emoji 3D asset (`clipboard`, `gem`, `party`, `warning`, `bee`, `run`, `eye_off`...) vào `kTaskIconKeys`.
- **Tăng cường tương tác & Phản hồi xúc giác vai con (§9)**:
  - Tích hợp rung xúc giác nhẹ (`HapticFeedback.lightImpact()`) khi con chạm tích hoàn thành nhiệm vụ trên `TaskCard`.
  - Bổ sung tương tác chạm vào linh vật Bé Ong (`BeeMascot`) để kích hoạt chuyển động nảy vui nhộn.

---

## v0.2.6+13 (2026-08-23) — Sửa lỗi Luồng Chạy & Đồng bộ Tài liệu (Audit Phần I)

### [FIX]
- **Sửa thông điệp ghép cặp QR**: Cập nhật câu thông báo sau khi quét mã QR sang *"Tính năng đồng bộ qua mạng đang được hoàn thiện"*, phản ánh trung thực trạng thái tính năng.
- **Kích hoạt chế độ kiểm tra bằng chứng (`proof_mode`)**: Nối trường `proof_mode` vào quy trình hoàn thành nhiệm vụ tại `TaskReviewService.complete`. Khi việc yêu cầu chụp ảnh, bắt buộc chuyển trạng thái sang `pendingReview` để bố mẹ duyệt bất kể cấu hình chung của gia đình.
- **Đồng bộ tài liệu ADR-027**: Chuẩn hoá quy định mật khẩu hồ sơ (Bố mẹ bắt buộc, Bé tuỳ chọn).
- **Kiểm chứng giao diện thực tế**: Chụp bổ sung 10 ảnh kiểm chứng các màn hình mới (`docs/screenshot/81`–`90`).

---

## v0.2.6 (2026-08-23) — Universal Link QR, Quản lý Gia đình & Supabase Schema

### [NEW]
- **Ghép cặp thiết bị bằng Camera native & Universal Link**:
  - Hỗ trợ quét mã ghép cặp QR trực tiếp bằng ứng dụng Camera mặc định của điện thoại thông qua Universal Link / App Link (`https://beong.net/pair?code=...`).
  - Tích hợp `mobile_scanner` quét mã QR trực tiếp trong app và hiển thị vector QR bằng `qr_flutter`.
- **Quản lý Hồ sơ Con & Xoá Gia đình**:
  - Thêm tính năng sửa thông tin con (tên, avatar, màu đại diện, ngày sinh/năm sinh).
  - Hỗ trợ xoá toàn bộ dữ liệu gia đình kèm cơ chế xác thực mật khẩu phụ huynh và cảnh báo nguy hiểm.
- **Múi giờ & Giờ đổi ngày linh hoạt**:
  - Cho phép chọn múi giờ (`Asia/Ho_Chi_Minh`, `Asia/Tokyo`, `America/New_York`...) độc lập với múi giờ thiết bị.
  - Cho phép cấu hình giờ đổi ngày (`day_rollover_hour`) từ 0h đến 6h sáng để tính toán streak và nhiệm vụ chính xác theo lịch sinh hoạt.
- **Chế độ Bằng chứng hình ảnh (`proof_mode`)**: Bổ sung tuỳ chọn yêu cầu chụp ảnh khi tạo/sửa việc trong Task Editor.
- **CRUD Quản lý Phần thưởng**: Cho phép bố mẹ tạo mới, chỉnh sửa tên, icon, giá xu và xóa phần thưởng.
- **Backend Schema & RLS Policies (Sprint 3)**: Hoàn thiện 11 bảng cơ sở dữ liệu PostgreSQL + Supabase Row Level Security tại `supabase/migrations/`.

### [FIX]
- Nâng deployment target iOS lên 15.5 tương thích thư viện `mobile_scanner`.
- Sửa 13 lỗi strict linter và warning liên quan đến `discarded_futures` và unawaited async.

---

## v0.2.5 (2026-08-23) — Bảo mật Hồ sơ ADR-027 & Tối ưu Trải nghiệm Con

### [NEW]
- **Mật khẩu bảo vệ từng hồ sơ (ADR-027)**:
  - Cơ chế mã hoá và băm mật khẩu hồ sơ bằng SHA-256 (`crypto`).
  - Hộp thoại nhập mật khẩu (`MatKhauSheet`, `hoiMatKhau`) khi chuyển đổi giữa các vai hoặc mở các tính năng nhạy cảm.
- **Khung pháp lý & Quyền riêng tư**:
  - Bổ sung `PrivacyInfo.xcprivacy` cho hệ sinh thái Apple iOS.
  - Cập nhật chính sách quyền riêng tư (`10-privacy-policy.md`) và điều khoản bản quyền EULA 360 CORP.

### [IMPROVE]
- **Khắc phục triệt để hiện tượng giật danh sách việc**:
  - Tối ưu hoá luồng dữ liệu `StreamBuilder` tại `ChildHomeScreen`, lưu trữ stream trong State để tránh huỷ/đăng ký lại stream khi `setState` nổ hoa giấy.

---

## v0.2.3 & v0.2.4 (2026-08-22) — Bảo vệ Phiên làm việc & Tự động hoá CI/CD Release

### [NEW]
- **Cơ chế Khoá lại (Lock App)**: Nút "KHOÁ LẠI" thay cho nút Đăng xuất cũ, giúp phụ huynh đưa máy cho con mà không lo mất dữ liệu.
- **Lối thoát khi quên PIN/Mật khẩu**: Cơ chế xác thực an toàn giúp phụ huynh lấy lại quyền quản trị khi quên mật khẩu.

### [IMPROVE]
- Tự động hoá kiểm tra và xác thực chứng chỉ Play Console / App Store Distribution trước khi build release trong GitHub Actions.

---

## v0.2.1 & v0.2.2 (2026-08-17 – 2026-08-20) — Tách lớp Clean Architecture (Tầng Repository)

### [NEW]
- **Tầng Repository chuẩn Clean Architecture**:
  - Đóng gói 7 abstract interfaces tại `lib/domain/repositories/` (`MemberRepository`, `TaskRepository`, `WalletRepository`, `RewardRepository`, `JarRepository`, `GoalRepository`, `BadgeRepository`).
  - Tách biệt hoàn toàn tầng UI (`lib/features/`) khỏi tầng dữ liệu trực tiếp SQLite DAO (`lib/data/`).
  - Bổ sung bộ kiểm thử kiến trúc `kien_truc_test.dart` ngăn chặn vi phạm layer boundaries.

### [FIX]
- Khắc phục lỗi cộng xu 2 lần cho cùng một lượt việc.
- Sửa lỗi hiển thị trạng thái chờ duyệt của phiếu đổi thưởng.
- Dọn dẹp loại bỏ 6 thư viện dependency không sử dụng để giảm kích thước bundle.

---

## v0.2.0 (2026-08-15 – 2026-08-16) — Hệ thống Tài chính, Thói quen & Báo lỗi Chẩn đoán

### [NEW]
- **Mục tiêu Tiết kiệm (`SavingsGoal`)**: Cho phép trẻ đặt mục tiêu để dành xu kèm thanh tiến độ trực quan.
- **Hệ thống 8 Huy hiệu (`Badges`) & Chuỗi ngày liên tiếp (`Streaks`)**: Tự động tính streak có ngày ân hạn và trao huy hiệu danh dự khi đạt các mốc thành tích.
- **Trình chỉnh sửa Thói quen (`RoutineEditor`)**: Hỗ trợ kéo thả sắp xếp thứ tự nhiệm vụ trong bộ thói quen và tuỳ chỉnh mức thưởng trọn bộ.
- **Quy đổi Xu ra Tiền thật (ADR-017)**: Hỗ trợ phụ huynh cấu hình tỷ lệ quy đổi hiển thị (ví dụ 1 xu = 1.000đ), mặc định tắt.
- **Bộ Icon 3D Fluent Emoji (MIT)**: Chuyển đổi toàn bộ icon sang asset PNG 3D chất lượng cao, đồng nhất trên tất cả các nền tảng (iOS, Android, Desktop).
- **Hệ thống Báo lỗi Chẩn đoán trong App (`NhatKyLoi`)**: Tự động thu thập log, thông số thiết bị và gửi issue chẩn đoán trực tiếp cho đội ngũ phát triển.
- **Điều chỉnh Xu thủ công**: Cho phép bố mẹ cộng/trừ xu tay kèm bắt buộc nhập lý do điều chỉnh để minh bạch sổ cái.

---

## v0.1.0 (2026-08-08 – 2026-08-10) — Quy tắc 3 Hũ Xu, Trừ Xu & Giao diện 5 Tab

### [NEW]
- **Mô hình 3 Hũ Tài chính (ADR-024)**:
  - Thiết kế bảng `jars` với 3 hũ mặc định: `Tiêu`, `Để dành`, `Cho đi`.
  - Hỗ trợ tạo thêm các hũ tuỳ chỉnh riêng của từng gia đình.
  - Cơ chế con tự chia xu từ hũ chờ (`inbox`) vào các hũ theo tỷ lệ mong muốn.
- **Cơ chế Trừ Xu vi phạm & Duyệt việc (ADR-022, ADR-023)**:
  - Hỗ trợ thiết lập mức phạt trừ xu khi bỏ lỡ nhiệm vụ.
  - Cơ chế duyệt nhiệm vụ linh hoạt: mặc định "làm xong là xong", tuỳ chọn duyệt theo từng việc hoặc theo gia đình.
- **Quy trình Đổi thưởng & Duyệt thưởng (ADR-025)**: Hệ thống quà tặng, phiếu đổi thưởng và hoàn xu tự động khi bị từ chối.
- **Giao diện Trẻ em Thích ứng theo Nhóm tuổi (`KidScale`)**: Tự động căn chỉnh kích thước nút bấm, font chữ, khoảng cách theo nhóm tuổi (5–8 tuổi vs 9–15 tuổi).
- **Linh vật Bé Ong (`BeeMascot`)**: Vẽ bằng CustomPainter với các biểu cảm sinh động theo tiến độ trong ngày (`sleepy`, `happy`, `celebrating`).

---

## v0.0.1 (2026-08-01 – 2026-08-04) — Khởi tạo Nền tảng Đa nền tảng (Sprint 0)

### [NEW]
- **Khởi tạo mã nguồn dự án**: Dựng nền tảng Flutter đa nền tảng (iOS, Android, macOS, Windows, Linux).
- **Cơ sở dữ liệu Local Offline-First**: Thiết lập Drift SQLite ORM với đầy đủ bảng dữ liệu ban đầu và sổ cái ví xu (`wallet_ledger`).
- **State Management & Routing**: Tích hợp Riverpod (`StateNotifier`, `Provider`) và `go_router` với `StatefulShellRoute`.
- **Hệ thống Thiết kế & Đa ngôn ngữ**:
  - Design tokens, typography font Nunito, theme màu vàng nhận diện Bé Ong kết hợp xanh 360 CORP.
  - Hỗ trợ song ngữ Tiếng Việt và Tiếng Anh (`app_vi.arb`, `app_en.arb`).
- **Quy trình CI/CD**: Thiết lập GitHub Actions tự động kiểm tra code (`analyze --fatal-infos`), format, chạy unit test và build đa nền tảng.
