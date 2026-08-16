# 08 — Phát hành lên App Store / Play Store qua CI/CD

Workflow: `.github/workflows/release.yml`, chạy tay từ tab **Actions → Release → Run workflow**.
Repo public nên GitHub-hosted runner (kể cả macOS) miễn phí không giới hạn phút.

Trước mỗi lần chạy: tăng `version:` trong `pubspec.yaml` (`x.y.z+build`) — build number
phải tăng, cả hai store đều từ chối nộp trùng build number.

## Bundle ID / package name

Đã cố định: **`net.beong.app`** — dùng chung cho cả Android (`applicationId`) và iOS
(`PRODUCT_BUNDLE_IDENTIFIER`). Không đổi được sau khi đã public lên store; đã chốt ở **ADR-026**.

Khi tạo App ID trên developer.apple.com và app trên Play Console, gõ **chính xác** chuỗi này. Gõ
lệch một ký tự thì build vẫn chạy và chỉ chết ở bước upload với "App not found", không nói vì sao.

---

# Phần I — Hướng dẫn từ số 0

Phần này là **thứ tự việc phải làm**, đọc từ trên xuống. Phần II là bảng tra cứu từng secret.

## Trước khi bắt đầu: cái gì tốn tiền, cái gì phải chờ

| Việc | Tiền | Thời gian chờ |
|---|---|---|
| Tài khoản Google Play Developer | **25 USD, trả một lần** | Xác minh danh tính 1–3 ngày. Tài khoản **cá nhân** mở gần đây còn phải qua một vòng test đóng **≥12 tester, giữ liên tục 14 ngày** trước khi được xin quyền lên production |
| Tài khoản Apple Developer | **99 USD/năm** | Xác minh 1–2 ngày, dạng tổ chức thì lâu hơn (cần D-U-N-S) |
| Máy Mac | không bắt buộc | CI dùng macOS runner của GitHub. Nhưng **cần Mac đúng một lần** để xuất chứng chỉ `.p12` (bước B-2) |

Hai việc **không** tự động hoá được, dù CI đã sẵn: **tạo tài khoản**, và **điền metadata store**
(mô tả, ảnh chụp, phân loại nội dung, khai báo dữ liệu). Cả hai store đều bắt làm trên web.

App cho trẻ em còn hai thứ **bắt buộc có trước khi nộp** mà hiện **chưa làm** (`05-roadmap.md`
Sprint 6): **chính sách quyền riêng tư có URL công khai**, và **icon + ảnh chụp**. Thiếu URL chính
sách quyền riêng tư là không điền xong nổi form, không cần chờ tới lúc review mới bị từ chối.

---

## A. Android — từ số 0 lên Play Store

### A-1. Tạo tài khoản Play Developer

1. https://play.google.com/console → **Create account** → chọn *cá nhân* hay *tổ chức*.
   **Tổ chức** cần mã D-U-N-S và lâu hơn; **cá nhân** thì phải chịu luật test-14-ngày ở A-5.
2. Trả 25 USD, nộp giấy tờ xác minh, chờ Google duyệt.

### A-2. Tạo keystore — **một lần cho cả đời app**

```bash
keytool -genkey -v -keystore release.keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias beong
```

> **Mất file này hoặc mất mật khẩu là không bao giờ update được app cũ nữa** — Play nhận diện
> app bằng chữ ký, không bằng tên. Sao lưu ít nhất hai chỗ (password manager + ổ ngoài).
> Không commit vào repo: `android/key.properties` và `*.jks` đã nằm trong `.gitignore`.

Bật **Play App Signing** ở A-4 thì Google giữ khoá ký cuối, keystore này thành khoá *upload* —
vẫn phải giữ, nhưng mất thì xin Google cấp lại được. **Nên bật.**

### A-3. Nạp 5 secret Android

Repo → **Settings → Secrets and variables → Actions → New repository secret**. Tên phải đúng
từng chữ vì workflow đọc theo tên: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `PLAY_STORE_SERVICE_ACCOUNT_JSON`.
Cách lấy từng cái: bảng §1.

`ANDROID_KEYSTORE_BASE64` là **nội dung file đã base64 thành một dòng**, không phải đường dẫn:

```bash
base64 -w0 release.keystore.jks           # Linux
base64 -i release.keystore.jks | pbcopy   # macOS
```

