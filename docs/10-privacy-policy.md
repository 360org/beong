# Chính sách quyền riêng tư — Bé Ong

**Cập nhật lần cuối:** 16/08/2026
**Áp dụng cho:** ứng dụng Bé Ong (bundle ID `net.beong.app`) trên iOS và Android.

> **Đây là bản thảo do đội phát triển soạn, chưa qua rà soát pháp lý.** App phục vụ trẻ em nên
> chịu COPPA (Hoa Kỳ), GDPR-K (EU) và Nghị định 13/2023/NĐ-CP (Việt Nam) về bảo vệ dữ liệu cá
> nhân. Trước khi nộp store, nhờ luật sư đọc lại — đặc biệt mục 4 và 8. Phần mô tả kỹ thuật ở
> đây thì đúng với mã nguồn tại thời điểm cập nhật.
>
> Tài liệu này cần được đăng ở một **URL công khai** trước khi điền form App Store Connect và
> Google Play Console; xem `08-release-cicd.md` §Chặn thật.

---

## 1. Tóm tắt

Bé Ong là ứng dụng giúp gia đình theo dõi việc nhà và phần thưởng cho trẻ.

- **Dữ liệu nằm trên máy của bạn.** App chạy đầy đủ khi không có mạng (ADR-002).
- **Không quảng cáo. Không mua trong app. Không thư viện theo dõi hành vi** (ADR-014).
- **Không bán, không chia sẻ dữ liệu** cho bên thứ ba vì mục đích tiếp thị.
- **Trẻ không cần tài khoản.** Hồ sơ trẻ không có email, số điện thoại hay bất kỳ định danh
  liên lạc nào (ADR-006).

---

## 2. Chúng tôi lưu những gì

Toàn bộ danh sách dưới đây nằm trong một file cơ sở dữ liệu **trên chính thiết bị**
(`beong.sqlite`).

### 2.1 Bạn tự nhập

| Dữ liệu | Ví dụ | Vì sao cần |
|---|---|---|
| Tên gia đình | "Nhà mình" | Hiện trên màn hình Cài đặt |
| Tên hiển thị của trẻ | "Minh" | Để trẻ nhận ra phần của mình |
| **Năm sinh** của trẻ (tuỳ chọn, bỏ trống được) | 2018 | Điều chỉnh cỡ chữ và icon theo tuổi |
| Con vật và màu đại diện | 🐯, màu xanh | Để trẻ chưa đọc thạo nhận ra hồ sơ |
| Việc nhà, thói quen, phần thưởng, mục tiêu tiết kiệm | "Gấp chăn màn", 10 xu | Chính là nội dung app |
| PIN của phụ huynh (tuỳ chọn) | 4 chữ số | Ngăn trẻ tự đổi sang vai bố mẹ |

**Chúng tôi không hỏi và không có chỗ để nhập**: họ tên đầy đủ, ngày sinh chính xác, địa chỉ,
số điện thoại, email của trẻ, ảnh khuôn mặt, vị trí, danh bạ.

### 2.2 App tự sinh ra

Nhật ký xu (mỗi lần cộng/trừ, kèm lý do), lượt việc theo ngày, chuỗi ngày liên tiếp, huy hiệu.
Tất cả đều dẫn xuất từ mục 2.1 và cũng chỉ nằm trên máy.

### 2.3 Chúng tôi **không** thu thập

- Không có SDK phân tích hành vi, không đo lường quảng cáo, không định danh thiết bị dùng cho
  quảng cáo (IDFA/GAID).
- Không thu thập tự động nhật ký sự cố hay số liệu sử dụng. Nếu sau này có, chính sách này sẽ
  được cập nhật **trước**, và sẽ là tuỳ chọn bạn tự bật.

---

## 3. PIN của phụ huynh

PIN được lưu dưới dạng **băm SHA-256**, không lưu bốn chữ số gốc.

Nói thẳng: đây **không phải bảo mật thật**. PIN 4 chữ số có 10.000 khả năng, ai lấy được file
cơ sở dữ liệu thì dò ra ngay. Nó chặn được một đứa trẻ tò mò, không chặn được người có thiết bị
trong tay. **Đừng dùng lại PIN ngân hàng hay mật khẩu điện thoại của bạn ở đây.**

