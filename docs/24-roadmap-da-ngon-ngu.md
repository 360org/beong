# Roadmap đa ngôn ngữ — giao cho agent khác thực hiện

Bối cảnh và số đo: đọc `docs/23-audit-da-ngon-ngu.md` **trước**. File này chỉ
nói làm gì, theo thứ tự nào, và làm sao biết đã xong.

Mục tiêu: **tiếng Việt là ngôn ngữ gốc, app hỗ trợ đủ Việt + Anh.**

---

## Luật chung — đọc hết trước khi gõ dòng đầu tiên

1. **Tiếng Việt là gốc.** `app_vi.arb` là template (`l10n.yaml` đã trỏ đúng).
   Viết chuỗi Việt trước, rồi mới dịch sang `app_en.arb`. Không bao giờ ngược
   lại.
2. **Không dịch dữ liệu của người dùng.** Tên bé, tên việc bố mẹ tự gõ, tên hũ
   bố mẹ đã sửa, lý do cộng/trừ xu, ghi chú — giữ nguyên như người dùng nhập.
   Dịch những thứ này là sửa lời của người khác.
3. **"Bé Ong" không dịch.** Tên thương hiệu, giữ nguyên ở cả hai ngôn ngữ.
   Slogan thì dịch.
4. **Không đổi khoá đã đi vào DB.** `jars.jar_key`, `tasks.icon_key`,
   `badge.key`, `preset.key` — chúng nằm trong cơ sở dữ liệu người dùng. Đổi
   khoá là làm hỏng dữ liệu đang có.
5. **Mỗi đợt một commit, một lần push.** Không gộp nhiều đợt: một bản vá 877
   chuỗi là bản vá không ai soát nổi.
6. Chuỗi mới thêm trong lúc làm cũng phải đi qua `.arb`. Đợt 0 dựng chốt chặn
   để điều này không trông chờ trí nhớ.

### Quy ước đặt tên khoá

`<miền><Việc>` kiểu camelCase, miền theo thư mục tính năng:

```
settingsJarsTitle, settingsPenaltySubtitle
tasksRoutineHint, tasksAddRoutineRow
statsTotalXu, statsJarEditTitle
commonSave, commonCancel, commonClose      // dùng ở từ hai miền trở lên
errorJarMustHaveName                        // ngoại lệ ném từ data/
```

Có sẵn 41 khoá khai rồi chưa dùng (`actionSave`, `jarSpend`, `timeMorning`…).
**Dùng lại chúng** chứ đừng đẻ khoá trùng nghĩa; đổi tên cho khớp quy ước trên
nếu cần, vì chưa chỗ nào gọi tới.

### Cạm bẫy của repo này

- `lib/core/l10n/gen/` **nằm trong .gitignore**. Sau khi sửa `.arb` phải chạy
  `flutter gen-l10n`, nếu không mã không biên dịch được ở máy sạch.
- CI chạy `dart format` **trước** `flutter analyze --fatal-infos`. Format đổi
  một dòng là analyze có thể đỏ ở dòng đó. Hook pre-commit đã làm đúng thứ tự
  này — đừng bỏ qua hook.
- `--fatal-infos`: mọi lint mức info đều chặn CI.
- `L10n.of(context)` cần `BuildContext`. Chuỗi nằm trong hàm không có context
  (service, DAO, hằng số cấp file) **không** chuyển thẳng được — xem Đợt 5.

---

## Đợt 0 — Chốt chặn và ô đổi ngôn ngữ

Làm trước tiên. Không có đợt này thì mọi đợt sau vừa dọn vừa bị đổ lại.

- [ ] **Ô "Ngôn ngữ" trong Cài đặt**, nhóm *Ứng dụng*, cạnh "Giao diện".
      Ba lựa chọn: *Theo hệ thống / Tiếng Việt / English*.
      Khuôn mẫu có sẵn: `lib/core/providers/theme_mode_provider.dart` — lưu ở
      `device_settings`, `restore()` gọi **trước** `runApp` trong `main.dart`
      (nạp sau thì khung hình đầu hiện sai ngôn ngữ rồi mới đổi).
      `BeOngApp` truyền `locale:` xuống `MaterialApp`; `null` = theo máy, để
      `resolveAppLocale` làm việc như hiện nay.
- [ ] **Test chặn chuỗi cứng mới.** Quét `lib/features/` tìm chuỗi có dấu
      tiếng Việt trong mã (bỏ qua chú thích), so với một **danh sách nợ** ghi
      rõ từng file kèm số chuỗi còn lại. Thêm chuỗi cứng mới vào file đã dọn
      xong ⇒ test đỏ. Mỗi đợt xong thì hạ số trong danh sách nợ xuống.
      Cùng lối với `test/unit/sheet_co_nut_dong_test.dart` đang có.
- [ ] Cập nhật `docs/04-design-system.md`: mọi chữ hiện cho người dùng đi qua
      `.arb`, không viết thẳng vào widget.

**Xong khi:** đổi sang English trong Cài đặt thì thanh điều hướng và 5 tiêu đề
màn đổi ngay, không cần khởi động lại; test nợ chạy xanh và đỏ đúng lúc.

## Đợt 1 — Món rẻ nhất: `titleEn` đang chết