### A-4. Tạo app trên Play Console

**Play Console → Create app**: tên, ngôn ngữ mặc định (Tiếng Việt), *App*, *Free*.
Rồi đi hết các mục còn dấu chấm than ở **Dashboard**:

- **App content** — chính sách quyền riêng tư (URL), quảng cáo → **không**, quyền truy cập app,
  **Data safety**, **Content rating**
- **Target audience and content** — chọn nhóm tuổi có trẻ em, sẽ tự kéo theo bộ câu hỏi
  **Families Policy**. Trả lời trung thực: app **không quảng cáo, không mua trong app**
  (ADR-014); thu thập gì thì khai đúng cái đó
- **Store listing** — mô tả ngắn/dài, icon 512×512, ảnh feature 1024×500, ảnh chụp

### A-5. Bản đầu tiên phải qua track kiểm thử

Play **không** cho phát hành thẳng production:

1. Chạy workflow với `platforms: android`, `android_track: internal`
2. Play Console → **Testing → Internal testing** → thêm email tester → gửi link cho họ
3. Tài khoản **cá nhân** mở từ cuối 2023: thêm một vòng **Closed testing** với **≥12 tester
   giữ liên tục 14 ngày**, rồi mới xin được **Production access**
4. Được duyệt thì chạy lại với `android_track: production`

> Lần đầu `upload_to_play_store` sẽ **lỗi** nếu app chưa từng có bản nào trên Console —
> Google không cho tạo app mới hoàn toàn qua API. Gặp lỗi này thì build tại máy
> (`flutter build appbundle --release`) và upload tay **một lần** qua web; từ lần sau CI chạy được.

---

## B. iOS — từ số 0 lên App Store

### B-1. Tạo tài khoản Apple Developer

https://developer.apple.com/programs/ → đăng ký, trả 99 USD/năm, chờ duyệt.
Xong thì lấy **Team ID** (10 ký tự) ở **Membership** → nạp vào `IOS_TEAM_ID`.

### B-2. Chứng chỉ phân phối — bước duy nhất cần máy Mac

1. **Xcode → Settings → Accounts → Manage Certificates → + → Apple Distribution**
   (hoặc developer.apple.com → Certificates → + → Apple Distribution)
2. **Keychain Access** → tìm cert vừa tạo → chuột phải → **Export** → định dạng `.p12`, đặt
   mật khẩu. Phải export **kèm private key**; nếu Keychain không cho chọn `.p12` là đang chọn
   nhầm dòng — chọn dòng cert mở ra được khoá bên trong.
3. `base64 -i cert.p12 | pbcopy` → `IOS_DIST_CERTIFICATE_BASE64`;
   mật khẩu vừa đặt → `IOS_DIST_CERTIFICATE_PASSWORD`

Không có Mac thì mượn một lần cũng được — xong rồi secret dùng mãi, CI không cần Mac riêng.

### B-3. App ID + provisioning profile

1. developer.apple.com → **Identifiers → +** → App IDs → App → Bundle ID **`net.beong.app`**
   (Explicit, **không** dùng wildcard)
2. → **Profiles → + → App Store Connect** → chọn App ID trên → chọn cert ở B-2 → **đặt tên** →
   Download
3. `base64 -i *.mobileprovision | pbcopy` → `IOS_PROVISIONING_PROFILE_BASE64`;
   **tên đã đặt ở bước 2** (không phải tên file) → `IOS_PROVISIONING_PROFILE_NAME`

Sai tên profile là lỗi hay gặp nhất: `xcodebuild` báo *"No profile matching … found"* mà không
nói nó đang tìm tên gì. Kiểm lại chính tả, kể cả dấu cách.

### B-4. Khoá App Store Connect API

**App Store Connect → Users and Access → Integrations → Team Keys → +**, role **App Manager**.

- `APP_STORE_CONNECT_KEY_ID` — Key ID trong bảng
- `APP_STORE_CONNECT_ISSUER_ID` — hiện ở đầu trang, dùng chung cho cả team
- `APP_STORE_CONNECT_API_KEY_BASE64` — file `.p8` **chỉ tải được một lần duy nhất**. Tải xong
  lưu ngay: `base64 -i AuthKey_XXXX.p8 | pbcopy`. Mất thì thu hồi key và tạo key mới.

### B-5. Tạo app trên App Store Connect

