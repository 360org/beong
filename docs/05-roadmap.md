# 05 — Lộ trình & kế hoạch triển khai

Ước lượng theo **1 dev full-time**. Có 2 dev thì chia Sprint 3–6 song song (một người backend/sync,
một người UI).

## Trạng thái hiện tại

Cập nhật bằng cách **đọc code**, không tick theo cảm giác — xem quy trình ở
`.claude/skills/flutter-8-buoc`.

| Sprint | Trạng thái | Ghi chú |
|---|---|---|
| 0 — Nền móng | ✅ Xong | Còn pre-commit hook, cố ý hoãn |
| 1 — Dữ liệu local | ✅ Xong | Trừ **tầng repository** (`lib/domain/repositories/` rỗng) |
| 2 — Luồng UI cốt lõi | 🟡 Gần xong | PIN phụ huynh ✅. Còn khối chế độ bằng chứng của Task Editor, integration test |
| 3 — Backend & ghép cặp | 🔴 Chưa bắt đầu | Pha 0 đã xong 2/4; phần backend chờ dựng Supabase |
| 4 — Phần thưởng & tài chính | 🟡 Đang làm | Đổi thưởng + duyệt + hoàn xu ✅, trừ xu ✅, con tự chia xu ✅, hũ tự lập ✅, huy hiệu + streak ✅, mục tiêu tiết kiệm ✅. Thiếu tỷ giá tiền thật |
| 5 — Thông báo & hoàn thiện | 🔴 Chưa bắt đầu | |
| 6 — Phát hành v1.0 | 🟡 Hạ tầng sẵn | CI/CD 7 job + Fastlane ✅; chưa có tài khoản store, chưa có icon/ảnh chụp |

**Chặn lớn nhất:** chưa có backend nên chưa ghép cặp được máy con — mà "mỗi bé một máy" là điểm bán
chính (ADR-021). Mọi thứ khác đang chạy được trên **một** thiết bị.

**Đã làm nhiều hơn kế hoạch ở Sprint 4** vì chủ dự án yêu cầu theo thứ tự khác: trừ xu, duyệt tuỳ
chọn, đổi thưởng, con tự chia xu đều đã xong trước khi Sprint 3 bắt đầu.

## Sprint 0 — Nền móng ✅ XONG
- [x] `flutter create` với 5 platform (ios, android, macos, windows, **linux**)
- [x] Cấu hình lint (`very_good_analysis`), format
- [x] Theme + design tokens từ `04-design-system.md`
- [x] i18n (vi/en) với ARB + trần phóng chữ 1.6
- [x] go_router + `StatefulShellRoute` (mỗi tab giữ lịch sử riêng)
- [x] `ResponsiveScaffold` + test 3 breakpoint
- [x] CI: analyze + format + test + build 5 nền tảng
- [ ] Pre-commit hook (hoãn — CI đã chặn đủ, thêm sau nếu thấy cần)

**Ghi chú:** thêm Linux ngoài kế hoạch vì build/test được ngay trong CI (Ubuntu runner
rẻ và nhanh hơn macOS/Windows) — không phải nền tảng phát hành.

**Phát hiện khi làm:** bảng màu hồ sơ trẻ trong `04-design-system.md` chỉ đạt contrast
2.7–3.9:1 với chữ trắng, không đạt WCAG AA như tài liệu đã ghi. Đã tính lại và bổ sung test
tự động. Bài học: **mọi ràng buộc khả dụng ghi trong tài liệu phải có test tương ứng**,
nếu không nó chỉ là ước muốn.

## Sprint 1 — Dữ liệu local ✅ XONG
- [x] Drift schema đầy đủ theo `03-data-model.md` (gồm `routines`, `streaks`, `badges_earned`)
- [x] DAO local-only: `TaskDao`, `WalletDao`, `MemberDao`, `RewardDao`, `SettingsDao`
- [ ] Tầng repository — **chưa làm.** `lib/domain/repositories/` vẫn rỗng; UI và service gọi
      thẳng DAO. Chấp nhận được ở giai đoạn local-only, nhưng phải có trước khi thêm sync,
      vì lúc đó "đọc ở đâu" mới thành câu hỏi thật.
