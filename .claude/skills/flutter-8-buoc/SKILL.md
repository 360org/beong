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

## Bước 3 — Ghi quyết định có hệ quả thành ADR

Nếu quyết định sẽ khiến người sau hỏi "sao lại làm thế?", ghi lại ngay: bối cảnh
→ quyết định → lý do → hệ quả → đã cân nhắc gì. Đặc biệt ghi **lý do phủ định**
(vì sao *không* chọn cách hiển nhiên hơn), vì đó là phần dễ mất nhất.

> **Ví dụ thật:** "QR ghép cặp chỉ chứa mã dùng một lần, không chứa dữ liệu" —
> cách hiển nhiên là nhét `family_id` + tên con vào QR cho gọn. Lý do không làm:
> QR bị chụp lại là chuyện thường, mà ảnh đã chụp thì không rút lại được. Hệ quả
> kéo theo rất lớn: **ghép cặp bắt buộc cần backend**, đôn cả lộ trình. Không ghi
> lại thì 3 tháng sau có người "tối ưu" bằng cách nhét dữ liệu vào QR.

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
sleep 4
nohup env DISPLAY=:98 LANG=vi_VN.UTF-8 ./build/linux/x64/debug/bundle/<app> \
  > /tmp/app.log 2>&1 & disown
sleep 6
# Cửa sổ Flutter mặc định 1280 rộng -> phải resize về đúng cỡ máy
WID=$(DISPLAY=:98 xdotool search --class <app> | tail -1)
DISPLAY=:98 xdotool windowsize "$WID" 412 900
DISPLAY=:98 import -window root /tmp/shot.png
```

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
