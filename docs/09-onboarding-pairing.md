# 09 — Luồng khởi tạo & ghép cặp thiết bị con

Cụ thể hoá ADR-006 ("trẻ không có tài khoản đăng nhập, thiết bị con được ghép cặp một lần").
Tài liệu này là nguồn sự thật cho luồng từ lúc tải app đến lúc trẻ tick được việc đầu tiên.

## 1. Luồng chuẩn

Luồng đi qua **hai thiết bị**, và đây là điểm dễ nhầm nhất khi đọc dạng danh sách phẳng: cùng
một app nhưng hai vai khác nhau, giữ dữ liệu khác nhau, quyền khác nhau.

### Thiết bị bố mẹ

| # | Bước | Ghi chú |
|---|---|---|
| 1 | Tải app, mở lần đầu | |
| 2 | Chọn vai **Bố mẹ** | Ghi nhớ vĩnh viễn, không hỏi lại (§3.1) |
| 3 | Đăng nhập Google **hoặc** Apple | Trên iOS bắt buộc có cả hai (§5.2) |
| 4 | Tạo hồ sơ gia đình | Tên nhà, múi giờ, giờ đổi ngày (ADR-008) |
| 5 | Tạo hồ sơ con — 1 đứa, 2 đứa, … | Tên, con vật, màu, nhóm tuổi |
| 6 | Thêm task cho từng con | Chọn routine dựng sẵn hoặc task lẻ |
| 7 | Mở QR ghép cặp cho **một** con cụ thể | QR có hạn, dùng một lần (§4) |

### Thiết bị con

| # | Bước | Ghi chú |
|---|---|---|
| 8 | Tải app, mở lần đầu | |
| 9 | Chọn vai **Con** | |
| 10 | Quét QR trên máy bố mẹ | Cần mạng đúng một lần ở bước này |
| 11 | Nhận credential phạm vi hẹp, tải dữ liệu của mình | Chỉ dữ liệu của chính bé đó |
| 12 | Bắt đầu tick checklist | Từ đây chạy offline được |

Bước 6 đứng trước bước 7 là **đúng và nên giữ**: bé mở app lần đầu thấy việc ngay, không thấy
màn hình trống. Nhưng app vẫn phải cho ghép cặp bất cứ lúc nào, và app con phải xử lý được
trạng thái "đã ghép nhưng chưa có việc nào".

## 2. Những gì app hiện **chưa** có

Luồng trên cần bốn khối hạ tầng mà bản hiện tại chưa có khối nào:

| Khối | Trạng thái | Ghi chú |
|---|---|---|
| Chọn vai + ghi nhớ | ✗ chưa có | App hiện luôn vào onboarding bố mẹ |
| Lưu session bền vững | ✗ **đang lỗi** | Mở lại app là mất session, phải onboarding lại từ đầu |
| Auth (Google/Apple) | ✗ chưa có | Chưa có tầng auth nào |
| Backend + RLS | ✗ chưa có | Supabase đã chọn (ADR-004), chưa dựng |

Session không được lưu là **lỗi đang chặn đường**, không phải thiếu tính năng: hiện tại mở lại
app thì `sessionProvider` về `null` → router đẩy về onboarding → tạo lại gia đình mới. Phải sửa
trước mọi thứ khác, vì cả hai vai đều dựa vào nó.

## 3. Ràng buộc kiến trúc

### 3.1 Vai được ghi nhớ, nhưng vai **không** cấp quyền

Vai lưu ở local chỉ để biết mở màn hình nào. Quyền phải suy ra từ **credential**, không từ cờ
local. Nếu không, trẻ chỉ cần đổi vai trong Cài đặt là thành bố mẹ.

Bất biến: *thiết bị con giữ credential phạm vi hẹp; đổi vai thành "Bố mẹ" chỉ dẫn tới màn hình
đăng nhập, không cấp thêm quyền gì.* Nhờ vậy việc đổi vai không cần khoá bằng PIN — nó vô hại.

### 3.2 QR **không** chứa dữ liệu

Dễ nghĩ là nhét `family_id` + tên con vào QR cho gọn. Không được, vì hai lý do:

- QR bị chụp lại (bạn bè, ảnh chụp màn hình, camera lớp học) sẽ tiết lộ dữ liệu của trẻ ngay cả
  sau khi hết hạn.
- Không có đường thu hồi: dữ liệu đã nằm trong ảnh thì không rút lại được.

QR chỉ chứa **một mã dùng một lần**, tự nó vô nghĩa. Mọi dữ liệu đi qua server sau khi mã được
xác thực.

### 3.3 Ghép cặp bắt buộc cần backend

Hệ quả trực tiếp của §3.2: **không có backend thì không ghép cặp được**. Đây là điểm cần chú ý
với lộ trình hiện tại — `05-roadmap.md` đặt backend ở Sprint 4, sau Sprint 3 (phần thưởng). Nếu
coi luồng này là yêu cầu của v1 thì backend phải lên trước Sprint 3, hoặc luồng phải chia pha
(xem §7).

