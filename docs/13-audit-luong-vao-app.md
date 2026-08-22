# Audit — luồng vào app, đăng xuất, và mã PIN

**Ngày:** 22/08/2026 · **Bản kiểm:** v0.2.1 · **Cách kiểm:** chạy app thật ở
412×900, đi hết luồng, và đọc thẳng file dữ liệu sau mỗi bước.

Tài liệu này dành cho người sẽ sửa. Mỗi lỗi ghi: **hiện tượng đã dựng lại được**,
**nguyên nhân gốc trong mã**, **phương án**, và **test phải có** để lỗi không quay lại.

---

## Tóm tắt

| # | Vấn đề | Kết luận | Mức |
|---|---|---|---|
| 1 | Tắt app rồi mở lại phải cấu hình từ đầu | **Không tái tạo được** trên bản Linux — session giữ đúng. Có nguyên nhân khác, xem §1 | Cần thêm dữ kiện |
| 2 | Đăng xuất xong quay về welcome, không có chỗ đăng nhập | **Đúng, và nặng hơn mô tả** — làm lại onboarding sinh gia đình thứ hai, dữ liệu cũ thành mồ côi | 🔴 Nghiêm trọng |
| 3 | Đặt PIN không có chỗ đặt lại | **Đúng** — quên PIN là mất quyền bố mẹ vĩnh viễn, chỉ gỡ app mới thoát | 🔴 Nghiêm trọng |

Hai lỗi 🔴 có **cùng một gốc**: app coi "đã đăng nhập" là trạng thái duy nhất
đáng quan tâm, và không có khái niệm *"máy này đã có dữ liệu, cho tôi vào lại"*.

---

## 1. Tắt app rồi mở lại — chưa tái tạo được

### Đã kiểm những gì

Dựng lại đúng kịch bản trên bản Linux: cấu hình xong → tắt hẳn tiến trình → mở lại.

Kết quả: **vào thẳng Trang chính**, không quay về onboarding. Đọc file dữ liệu
ngay sau khi tắt thấy session còn đủ ba khoá:

```
session.family_id         ace39848-…
session.active_member_id  22c1c2d9-…
session.is_parent         true
```

Đường mã cũng đúng: `main.dart` đọc session **trước** khung hình đầu, và
`SettingsDao.writeAll` ghi cả ba khoá trong một batch nên không có trạng thái
nửa vời.

### Vậy vì sao anh gặp?

Ba khả năng, xếp theo mức có lý:

1. **Cài lại bản mới đè lên bản cũ.** Mỗi lần cài bản dựng mới từ máy chủ dựng
   app, nếu chữ ký hoặc cách cài khác lần trước thì hệ điều hành coi là app
   khác và cấp vùng dữ liệu trắng. Đây là hành vi của hệ điều hành, không phải
   lỗi app — nhưng người dùng thấy y hệt như lỗi.
2. **Chỗ lưu dữ liệu khác nhau giữa các nền tảng.** Cần kiểm lại trên đúng máy
   anh đang thử.
3. **Lỗi lúc mở dữ liệu bị nuốt.** `main.dart` bọc bộ sinh việc đầu ngày trong
   `try/catch` và chỉ `debugPrint`. Nếu chỗ *đọc session* cũng hỏng thì app rơi
   về onboarding **mà không báo gì**.

### Phương án

**P1 — thêm dấu vết chẩn đoán (làm trước, rẻ).** Ghi vào nhật ký lỗi mỗi lần
khởi động: đọc session thành công hay thất bại, và đường dẫn file dữ liệu đang
dùng. Có dòng này thì lần sau anh bấm Báo lỗi là biết ngay lý do, thay vì đoán.

**P2 — không nuốt lỗi khởi động.** Nếu đọc session ném lỗi, phải phân biệt
"chưa từng cấu hình" với "có cấu hình nhưng đọc hỏng". Ca thứ hai **không được**
im lặng đưa về onboarding, vì onboarding sẽ ghi đè dữ liệu cũ (xem §2).

