# 05 — Lộ trình & kế hoạch triển khai

Ước lượng theo **1 dev full-time**. Có 2 dev thì chia Sprint 3–6 song song (một người backend/sync,
một người UI).

## Trạng thái hiện tại

*Soát lần cuối: 23/08/2026, bản `v0.2.6+11`.*

Cập nhật bằng cách **đọc code**, không tick theo cảm giác — xem quy trình ở
`.claude/skills/flutter-8-buoc`.

| Sprint | Trạng thái | Ghi chú |
|---|---|---|
| 0 — Nền móng | ✅ Xong | Còn pre-commit hook, cố ý hoãn |
| 1 — Dữ liệu local | ✅ Xong | Gồm cả **tầng repository** — 7 interface + bản `Local...`, có test kiến trúc canh |
| 2 — Luồng UI cốt lõi | ✅ Xong | Mật khẩu **từng hồ sơ** ✅ (ADR-027), chọn vai lần mở đầu ✅, integration test ✅, Task Editor đủ 8 khối gồm proof_mode ✅, CRUD hồ sơ con & xoá gia đình ✅, xem việc chưa xong hôm nay trên Home bố mẹ ✅ |
| 3 — Backend & ghép cặp | 🟡 Đang làm | **Pha 0 xong 4/4**; migration SQL & RLS policy Supabase ✅ (`supabase/migrations/`); QR scanner camera native & QR code ✅; chờ kết nối client |
| 4 — Phần thưởng & tài chính | ✅ Xong | Đổi thưởng + duyệt + hoàn xu, trừ xu (chung + riêng theo việc), con tự chia xu linh hoạt dở dang, hũ tự lập, huy hiệu + streak, mục tiêu tiết kiệm, tỷ giá tiền thật, sửa xu tay, CRUD sửa phần thưởng |
| 5 — Thông báo & hoàn thiện | 🟡 Đang làm | Báo lỗi trong app ✅; từ điển i18n app_vi/app_en mở rộng ✅; dải tuổi 3–15 tính động từ birthYear ✅; chờ FCM push |
| 6 — Phát hành v1.0 | 🟡 Đang chạy | **Đã lên TestFlight thật** (`0.2.6+11`). Chặn còn lại **không phải mã**: hồ sơ App Store chưa điền, secret Play Console chưa hợp lệ |

**Hai lỗi 🔴 chặn phát hành tìm ra ngày 22/08 đã sửa xong**, cộng hai lỗi nữa lộ ra sau đó khi
chạy app thật — xem mục *Chặn phát hành* bên dưới. Còn đúng một mục để mở, và cố ý: dấu vết chẩn
đoán lúc khởi động, vì hiện tượng của nó chưa dựng lại được lần nào.

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
- [x] Tầng repository ✅ — 7 interface + bản `Local...` ở `lib/domain/repositories/`, mặt cắt lấy
      đúng bằng 73 phương thức `lib/features` thật sự gọi (không bọc lại cả 244 phương thức DAO —
      lý do ở README cùng thư mục). Ràng buộc "features không chạm `lib/data`" có
      `test/unit/kien_truc_test.dart` canh.
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
- [x] **Task Editor** — có đủ 8 khối: tên, điểm, preset, icon, **chọn con nào**, **lịch lặp**
      (hằng ngày / chọn thứ / một lần), **chế độ duyệt riêng**, mức **trừ xu riêng** cho
      từng việc, và **chế độ bằng chứng** (`proof_mode`).
- [x] **Routine Editor** + kéo thả đổi thứ tự task — xong: sửa tên/hình/xu thưởng trọn bộ, kéo thả
      thứ tự việc, bỏ việc ra và đưa việc lẻ vào, ngừng dùng thói quen (việc bên trong không mất).
- [~] Child Home — vòng tiến độ ✅, linh vật đổi tâm trạng theo tiến độ ✅, hoa giấy ăn mừng ✅
      (kèm báo tên huy hiệu khi vừa mở khoá), mục tiêu tiết kiệm ✅. Khác tài liệu một chỗ:
      nhóm theo **trạng thái** (Cần làm / Đã xong / Bỏ lỡ), **không** nhóm theo routine.