---

## 4. Trẻ em

Bé Ong dành cho trẻ 5–15 tuổi **sử dụng dưới sự thiết lập của phụ huynh**.

- Hồ sơ trẻ do phụ huynh tạo trên máy của phụ huynh. Trẻ không đăng ký tài khoản, không nhập
  email, không nhận được lời mời kết bạn hay bất kỳ hình thức liên lạc nào với người lạ.
- App **không có** tính năng mạng xã hội, chat, bình luận, hay nội dung do người dùng khác tạo.
- App **không có** quảng cáo và **không có** mua trong app (ADR-014), nên không có luồng nào
  dụ trẻ chi tiền.
- Tính năng "quy đổi ra tiền thật" **mặc định tắt** (ADR-017) và chỉ là ghi sổ: app không kết
  nối ví điện tử, không chuyển tiền, không thu thập thông tin thanh toán.
- Vì phụ huynh là người tạo hồ sơ và mọi dữ liệu nằm trên thiết bị gia đình, việc thu thập
  diễn ra dưới sự kiểm soát trực tiếp của phụ huynh.

Nếu bạn là phụ huynh và muốn xoá dữ liệu của con, xem mục 6 — bạn làm được ngay trong app,
không cần liên hệ ai.

---

## 4b. Gửi báo lỗi

Trong Cài đặt có mục **Báo lỗi**. Đây là chỗ **duy nhất** trong app có thể đưa dữ liệu ra khỏi
máy, và nó chỉ chạy khi bạn chủ động bấm.

Khi bạn bấm, app soạn sẵn một nội dung gồm: mô tả bạn tự viết, thông tin thiết bị (hệ điều hành,
cỡ màn hình, cỡ chữ, phiên bản app), nhật ký lỗi kỹ thuật của phiên chạy hiện tại, và — nếu bạn
để bật — một ảnh chụp màn hình.

Ba điều quan trọng:

1. **Chỉ gửi khi bạn bấm nút.** Không có nền, không tự động, không định kỳ.
2. **Báo cáo thành một issue công khai trên GitHub** — ai cũng đọc được. Ảnh màn hình có thể
   chứa tên con và số xu, nên màn Báo lỗi hiện ảnh **xem trước** và có công tắc tắt ảnh đi.
3. **Nhật ký lỗi chỉ có thông điệp kỹ thuật**, không chứa tên, tuổi hay dữ liệu gia đình, và chỉ
   nằm trong bộ nhớ tạm — đóng app là mất.

Về đường đi kỹ thuật: app gửi tới một endpoint của nhà phát triển, endpoint đó tạo issue hộ.
App **không** chứa khoá truy cập GitHub — xem `11-bao-loi-endpoint.md` để biết vì sao.