- [x] Bộ sinh `task_instances` + ngày theo timezone/rollover + kế thừa lịch từ routine
- [x] Ledger theo hũ + tính số dư từng hũ (ADR-016, mở rộng ở ADR-024)
- [x] Thưởng trọn bộ routine, idempotent
- [x] Tính streak (ngày trung tính + ngày ân hạn)
- [x] Seed preset — thực tế **25 task preset + 4 routine**, nhiều hơn con số 24/3 tài liệu ghi ban đầu
- [x] Unit test: scheduler, ledger, đổi ngày, streak, routine bonus

**Xong khi:** tạo routine → sinh instance đúng 7 ngày tới → tick hết → cộng điểm + bonus trọn bộ,
toàn bộ offline. ✅ đạt.

**Sai lệch với tài liệu, đã sửa lại ở đây:**
- "Idempotent bằng UUID v5" → thực tế dùng **chuỗi khoá tất định**
  (`routine-bonus:<routineId>:<memberId>:<dueDate>`) làm `client_op_id`. Hiệu quả tương đương và
  đọc được khi debug, nhưng không phải UUID v5 như tài liệu hứa. Nếu sync cần UUID thật thì đây là
  chỗ phải đổi, và đổi được vì `client_op_id` chỉ cần tất định.
- Bộ sinh instance **chưa chạy lúc mở app** như `03-data-model.md` §3 tả — xem Sprint 3.

## Sprint 2 — Luồng cốt lõi UI (gần xong)
- [x] Onboarding 4 bước (thêm bước chọn tuổi ngoài kế hoạch — xem ghi chú dưới)
- [~] **Task Editor** — có `_AddTaskSheet` với 6 khối: tên, điểm, preset, icon, **chọn con nào**,
      **lịch lặp** (hằng ngày / chọn thứ / một lần). Thiếu 2 khối: chế độ duyệt riêng của task,
      chế độ bằng chứng.
- [x] **Routine Editor** + kéo thả đổi thứ tự task — xong: sửa tên/hình/xu thưởng trọn bộ, kéo thả
      thứ tự việc, bỏ việc ra và đưa việc lẻ vào, ngừng dùng thói quen (việc bên trong không mất).
- [~] Child Home — vòng tiến độ ✅, linh vật đổi tâm trạng theo tiến độ ✅, nhưng:
  - Nhóm theo **trạng thái** (Cần làm / Đã xong / Bỏ lỡ), **không** nhóm theo routine như tài liệu tả.
  - **Chưa có animation ăn mừng.** `KidScale.celebrateOnTap` đã khai nhưng không nối vào hiệu ứng
    nào — vẫn là cờ chết.
- [x] Parent Home + hàng đợi duyệt (+ nút Duyệt tất cả, + danh sách "Đã xong hôm nay" để mở lại)
- [x] Chuyển hồ sơ + **PIN phụ huynh** — `09` §6 ca "máy bố mẹ cũng là máy con dùng". Trước đó
      đổi vai không cần gì cả, tức là cả vòng duyệt của ADR-023/ADR-025 dựa trên một giả định
      chưa từng được bảo vệ: con bấm avatar, chọn "Bố mẹ", rồi tự duyệt việc của mình.
- [ ] Integration test luồng đầy đủ — chưa có, thư mục `integration_test/` chưa tồn tại.

**Xong khi:** dùng được thật trên 1 thiết bị, không cần mạng. ✅ đạt — đã chạy thật và chụp 27 ảnh
qua toàn bộ luồng.

**Còn thiếu so với luồng ở `09-onboarding-pairing.md`:** chọn vai bố mẹ/con lần mở đầu, tạo **nhiều**
con. Đã chuyển sang Sprint 3 vì là điều kiện của ghép cặp.

Hai việc trong danh sách này **đã xong** và tài liệu ghi sai từ đó tới giờ:
- **Lưu session bền vững** — xong, `device_settings` + `SessionStore`, nạp trước `runApp`.
- **Chọn con khi thêm task** — xong, `_AddTaskSheet` có `_selectedChildren`, không còn gán cho tất cả.

**Đã làm thêm ngoài kế hoạch:**
- Hỏi tuổi bé trong onboarding để `KidScale` hoạt động thật — trước đó `AgeBand` là code chết.
- Trừ xu (ADR-022), duyệt tuỳ chọn (ADR-023), hũ tự lập (ADR-024, đang dở).
- Đổi nhãn tab "Việc nhà" → "Nhiệm vụ": app dùng cho cả học bài, đi chơi, thể dục.

## Sprint 3 — Backend, tài khoản bố mẹ & ghép cặp máy con (2 tuần)