- [x] Parent Home + hàng đợi duyệt (+ nút Duyệt tất cả, + danh sách "Đã xong hôm nay" để mở lại)
- [x] Chuyển hồ sơ + **mật khẩu từng hồ sơ** — `09` §6 ca "máy bố mẹ cũng là máy con dùng". Trước
      đó đổi vai không cần gì cả, tức là cả vòng duyệt của ADR-023/ADR-025 dựa trên một giả định
      chưa từng được bảo vệ: con bấm avatar, chọn "Bố mẹ", rồi tự duyệt việc của mình.

      **Đổi lần hai ngày 23/08 (ADR-027):** từ *một PIN chung cả nhà, tuỳ chọn* thành *mỗi hồ sơ
      một mật khẩu riêng, bắt buộc từ onboarding*. Mật khẩu đổi vai trò — không còn là cái chốt
      cửa Cài đặt mà là cách **định danh ai đang dùng máy**. Mật khẩu của bé này không mở được hồ
      sơ bé kia.
- [x] **Integration test luồng đầy đủ** — `integration_test/luong_day_du_test.dart`, dựng nguyên
      `BeOngApp` với router thật trên Linux desktop dưới Xvfb, có job CI riêng. Ba luồng:
      onboarding → con bấm xong việc, xu vào ví ngay → đổi thưởng vào hàng chờ duyệt.

**Xong khi:** dùng được thật trên 1 thiết bị, không cần mạng. ✅ đạt — đã chạy thật và chụp 27 ảnh
qua toàn bộ luồng.

**~~Còn thiếu so với luồng ở `09-onboarding-pairing.md`~~ — đã xong 23/08:** chọn vai bố mẹ/con và
tạo **nhiều** con. `VaoAppScreen` đi bốn bước (chọn nhà → chọn vai → chọn hồ sơ → mật khẩu), tự bỏ
qua bước nào chỉ có một lựa chọn; thêm bé làm qua sheet "Thêm bé" trong Cài đặt.

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
- [x] **Màn chọn vai Bố mẹ / Con**, ghi nhớ vĩnh viễn (ADR-018) — `VaoAppScreen`, 23/08
- [x] **Tách điều hướng theo vai** — `diemDenDauTien` tách ba trạng thái (máy trống / có dữ liệu
      chưa chọn ai / đã chọn), canh bằng bảng test. Onboarding chỉ dành cho máy **thật sự trống**

**Việc còn nợ từ Sprint 1–2, không cần backend:**
- [x] Tầng repository ✅ (xem Sprint 1) — xong trước khi bắt đầu sync, đúng như hạn chót đặt ra
- [x] Task Editor đủ 8 khối (đã hoàn thiện chế độ bằng chứng `proof_mode` và chế độ duyệt riêng)
- [x] Routine Editor + kéo thả thứ tự
- [x] Animation ăn mừng — `ConfettiBurst`, nổ ở cấp màn hình vì thẻ việc bị tháo ngay sau khi bấm
- [x] **Mật khẩu từng hồ sơ** (ADR-027) — `MatKhauHoSo` khoá theo `member_id`, hỏi ở cả hai cửa
      đổi vai và ở màn vào app. Bắt buộc đặt từ onboarding và khi thêm bé; bố mẹ đặt lại được cho
      con mà không cần mật khẩu cũ. "Quên mật khẩu?" **đổi** chứ không **gỡ** — gỡ sẽ để lại hồ sơ
      trống, tức vi phạm chính ADR-027.
      Không phải bảo mật thật: 4 số băm SHA-256 chặn được người trong nhà mở nhầm hồ sơ của nhau,
      không chặn được ai cầm file DB.
- [x] Gộp các dòng sổ cái của cùng một giao dịch trong "Sổ của con" (`op_group_id`), hiện **tên
      việc / tên phần thưởng**, **trạng thái** (chữ + màu, theo dõi sống), và chi tiết từng hũ

**Backend & tài khoản:**
- [x] Dự án Supabase, migration SQL, RLS policy theo `family_id` — `supabase/migrations/20260823000000_init_beong_schema.sql` (11 bảng + RLS policy theo từng vai)
- [ ] Auth phụ huynh: Sign in with Apple + Google (cả hai — `09` §5.2)
- [ ] Liên kết tài khoản ↔ hồ sơ gia đình; ca "đăng nhập lại trên máy mới"
- [x] Tạo **nhiều** con — ô "Thêm bé" trong Cài đặt, dùng chung `ChildProfileForm` với
      onboarding. Onboarding vẫn chỉ khai một bé (đường nhanh), nhưng nhà hai con không còn
      phải đăng xuất làm lại từ đầu và mất dữ liệu cũ. Màu hồ sơ tự né màu các bé đã dùng.
      Phần "chọn con khi thêm task" thì **đã có sẵn** — hàng chip "Giao cho" trong ô thêm việc.