Sau khi gửi, nội dung nằm trên GitHub và chịu
[chính sách quyền riêng tư của GitHub](https://docs.github.com/site-policy/privacy-policies).
Muốn xoá thì báo cho chúng tôi, hoặc tự xoá nếu bạn có tài khoản GitHub và là người tạo issue.

---

## 5. Chia sẻ với bên thứ ba

**Không**, trừ báo lỗi bạn tự gửi (mục 4b). App không tự gửi dữ liệu gia đình đi đâu cả.

Các thư viện mã nguồn mở app dùng (Flutter, Drift, SQLite, Riverpod, go_router) chạy hoàn toàn
trên thiết bị và không tự gửi dữ liệu ra ngoài.

**Sẽ thay đổi khi có đồng bộ nhiều thiết bị** (dự kiến bản sau, xem `05-roadmap.md` Sprint 3).
Khi đó dữ liệu gia đình sẽ được lưu trên máy chủ để các máy trong nhà đồng bộ với nhau, và
chính sách này sẽ được cập nhật với tên nhà cung cấp, nơi đặt máy chủ và thời gian lưu trữ
**trước khi** tính năng đó được bật.

---

## 6. Quyền của bạn — và cách tự làm

Vì dữ liệu nằm trên máy bạn, bạn không phải xin phép ai:

| Bạn muốn | Cách làm |
|---|---|
| Xem toàn bộ dữ liệu | Mở app — không có phần nào bị ẩn khỏi phụ huynh |
| Sửa tên, tuổi, avatar của trẻ | Cài đặt → chọn hồ sơ |
| Xoá **toàn bộ** dữ liệu | Gỡ cài đặt app. File cơ sở dữ liệu bị xoá cùng ứng dụng |
| Ngừng dùng mà giữ máy | Cài đặt → Đăng xuất |

Khi có đồng bộ máy chủ (mục 5), sẽ có thêm đường yêu cầu xoá dữ liệu phía máy chủ và xuất dữ
liệu ra file.

---

## 7. Quyền truy cập thiết bị

App hiện **không** xin quyền nào: không máy ảnh, không micro, không vị trí, không danh bạ,
không thông báo, không thư viện ảnh.

Ảnh chụp màn hình ở mục Báo lỗi do chính app tự vẽ lại từ giao diện của mình, không dùng chức
năng chụp màn hình của hệ điều hành — nên không cần quyền, và cũng **không** lấy được thanh
thông báo hay nội dung của ứng dụng khác.

Bản sau sẽ xin **thông báo** (để nhắc việc) và có thể xin **máy ảnh** (để trẻ chụp ảnh chứng
minh đã làm việc). Cả hai đều sẽ là tuỳ chọn, hỏi đúng lúc dùng, và từ chối vẫn dùng app bình
thường.

---

## 8. Cơ sở pháp lý và lưu trữ

- **Cơ sở xử lý dữ liệu** (GDPR Điều 6): sự đồng ý của phụ huynh khi tạo hồ sơ, và việc thực
  hiện chính chức năng bạn yêu cầu.
- **Thời gian lưu**: cho tới khi bạn xoá — dữ liệu ở trên máy bạn, chúng tôi không giữ bản sao
  nào.
- **Chuyển dữ liệu ra nước ngoài**: chỉ khi bạn gửi báo lỗi — máy chủ GitHub đặt ngoài Việt Nam.
  Ngoài đường đó ra, không có truyền dữ liệu nào.

---

## 9. Thay đổi chính sách

Thay đổi có ảnh hưởng thật (thu thập thêm dữ liệu, thêm bên thứ ba, bật đồng bộ máy chủ) sẽ
được thông báo **trong app** trước khi có hiệu lực, không chỉ sửa lặng lẽ ngày ở đầu trang.

---

## 10. Liên hệ

*(Cần điền trước khi đăng công khai — form của cả hai store bắt buộc có địa chỉ liên hệ.)*

- Email: `<chưa điền>`
- Đơn vị phát hành: `<chưa điền>`

---

## Phụ lục — khai báo cho store

Dùng khi điền form; giữ khớp với các mục trên.

**Apple — App Privacy (App Store Connect):**
- Phần app tự thu thập: **Data Not Collected**.
- Riêng mục **Báo lỗi**: khai là *Diagnostics → Crash Data / Other Diagnostic Data*, mục đích
  *App Functionality*, **không** liên kết với danh tính người dùng, **không** dùng để theo dõi.
  Nội dung chỉ rời máy khi người dùng chủ động bấm gửi — nhưng đây vẫn là truyền dữ liệu, nên
  khai đúng như mục 4b, đừng giấu.
- Phải khai lại khi bật đồng bộ ở Sprint 3.

**Google — Data safety (Play Console):**
- "Does your app collect or share any of the required user data types?" → **Yes**, đúng một
  mục: *App info and performance → Crash logs / Diagnostics*, "Optional" (người dùng tự bấm).
- "Is all of the user data collected by your app encrypted in transit?" → **Yes** (HTTPS).
- "Do you provide a way for users to request that their data is deleted?" → **Yes**, gỡ cài đặt
  xoá toàn bộ dữ liệu.

**Cả hai store — phần trẻ em:**
- Không quảng cáo, không mua trong app (ADR-014).
- Play: cân nhắc chương trình **Teacher Approved**; Apple: cân nhắc **Kids Category**. Cả hai
  đều siết thêm về SDK bên thứ ba — app hiện không có SDK nào như vậy nên đủ điều kiện.