> **Đã đảo lên trước phần thưởng** theo ADR-021: cấu hình gia đình cư trú trên tài khoản bố mẹ,
> nên không có sprint này thì luồng ở `09-onboarding-pairing.md` (bố mẹ cấu hình → máy con quét QR
> tải hồ sơ về → đồng bộ) không chạy được, và v1.0 không phát hành được.

**Pha 0 — gỡ chặn, làm trước tiên và không cần backend:**
- [x] Sinh `task_instances` lúc **mở app**, khi quay lại app, và sau onboarding —
      `DayStartService`, có khoá một-lần-mỗi-ngày
- [x] **Lưu session bền vững** — `device_settings` + `SessionStore` (làm trước, ngoài kế hoạch)
- [ ] Màn chọn vai Bố mẹ / Con ở lần mở đầu, ghi nhớ vĩnh viễn (ADR-018)
- [ ] Tách điều hướng theo vai; onboarding tách hai nhánh

**Việc còn nợ từ Sprint 1–2, không cần backend:**
- [ ] Tầng repository (`lib/domain/repositories/` đang rỗng) — phải có trước khi thêm sync
- [ ] Task Editor đủ 8 khối (còn thiếu **chế độ bằng chứng**; chế độ duyệt riêng đã xong)
- [x] Routine Editor + kéo thả thứ tự
- [x] Animation ăn mừng — `ConfettiBurst`, nổ ở cấp màn hình vì thẻ việc bị tháo ngay sau khi bấm
- [x] **PIN phụ huynh** — `ParentPinService` + sheet nhập PIN, hỏi ở cả hai cửa đổi vai (màn con
      và màn Cài đặt) và hỏi lại PIN cũ trước khi đổi/bỏ. Nhà chưa đặt PIN thì không chặn gì.
      Không phải bảo mật thật: 4 số băm SHA-256 chặn được trẻ con, không chặn được ai cầm file DB.
- [x] Gộp các dòng sổ cái của cùng một giao dịch trong "Sổ của con" (`op_group_id`), hiện **tên
      việc / tên phần thưởng**, **trạng thái** (chữ + màu, theo dõi sống), và chi tiết từng hũ
- [ ] `integration_test/` cho luồng đầy đủ

**Backend & tài khoản:**
- [ ] Dự án Supabase, migration SQL, RLS policy theo `family_id`
- [ ] Auth phụ huynh: Sign in with Apple + Google (cả hai — `09` §5.2)
- [ ] Liên kết tài khoản ↔ hồ sơ gia đình; ca "đăng nhập lại trên máy mới"
- [x] Tạo **nhiều** con — ô "Thêm bé" trong Cài đặt, dùng chung `ChildProfileForm` với
      onboarding. Onboarding vẫn chỉ khai một bé (đường nhanh), nhưng nhà hai con không còn
      phải đăng xuất làm lại từ đầu và mất dữ liệu cũ. Màu hồ sơ tự né màu các bé đã dùng.
      Phần "chọn con khi thêm task" thì **đã có sẵn** — hàng chip "Giao cho" trong ô thêm việc.

**Ghép cặp máy con:**
- [ ] Bảng `pairing_codes` (lưu hash, TTL, cờ đã dùng) + bảng `devices`
- [ ] **Ghép cặp bằng QR** — chi tiết ở `09-onboarding-pairing.md` §4
- [ ] Credential phạm vi hẹp + **RLS theo hàng** cho máy con
- [ ] Nhiều hồ sơ con trên cùng một máy + nút chuyển; danh sách thiết bị + thu hồi
- [ ] Mời phụ huynh thứ hai vào gia đình (dùng lại hạ tầng QR, cấp vai `parent`)

**Sync:**
- [ ] Outbox + SyncEngine + retry/backoff + idempotency
- [ ] Realtime subscribe theo `family_id`
- [ ] Test xung đột: 2 thiết bị offline cùng sửa → kết quả hội tụ
- [ ] Job đối soát `balance_cache`

**Test bảo mật (không phải tuỳ chọn):**
- [ ] Máy con **không** đọc được dữ liệu anh chị em
- [ ] Mã QR hết hạn / đã dùng đều bị từ chối
- [ ] Thu hồi thiết bị thì máy con mất quyền ngay

**Xong khi:** bố mẹ cấu hình trên máy A, con quét QR trên máy B nhận đúng hồ sơ của mình, con tick
việc lúc mất mạng thì có mạng bố mẹ thấy.