**Ghép cặp máy con:**
- [x] Bảng `pairing_codes` (lưu hash, TTL, cờ đã dùng) + bảng `devices` (schema Supabase)
- [x] **Ghép cặp bằng QR** — chi tiết ở `09-onboarding-pairing.md` §4 (`PairingService` sinh URI chuẩn `beong://pair?v=1&c=<code>`, sheet cấp mã QR trên máy bố mẹ kèm đếm ngược 10 phút, dialog quét/nhập mã trên máy con)
- [ ] Credential phạm vi hẹp + **RLS theo hàng** cho máy con
- [ ] Nhiều hồ sơ con trên cùng một máy + nút chuyển; danh sách thiết bị + thu hồi
- [ ] Mời phụ huynh thứ hai vào gia đình (dùng lại hạ tầng QR, cấp vai `parent`)

**Sync:**
- [x] Outbox + SyncEngine + retry/backoff + idempotency (`SyncEngine` quản lý hàng đợi biến đổi local, đẩy tuần tự và xử lý lỗi retry)
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

- [x] **CRUD phần thưởng** — tạo/xoá/sửa/đổi xong: `_RewardEditorSheet` hỗ trợ sửa tên, giá xu, icon,
      giới hạn số lượng `stock`.
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
- [x] **Tỷ giá quy đổi ra tiền thật** (mặc định tắt — ADR-017). Cột `exchange_rate_xu` có từ v1
      nhưng không ai đọc/ghi. Đơn vị chốt là **nghìn đồng** ("10 xu = 1.000 đ"); lấy 1 đồng làm
      mốc thì tỷ lệ thành số lẻ vô nghĩa. Làm tròn **xuống** — hiện nhiều hơn số con đổi được là
      hứa hão, mà hứa hão về tiền thì bố mẹ trả bằng tiền thật.
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
- [x] Trừ xu: **mức riêng theo từng việc** — schema v8, chốt vào lượt việc lúc sinh như
      `points_snapshot` (ADR-007). Chỉ ghi đè mức *bỏ việc*, không ghi đè mức *mở lại*. Mức riêng
      **không** vượt qua công tắc chung: nhà tắt trừ xu thì không việc nào bị trừ.
- [ ] Trừ xu: thông báo đẩy sang máy bố mẹ khi con bấm xong (hiện chỉ hiện trong hàng đợi duyệt —
      push nằm ở Sprint 5)

## Sprint 5 — Thông báo & hoàn thiện (1 tuần)
- [x] **Báo lỗi trong app** (ngoài kế hoạch) — gom nhật ký lỗi + thiết bị + ảnh chụp màn hình,
      bấm một nút là **gửi thẳng**, người dùng không phải biết GitHub là gì. App POST tới một
      endpoint nhỏ giữ token phía máy chủ (`11-bao-loi-endpoint.md`); **không nhúng token vào
      app** vì token trong APK/IPA thì ai cũng rút ra được và nó có quyền ghi vào repo.
      Bản dựng thiếu `--dart-define=BEONG_REPORT_ENDPOINT` rơi về đường mở trang, và nói rõ là
      **chưa gửi** chứ không giả vờ đã xong.
- [ ] Dựng endpoint nhận báo lỗi (Cloudflare Worker) + tạo nhãn `bug`, `from-app` — cần tài
      khoản của chủ dự án, xem `11-bao-loi-endpoint.md`
- [ ] FCM push (mobile) + local notification (desktop)
- [ ] 7 loại thông báo trong bảng ở `01-product-spec.md` §4.7
- [ ] Bộ điều tiết "nhắc nhẹ, không cằn nhằn": trần 2 thông báo/ngày cho trẻ, gộp sự kiện,
      chặn gửi sau giờ đi ngủ — có unit test riêng
- [x] Cài đặt: **chủ đề sáng/tối** (lưu theo thiết bị) và **giờ đổi ngày** (0/3/4/5/6 giờ). Sửa
      kèm một lỗi chờ sẵn: các màn hình tự dựng `FamilyClock` với mặc định 4 và bỏ qua cột
      `day_rollover_hour` mà `DayStartService` vẫn đọc — hai bên sẽ lệch ngày ngay khi có ai đổi.
