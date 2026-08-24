---
name: flutter-8-buoc
description: Quy trình 8 bước phát triển app mobile Flutter — từ chốt phạm vi, ghi quyết định kiến trúc, sinh code, kiểm tự động, chạy app thật soi ảnh chụp, tới commit/push. Dùng skill này mỗi khi làm bất cứ việc gì trên codebase Flutter: thêm màn hình, sửa giao diện, đổi bảng màu, thêm dependency, sửa lỗi, hay refactor — kể cả khi người dùng chỉ nói ngắn như "thêm tab này", "màu này không đẹp", "font khó đọc", "làm tiếp đi". Đặc biệt hữu ích khi repo có lint nghiêm (`--fatal-infos`), có code generation (drift/riverpod/freezed/l10n), hoặc có ràng buộc khả dụng (contrast, vùng chạm) cần giữ.
---

# 8 bước phát triển app Flutter

Quy trình này rút ra từ việc làm thật, không phải từ sách. Mỗi bước tồn tại vì
**đã có lỗi lọt qua khi thiếu nó**. Chỗ nào có ví dụ cụ thể là lỗi thật đã gặp.

Nguyên tắc xuyên suốt: **`flutter analyze` sạch và test xanh không có nghĩa là
đúng.** Phần lớn lỗi giao diện nghiêm trọng nhất chỉ hiện ra khi chạy app thật
và *nhìn* vào ảnh chụp. Bước 6 là bước đắt nhất nhưng cũng là bước bắt được
nhiều lỗi nhất — đừng bỏ.

---

## Hiến pháp dự án — thứ không thương lượng

Trước 8 bước, phải biết đâu là **ràng buộc không được thoả hiệp**. Trong repo
Flutter, hiến pháp thường nằm rải ở:

- **ADR** (`docs/06-decisions.md` hoặc tương đương) — quyết định kiến trúc kèm lý do
- **Ràng buộc khả dụng** trong design system — ngưỡng tương phản, vùng chạm, trần phóng chữ
- **Cổng CI** — `--fatal-infos`, format, test phải xanh
- **Ràng buộc nền tảng** — offline-first, quyền riêng tư trẻ em, không quảng cáo

Điều luật quan trọng nhất, và cũng là chỗ dễ sai nhất khi đang gấp:

> **Xung đột với hiến pháp thì sửa việc đang làm, không pha loãng nguyên tắc.**
> Nếu bản thân nguyên tắc cần đổi, đó phải là **một hành động riêng, tường minh**
> — không bao giờ là tác dụng phụ của việc làm cho công việc hôm nay chạy được.

Ba dạng pha loãng hay gặp, đều phải nhận ra và từ chối:

| Dạng pha loãng | Ví dụ thật |
|---|---|
| **Hạ ngưỡng test** | Test đòi 3:1, thực tế 2.94:1 → sửa assertion xuống 2.9. Đúng: thêm viền cho linh vật để đạt 3:1 thật. |
| **Diễn giải lại** | "Ngưỡng 3:1 kia chắc chỉ áp cho chữ thôi" — trong khi hình mang nghĩa cũng thuộc phạm vi. |
| **Im lặng bỏ qua** | Commit test bị `skip` mà không nói, hoặc bỏ ràng buộc mà không sửa tài liệu. |

Khi thật sự cần đổi nguyên tắc: đổi nó trong một commit riêng, ghi rõ vì sao, rồi
mới làm việc phụ thuộc vào nó.

---

## Bước 1 — Đọc tài liệu sẵn có trước khi viết dòng code nào

Trước khi làm, tìm xem quyết định đã được chốt chưa:

```bash
ls docs/ .claude/skills/ 2>/dev/null
grep -rn -i "<từ khoá liên quan>" docs/ | head -20
```

Vì sao quan trọng: rất nhiều thứ tưởng là việc mới thì hoá ra đã có quyết định,
và đôi khi đã có cả TODO chỉ chờ người làm.