## Sprint 4 — Phần thưởng, tài chính, streak, huy hiệu (2 tuần)

> Nội dung không đổi, chỉ **đi sau** Sprint 3 theo ADR-021.

- [~] CRUD phần thưởng — tạo/xoá/đổi xong; **chưa** có màn sửa, và trường riêng theo loại
      (`meta_json`: số phút, số tiền) chưa có UI nhập
- [x] **Đổi thưởng + hàng chờ duyệt + hoàn điểm khi từ chối** — `RedemptionService`.
      Sửa ba lỗi thật của luồng cũ: không nguyên tử (trừ xu trước khi kiểm còn hàng),
      từ chối **không hoàn xu**, và không có màn nào gọi `fulfillRedemption` nên phiếu
      nằm `pending` mãi mãi.
- [x] Màn "Phiếu của con" + nút "Đã dùng"
- [x] Bước duyệt của bố mẹ là **bắt buộc** cho mọi lượt đổi thưởng (ADR-025) — bịt lỗ
      `requires_approval = false` cho phép tự duyệt
- [x] Template phần thưởng và nhiệm vụ hiện **ngay trên trang trống**, không chôn trong
      bottom sheet sau nút "+"
- [x] Màn huy hiệu (8 huy hiệu MVP) + **nối `calculateStreak` vào dữ liệu thật**. Hai thứ này có
      logic và test từ Sprint 1 nhưng chưa từng chạy: bảng `badges_earned` không ai đọc/ghi, và
      `calculateStreak` không được gọi từ đâu nên bảng `streaks` luôn rỗng. `StreakFlame` như một
      widget riêng thì **không cần** — ngọn lửa đã nằm trong thẻ tổng quan của màn hình con.
- [ ] Tỷ giá quy đổi ra tiền thật (mặc định tắt — ADR-017)
- [x] **Mục tiêu tiết kiệm + thanh tiến độ** — `GoalDao` + `GoalService`. Bảng `savings_goals` có
      từ v1 nhưng không ai đọc/ghi. Tiến độ đo bằng **hũ Để dành**, không phải tổng xu; tới đích
      **không trừ xu**. Bố mẹ đặt từ Thống kê, con chỉ xem.
- [x] **Sổ của con** — lịch sử đầy đủ, và `manual_adjust` **bắt buộc có lý do**. `WalletDao
      .manualAdjust` viết từ Sprint 1 nhưng không có chỗ nào gọi; nay có sheet "Sửa xu" trong
      Thống kê, cộng/trừ vào hũ bất kỳ kể cả hũ tự lập, lý do hiện trong sổ cho con đọc.
- [x] **Duyệt là tuỳ chọn, mặc định xong-là-xong** (ADR-023, thay ADR-009) — công tắc trong Cài đặt,
      nút "Duyệt tất cả", danh sách "Đã xong hôm nay" để mở lại. Sửa kèm một lỗi thật: đường tự
      động duyệt trước đây **không cộng xu**.
- [x] Gộp "ĐIỂM" và banner "xu chờ chia" thành **một ô XU** duy nhất; sửa nhãn "ĐIỂM" → "XU"
      cho khớp ADR-015
- [x] Ẩn tab Cài đặt với vai con, thêm đường đổi người dùng ở avatar
- [x] **Con tự chia xu** (ADR-024) — công tắc trong Cài đặt, hũ chờ (`Jar.inbox`), banner trên màn
      con, màn "Chia xu vào hũ". Tổng điểm tính cả hũ chờ.
- [x] **Hũ do bố mẹ tự lập** (ADR-024) — xong: `JarDao`, màn Cài đặt → Các hũ (thêm/sửa/emoji/tỷ
      lệ/xếp lại), chia tự động đọc bảng `jars`, màn chia xu và Sổ của con hiện mọi hũ. Sửa kèm một
      lỗi mất xu có sẵn: `WalletBalance` chỉ đếm bốn khoá cứng nên xu trong hũ tự lập không hiện ở
      đâu cả dù vẫn nằm trong sổ cái.
- [x] ~~Đổi tên `JarTrio`~~ — **không cần nữa**: widget đó chưa từng được viết, chỗ hiện các hũ là
      `_JarOverview` và nó không hàm ý số hũ nào.
- [x] **Trừ xu** (ADR-022) — làm sớm hơn kế hoạch: cấu hình hai mức ở cấp gia đình, nút "mở lại"
      trong hàng đợi duyệt, khoản trừ cuối ngày cho việc bỏ. Mặc định tắt.