**P3 — kiểm trên máy thật** trước khi kết luận, theo cách ở §1 "Đã kiểm những gì".

---

## 2. 🔴 Đăng xuất xong không có đường vào lại

### Dựng lại được, từng bước

1. Cấu hình xong, nhà có bé "Minh", 12 việc.
2. Cài đặt → **ĐĂNG XUẤT**.
3. App về màn welcome, **chỉ có đường tạo nhà mới**. Không có nút nào để vào lại
   nhà vừa tạo.
4. Buộc phải làm lại onboarding, đặt tên bé "Lan".

Đọc file dữ liệu sau bước 4:

```
số gia đình : 2      Nhà mình (ace39848-…)   ← mồ côi, không còn đường vào
                     Nhà mình (4cc8807e-…)   ← đang dùng
số thành viên: 4     Bố mẹ + Minh  |  Bố mẹ + Lan
số việc      : 24    (12 cũ + 12 mới)
```

### Vì sao nặng hơn mô tả

Dữ liệu của Minh — xu, sổ cái, huy hiệu, mục tiêu — **không bị xoá**, nhưng
**không còn màn hình nào mở tới được**. Với người dùng thì y như mất; với máy
thì dữ liệu phình ra sau mỗi lần đăng xuất.

Sổ cái là thứ app hứa "chỉ ghi thêm, không sửa, không xoá". Lời hứa đó vô nghĩa
nếu cả cuốn sổ biến mất khỏi giao diện chỉ vì một lần bấm nhầm ĐĂNG XUẤT.

### Nguyên nhân gốc

`Session.logout()` xoá session của **thiết bị**, nhưng dữ liệu gia đình nằm ở
bảng khác và không bị đụng tới. Sau đó `router.dart` chỉ hỏi đúng một câu:

```dart
if (session == null && !isOnboarding) return Routes.onboarding;
```

`session == null` bị hiểu là *"máy này chưa có gì"*, trong khi thực tế nó có
thể là *"máy có đủ dữ liệu, chỉ là chưa chọn ai đang dùng"*. Hai trạng thái khác
hẳn nhau mà đang dùng chung một nhánh.

### Phương án

**Nguyên tắc:** onboarding chỉ dành cho máy **thật sự trống**. Máy đã có dữ liệu
thì phải vào màn **chọn người dùng**, không phải màn tạo nhà.

**P1 — tách hai trạng thái ở router.** Hỏi thêm "trong máy đã có gia đình nào
chưa":

| Có dữ liệu? | Có session? | Đi đâu |
|---|---|---|
| Không | Không | Onboarding (như hiện nay) |
| **Có** | **Không** | **Màn chọn người dùng (mới)** |
| Có | Có | Trang chính |

**P2 — màn chọn người dùng.** Liệt kê các thành viên đã có, bấm vào là vào. Vào
vai bố mẹ vẫn hỏi PIN như hiện nay. Dùng lại được phần lớn giao diện của sheet
"Đổi người dùng" đang có.

**P3 — đổi chữ ĐĂNG XUẤT.** Nút hiện nay không đăng xuất khỏi đâu cả — app không
có tài khoản. Việc nó thật sự làm là **khoá máy lại và hỏi ai đang dùng**. Đề
xuất đổi thành **"Khoá lại"**, kèm một dòng nói rõ dữ liệu vẫn còn.

**P4 — chặn tạo trùng.** Nếu vì lý do nào đó vẫn vào được onboarding trong khi
máy đã có gia đình, onboarding phải hỏi trước: *"Máy này đã có nhà «Nhà mình».
Vào lại nhà đó, hay tạo nhà mới?"* Đây là lưới an toàn cuối cho cả §1 lẫn §2.

### Test phải có

- Đăng xuất rồi vào lại: số gia đình trong máy **vẫn là 1**.
- Máy có dữ liệu + không có session → router trả về màn chọn người dùng,
  **không** phải onboarding.
- Máy trống + không có session → vẫn là onboarding.

---

## 3. 🔴 Quên PIN là mất quyền bố mẹ vĩnh viễn

