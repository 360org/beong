# Bộ icon — Microsoft Fluent Emoji (kiểu 3D)

Nguồn: https://github.com/microsoft/fluentui-emoji
Giấy phép: **MIT** (xem `LICENSE` cạnh file này).

## Vì sao chọn bộ này

Trước đây app vẽ icon bằng **emoji của hệ thống** (`Text('🪥')`). Cách đó nhẹ và
không cần asset, nhưng có ba vấn đề thật:

1. **Mỗi nền tảng vẽ một kiểu.** Cùng một `iconKey` cho ra hình khác nhau trên
   iOS, Android, Windows và Linux — có máy còn không có glyph nên hiện ô vuông
   ▯. Không kiểm soát được thứ trẻ nhìn thấy, mà đây là app cho trẻ đọc hình
   trước khi đọc chữ.
2. **Ảnh chụp store không giống máy người dùng.** Ảnh chụp trên máy build sẽ
   mang emoji của máy đó.
3. Emoji hệ thống thường phẳng và nhạt; bộ 3D này tròn, có khối, ngộ nghĩnh —
   đúng tinh thần `00-brand-values.md`.

## Vì sao MIT quan trọng

Ba bộ emoji mở phổ biến khác đều ràng buộc hơn:

| Bộ | Giấy phép | Ràng buộc |
|---|---|---|
| **Fluent Emoji** (đang dùng) | MIT | Chỉ cần giữ kèm bản quyền — không phải ghi công trong app |
| Twemoji | CC-BY 4.0 | **Phải ghi công** trong app |
| OpenMoji | CC BY-SA 4.0 | Phải ghi công **và** ShareAlike |
| Noto Emoji | OFL / Apache | Ghi công, và OFL có ràng buộc riêng về tên font |

Với app phát hành lên store cho trẻ em, MIT là bộ ít rủi ro nhất: không phải
thêm trang "Giấy phép" chỉ vì icon, và không lo điều khoản ShareAlike lan sang
phần khác.

## Quy ước

- Kiểu **3D**, PNG, đã hạ xuống **128×128** (`convert -resize 128x128 -strip`).
  Ô icon lớn nhất trong app khoảng 40dp, nên 128px vẫn nét ở màn 3x.
- Tên file = `iconKey` trong `lib/core/theme/task_icons.dart`, **không** phải tên
  gốc của Fluent. Nhờ vậy đổi bộ icon về sau chỉ là thay file, không sửa DB —
  `tasks.icon_key` đã lưu khoá này trong dữ liệu người dùng.
- Tiền tố `jar_` cho hũ, `av_` cho avatar.

## Thêm icon mới

```bash
folder="Soccer ball"                        # tên thư mục trong repo Fluent
file=$(echo "$folder" | tr 'A-Z' 'a-z' | tr ' ' '_')   # -> soccer_ball
base=https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets
curl -sL "$base/${folder// /%20}/3D/${file}_3d.png" -o /tmp/x.png
convert /tmp/x.png -resize 128x128 -strip assets/icons/<iconKey>.png
```

Lưu ý quy tắc đặt tên file của Fluent: dấu cách thành `_` nhưng **dấu gạch nối
giữ nguyên** (`T-shirt` -> `t-shirt_3d.png`). Đoán sai chỗ này thì nhận 404.
