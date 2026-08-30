# Audit đa ngôn ngữ — 30/08/2026

Yêu cầu chủ dự án: *"kiểm tra lại phần ngôn ngữ dịch, tiếng Việt là ngôn ngữ
gốc, hỗ trợ tiếng Việt & tiếng Anh."*

Kết luận một câu: **hạ tầng dịch đúng, nhưng gần như không được dùng.** App
hiện chạy ở trạng thái nửa Việt nửa Anh trên máy đặt tiếng Anh — và đó chính
là những gì chủ dự án đang nhìn thấy mỗi ngày trên máy mình.

---

## 1. Chứng cứ: app trên máy tiếng Anh

Chạy bản dựng Linux với `LANG=en_US.UTF-8`, dữ liệu thật:

| Màn | Kết quả |
|---|---|
| Trang chính | tiêu đề **"Trang chính"** (Việt) · thanh dưới **"Home, Tasks, Rewards, Stats, Settings"** (Anh) |
| Nhiệm vụ | tiêu đề **"Tasks"** (Anh) · nội dung *"Thói quen / Giữ và kéo để sắp xếp / Buổi sáng / 5 việc / Tất cả"* (Việt) |

Đây không phải app tiếng Việt, cũng không phải app tiếng Anh. Nó là hai thứ
lẫn vào nhau trên cùng một màn hình.

Điều này giải thích mọi ảnh chụp chủ dự án gửi trong ngày: thanh điều hướng
luôn hiện tiếng Anh trong khi phần còn lại tiếng Việt. Không phải lỗi hiển
thị — máy đang đặt tiếng Anh, và đúng 15 chuỗi trong app biết điều đó.

## 2. Con số

| | |
|---|---|
| Khoá dịch khai trong `.arb` | **56** |
| Khoá **thật sự được gọi** trong mã | **15** |
| Khoá khai rồi bỏ đó | **41** |
| Chuỗi tiếng Việt **viết cứng** trong `lib/` | **877** (765 chuỗi khác nhau, 68 file) |

Tỷ lệ chữ trên màn hình đi qua tầng dịch: khoảng **1,7%**.

15 khoá đang dùng: `appTitle`, `appSlogan`, `badgeBusyBee`, 7 nhãn thanh điều
hướng (`nav*`), 5 tiêu đề màn (`*Title`).

## 3. Chuỗi cứng nằm ở đâu

| Số chuỗi | Tầng | Ghi chú |
|---:|---|---|
| 715 | `features/` | Chữ trên màn hình. Phần chính của việc dịch. |
| 93 | `domain/` | **Dữ liệu gieo vào DB** — việc mẫu, huy hiệu, hũ mặc định. Bài toán khác, xem §5. |
| 36 | `core/` | Widget dùng chung. |
| 27 | `data/` | Thông báo lỗi ném từ tầng dữ liệu (`JarException`, `TaskTrungTenException`…). |
| 6 | khác | `main.dart`, `app/router.dart`. |

Mười file nặng nhất:

| Chuỗi | File |
|---:|---|
| 82 | `lib/features/settings/settings_screen.dart` |
| 53 | `lib/features/stats/stats_screen.dart` |
| 48 | `lib/features/tasks/tasks_screen.dart` |
| 39 | `lib/features/parent_home/parent_home_screen.dart` |
| 39 | `lib/features/rewards/rewards_screen.dart` |
| 39 | `lib/features/members/child_profile_form.dart` |
| 36 | `lib/domain/entities/badge_def.dart` |
| 34 | `lib/features/child_home/child_home_screen.dart` |
| 34 | `lib/features/tasks/routine_editor_screen.dart` |
| 29 | `lib/features/onboarding/onboarding_screen.dart` |

Bảng đầy đủ 68 file: chạy lại lệnh ở §7.

## 4. Những thứ đã đúng, đừng làm lại

- `resolveAppLocale` (`lib/app/app.dart`) chọn theo thứ tự ưu tiên người dùng
  đặt trên máy, không khớp thì về tiếng Việt. Có test riêng
  (`test/unit/app/locale_resolution_test.dart`).
- `app_vi.arb` và `app_en.arb` **khớp khoá hoàn toàn**, không lệch cái nào.
- Bản dịch Anh của 15 khoá đang dùng đọc ổn; giữ nguyên **"Bé Ong"** làm tên
  thương hiệu ở cả hai ngôn ngữ — đúng.
- `l10n.yaml` đã trỏ `template-arb-file: app_vi.arb`, tức tiếng Việt **đã** là
  ngôn ngữ gốc theo đúng yêu cầu.

## 5. Ba vấn đề cần quyết định, không chỉ cần gõ code