**My Apps → + → New App**: platform iOS, tên, ngôn ngữ chính, chọn bundle ID `net.beong.app`
(chỉ hiện ra sau khi làm B-3), SKU tự đặt.

Rồi điền: mô tả, từ khoá, ảnh chụp (đúng kích thước Apple yêu cầu cho từng dòng máy),
**Privacy Policy URL** (bắt buộc), **App Privacy**, **Age Rating**. App cho trẻ em thì xem thêm
yêu cầu **Kids Category** — vào Kids Category là Apple review khắt khe hơn về quảng cáo,
phân tích hành vi và link ra ngoài.

### B-6. Nộp bản đầu

1. Chạy workflow với `platforms: ios`, `ios_lane: beta` → build lên **TestFlight**
2. Apple xử lý build vài phút tới vài giờ mới hiện cho tester. Build đầu còn phải trả lời
   **Export Compliance** (app này không dùng mã hoá riêng ngoài HTTPS)
3. Test xong trên máy thật → App Store Connect → chọn build → **Submit for Review**

> Workflow **không** tự bấm Submit for Review, kể cả lane `release` — cố ý, để không nộp nhầm
> một bản chưa test lên store công khai.

---

## C. Thứ tự khuyến nghị cho lần đầu

1. **Android trước** — rẻ hơn, duyệt nhanh hơn, không cần Mac → `internal` → cầm máy test thật
2. **Song song**: đăng ký Apple và làm B-2 → B-4, vì mấy bước này phải chờ người khác duyệt
3. iOS `beta` → TestFlight
4. Chuẩn bị **icon, ảnh chụp, chính sách quyền riêng tư** — đây mới là việc chặn thật, không phải CI
5. Beta 10 gia đình (Sprint 6), sửa xong mới `production` / Submit for Review

---

# Phần II — Bảng tra cứu secret

**Không secret nào được ghi vào repo.** Hai bảng dưới chỉ ghi *tên* secret và cách tự lấy giá
trị; giá trị chỉ tồn tại trong GitHub Secrets và trong password manager của chủ dự án.

## 1. Secrets cho Android

Vào **Settings → Secrets and variables → Actions** của repo, thêm:

| Secret | Cách lấy |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Tạo keystore release (chỉ tạo **một lần duy nhất**, mất là không update app cũ được nữa): `keytool -genkey -v -keystore release.keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias beong`. Sau đó `base64 -i release.keystore.jks \| pbcopy` (macOS) hoặc `base64 -w0 release.keystore.jks` (Linux) rồi dán vào secret. |
| `ANDROID_KEYSTORE_PASSWORD` | Mật khẩu đã đặt lúc `keytool -genkey` |
| `ANDROID_KEY_ALIAS` | Alias đã đặt, ví dụ `beong` |
| `ANDROID_KEY_PASSWORD` | Thường giống `ANDROID_KEYSTORE_PASSWORD` trừ khi đặt riêng |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Play Console → **Setup → API access** → tạo service account trong Google Cloud Console (role "Service Account User") → cấp quyền "Release manager" cho app trong Play Console → tạo key JSON → dán **nguyên nội dung file JSON** vào secret |

Lưu ý: app phải đã tồn tại trên Play Console (tạo app, điền metadata tối thiểu, nộp
**thủ công một bản đầu tiên** qua web) trước khi `upload_to_play_store` API hoạt động —
Google không cho tạo app mới hoàn toàn qua API.

Muốn dùng cho local dev (không qua CI): tạo file `android/key.properties` (đã gitignore):
```properties
storeFile=/đường/dẫn/tới/release.keystore.jks
storePassword=...
keyAlias=beong
keyPassword=...
```

## 2. Secrets cho iOS