> **Ví dụ thật:** khi cần chọn font, `docs/04-design-system.md` §2 đã chốt Nunito
> từ đầu với đúng lý do cần tìm ("bo tròn thân thiện trẻ em, hỗ trợ đầy đủ tiếng
> Việt có dấu"), và `app_typography.dart` có sẵn `// TODO(sprint1)`. Nếu không
> đọc thì sẽ tự chọn font khác và phá vỡ tài liệu.

Nếu yêu cầu mới **ngược** với quyết định cũ, đừng im lặng đổi: nói ra sự ngược
đó, giải thích trade-off, rồi làm theo hướng đã bàn.

> **Ví dụ thật:** yêu cầu "icon hiện đại, công nghệ hơn" rồi ngay sau đó "thân
> thiện hơn với trẻ con". Không phải mâu thuẫn vô nghĩa — cách giải là giữ nét bo
> tròn hiện đại nhưng đổi ký hiệu trừu tượng (lưới dashboard, sliders) sang vật
> thể cụ thể (nhà, bánh răng), vì bé chưa đọc được nhãn thì icon là nội dung duy
> nhất. Nói rõ trade-off này thay vì lặng lẽ đổi qua đổi lại.

### Làm rõ chỗ chưa rõ **trước** khi thiết kế, không phải sau

Nếu yêu cầu còn mơ hồ ở mức **đổi cách làm**, hỏi trước. Nếu mơ hồ ở mức không
ảnh hưởng kết quả, tự quyết rồi nói rõ mình đã giả định gì. Phân biệt hai loại
này là việc phải làm ngay ở bước 1 — phát hiện muộn thì phải làm lại.

Cách tách: *"nếu đoán sai điều này, tôi có phải viết lại không?"* Có → hỏi.
Không → quyết và ghi lại giả định.

> **Ví dụ thật:** luồng ghép cặp QR kéo theo câu hỏi "đôn backend lên trước
> Sprint 3, hay ra v1.0 một-thiết-bị rồi ghép cặp ở v1.1?". Đoán sai thì cả thứ
> tự sprint sai — đây là quyết định sản phẩm, phải hỏi. Ngược lại "dùng
> `mobile_scanner` hay gói quét QR khác" thì tự quyết được, chỉ cần ghi lý do.

## Bước 2 — Tính ràng buộc, đừng ước lượng bằng mắt

Với mọi ràng buộc đo được (tương phản màu, cỡ chữ, vùng chạm, độ phủ ký tự
font), **tính bằng script rồi mới thiết kế**. Thiết kế theo cảm giác rồi kiểm sau
là làm ngược, và thường phải làm lại.

```bash
# Ví dụ: tính tương phản WCAG trước khi chốt bảng màu
python3 -c "
def srgb(c):
    c/=255
    return c/12.92 if c<=0.04045 else ((c+0.055)/1.055)**2.4
def lum(h):
    h=h.lstrip('#'); r,g,b=(int(h[i:i+2],16) for i in (0,2,4))
    return 0.2126*srgb(r)+0.7152*srgb(g)+0.0722*srgb(b)
def cr(a,b):
    la,lb=lum(a),lum(b); hi,lo=max(la,lb),min(la,lb)
    return (hi+0.05)/(lo+0.05)
print(cr('#FFC53D','#FFFFFF'))"
```

Ngưỡng WCAG cần nhớ: **4.5:1** chữ thường, **3:1** chữ lớn (≥18.66px đậm hoặc
≥24px) và hình mang nghĩa/thành phần UI.

> **Ví dụ thật:** vàng mật `#FFC53D` chỉ đạt **1.58:1** với chữ trắng nhưng
> **11.00:1** với chữ đậm. Chính con số đó quyết định vai của cả bảng màu — vàng
> làm nền nút với chữ đậm, xanh dương làm `primary` cho chỗ nét mảnh. Nếu chọn
> theo cảm giác sẽ ra nút vàng chữ trắng, không đọc được.

Tương tự, đừng tin tài liệu của thư viện — **kiểm bằng dữ liệu**:

> **Ví dụ thật:** font quảng cáo "hỗ trợ tiếng Việt" là chuyện thường, nhưng
> nhiều font thiếu dấu hoặc đặt dấu sai. Đã kiểm bằng `fontTools`: đủ 134/134 ký
> tự riêng của tiếng Việt ở cả ba file weight.

## Bước 3 — Ghi quyết định, và giữ tài liệu khớp với code

Nếu quyết định sẽ khiến người sau hỏi "sao lại làm thế?", ghi lại ngay: bối cảnh
→ quyết định → lý do → hệ quả → đã cân nhắc gì. Đặc biệt ghi **lý do phủ định**
(vì sao *không* chọn cách hiển nhiên hơn), vì đó là phần dễ mất nhất.

> **Ví dụ thật:** "QR ghép cặp chỉ chứa mã dùng một lần, không chứa dữ liệu" —
> cách hiển nhiên là nhét `family_id` + tên con vào QR cho gọn. Lý do không làm:
> QR bị chụp lại là chuyện thường, mà ảnh đã chụp thì không rút lại được. Hệ quả
> kéo theo rất lớn: **ghép cặp bắt buộc cần backend**, đôn cả lộ trình. Không ghi
> lại thì 3 tháng sau có người "tối ưu" bằng cách nhét dữ liệu vào QR.

### Đối chiếu chéo: code, tài liệu, lộ trình có nói khác nhau không?

Trước khi implement, rà một lượt **chỉ đọc** xem ba nguồn có mâu thuẫn:

```bash
grep -rn "<token/quyết định vừa đổi>" docs/ lib/ | head -20
```

Tài liệu lệch với code còn tệ hơn không có tài liệu: người sau tin vào nó và làm
sai. Nên **đổi ràng buộc thì cập nhật tài liệu trong cùng commit**, đừng để dồn.

> **Ví dụ thật:** sau khi đổi bảng màu sang màu thương hiệu 360, `docs/04-design-system.md`
> §1 vẫn ghi bảng màu tím cũ — tài liệu tự mâu thuẫn với chính code nó mô tả. Và
> luồng ghép cặp mới khiến `05-roadmap.md` (backend ở Sprint 4) không còn đúng.
> Cả hai đều phải sửa cùng lúc, không phải "để sau".

## Bước 4 — Sinh code trước khi làm bất cứ gì khác

Repo Flutter hiện đại thường có nhiều tầng codegen. Chạy **trước** khi viết code
và **trước** mỗi lần analyze/test, nếu không sẽ đuổi theo lỗi không tồn tại:

```bash
export PATH="/opt/flutter/bin:$PATH"      # chỉnh theo máy
flutter pub get
dart run build_runner build                # drift, riverpod, freezed, json
flutter gen-l10n                           # nếu dùng ARB
```

File `*.g.dart` thường bị gitignore, nên máy mới clone về là **chưa có** — CI
cũng vậy. Quên bước này thì thấy hàng loạt "Undefined name" của thứ mình vừa viết
đúng.

## Bước 5 — Viết code đi qua token, không hard-code

Trước khi đặt một con số hay một màu vào widget, tìm xem đã có token chưa:

```bash
grep -rn "class App" lib/core/theme/
```

Nguyên tắc:
- Màu → token trong `app_colors.dart` / `Theme.of(context)`, không `Color(0x...)` rải rác
- Khoảng cách, bo góc, cỡ icon → `AppSpacing` / token riêng
- Chuỗi hiển thị → ARB, không hard-code
- Ràng buộc khả dụng (cỡ icon tối thiểu, vùng chạm) → **đưa vào token có tên**,
  vì nó là ràng buộc cần test giữ, không phải tinh chỉnh thẩm mỹ tuỳ ý

> **Ví dụ thật:** cỡ icon nav 30dp (lớn hơn 24dp mặc định của Material) không
> phải sở thích — bé chưa đọc được nhãn thì icon là nội dung duy nhất. Đưa vào
> `AppNavMetrics.iconSize` kèm test chặn việc hạ xuống, thay vì viết `size: 30`
> trong theme.

Khai báo **tường minh** các trường mà framework sẽ tự điền nếu bỏ trống, khi giá
trị tự điền đó sai với thương hiệu:

> **Ví dụ thật:** `ColorScheme` không khai `secondaryContainer` thì Material 3
> tự suy ra màu **teal**, và màu đó lọt vào viên nền icon nav — lạc hoàn toàn
> khỏi bảng màu. Lỗi này sống sót qua nhiều sprint vì nó không nằm ở màu nào ta
> viết ra, mà ở màu framework tự điền vào chỗ trống.

## Bước 6 — Chạy app thật và *nhìn* ảnh chụp

Đây là bước bắt được nhiều lỗi nhất, và không có bước nào thay được nó.

```bash
# Màn hình ảo đúng cỡ điện thoại — không phải cỡ desktop
nohup Xvfb :98 -screen 0 412x900x24 >/dev/null 2>&1 & disown
sleep 2
# BẮT BUỘC: không có window manager thì cửa sổ Flutter vẫn nằm ở 1280x720
nohup env DISPLAY=:98 matchbox-window-manager -use_titlebar no \
  >/dev/null 2>&1 & disown
sleep 2
nohup env DISPLAY=:98 LANG=vi_VN.UTF-8 ./build/linux/x64/debug/bundle/<app> \
  > /tmp/app.log 2>&1 & disown
sleep 8
DISPLAY=:98 import -window root /tmp/shot.png
```

Chỗ này mất thời gian nhất nếu làm sai: `gtk_window_set_default_size` trong
`linux/runner/my_application.cc` là **1280x720**, và trên Xvfb trống không có
window manager thì `xdotool windowsize` chỉ đổi cửa sổ X — Flutter không nhận
configure event nên surface vẫn 1280 rộng. Ảnh chụp ra là **layout desktop bị
cắt còn 412px**, trông rất giống mobile: cùng một màn hình, cùng font, chỉ lệch
lề và mất thanh trên. Dấu hiệu nhận biết: `xdotool getwindowgeometry` báo đúng
412x900 nhưng nội dung vẫn tràn khỏi mép phải, và phần dưới y=720 là **đen**.
Cách chắc chắn: cài `matchbox-window-manager` rồi để WM tự map cửa sổ full
screen — không cần resize tay nữa.

Rồi **đọc ảnh bằng công cụ đọc ảnh**, và zoom vào chi tiết đáng ngờ:

```bash
convert /tmp/shot.png -crop 170x170+230+95 +repage -resize 350% /tmp/zoom.png
```

Ba điều bắt buộc:

1. **Chụp ở đúng cỡ thiết bị thật.** Layout responsive đổi nhánh theo bề rộng;
   chụp ở 1280 thì đang xem nhánh desktop chứ không phải mobile.
2. **Đi hết luồng**, không chỉ mở app. Lỗi nằm ở lúc danh sách xếp lại, lúc
   chuyển tab, lúc hoàn thành item cuối.
3. **Đọc log song song.** Exception in lặng vào log chứ không hiện trên UI.

> **Lỗi thật bước này bắt được, mà test không bắt:**
> - Danh sách 9 việc hiện **trùng tên 3 lần**, mất 2 việc — do thẻ trong list
>   thiếu `key` nên Flutter tái dùng `State` theo vị trí, `initState` không chạy
>   lại và thẻ giữ tên của item cũ.
> - Sọc của linh vật **chạy ngang qua mắt** — chỉ thấy khi zoom 350%.
> - Chữ số xu **vàng trên nền vàng nhạt**, 1.47:1, gần như không đọc được.
> - Viên nền icon nav màu **teal** lạc bảng màu.
>
> Cả bốn lỗi này đều tồn tại khi `flutter analyze` sạch và toàn bộ test xanh.

Cẩn thận `pkill -f "<đường dẫn app>"`: mẫu `-f` khớp cả command line của chính
script đang chạy nên nó tự giết shell. Dùng `pkill -x <tên process>`.

## Bước 7 — Kiểm tự động, và viết test cho mọi ràng buộc vừa tuyên bố

```bash
flutter analyze --fatal-infos     # info-level cũng chặn CI
flutter test
dart format --set-exit-if-changed lib test
```

`--fatal-infos` biến mọi gợi ý thành lỗi. Danh mục lint hay gặp và cách sửa:
`references/lint-thuong-gap.md`.

Quy tắc quan trọng nhất của bước này:

> **Ràng buộc ghi trong tài liệu mà không có test tương ứng thì chỉ là ước
> muốn.** Nếu vừa viết "mọi màu đạt 4.5:1" hay "icon tối thiểu 30dp", viết test
> ép nó ngay trong cùng lần commit.

Test tốt còn chặn được cả việc **tiền đề bị đổi trôi**:

> **Ví dụ thật:** có test khẳng định vàng mật và xanh lá *vẫn không* gánh được
> chữ trắng. Nghe vô nghĩa, nhưng nếu ngày nào hai màu đó bỗng đạt ngưỡng thì tức
> là mã màu đã bị đổi, và toàn bộ lý do chia vai trong bảng màu không còn đúng —
> test phải đỏ để có người xem lại.

Với danh sách động, test luôn: **sau khi item chuyển mục/xoá, mỗi tên còn xuất
hiện đúng một lần** — đó chính là bẫy thiếu `key`.

### Chốt chặn trước khi đẩy và trước khi tag — **không thương lượng**

> **Chưa chạy ba lệnh trên thì chưa được `git push`. Chưa xanh thì chưa được
> `git tag`.**

`flutter analyze --fatal-infos` mất **dưới 20 giây**. Một vòng CI mất **3–8
phút**, một vòng release mất **4–5 phút và tiêu một build number vĩnh viễn**
(Apple không nhận lại `+build` đã dùng). Đổi 20 giây lấy chừng đó là phép tính
không cần cân nhắc.

Đây là bài học đắt nhất của dự án tính tới nay, và nó đã lặp **ba** lần:

| Ngày | Chuyện gì xảy ra |
|---|---|
| 23/08 | 8/16 lượt CI đỏ liên tiếp; `main` để đỏ qua đêm. Chuỗi commit `fix(linter)`, `fix(domain): tuân thủ strict linter` là dấu hiệu của vòng lặp đẩy-lên-xem-CI-đỏ-sửa-đẩy-lại |
| 24/08 | **Tag `v0.2.7` gắn lên code không biên dịch được.** Ba lượt release đỏ ở bước *build*, không phải bước đẩy store. Bốn lỗi, phát hiện ở local trong 19 giây |
| 24/08 | Commit gây ra chúng tên là **`fix(linter): resolve analyzer warnings`** — commit dọn cảnh báo lại làm hỏng bản dựng |

**CI không phải trình biên dịch của bạn.** Nó là lưới an toàn cuối, chạy sau khi
bạn đã tự tin. Dùng nó để *phát hiện* lỗi cú pháp là biến mỗi lỗi vặt thành 5
phút chờ, và trong lúc đó không ai khác build được.

#### Bốn cái bẫy đã thật sự xảy ra ở dự án này

Cả bốn đều **không** bị `dart format` hay code review bắt, và cả bốn đều làm
hỏng bản dựng release:

1. **Xoá một trường nhưng còn chỗ dùng.** Tách "xu chưa chia" ra banner riêng,
   xoá trường `pending` khỏi `_JarCard`, để sót ba chỗ còn đọc nó.
   → Sau khi xoá field/param, `grep` tên đó trên cả `lib/` trước khi commit.
2. **Dùng `unawaited` mà thiếu `import 'dart:async'`.** Trình soạn thảo không
   tự thêm vì `unawaited` trông như một hàm sẵn có.
3. **Gọi hàm bằng tham số của hàm khác.** `hoiMatKhau(batBuoc:, moTa:)` —
   `batBuoc` thuộc `datMatKhauMoi`. Tên gần giống nhau là đủ để nhầm.
4. **Bịa tên token màu.** `AppColors.kpiRed` không tồn tại; bảng màu có
   `dangerLight`. Đặt màu cho nút phá huỷ thì dùng `context.semantic.danger`,
   không dùng hằng số cứng — hằng số cứng sai màu ở giao diện Tối.

#### Ba thứ luôn phải đồng bộ khi đổi phiên bản

Đổi `pubspec.yaml` mà quên hai chỗ kia là test đỏ — và đã đỏ **ba lần**:

```
pubspec.yaml  version: X.Y.Z+N
lib/features/settings/bao_loi_screen.dart   kPhienBanApp = 'X.Y.Z'
```

Test `test/unit/core/bao_cao_loi_test.dart` canh đúng cặp này: báo cáo lỗi ghi
sai phiên bản thì mọi kết luận rút ra từ nó sai theo.

#### Trước khi tag phát hành, kiểm thêm

- **Build number**: đã tự động, đừng tăng tay nữa. CI cấp
  `1000 + run_number*10 + run_attempt` cho cả hai nền tảng, nên `+build` trong
  pubspec chỉ còn dùng khi build tại máy. Bối cảnh: Apple từ chối `+build`
  trùng bản đã nộp — kể cả bản chỉ nằm trên TestFlight, kể cả khi lần nộp
  trước hỏng giữa chừng — và run #27 (24/08/2026) đã dựng IPA xong 2 phút 22
  rồi hỏng ở giây thứ 8 của bước đẩy vì `+14` đã có trên TestFlight
  (`ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE`, `previousBundleVersion: 14`).
  Quy tắc "nhớ tăng build number" đã nằm trong tài liệu từ trước mà vẫn hỏng —
  đó là bằng chứng quy tắc trông chờ trí nhớ thì không phải là quy tắc. Nếu
  lần sau vẫn gặp lỗi này, sửa **công thức trong workflow**, đừng sửa pubspec.
- **Hồ sơ trên store đã điền xong chưa?** Nếu chưa, lane `release` sẽ dựng xong
  binary rồi mới hỏng ở `submit_for_review` — tốn một build number cho không.
  Chi tiết ở đầu `docs/08-release-cicd.md`.

### Ngân sách hiệu năng — đo được, không tuyên bố suông

App mobile bị giới hạn bởi pin, RAM và mạng, nên đặt ngưỡng **kèm cách đo**.
Ngưỡng không có lệnh đo đi cùng thì cũng chỉ là ước muốn, giống ràng buộc không
có test:

| Chỉ tiêu | Ngưỡng khởi điểm | Cách đo |
|---|---|---|
| Thời gian mở app (lạnh) | < 3 giây | `flutter run --profile --trace-startup` → đọc `timeToFirstFrameMicros` trong `build/start_up_info.json` |
| Cỡ bản cài | theo dõi mỗi release | `flutter build apk --release --analyze-size --target-platform android-arm64` |
| Nhịp khung hình | không jank ở luồng chính | `flutter run --profile` + Performance overlay / DevTools |
| RAM | không tăng đơn điệu khi điều hướng qua lại | DevTools → Memory, chuyển tab 10 lần rồi xem có nhả không |

Hai lưu ý về `--analyze-size`: chỉ chạy được với `--release`, và trên Android
phải chỉ định đúng **một** ABI bằng `--target-platform`.

Đừng đo hiệu năng ở bản `debug` — debug chậm hơn nhiều lần, số liệu vô nghĩa.
Luôn dùng `--profile` (hoặc `--release` cho cỡ bản cài).

## Bước 8 — Sửa gốc, nói thật, rồi commit từng phần

**Sửa gốc, không hạ ngưỡng.** Khi test đỏ vì thực tế chưa đạt, sửa thực tế.

> **Ví dụ thật:** thân linh vật chỉ đạt 2.94:1 với nền, dưới ngưỡng 3:1. Cách sai
> là hạ assertion xuống 2.9. Cách đúng là thêm viền sáng kiểu sticker làm phần
> tiếp giáp nền — vừa đạt ngưỡng thật, vừa đẹp hơn.

**Nói thật phần chưa làm được.** Không commit test bị treo hay bị skip âm thầm —
nó làm đứng CI hoặc tạo cảm giác an toàn giả. Ghi rõ trong commit message cái gì
chưa có test và vì sao.

> **Ví dụ thật:** widget test dựng cả màn hình với DB trong bộ nhớ bị treo do
> tương tác giữa stream drift đang mở, Riverpod auto-dispose và đồng hồ giả của
> `testWidgets`. Sau 4 cách thử vẫn treo → xoá test, ghi rõ trong commit là lỗi
> đó chưa có test tự động và vì sao, thay vì commit test làm đứng CI.

**Commit từng phần, push ngay.** Mỗi phần hoàn chỉnh (đã analyze + test + format
xanh) là một commit. Commit message viết **vì sao**, không chỉ *cái gì* — nhất là
lý do không chọn cách hiển nhiên hơn.

```bash
flutter analyze --fatal-infos && flutter test && dart format --set-exit-if-changed lib test
git add -A && git commit -m "..." && git push -u origin <branch>
```

---

## Mẫu báo cáo khi giao việc

Kết thúc một phần việc, báo lại theo khung này. Mục **Chưa làm / chưa kiểm** là
mục quan trọng nhất và không được bỏ trống bằng chữ "không có" nếu thực tế có:

```markdown
## Đã làm
- [thay đổi, kèm lý do nếu có chọn lựa đáng nói]

## Kiểm chứng thế nào
- analyze --fatal-infos: [sạch / còn gì]
- test: [n pass, có test mới nào]
- Chạy app thật: [cỡ màn hình, luồng đã đi, ảnh chụp]

## Lỗi phát hiện thêm (nếu có)
- [lỗi, nguyên nhân gốc, đã sửa chưa]

## Chưa làm / chưa kiểm
- [phần bỏ lại và **vì sao**, nhất là chỗ không có test tự động]
```

Vì sao có mục cuối: người đọc cần biết ranh giới của thứ đã được kiểm. Báo cáo
chỉ toàn phần thành công tạo cảm giác an toàn giả, và người sau sẽ tin vào chỗ
chưa từng được kiểm.

## Tiêu chí "xong" cho một phần việc

Đủ cả sáu, không phải năm:

1. `flutter analyze --fatal-infos` sạch
2. `flutter test` xanh, **và** mọi ràng buộc vừa tuyên bố đều có test tương ứng
3. `dart format --set-exit-if-changed lib test` sạch
4. Đã chạy app thật ở **đúng cỡ thiết bị** và đã *nhìn* ảnh chụp
5. Chuỗi hiển thị nằm trong ARB, màu/khoảng cách đi qua token
6. Đã nói rõ phần nào chưa có test và vì sao

---

## Bảng tra nhanh

| Triệu chứng | Nguyên nhân thường gặp | Bước |
|---|---|---|
| "Undefined name" cho thứ vừa viết đúng | Chưa chạy `build_runner` / `gen-l10n` | 4 |
| Màu lạ không có trong bảng màu | Trường `ColorScheme` bỏ trống, framework tự điền | 5 |
| Danh sách hiện trùng tên / sai tên item | Thiếu `key` trong list, `State` bị tái dùng | 6, 7 |
| Layout trông như desktop | Chụp ở bề rộng sai, đang xem nhánh khác | 6 |
| CI đỏ mà máy local xanh | `--fatal-infos`, hoặc thiếu codegen trên CI | 4, 7 |
| Chữ mờ khó đọc | Chưa tính tương phản, hoặc dùng màu nền làm màu chữ | 2 |
| `pkill` tự giết shell | `-f` khớp command line của chính script | 6 |
| Release đỏ ở bước **build** (không phải bước đẩy store) | Code không biên dịch được — chạy `analyze` ở local, 20 giây | 7 |
| Release đỏ ở bước **đẩy store** | Hồ sơ store chưa điền, hoặc secret sai — không phải lỗi mã | 7 |
| `The getter 'X' isn't defined` sau khi refactor | Xoá field/param nhưng còn chỗ dùng — `grep` tên đó trên `lib/` | 7 |
| `The method 'unawaited' isn't defined` | Thiếu `import 'dart:async'` | 7 |
| `The named parameter 'X' isn't defined` | Gọi hàm bằng tham số của **hàm khác** tên gần giống | 7 |
| Test phiên bản đỏ sau khi bump | Quên `kPhienBanApp` trong `bao_loi_screen.dart` | 7 |
| Đẩy store hỏng sau ~8 giây, `ENTITY_ERROR...DUPLICATE` | Build number trùng bản đã nộp — CI đã tự cấp, kiểm công thức trong `release.yml` | 7 |