Không có cách nào ghép cặp "local-only" cho ra sản phẩm thật. Ghép qua LAN/Bluetooth thì hỏng
ngay khi hai máy không cùng mạng, mà đó là trường hợp thường gặp (bố mẹ ở cơ quan, con ở nhà).

### 3.4 Sau khi ghép, thiết bị con chạy offline

Ghép cặp cần mạng **một lần**. Sau đó app con đọc/ghi Drift local như hiện nay và đồng bộ khi có
mạng (ADR-002). Trẻ tick việc lúc mất mạng vẫn phải được cộng xu ngay.

## 4. Thiết kế ghép cặp bằng QR

### Tạo mã (máy bố mẹ, đã đăng nhập)

```
POST /pairing-codes  { child_member_id }
  -> { code, expires_at }
```

- `code`: 128 bit ngẫu nhiên, server chỉ lưu **hash**
- Hạn: 10 phút. Dùng **một lần**. Gắn với đúng một `(family_id, child_member_id)`
- QR mã hoá: `beong://pair?v=1&c=<code>` — không tên, không id gia đình

App bố mẹ hiện đồng hồ đếm ngược và nút tạo lại mã, để bố mẹ hiểu mã có hạn.

### Đổi mã (máy con)

```
POST /pairing-codes/redeem  { code, device_name, platform }
  -> { device_id, refresh_token, family_id, member_id }
```

Server kiểm: mã tồn tại, chưa hết hạn, chưa dùng. Sau đó tạo bản ghi `devices` và cấp
**credential phạm vi hẹp** gắn với `(family_id, member_id, device_id)` — không phải session của
một auth user.

`refresh_token` lưu ở **secure storage** (Keychain / Keystore), không lưu ở `SharedPreferences`.

### Phạm vi quyền của thiết bị con

RLS phải chặn theo hàng, không chỉ theo gia đình:

| Bảng | Quyền của thiết bị con |
|---|---|
| `task_instances` | đọc/sửa **chỉ** của `member_id` mình |
| `point_transactions` | chỉ đọc của mình |
| `tasks`, `routines` | chỉ đọc, chỉ những task được gán cho mình |
| `rewards` | chỉ đọc danh mục |
| `redemptions` | tạo được của mình, không tự duyệt |
| `members` | đọc tên/avatar anh chị em; **không** đọc năm sinh, PIN |
| Duyệt việc, sửa task, sửa xu | ✗ không có quyền |

Điểm quan trọng: **thiết bị con không được đọc dữ liệu của anh chị em**. Máy bị mượn, bị mất, hay
bé tò mò đều không lấy được điểm/lịch sử của đứa khác.

### Thu hồi

Bố mẹ xem danh sách thiết bị đã ghép và xoá được. Xoá → refresh token vô hiệu → máy con về
trạng thái chưa ghép, dữ liệu local bị xoá ở lần mở app kế tiếp có mạng.

## 5. Riêng tư & chính sách store

Phần này ảnh hưởng tới **mô hình dữ liệu ngay từ giờ**, không phải việc để dành tới lúc phát hành.

### 5.1 Server giữ càng ít về trẻ càng tốt

`members.birthYear` hiện dùng để chọn nhóm tuổi giao diện (`age_band.dart`). Năm sinh chính xác
của trẻ là dữ liệu cá nhân của trẻ vị thành niên, mà giao diện **chỉ cần nhóm tuổi**.

Quyết định: **đồng bộ nhóm tuổi (`little`/`middle`/`teen`), giữ năm sinh chỉ ở local máy bố mẹ.**
Mất rất ít, giảm được nghĩa vụ đáng kể.

### 5.2 Sign in with Apple là bắt buộc, không phải tuỳ chọn

Nếu app có đăng nhập Google trên iOS thì App Store yêu cầu có thêm một lựa chọn đăng nhập bảo vệ
quyền riêng tư tương đương — Sign in with Apple thoả điều đó. Anh đã muốn cả hai nên không phát
sinh việc, nhưng ghi lại để sau này không ai cắt bớt cho nhanh.

### 5.3 Những thứ cần kiểm lại tại thời điểm nộp store

Chính sách app trẻ em đổi khá thường xuyên, nên đây là danh sách **phải tra lại**, không phải kết
luận:

- App Store Kids Category: giới hạn về analytics/SDK bên thứ ba, yêu cầu parental gate cho link
  ra ngoài. ADR-010 (không quảng cáo, không analytics bên thứ ba) đã đi đúng hướng này.
- Google Play Families policy: yêu cầu tương tự.
- Cả hai store đều bắt buộc có chính sách quyền riêng tư — đã có trong Sprint 6.
- Camera: quét QR cần quyền camera, phải khai lý do trong `Info.plist` /
  `AndroidManifest.xml`. Chỉ xin quyền **đúng lúc bấm quét**, không xin lúc mở app.

## 6. Trường hợp thực tế phải xử lý

Luồng chính chỉ là đường thẳng đẹp nhất. Những ca dưới đây xảy ra thật và phải có đường đi:

