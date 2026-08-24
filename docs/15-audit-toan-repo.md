# 15 — Audit toàn repo, giao việc cho agent khác

**Ngày:** 24/08/2026 · **Bản kiểm:** `0.2.7+14`, commit `898da2b` ·
**Cách kiểm:** quét **có hệ thống** bằng script, không đọc lướt. Mỗi phát hiện
đều kèm lệnh dựng lại được.

Tài liệu này viết để **giao cho một agent khác sửa**. Mỗi mục có: bằng chứng,
cách dựng lại, việc phải làm, và cách biết là đã xong.

Hai audit trước: [`13`](13-audit-luong-vao-app.md) (luồng vào app, đã đóng),
[`14`](14-audit-tinh-nang-moi.md) (Sprint 3 & 5 + giao diện).

---

## Trạng thái hiện tại

`flutter analyze --fatal-infos` sạch · **523 test + 4 integration test xanh** ·
`dart format` sạch · phiên bản đồng bộ.

## Tóm tắt phát hiện

| # | Vấn đề | Mức | Người sửa |
|---|---|---|---|
| 1 | **"Chụp ảnh" không hề chụp ảnh** — cổng chặn hoạt động, bằng chứng thì không tồn tại | 🔴 | agent |
| 2 | `PushNotificationService` — **cả file không ai import** | 🔴 | agent |
| 3 | `SyncEngine` + `NotificationService` — chỉ có provider, không ai gọi | 🟠 | agent (Sprint 3) |
| 4 | **Hai file CHANGELOGS** cùng tồn tại, đã lệch nhau | 🟠 | agent |
| 5 | `Rewards.requiresApproval` — cột **mâu thuẫn với ADR-025** | 🟠 | agent |
| 6 | 5 cột schema không ai đọc/ghi | 🟡 | agent |
| 7 | Không test nào canh **chỗ gọi** truyền `batBuoc` đúng | 🟡 | agent |
| 8 | Preset `exercise` vẫn dùng emoji người 🏃 | 🟡 | **chủ dự án chốt** |

Ba mục 🔴/🟠 đầu là **cùng một lỗi** — thứ tồn tại trong code nhưng không nằm
trên đường chạy nào. Đây là lần thứ **mười** dự án gặp nó.

---

## 1 · 🔴 "Chụp ảnh" không hề chụp ảnh

Audit `14` §2 đã nối `proof_mode` vào `TaskReviewService`: việc có yêu cầu bằng
chứng thì **buộc qua duyệt**. Phần đó đúng và có test.

Nhưng **bằng chứng thì không tồn tại**:

```bash
grep -rn "image_picker\|ImagePicker\|proofUrl" lib --include=*.dart
#  → chỉ ra đúng một dòng: khai báo cột trong tables.dart
```

- Không có gói chụp ảnh nào trong `pubspec.yaml`.
- Cột `task_instances.proof_url` **chưa từng được ghi**.
- Con bấm xong việc: không ai hỏi ảnh.
- Bố mẹ mở hàng đợi duyệt: **không có gì để xem**, chỉ có tên việc như mọi việc khác.

Nghĩa là bố mẹ bật "Chụp ảnh", thấy việc vào hàng chờ duyệt, và **tin rằng mình
đang duyệt dựa trên một tấm ảnh không hề có**. Đó là dạng sai tệ hơn cả không
làm gì: nó tạo niềm tin sai.

**Việc phải làm — chọn một, không để nguyên:**

- **A. Làm cho đủ:** thêm chụp/chọn ảnh khi con bấm xong, lưu vào thư mục app
  (offline-first, ADR-002 — **không** upload), ghi đường dẫn vào `proof_url`,
  và hiện ảnh đó trong hàng đợi duyệt của bố mẹ. Chế độ `note` thì hiện ô ghi
  chú.
- **B. Thu hẹp cho thật:** đổi nhãn từ "Chụp ảnh 📷 / Ghi chú ✎" thành đúng thứ
  nó làm — ví dụ "Việc này luôn cần bố mẹ duyệt" — và bỏ cột `proof_url`.