- [~] Cài đặt: **ngôn ngữ** — đã làm rồi **gỡ ra**. Ô chọn chạy đúng về mặt kỹ thuật, nhưng app
      chưa dịch được, nên chọn "English" ra một app nửa Việt nửa Anh. Đó đúng là loại lời hứa
      suông vừa gỡ ở ô "Thông báo".

      Số đo lại ngày 17/08 (con số cũ ở đây — "3 chỗ dùng ARB / 89 chuỗi cứng" — sai cả hai đầu):
      **15** lần gọi `L10n.of` ở 6 file, phần lớn là tiêu đề và nhãn thanh điều hướng trong
      `router.dart`. Chữ viết cứng thì **98** chuỗi nằm trực tiếp trong `Text('...')` — đây là
      con số mà lần đo trước bắt được — nhưng tổng số chuỗi có dấu tiếng Việt trong `lib/` là
      **~644**, vì rất nhiều chữ hiển thị đi qua tham số (`label:`, `title:`, `hintText:`,
      `content:` của SnackBar) chứ không nằm trong `Text()`. Trừ ~23 chuỗi là thông điệp lỗi nội
      bộ thì việc thật vẫn cỡ **600 chuỗi**, không phải 89.

      Nói cách khác đây **không** phải việc một buổi. Việc thật cần làm trước là đưa chuỗi vào
      ARB theo từng màn; ô chọn ngôn ngữ chỉ là phần ngọn.
- [ ] Cài đặt: âm thanh — hoãn có chủ ý. App chưa phát âm thanh nào; một công tắc không điều
      khiển gì là cờ chết, đúng thứ dự án này đã phải đi dọn năm lần.
- [x] Trang trống ✅ (đã có sẵn ở mọi màn chính) và **trạng thái lỗi** — `LoiManHinh` +
      `LuongDuLieu`. Trước đó **không một `StreamBuilder` nào** kiểm `hasError`: luồng hỏng thì
      màn hình rơi về mặc định và hiện như thể nhà chưa có việc nào. Áp cho 5 chỗ mà hiện sai
      tệ hơn hiện lỗi: việc của con, việc của nhà, phần thưởng, thành viên, sổ cái.
- [ ] ~~Màn hình mất mạng~~ — **không cần**: app là offline-first (ADR-002), không có màn nào
      chờ mạng. Sẽ cần lại khi có sync ở Sprint 3.
- [x] Rà soát khả dụng — thành **test tự động** (`test/unit/kha_dung_test.dart`), theo đúng bài
      học Sprint 0: ràng buộc khả dụng không có test thì chỉ là ước muốn. Canh tooltip cho mọi
      `IconButton`, `excludeFromSemantics` cho icon trang trí, trần phóng chữ ở gốc app, và
      không màu hard-code trong `lib/features`. Bắt được một màu lọt lưới, nay là token `onXu`.
      Vẫn cần một lượt bật TalkBack thật trước khi phát hành.

## Chặn phát hành — sửa trước khi cho người ngoài dùng

Tìm ra ngày 22/08 khi chạy app thật; chi tiết, nguyên nhân gốc và cách kiểm ở
[`13-audit-luong-vao-app.md`](13-audit-luong-vao-app.md).

- [x] 🔴 **Đăng xuất xong không có đường vào lại** — sửa ở `v0.2.3`. Router tách ba trạng thái
      thay vì hai; thêm màn **"Ai đang dùng máy?"** liệt kê **mọi** nhà trong máy, nên máy nào đã
      lỡ dính lỗi vẫn mở lại được nhà mồ côi. Nút ĐĂNG XUẤT đổi thành **KHOÁ LẠI** — chữ cũ sai
      với việc nó làm, app không có tài khoản nào để xuất ra.
      Kiểm trên đúng máy đã dính lỗi (2 nhà, 4 thành viên, 24 việc): chọn nhà cũ → vào lại đủ 12
      việc, không mất gì.
- [x] 🔴 **Quên PIN là mất quyền bố mẹ vĩnh viễn** — sửa ở `v0.2.3`, mở rộng ở `v0.2.4`. Có
      "Quên mật khẩu?" ngay ở màn nhập; từ ADR-027 thì nó **đổi** mật khẩu chứ không **gỡ**, vì
      gỡ sẽ để lại hồ sơ trống. Bố mẹ cũng đặt lại được mật khẩu cho con từ Cài đặt.