- [x] Trừ xu: cho phép tự nhập mức % bất kỳ (chip "Khác…")
- [ ] Trừ xu: cho phép đặt mức riêng theo từng task (hiện chỉ có mức chung của gia đình)
- [ ] Trừ xu: thông báo đẩy sang máy bố mẹ khi con bấm xong (hiện chỉ hiện trong hàng đợi duyệt —
      push nằm ở Sprint 5)

## Sprint 5 — Thông báo & hoàn thiện (1 tuần)
- [ ] FCM push (mobile) + local notification (desktop)
- [ ] 7 loại thông báo trong bảng ở `01-product-spec.md` §4.7
- [ ] Bộ điều tiết "nhắc nhẹ, không cằn nhằn": trần 2 thông báo/ngày cho trẻ, gộp sự kiện,
      chặn gửi sau giờ đi ngủ — có unit test riêng
- [x] Cài đặt: **chủ đề sáng/tối** (lưu theo thiết bị) và **giờ đổi ngày** (0/3/4/5/6 giờ). Sửa
      kèm một lỗi chờ sẵn: các màn hình tự dựng `FamilyClock` với mặc định 4 và bỏ qua cột
      `day_rollover_hour` mà `DayStartService` vẫn đọc — hai bên sẽ lệch ngày ngay khi có ai đổi.
- [ ] Cài đặt: ngôn ngữ, âm thanh
- [ ] Trang trống, trạng thái lỗi, màn hình mất mạng
- [ ] Rà soát khả dụng (TalkBack/VoiceOver, contrast, text scale)

## Sprint 6 — Phát hành v1.0 (1 tuần)

> **Hạ tầng đã sẵn, tài khoản thì chưa.** `.github/workflows/release.yml` + Fastlane cho cả hai store
> đã viết và CI 7 job đang xanh, nhưng chưa có tài khoản Apple Developer / Google Play, chưa có
> secret nào được nạp. Hướng dẫn từng bước ở `08-release-cicd.md`.
- [ ] Icon app, splash, ảnh chụp store
- [ ] Chính sách quyền riêng tư + điều khoản (bắt buộc cho app trẻ em)
- [ ] Khai báo store: **không mua trong app, không quảng cáo** (ADR-014)
- [ ] Khai báo App Store "Kids Category" / Play "Teacher Approved" nếu áp dụng
- [ ] Fastlane → TestFlight + Play Internal
- [ ] Beta 10 gia đình, thu phản hồi 2 tuần

**Tổng MVP: ~9.5 tuần** (thêm 0.5 tuần cho trụ giáo dục tài chính). Tổng thời lượng không đổi khi
đảo Sprint 3 ↔ 4, nhưng **mốc "dùng được thật" lùi lại**: trước đây sau Sprint 3 đã có app một máy
đầy đủ phần thưởng; giờ sau Sprint 3 mới có tài khoản và ghép cặp, phần thưởng đến sau (ADR-021).
Tăng 1.5 tuần so với bản đầu do đôn Routines, phần thưởng phân loại, streak và huy hiệu lên MVP
(`07-competitive-analysis.md` §7); bù lại giảm ~1 tuần vì **v1 miễn phí hoàn toàn** nên không
phải làm StoreKit / Play Billing / paywall / khôi phục mua hàng (ADR-014).

## Sau v1.0

| Phiên bản | Nội dung |
|---|---|
| v1.1 | Level, thêm huy hiệu; bằng chứng ảnh/ghi chú; weekly goals; **lãi tượng trưng cho hũ Để dành** |
| v1.2 | Thống kê tuần/tháng, xuất CSV/PDF; bảng thành tích in được |
| v1.3 | Desktop 3 cột tối ưu, phím tắt; widget màn hình chính iOS/Android |
| v1.4 | Nhiều gia đình / ly thân (trẻ ở 2 nhà); chia sẻ task giữa 2 hộ |
| v2.0 | Web app; mục tiêu tiết kiệm dài hạn; gợi ý task bằng AI theo độ tuổi |

## Định nghĩa "Xong" (mọi task)
1. Code + test (unit ở domain, widget ở màn hình mới)
2. `flutter analyze` sạch, format chuẩn
3. Chạy được trên ít nhất 1 mobile + 1 desktop
4. Chuỗi hiển thị đều nằm trong ARB (không hard-code)
5. Tự review khả dụng: vùng chạm, contrast, semantics