**Xong khi:** hoặc bố mẹ nhìn thấy ảnh/ghi chú thật trong hàng đợi duyệt, hoặc
không còn chữ nào trong app hứa hẹn ảnh. Kèm test.

## 2 · 🔴 `PushNotificationService` — cả file không ai import

```bash
grep -rn "PushNotification\|pushNotification" lib --include=*.dart \
  | grep -v push_notification_service.dart
#  → không có kết quả
```

109 dòng, thêm ở `0.2.7`. Không gắn vào provider nào, không màn hình nào gọi,
`main.dart` không khởi tạo. Nặng hơn `SyncEngine` ở mục 3 — cái đó ít ra còn có
provider.

Kèm theo đó, đã commit vào repo:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `supabase/functions/notify-fcm/index.ts`
- `supabase/migrations/20260824000000_device_tokens_and_push.sql`

Tức là **hạ tầng phía máy chủ có, cấu hình có, mã client có — nhưng không có
đường nào nối chúng lại**. Không thông báo nào được gửi hay nhận.

**Việc phải làm:** hoặc nối vào `main.dart` (xin quyền, đăng ký token, lưu vào
`device_tokens`, xử lý thông báo tới), hoặc ghi rõ trong roadmap là "đã viết,
chưa nối" như đã làm với `SyncEngine`. **Đừng để ✅ trơn.**

> **Lưu ý bảo mật, cần kiểm chứ chưa kết luận:** hai file cấu hình Firebase là
> định danh client, thường vẫn commit được. Nhưng khoá API trong đó **phải được
> giới hạn** (theo bundle ID / package name / SHA-1) ở Google Cloud Console.
> Người có quyền vào console cần xác nhận điều này — không kiểm được từ repo.

## 3 · 🟠 `SyncEngine` + `NotificationService` vẫn chỉ có provider

Quét lại 24 provider trong `database_provider.dart`. Kết quả:

- **`syncEngineProvider`** và **`notificationServiceProvider`**: không nơi nào
  dùng, kể cả trong chính file khai báo.
- Các `*DaoProvider` cũng chỉ dùng trong file đó — **nhưng đúng kiến trúc**:
  `lib/features` không được chạm DAO, có `test/unit/kien_truc_test.dart` canh.
  Đừng nhầm hai loại này với nhau.
- `goalServiceProvider` / `streakServiceProvider`: dùng để dựng
  `dayStartService` ngay trong file. Bình thường.

Roadmap đã nói đúng về mục này ("đã viết logic, chờ tích hợp"). Giữ nguyên cách
mô tả đó cho tới khi Sprint 3 nối thật.

## 4 · 🟠 Hai file CHANGELOGS, đã lệch nhau

```
CHANGELOGS.md         14 707 byte
docs/CHANGELOGS.md    12 642 byte
```

Hai file, hai nội dung khác nhau. `README.md` trỏ vào bản ở gốc. Đây là loại
lỗi tự nhân lên: người sau sửa một bản, bản kia im lặng cũ đi.

**Việc phải làm:** giữ **một** bản (đề nghị giữ `CHANGELOGS.md` ở gốc vì README
và quy ước dự án đang trỏ vào đó), gộp phần chỉ có ở bản kia sang, xoá bản thừa,
kiểm mọi liên kết còn sống.

## 5 · 🟠 `Rewards.requiresApproval` mâu thuẫn với ADR-025

ADR-025 ghi rõ: **"Đổi thưởng luôn cần bố mẹ duyệt, không cấu hình được."**

Nhưng bảng `Rewards` có cột `requires_approval`. Không dòng code nào đọc nó —
may mắn, vì nếu có ai đọc thì đó là một đường phá thẳng ADR-025.

Cột này là một cái bẫy đặt sẵn: người sau thấy nó, tưởng là tính năng chưa nối,
và nối vào.