| Secret | Cách lấy |
|---|---|
| `IOS_DIST_CERTIFICATE_BASE64` | Xcode → Settings → Accounts → Manage Certificates → tạo "Apple Distribution" cert, hoặc qua developer.apple.com → Certificates. Export ra `.p12` từ Keychain Access (kèm private key), rồi `base64 -i cert.p12 \| pbcopy` |
| `IOS_DIST_CERTIFICATE_PASSWORD` | Mật khẩu đặt lúc export `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | developer.apple.com → Profiles → tạo profile **App Store** cho `net.beong.app`, download, `base64 -i profile.mobileprovision \| pbcopy` |
| `IOS_PROVISIONING_PROFILE_NAME` | Tên chính xác đã đặt cho profile ở bước trên (không phải tên file) |
| `IOS_TEAM_ID` | developer.apple.com → Membership → Team ID (10 ký tự) |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect → Users and Access → Integrations → Team Keys → tạo key mới (role "App Manager") |
| `APP_STORE_CONNECT_ISSUER_ID` | Cùng trang trên, hiện ở đầu bảng |
| `APP_STORE_CONNECT_API_KEY_BASE64` | File `.p8` chỉ tải được **một lần** lúc tạo key — lưu ngay, `base64 -i AuthKey_XXXX.p8 \| pbcopy` |

App phải đã được tạo trên App Store Connect (App Store Connect → My Apps → +, điền
bundle ID `net.beong.app`) trước khi `upload_to_testflight` hoạt động.

---

## 3. Chạy release

Workflow được kích hoạt tự động khi **push tag `v*`** (VD: `v0.2.0`), hoặc chạy tay từ tab **Actions → Release → Run workflow**:
- `platforms`: `both` / `android` / `ios` (mặc định: `both`)
- `android_track`: `production` (hoặc `internal` nếu chỉ test)
- `ios_lane`: `release` (tự động submit nộp duyệt và auto-release khi Apple duyệt) hoặc `beta` (chỉ đẩy TestFlight)

**Luồng khuyến nghị:** `internal` + `beta` vài lần đầu để test kỹ trên máy thật qua
Play Console Internal Testing / TestFlight, sau đó mới chạy `production` / `release`.

> **`ios_lane: release` upload một build MỚI**, không đề bạt build đang có trên TestFlight.
> Nên chạy `beta` rồi chạy `release` mà **không tăng `+build`** thì Apple từ chối lần sau
> (*"The bundle version must be higher"*). Muốn đưa đúng cái build đã test trên TestFlight lên
> App Store thì chọn build đó trên App Store Connect và bấm tay — nhanh hơn và chắc hơn.

## 4. Android: lần đầu lên Play Store

Play Console không cho phép phát hành thẳng lên `production` nếu app chưa qua ít nhất một
track kiểm thử (internal/closed) với người test thật. Trình tự:
1. `android_track: internal` → thêm tester qua email trong Play Console → test
2. Điền metadata store listing, content rating, data safety (làm thủ công trên web,
   không tự động hoá) qua CI
3. `android_track: production`

## 5. iOS: lần đầu lên App Store

TestFlight build cần Apple xử lý xong (vài phút tới vài giờ) trước khi hiện cho tester.
Sau khi test xong trên TestFlight, vào App Store Connect điền metadata (screenshot, mô tả,
privacy policy URL — bắt buộc vì app có trẻ em, xem thêm yêu cầu **Kids Category** /
**Family Policy** của Apple) rồi tự bấm "Submit for Review".

---

## 6. Lỗi hay gặp

| Triệu chứng | Nguyên nhân thật |
|---|---|
| `Version code X has already been used` / `The bundle version must be higher` | Chưa tăng `+build` trong `pubspec.yaml`. Build number phải tăng **mỗi lần nộp**, kể cả khi nộp lại bản vừa bị từ chối |
| `No profile matching 'X' found` | `IOS_PROVISIONING_PROFILE_NAME` khác tên profile trên developer.apple.com — dán tên **file** thay vì tên profile là ca phổ biến nhất |
| `No signing certificate "iOS Distribution" found` | `.p12` export thiếu private key, hoặc cert đã hết hạn (Apple Distribution sống 1 năm — hết hạn thì làm lại B-2 và B-3) |
| `keystore was tampered with, or password was incorrect` | Sai mật khẩu, hoặc base64 bị chèn newline. Trên Linux dùng `base64 -w0`, không dùng `base64` trần |
| `The caller does not have permission` (Play) | Service account chưa được cấp quyền **trong Play Console** — tạo key ở Google Cloud là chưa đủ, còn phải mời nó vào app với role Release manager |
| `App not found` / `Cannot find app with bundle id` | Chưa tạo app trên Console / ASC, hoặc bundle ID gõ khác `net.beong.app` |
| Workflow xanh nhưng không thấy build đâu | Apple xử lý xong build mới hiện trên TestFlight, Play cũng mất vài phút. Xem tab Activity / TestFlight trước khi kết luận là lỗi |