### 5.1 Dữ liệu gieo sẵn nằm trong DB, không nằm trong mã

Tên hũ mặc định ("Hũ Để Dành"), tên việc mẫu, tên huy hiệu được **ghi vào cơ
sở dữ liệu** lúc tạo nhà. Dịch mã nguồn không đổi được dữ liệu đã nằm trên máy
người dùng: nhà tạo trước đó vẫn thấy hũ tên tiếng Việt dù chuyển sang tiếng
Anh.

Hai hướng, phải chọn một:

- **(a) Dịch lúc hiển thị theo khoá.** `jars.jar_key` = `spend`/`save`/`give`
  đã có sẵn, nên tra khoá ra nhãn dịch được. Nhưng hũ **bố mẹ tự đặt tên** thì
  không dịch — và không nên dịch, đó là dữ liệu của người dùng.
- **(b) Chấp nhận nhà cũ giữ tiếng Việt.** Rẻ, và không sai: tên hũ sau khi bố
  mẹ sửa vốn là dữ liệu của họ.

Khuyến nghị: **(a) cho hũ mặc định và huy hiệu** (khoá cố định, app sinh ra),
**(b) cho mọi thứ bố mẹ đã sửa tên**.

### 5.2 `titleEn` của việc mẫu đang chết

`TaskPreset` (`lib/domain/entities/presets.dart`) **đã có** cả `titleVi` lẫn
`titleEn` — 27 việc mẫu, và 12 phần thưởng mẫu trong `reward_presets.dart`.
Nhưng `titleEn` **không được đọc ở bất kỳ đâu**: cả 16 chỗ dùng preset đều gọi
`titleVi`.

Nghĩa là 39 bản dịch đã viết sẵn, đã trả công rồi, mà không ai thấy. Đây là
món rẻ nhất trong toàn bộ việc dịch.

`BadgeCategory` (`badge_def.dart`) thì ngược lại: chỉ có `titleVi`, chưa có
bản Anh.

### 5.3 Chưa có chỗ đổi ngôn ngữ

App chỉ chạy theo ngôn ngữ máy. Bố mẹ Việt dùng iPhone đặt tiếng Anh — **đúng
trường hợp của chủ dự án** — không có cách nào bắt app nói tiếng Việt.

Cần một ô "Ngôn ngữ" trong Cài đặt, theo đúng khuôn `ThemeModeSetting`
(`lib/core/providers/theme_mode_provider.dart`): lưu ở `device_settings`, ba
lựa chọn *Theo hệ thống / Tiếng Việt / English*, nạp trước `runApp`.

## 6. Ngày tháng và số

`lib/core/utils/ngay_viet.dart` định dạng theo lối Việt và **cố ý** không dùng
`intl`: `dd/MM`, thứ viết `T2`…`T7`, `CN`. Chú thích trong file nói rõ lý do —
`10 thg 8` dài, và `MM/DD` kiểu Anh gây nhập nhằng.

Sang tiếng Anh thì `T2` không đọc được. Nhưng đây **không phải** lỗi cần sửa
vội: nó chỉ sai khi người dùng thật sự chạy app ở tiếng Anh, tức sau khi §5.3
xong. Xếp vào đợt cuối, và giữ nguyên lựa chọn không dùng `intl` cho các dạng
ngắn — chỉ thêm nhánh tiếng Anh.

`dinhDangDong` trong `money_exchange.dart` ngăn nghìn bằng dấu chấm theo lối
Việt. Tiếng Anh dùng dấu phẩy. Cùng nhóm với trên.

## 7. Chạy lại phép đo

```
python3 - <<'PY'
import re, os, collections
VI='àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
VI+=VI.upper(); vi=re.compile('['+VI+']')
lit=re.compile(r"""(?<!r)'((?:[^'\\\n]|\\.)*)'|(?<!r)"((?:[^"\\\n]|\\.)*)\"""")
per=collections.Counter()
for root,dirs,files in os.walk('lib'):
    dirs[:]=[d for d in dirs if d!='gen']
    for f in sorted(files):
        if not f.endswith('.dart') or f.endswith('.g.dart'): continue
        p=os.path.join(root,f)
        for line in open(p,encoding='utf-8'):
            if line.lstrip().startswith('//'): continue
            for m in lit.finditer(line):
                s=m.group(1) if m.group(1) is not None else m.group(2)
                if s and vi.search(s): per[p]+=1
for p,c in sorted(per.items(), key=lambda kv:-kv[1]): print(f'{c}\t{p}')
print(sum(per.values()), 'TỔNG')
PY
```

Con số phải **giảm** sau mỗi đợt của `docs/24`. Đó là thước đo tiến độ duy
nhất không nói dối được.