| Ca | Xử lý |
|---|---|
| Hai con dùng chung một iPad | Một thiết bị giữ **nhiều** hồ sơ con đã ghép + nút chuyển. Ghép thêm bằng cách quét QR của đứa kia. |
| Con mất/đổi máy | Bố mẹ thu hồi thiết bị cũ, tạo QR mới |
| Cài lại app trên máy con | Credential mất theo app → phải ghép lại |
| QR hết hạn giữa lúc quét | Máy con báo rõ "mã hết hạn", máy bố mẹ có nút tạo lại |
| Máy con không có mạng lúc quét | Báo rõ là bước này cần mạng; sau khi ghép mới chạy offline được |
| Bố/mẹ thứ hai | Cùng cơ chế QR nhưng cấp vai `parent` — dùng lại hạ tầng, xem `MembershipRole` |
| Bé chọn nhầm vai "Bố mẹ" | Đổi lại được, vô hại vì vai không cấp quyền (§3.1) |
| Máy bố mẹ cũng là máy con dùng | Đã có chuyển hồ sơ; cần PIN bố mẹ để về vai bố mẹ |

## 7. Checklist thực hiện

Chia pha theo thứ tự phụ thuộc. Pha 0 chặn tất cả phần còn lại.

### Pha 0 — Gỡ chặn (không có thì không làm được gì tiếp)

- [ ] **Lưu session bền vững** — hiện mở lại app là mất, phải onboarding lại (§2)
- [ ] Màn chọn vai Bố mẹ / Con ở lần mở đầu, ghi nhớ vĩnh viễn
- [ ] Tách điều hướng theo vai: app con không có tab Việc nhà/Cài đặt của bố mẹ
- [ ] Onboarding hiện tại tách làm hai: nhánh bố mẹ và nhánh con
- [ ] Test: mở lại app giữ đúng vai và đúng hồ sơ đang chọn

### Pha 1 — Tài khoản bố mẹ

- [ ] Dựng Supabase: schema theo `03-data-model.md`, migration SQL
- [ ] RLS theo `family_id` cho vai bố mẹ
- [ ] Google Sign-In
- [ ] Sign in with Apple (§5.2 — bắt buộc, không cắt)
- [ ] Liên kết tài khoản ↔ hồ sơ gia đình; xử lý ca "đăng nhập lại trên máy mới"
- [ ] Test: đăng nhập trên máy thứ hai thấy đúng gia đình

### Pha 2 — Hồ sơ con & task

- [ ] Tạo **nhiều** con (onboarding hiện chỉ tạo được 1)
- [ ] Sửa / xoá / vô hiệu hồ sơ con
- [ ] Chọn con khi thêm task (hiện gán cho tất cả)
- [ ] Hỏi năm sinh để chọn nhóm tuổi giao diện (hiện mọi bé rơi vào nhóm giữa)
- [ ] Test: task gán cho con A không hiện ở con B

### Pha 3 — Ghép cặp QR

- [ ] Bảng `pairing_codes` (lưu hash, TTL, cờ đã dùng) + bảng `devices`
- [ ] Endpoint tạo mã và đổi mã (§4)
- [ ] Credential phạm vi hẹp + **RLS theo hàng** cho thiết bị con (§4)
- [ ] Render QR ở app bố mẹ + đếm ngược + tạo lại mã
- [ ] Quét QR ở app con; xin quyền camera đúng lúc bấm quét
- [ ] Nhiều hồ sơ con trên cùng một thiết bị + nút chuyển
- [ ] Danh sách thiết bị đã ghép + thu hồi
- [ ] Test bảo mật: thiết bị con **không** đọc được dữ liệu anh chị em
- [ ] Test bảo mật: mã hết hạn / mã đã dùng đều bị từ chối
- [ ] Test: thu hồi thiết bị thì máy con mất quyền

### Pha 4 — Đồng bộ

- [ ] Outbox + SyncEngine + retry/backoff + idempotency (đã có trong Sprint 4)
- [ ] Realtime theo `family_id`
- [ ] Test: bé tick lúc mất mạng → có mạng thì bố mẹ thấy

### Pha 5 — Riêng tư & phát hành

- [ ] Chỉ đồng bộ nhóm tuổi, không đồng bộ năm sinh (§5.1)
- [ ] Chính sách quyền riêng tư + điều khoản
- [ ] Parental gate cho mọi link ra ngoài
- [ ] Tra lại chính sách Kids Category / Families tại thời điểm nộp (§5.3)

## 8. Ảnh hưởng tới lộ trình

Luồng này khiến **backend không còn là việc của Sprint 4** nếu coi nó là yêu cầu v1. Hai hướng:

**A. Đôn backend lên trước Sprint 3.** Luồng đầy đủ có sớm, đổi lại phần thưởng/streak lùi lại.

**B. Chia pha phát hành.** v1.0 chỉ một thiết bị (bố mẹ và con dùng chung máy — đã chạy được hôm
nay), v1.1 thêm tài khoản + ghép cặp. Ra hàng sớm hơn, nhưng "mỗi bé một máy" là điểm bán chính
nên hoãn nó cũng là hoãn giá trị lớn.

Việc chọn A hay B là quyết định sản phẩm, không phải kỹ thuật — cần chốt trước khi bắt Pha 1.