### Dựng lại được

Đặt PIN → đổi sang vai con → muốn quay lại vai bố mẹ:

- Màn nhập PIN chỉ có ô nhập và nút **HUỶ**. Không có "Quên PIN?".
- Vai con **không vào được Cài đặt** — `router.dart` chặn thẳng.
- "Đổi PIN" và "Bỏ PIN" đều nằm **bên trong** Cài đặt.

Tức là: đường duy nhất để bỏ PIN nằm sau chính cái PIN đã quên. Không có cách
nào thoát ngoài gỡ app — mà gỡ app là **mất toàn bộ dữ liệu**.

### Vì sao đây là lỗi thật, không phải bảo mật tốt

Chính app đã viết trong tài liệu rằng PIN bốn số **không phải bảo mật thật** —
nó chỉ chặn một đứa trẻ tò mò. Một cơ chế không nhằm chống kẻ tấn công thì
không có lý do gì để trừng phạt người quên bằng cách xoá sạch dữ liệu.

Cái giá đang lệch hoàn toàn: rủi ro là "trẻ mò được vào Cài đặt", còn hình phạt
là "mất hết sổ xu của con".

### Phương án

**P1 — thêm "Quên PIN?" vào màn nhập.** Bấm vào hiện một hộp thoại nói rõ hệ quả
rồi cho gỡ PIN. Không hỏi gì thêm.

Lập luận: người có thiết bị trong tay vốn đã đọc được file dữ liệu, nên "gỡ PIN
cần thiết bị" không hạ mức bảo vệ đi chút nào so với hiện tại. Nó chỉ bỏ đi cái
bẫy mất dữ liệu.

**P2 — nếu muốn chặt hơn** (chỉ làm nếu anh thấy P1 quá lỏng): thêm bước xác nhận
có ma sát — gõ đúng một câu như `GO PIN`, kèm cảnh báo. Vẫn tự làm được, nhưng
không bấm nhầm.

**P3 — nói trước ngay lúc đặt PIN.** Màn đặt PIN nên có một dòng: *"Quên PIN thì
gỡ được ngay trên máy này, không cần cài lại app."* Nói trước thì không ai hoảng.

**Không** đề xuất câu hỏi bí mật hay email khôi phục: app không có tài khoản,
không có email, và thêm hai thứ đó là thêm dữ liệu cá nhân vào một app trẻ em —
đi ngược đúng thứ app đang bán.

### Test phải có

- Màn nhập PIN có đường "Quên PIN?" và bấm được.
- Gỡ PIN qua đường đó xong thì vào lại vai bố mẹ được ngay.
- Đặt PIN xong, màn hình có nói cách gỡ khi quên.

---

## Thứ tự đề nghị làm

1. **§3 P1 + P3** — nhỏ, gọn trong một màn, gỡ ngay bẫy mất dữ liệu.
2. **§2 P1 + P2 + P3** — việc chính, cần thêm một màn hình mới.
3. **§2 P4** — lưới an toàn, chặn tạo gia đình trùng.
4. **§1 P1 + P2** — thêm dấu vết chẩn đoán, rồi kiểm lại trên máy thật.

§2 và §3 nên làm **trước khi phát hành cho người ngoài dùng**: cả hai đều dẫn
tới mất dữ liệu thật, và cả hai đều không có đường tự cứu.

---

## Ghi chú cho người sửa

- Ràng buộc nào tuyên bố ở đây thì phải có test tương ứng, nếu không nó chỉ là
  ước muốn — dự án này đã dọn nhiều lần đúng loại đó.
- Đừng thêm cột hay cờ mới rồi để không ai đọc. Đã có sáu chỗ như vậy trong lịch
  sử dự án; cái mới nhất (`TaskCard.isPending`) vừa phải sửa hôm 17/08.
- Sau khi sửa, chạy app thật và soi ảnh chụp. Cả ba lỗi trong tài liệu này đều
  không có test nào bắt được, và §2 chỉ lộ ra khi đọc thẳng file dữ liệu.