39 bản dịch **đã viết sẵn** trong mã mà không ai đọc (audit §5.2).

- [ ] 16 chỗ gọi `preset.titleVi` chuyển sang chọn theo ngôn ngữ đang chạy.
      Gợi ý: thêm `String title(Locale)` hoặc `titleFor(BuildContext)` vào
      `TaskPreset` và `RewardPreset` thay vì rải `if` khắp nơi.
- [ ] Kiểm lại 39 bản dịch Anh có còn đúng không — chúng viết từ lâu.
- [ ] `BadgeCategory` (`badge_def.dart`) mới chỉ có `titleVi`: thêm `titleEn`.

**Xong khi:** chạy app ở English, danh sách việc mẫu và phần thưởng mẫu hiện
tiếng Anh. Ước lượng: nhỏ, nhưng chạm 6 file màn hình.

## Đợt 2 → 4 — Dịch màn hình (`features/`, 715 chuỗi)

Chia theo thư mục, **mỗi thư mục một commit**. Thứ tự dưới đây xếp theo mức
người dùng nhìn thấy, không theo số chuỗi:

| Đợt | Thư mục | Chuỗi |
|---|---|---:|
| 2 | `features/parent_home/` + `features/child_home/` | 110 |
| 2 | `features/tasks/` | 128 |
| 3 | `features/stats/` | 102 |
| 3 | `features/rewards/` + `features/goals/` | 87 |
| 4 | `features/settings/` | 142 |
| 4 | `features/members/` + `features/onboarding/` | 128 |
| 4 | `features/journey/` | 19 |

Với mỗi file:

1. Rút chuỗi ra `.arb` (vi trước, en sau), đặt tên theo quy ước trên.
2. Thay bằng `L10n.of(context).<khoá>`.
3. Chú thích tiếng Việt trong mã **giữ nguyên** — đó là tài liệu cho người
   bảo trì, không phải chữ trên màn hình.
4. Hạ số của file đó trong danh sách nợ ở test Đợt 0.

**Xong mỗi đợt khi:** `flutter analyze --fatal-infos` sạch, toàn bộ test xanh,
và **chạy app thật ở cả hai ngôn ngữ** soi từng màn vừa dịch — số đếm chuỗi
giảm không chứng minh được màn hình còn đọc được.

⚠️ Chữ tiếng Anh thường **dài hơn** tiếng Việt 20–30%. Soi kỹ nút và nhãn hẹp
ở bề ngang 412: màn Nhiệm vụ đang có sẵn một vệt tràn 7,5px chưa sửa.

## Đợt 5 — `core/`, `data/`, và chuỗi không có `BuildContext`

63 chuỗi ở `core/` và `data/`, cộng vài chỗ trong `domain/services/`.

- [ ] Widget dùng chung trong `core/` có context ⇒ làm như Đợt 2–4.
- [ ] **Ngoại lệ ném từ `data/`** (`JarException`, `TaskTrungTenException`…)
      không có context. Đừng nhét context vào DAO. Hai cách, chọn một và làm
      nhất quán: ném **mã lỗi** rồi tra ra chữ ở tầng giao diện, hoặc giữ chuỗi
      Việt trong exception và để tầng giao diện dịch theo mã kèm theo.
      Cách thứ nhất sạch hơn và hợp với lớp kiến trúc sẵn có.
- [ ] `lib/core/diagnostics/` là **nhật ký nội bộ**, không hiện cho người dùng:
      **không dịch**. Ghi rõ điều này vào chú thích file để đợt sau không ai
      dọn nhầm.

## Đợt 6 — Ngày tháng, số, và dữ liệu gieo sẵn

- [ ] `lib/core/utils/ngay_viet.dart`: thêm nhánh tiếng Anh (`MM/DD`, `Mon`…
      `Sun`). **Giữ** lựa chọn không dùng `intl` cho các dạng ngắn — lý do đã
      ghi trong file, đọc trước khi đổi.
- [ ] `dinhDangDong` trong `money_exchange.dart`: tiếng Anh ngăn nghìn bằng
      dấu phẩy.
- [ ] **Dữ liệu gieo sẵn** — quyết định ở audit §5.1: hũ mặc định và huy hiệu
      dịch **lúc hiển thị theo khoá**; mọi thứ bố mẹ đã sửa tên thì giữ nguyên.
      Nhớ: nhà tạo từ trước có tên hũ tiếng Việt **nằm sẵn trong DB** — không
      migration nào nên đụng vào, vì không phân biệt được đâu là tên app gieo
      và đâu là tên bố mẹ đã sửa.

---

## Thước đo

Chạy lệnh đếm ở `docs/23` §7 sau mỗi đợt. Con số phải giảm, và **chỉ** giảm ở
những file đợt đó nhận. Ghi lại vào bảng dưới:

| Ngày | Đợt | Chuỗi cứng còn lại |
|---|---|---:|
| 30/08/2026 | — (mốc đầu) | 877 |

## Việc này **không** bao gồm

- Thêm ngôn ngữ thứ ba. Cấu trúc chịu được, nhưng chưa ai yêu cầu.
- Dịch `docs/`. Tài liệu dự án viết cho người bảo trì, tiếng Việt là đúng.
- Dịch nội dung trang web `beong.net`.