**Việc phải làm:** gỡ cột trong một migration, hoặc nếu chưa muốn migration thì
thêm chú thích ngay tại `tables.dart` nói rõ **không được đọc cột này** và vì
sao. Ưu tiên gỡ hẳn.

## 6 · 🟡 Năm cột schema không ai đọc/ghi

| Cột | Bảng | Ghi chú |
|---|---|---|
| `proof_url` | TaskInstances | Xem mục 1 — gắn với tính năng nửa vời |
| `currency` | Families | Quy đổi tiền thật đang dùng cách khác |
| `user_id` | Members | ADR-006: trẻ không có tài khoản. Dành cho Sprint 3 |
| `start_time` | Routines | Chưa có giao diện đặt giờ cho thói quen |
| `due_time` | Tasks | Chưa có giao diện đặt giờ cho việc |

`user_id` có lý do chính đáng để tồn tại trước (Sprint 3 cần). Bốn cột còn lại
nên **hoặc nối, hoặc gỡ** — dự án đã dọn tám lần đúng loại này.

**Việc phải làm:** với mỗi cột, thêm một dòng ghi rõ *"để dành cho X, chưa nối"*
ngay tại `tables.dart`, hoặc gỡ. Cột không chú thích và không ai đọc là cột sẽ
bị hiểu nhầm.

## 7 · 🟡 Không test nào canh chỗ gọi truyền `batBuoc` đúng

ADR-027: mật khẩu **bố mẹ bắt buộc**, bé tuỳ chọn.

Test hiện có (`test/widget/mat_khau_sheet_test.dart`) canh **sheet cư xử đúng
với cờ** — `batBuoc: true` thì không có nút HUỶ. Nhưng không gì canh **onboarding
truyền `true` cho hồ sơ bố mẹ**.

Đổi thành `false` thì mọi test vẫn xanh, và quy tắc trôi mất trong im lặng —
đúng cách quy tắc "bé bắt buộc" đã trôi hôm 23/08.

**Việc phải làm:** thêm vào `integration_test/luong_day_du_test.dart` — đi hết
onboarding, bấm HUỶ ở sheet của bố mẹ (nếu có nút HUỶ là test đỏ ngay), rồi
kiểm hồ sơ bố mẹ **luôn** có `pin_hash`.

## 8 · 🟡 Preset `exercise` vẫn dùng emoji người — **chủ dự án chốt**

`presets.dart` có `TaskPreset(key: 'exercise', iconKey: 'run')` → 🏃.

Quy tắc đã có: *"Hình người luôn mang theo giới tính và màu da, mà đây là bộ
hình dùng chung cho mọi bé."* Hôm nay `'run'` đã bị gỡ khỏi **bộ bố mẹ chọn**
(test bắt), nhưng preset vẫn dùng nó, nên 🏃 vẫn hiện trên thẻ việc của bé.

Về nguyên tắc đây là cùng một vấn đề, chỉ khác là chưa test nào canh.

**Không tự sửa** vì đổi hình của một preset là quyết định thiết kế. Hai hướng:
đổi sang hình không phải người (🎽 áo thể thao, 🏅 huy chương), hoặc ghi rõ
trong quy tắc rằng preset được miễn trừ và vì sao.

---

## Thứ tự đề nghị

1. **§1** — nặng nhất, vì nó tạo niềm tin sai cho bố mẹ.
2. **§4** — rẻ nhất, và để lâu thì hai file càng lệch.
3. **§5** rồi **§6** — dọn bẫy trong schema trước khi có người vấp.
4. **§2** — nối FCM hoặc nói đúng trạng thái của nó.
5. **§7** — thêm test canh.
6. **§8** — chờ chủ dự án chốt.

## Hai câu hỏi để không phải audit lần thứ mười một

Ba mục 🔴/🟠 đầu đều là cùng một lỗi. Trước khi đánh dấu bất cứ thứ gì là xong,
hỏi:

- **Ai gọi hàm này?** Nếu câu trả lời chỉ là "provider của chính nó", hoặc
  "không ai", thì nó **chưa chạy**.
