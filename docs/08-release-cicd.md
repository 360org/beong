# 08 — Phát hành lên App Store / Play Store qua CI/CD

Workflow: `.github/workflows/release.yml`, chạy tay từ tab **Actions → Release → Run workflow**.
Repo public nên GitHub-hosted runner (kể cả macOS) miễn phí không giới hạn phút.

Trước mỗi lần chạy: tăng `version:` trong `pubspec.yaml` (`x.y.z+build`) — build number
phải tăng, cả hai store đều từ chối nộp trùng build number.

## Bundle ID / package name

Đã cố định: **`net.beong.app`** — dùng chung cho cả Android (`applicationId`) và iOS
(`PRODUCT_BUNDLE_IDENTIFIER`). Không đổi được sau khi đã public lên store.

---

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

Tab **Actions → Release → Run workflow**, chọn:
- `platforms`: `both` / `android` / `ios`
- `android_track`: `internal` (kiểm thử nội bộ, lên máy ngay) hoặc `production`
- `ios_lane`: `beta` (đẩy lên TestFlight) hoặc `release` (đẩy build đã duyệt lên bản chờ
  submit — vẫn phải tự bấm "Submit for Review" trên App Store Connect, workflow không tự
  submit để tránh nộp nhầm bản chưa test)

**Luồng khuyến nghị:** `internal` + `beta` vài lần đầu để test kỹ trên máy thật qua
Play Console Internal Testing / TestFlight, sau đó mới chạy `production` / `release`.

## 4. Android: lần đầu lên Play Store

Play Console không cho phát hành thẳng lên `production` nếu app chưa qua ít nhất một
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