- [ ] Thêm dấu vết chẩn đoán lúc khởi động (đọc session thành công/thất bại, đường dẫn dữ liệu)
      để lần sau chẩn được ca "mở lại app phải cấu hình từ đầu" thay vì đoán.

      **Vẫn để mở, và cố ý.** §1 của audit chưa dựng lại được lần nào trên bản Linux, nên chưa có
      gì để sửa. Nhưng lưới an toàn của §2 che một phần ca xấu nhất: nếu cờ "máy đã có dữ liệu"
      sai vì đọc DB lúc khởi động hỏng, onboarding vẫn hỏi lại trước khi ghi đè.

### Sửa thêm sau khi chạy thật, không nằm trong audit

- [x] **Bấm xong việc bị giật cục** (`v0.2.5`) — chủ dự án báo 23/08. Đo trước khi đoán: ghi DB
      mất 3ms, nên nghẽn ở giao diện chứ không ở dữ liệu. Ba lớp chồng nhau:
      bốn luồng được tạo mới trong mỗi `build()` nên `StreamBuilder` đăng ký lại và cả danh sách
      nháy thành vòng xoay — hai lần mỗi cú chạm, vì hoa giấy `setState` hai lượt; mỗi thẻ tự đi
      hỏi dữ liệu riêng và cao 0 trong lúc chờ; và thẻ không phản hồi gì cho tới khi ghi xong.
- [x] **Bước đặt mật khẩu của onboarding không bao giờ chạy** (`v0.2.4`) — `login()` gọi trước
      nên router đá khỏi màn, `if (!mounted) return` nuốt gọn cả vòng. Onboarding chạy xong với
      hai hồ sơ `pin_hash = NULL` mà không báo gì. Sống sót qua 507 test xanh; chỉ lộ ra khi chạy
      app thật và nhìn.

Cả hai lỗi trên đều thuộc **loại lặp đi lặp lại của dự án**: thứ có trong code mà không ai đọc,
hoặc không bao giờ chạy. Danh sách các lần trước ở Sprint 2, khối `proof_mode`.

## Sprint 6 — Phát hành v1.0 (1 tuần)

> **iOS đã đi được tới TestFlight thật.** `0.2.5+8`, run #19 ngày 23/08. Trước đó lane `release`
> chưa từng chạy lần nào nên mang một lỗi không ai biết (`reject_build_waiting_for_review` — tên
> tuỳ chọn không tồn tại); đã sửa. Chốt chặn còn lại **không phải mã** — xem đầu
> [`08-release-cicd.md`](08-release-cicd.md).
- [ ] Icon app, splash, ảnh chụp store
- [ ] 🔴 **Hồ sơ App Store chưa điền** — chặn cứng đường ra công khai. Binary lên được App Store
      Connect nhưng `submit_for_review` hỏng vì thiếu: ảnh chụp (`iphone65`, `ipadPro129`), mô tả,
      từ khoá, URL hỗ trợ, URL chính sách, **toàn bộ bảng phân loại độ tuổi**, khai báo thu thập
      dữ liệu, danh mục chính, **giá**, và khai báo bản quyền nội dung. Chỉ chủ tài khoản điền
      được; chạy lại CI bao nhiêu lần cũng vậy, mỗi lần chỉ tốn thêm một build number.
- [ ] 🔴 **Secret `PLAY_STORE_SERVICE_ACCOUNT_JSON` không hợp lệ** — thiếu `"type":
      "service_account"`, hay gặp nhất là dán bản base64 thay vì nguyên văn. CI nay kiểm ngay sau
      checkout và báo rõ, thay vì để lộ ra sau bốn phút build.
- [x] **Chính sách quyền riêng tư** — đăng công khai ở `site/quyen-rieng-tu.html`, đã điền đơn vị
      phát hành (360 CORP) và email liên hệ (info@beong.net). Bản thảo kèm phụ lục khai báo cho
      form hai store vẫn ở `10-privacy-policy.md`. **Chưa qua rà soát pháp lý** — vẫn nên làm
      trước khi nộp.
- [x] **Điều khoản sử dụng** — `site/dieu-khoan.html`
- [ ] Khai báo store: **không mua trong app, không quảng cáo** (ADR-014)
- [ ] Khai báo App Store "Kids Category" / Play "Teacher Approved" nếu áp dụng
- [x] **Fastlane → TestFlight** ✅ (run #14, #18, #19). Play Internal ❌ — chờ secret ở trên
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