- **Người dùng bật nó lên thì cái gì đổi?** Nếu không trả lời được bằng một câu
  cụ thể mà người dùng nhìn thấy được, thì nó **chưa xong**.

Mục §1 trượt đúng câu thứ hai: `proof_mode` bật lên thì việc vào hàng chờ duyệt
— nhưng thứ người dùng *tưởng* mình bật là "được xem ảnh", và điều đó không xảy ra.

## Trạng thái phát hành (cập nhật 24/08/2026, 22:43)

Đường phát hành **đã thông**. Không còn việc gì phải làm ở đây trước khi nhận
các mục §1–§8.

| Run | Commit | Hỏng ở đâu | Nguyên nhân |
|---|---|---|---|
| #24, #25, #26 | tag v0.2.6 / v0.2.7 | bước **build** | `main` không biên dịch được |
| #27 | `67b7dae` | bước **đẩy store**, giây thứ 8 | `+14` đã có trên TestFlight |
| #28 | `71d9752` | — | **xanh**, IPA lên TestFlight |
| #29 | `b0518ef` | bước **nộp duyệt** (iOS) / **đẩy Play** (Android) | hồ sơ App Store thiếu 6 mục; Play chưa bật API |

Hai nguyên nhân khác hẳn nhau và phải đọc log mới phân biệt được — đỏ ở bước
build là lỗi mã, sửa được tại máy trong 20 giây; đỏ ở bước đẩy là chuyện của
store, build lại bao nhiêu lần cũng không hết.

Lỗi của #27 nay không quay lại được nữa: build number do CI cấp theo
`1000 + run_number*10 + run_attempt`, không còn phụ thuộc ai đó nhớ tăng
`+build` trong pubspec. #28 dùng build number 1281.

### Run #29 — thử lane công khai, và đây là danh sách còn thiếu

Chạy `ios_lane: release` + `android_track: production` trên `b0518ef`. Cả hai
nền tảng đỏ, nhưng **không nền tảng nào đỏ vì mã**:

**iOS** — IPA build xong, `upload_to_app_store` đẩy binary lên App Store Connect
xong, rồi hỏng đúng ở `submit_for_review` (Fastfile dòng 37). Apple trả về đủ
sáu thứ còn thiếu trong hồ sơ, chép nguyên văn để khỏi đoán:

| Thiếu | Điền ở đâu trên App Store Connect |
|---|---|
| `Answers to what data your app collects and how it's used` | App Privacy → Data Collection |
| `primaryCategory` | App Information → Category |
| `privacyPolicyUrl` | App Privacy → Privacy Policy URL |
| `privacyPolicyText` | App Privacy → Privacy Policy Text |
| `App is missing required pricing` | Pricing and Availability |
| `contentRightsDeclaration` | App Information → Content Rights |

Binary thì **đã lên** — điền xong sáu mục trên là bấm nộp duyệt tay được ngay,
không cần chạy lại CI.

**Android** — hỏng trước cả khi đụng tới bản build:

```
PERMISSION_DENIED: Google Play Android Developer API has not been used in
project 369552230110 before or it is disabled.
```

Bật API tại `console.developers.google.com/apis/api/androidpublisher.googleapis.com`
cho đúng project đó, đợi vài phút rồi chạy lại. Đây là chuyện của Google Cloud,
không phải secret sai như đã đoán trước đây — secret đọc được, chỉ là project
chưa mở API.

Cả hai đều là việc của chủ dự án, không phải của agent. Cộng thêm: đẩy tag phải
làm từ máy cá nhân (proxy của môi trường agent chặn ref dạng tag, trả 403).

## Cách kiểm lại toàn bộ

```bash
flutter pub get && dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
DISPLAY=:98 flutter test integration_test/luong_day_du_test.dart -d linux
```

Quy trình đầy đủ, kèm chốt chặn trước khi đẩy và trước khi tag:
`.claude/skills/flutter-8-buoc/SKILL.md`.
