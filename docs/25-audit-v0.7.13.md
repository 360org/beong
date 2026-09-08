# 25 — Audit đợt v0.7.12 → v0.7.13

*Soát ngày 08/09/2026, từ `11c265b` tới `ce2f1bf`.*

Sau đợt này: `flutter analyze --fatal-infos` **sạch**, **655 test xanh** (654 → 655)
và 1 test bỏ qua **có in lý do**. Hai remote `origin` và `gitlab` cùng ở `ce2f1bf`.

Đợt này **không đổi gì trên màn hình**. Toàn bộ nằm ở lớp canh chất lượng và ở
tài liệu — vì bốn lỗi analyzer đã quay lại lần thứ tư dù đã có hook và bốn test
canh, nên việc cần làm là tìm cho ra *vì sao chốt chặn không chặn*, chứ không
phải sửa lại bốn dòng đó lần thứ năm.

---

## Phần 1 · Bốn món nợ đã trả

### B-003 🟡 — Chốt chặn chưa cắm điện

Đây là món đáng kể nhất, vì nó **không phải lỗi mã**.

`.githooks/pre-commit` nằm trong repo từ 26/08. Bốn test canh nó vẫn xanh suốt
ba tuần. Mà git **chưa gọi nó lần nào**: `git config core.hooksPath` là cấu
hình *của từng máy*, không đi theo repo, và máy này chưa từng chạy câu đó.

Bốn test cũ kiểm hook **có tồn tại và viết đúng**:

| Test | Kiểm gì |
|---|---|
| `còn tồn tại` | file `.githooks/pre-commit` chưa bị xoá |
| `vẫn chạy analyze với --fatal-infos` | nội dung hook còn đúng cờ |
| `format trước, rồi mới analyze` | đúng thứ tự của CI |
| `chạy được (có quyền thực thi)` | bit `+x` |

Không test nào kiểm hook **đã được cài**. Bốn test trên không phân biệt được
"hook đang bảo vệ ta" với "hook nằm im trong repo" — mà đó đúng là hai trạng
thái đã xảy ra.

**Đã sửa:** thêm test thứ năm ở `test/unit/pre_commit_hook_test.dart:101` đọc
`git config --get core.hooksPath` và đòi bằng `.githooks`, kèm câu lệnh sửa
ngay trong `reason`. Test tự bỏ qua ở CI (CI không commit — chính nó là lớp
chặn cuối; bắt CI cài hook là canh nhầm chỗ) và ở mọi bản chép không có `.git`.
Chỗ bỏ qua trả về **chuỗi lý do** chứ không phải `bool`, để trình chạy in ra vì
sao — một test bị nuốt trong im lặng thì cũng chẳng khác gì không có.

Đã thử phá: dựng một thư mục có `.git` mà không cài hook → test đỏ đúng như mong.

### B-001 🔴 — Mã sinh tự động không bao giờ về tới máy lập trình

`flutter` và `dart` trên máy này là shim rsync: đẩy mã nguồn lên máy chủ, chạy
ở đó, rồi… hết. Không kéo gì về.

`*.g.dart` bị gitignore nên nó **chỉ tồn tại ở nơi `build_runner` chạy** — tức
là trên máy chủ. Máy lập trình giữ mãi bản sinh ra từ 25/08, nên `flutter
analyze` chạy tại chỗ báo hàng loạt lỗi cho những cột vừa thêm vào schema:
`memberId` không có trên `JarRow`, `orderIndex` không có trên `Routine`. Cột có
thật trong `tables.dart`, chỉ là `database.g.dart` chưa biết.

14 lỗi, **không lỗi nào có thật**.

**Đã sửa:** thêm bước rsync thứ ba kéo `*.g.dart` / `*.freezed.dart` /
`*.mocks.dart` về sau khi chạy. Bước này chạy cả khi lệnh thất bại — build hỏng
vẫn có thể đã ghi ra một phần.

Gộp luôn `rflutter` và `rdart` vào một file chung `~/.local/bin/_rrun`. Trước
đó chúng là hai bản chép gần giống hệt, và **vá một bản rồi quên bản kia là
đúng cái bẫy đã làm mất nửa buổi**: `build_runner` chạy qua `dart`, không phải
`flutter`, nên vá xong `rflutter` thì codegen vẫn hỏng y như cũ.

#### Tầng lỗi nằm dưới, chỉ lộ ra sau khi vá xong tầng trên

Vá xong bước kéo về, thử lại vẫn hỏng. Lý do sâu hơn: rsync **đẩy cả `*.g.dart`
lên**, nên bản cũ ở máy này ghi đè bản đúng trên máy chủ. Rồi `build_runner`
băm **đầu vào** để quyết định có sinh lại hay không — thấy đầu vào y nguyên, nó
báo `wrote 0 outputs` và để nguyên file vừa bị làm hỏng. Kéo về vẫn là bản hỏng.

**Đã sửa:** mã sinh tự động nay đi **một chiều** máy chủ → máy này. Loại nó
khỏi lượt đẩy lên, và `--filter='protect ...'` giữ cho `--delete` không xoá mất
bản trên máy chủ.

**Đã thử phá:** cắt `database.g.dart` xuống còn 25 byte, chạy `build_runner
clean && build` → file về lại **515 989 byte**, có `orderIndex` ở dòng 131,
`diff -q` với bản sao lưu trước thử nghiệm cho kết quả **giống hệt**.

### B-002 🔴 — File đã xoá vẫn sống trên máy chủ

Rsync thiếu `--delete`, nên `jar_settings_screen.dart` — xoá ở `b5b1240` ngày
18/08 — vẫn nằm trên máy chủ. Test `sheet_co_nut_dong_test.dart` quét thư mục,
thấy nó, và báo một file **không tồn tại** là thiếu `SheetHeader`.

Lại là một lỗi không có thật, và lần này còn khó thấy hơn: mở file lên xem thì
không có file nào để mở.

**Đã sửa:** thêm `--delete`. **Đã thử phá:** trồng một `file_ma_test.dart` lên
máy chủ, chạy `flutter analyze` → file bị dọn. Đối chiếu hai danh sách file để
chắc không còn con nào khác sót lại.

### B-004 🟡 — GitLab lệch 42 commit

Policy AIaC ưu tiên GitLab private, nhưng các đợt gần đây chỉ push GitHub.
Đã push cả nhánh lẫn tag; hai remote nay cùng ở `ce2f1bf`, `0	0` cả hai chiều.

---

## Phần 2 · Bánh cóc chặn nợ đa ngôn ngữ

Nợ này **đang phình ra, không co lại**: giữa 18/08 và 08/09, số chỗ gọi
`L10n.of` chỉ nhích **15 → 18**, còn chuỗi cứng thì tăng khoảng một nửa. Mỗi
màn hình mới thêm chữ cứng nhanh hơn tốc độ đưa chữ cũ vào ARB.

Đo lại bằng cách đếm **mọi literal có dấu tiếng Việt** trong `lib/`, không chỉ
trong `Text()`:

| Cách đếm | Kết quả |
|---|---|
| Chỉ `Text('...')` — con số roadmap ghi trước đây | 146 |
| Mọi literal có dấu, kể cả `label:` `title:` `hintText:` `content:` | **897** |

Tức con số 146 chỉ là phần nổi. Rất nhiều chữ hiển thị đi qua tham số chứ không
nằm trong `Text()`.

`test/unit/chuoi_cung_test.dart` khoá ngưỡng ở 897 và đi **một chiều**: thêm
chuỗi cứng mới là đỏ, dọn bớt thì hạ ngưỡng xuống. Có cả chặn dưới, để dọn được
mà quên hạ ngưỡng thì cũng đỏ — nếu không, chỗ trống vừa dọn sẽ thành chỗ đắp
nợ mới vào mà test vẫn xanh.

**Cố ý không bắt chuỗi thuần ASCII** (`'OK'`, `'Save'`): bắt chúng sẽ dính hàng
loạt khoá, đường dẫn và tên biến, và một test kêu suốt là một test bị tắt.

Test này **không đòi dọn nợ cũ** — dọn 897 chỗ không phải việc của một commit.
Nó chỉ giữ cho nợ không lớn thêm trong lúc chờ dịch.

**Đã thử phá:** thêm một chuỗi tiếng Việt vào `celebration.dart` → đỏ với
`Có 898 chuỗi tiếng Việt viết cứng, vượt ngưỡng 897`. Khôi phục lại nguyên trạng.

---

## Phần 3 · Soát roadmap bằng code

Đọc lại 25 mục còn `- [ ]` và kiểm từng mục bằng mã nguồn. Ba chỗ lệch:

| Roadmap ghi | Thực tế |
|---|---|
| "Icon app, splash, ảnh chụp store" — gộp một dòng chưa tick | **Icon app đã xong** từ `d6c2648`, còn gỡ kênh alpha ở `0a2863e` sau khi Apple từ chối lỗi 90717, có `icon_ios_test.dart` canh |
| Ảnh chụp nội bộ ở `screenshot/` | Thật ra ở `docs/screenshot/`, đúng 90 tấm |
| Không ghi gì về "Thêm người lớn" và "chọn hũ cho bé mới" | Đã làm ở `v0.7.12`, nay ghi vào mục *Làm thêm ngoài danh sách* |

**Tách dòng icon/splash ra thì lộ một việc chưa ai để ý:** splash vẫn là ảnh
mặc định của `flutter create`. `LaunchImage.png` là PNG **1×1 xám, 68 byte**;
Android vẫn `launch_background.xml` gốc. App đang mở ra bằng một màn trắng
trống — thứ người dùng thấy **đầu tiên** — và nó không nằm trong danh sách chặn
phát hành nào cả.

Đây là ví dụ rõ cho một kiểu hỏng của checklist: gộp ba việc vào một dòng thì
dòng đó chưa tick, nhưng **không ai biết phần nào trong ba phần còn thiếu**.

---

## Phần 4 · Còn lại gì

**Không còn nợ kỹ thuật nào ở tầng mã.** `analyze --fatal-infos` sạch, 655 test
xanh, **0 TODO/FIXME** trong `lib/` và `test/`, `certs/` vẫn gitignore
(`.gitignore:53`) và không có file nào bị theo dõi.

26 mục còn `- [ ]`, không mục nào là nợ kỹ thuật:

| Nhóm | Số mục | Chặn bởi |
|---|---|---|
| Sprint 3 + FCM push | 19 | **Backend.** Mã client đã dựng (`PairingService`, outbox, `NotificationService` đều có unit test), chờ nối Supabase lúc chạy |
| Hồ sơ store & tài khoản | 5 | **Tài khoản của chủ dự án.** Gồm hai mục 🔴 chặn cứng: hồ sơ App Store chưa điền, secret Play Console không hợp lệ |
| Hoãn có chủ ý | 2 | Công tắc âm thanh (app chưa phát âm thanh nào — cờ chết), màn mất mạng (offline-first, ADR-002) |

Việc duy nhất làm được ngay mà không chờ ai: **splash screen**.

Hai mục 🔴 đáng nhắc lại vì chúng **không phải lỗi mã và chạy lại CI không sửa
được**: mỗi lần chạy lại chỉ tốn thêm một build number. Binary lên được App
Store Connect rồi; thiếu là ảnh chụp theo cỡ, mô tả, từ khoá, URL hỗ trợ,
bảng phân loại độ tuổi, khai báo thu thập dữ liệu, danh mục, giá và khai báo
bản quyền — chỉ chủ tài khoản điền được.

---

## Bài học rút ra

**Thứ nào không có test canh thì sẽ trôi lại** — bài học cũ của dự án, và B-003
là bản nâng cấp của nó: *có test canh vẫn trôi*, nếu test canh nhầm chỗ. Bốn
test kiểm hook có tồn tại và viết đúng, không test nào kiểm nó đã được cắm điện.
Chốt chặn chưa cắm điện thì không phải chốt chặn.

**Lỗi không có thật tốn thời gian hơn lỗi có thật.** B-001 và B-002 sinh ra 14
lỗi analyzer và 1 test đỏ, tất cả đều là ảo, và mất nửa buổi mới nhận ra. Lỗi
thật thì đọc mã là thấy; lỗi ảo thì đọc mã lại càng rối, vì mã đúng.

**Sửa một nửa một cặp file song sinh là chưa sửa.** `rflutter` được vá,
`rdart` thì không, và `build_runner` chạy qua `dart`. Nay chỉ còn một file.

**Gộp nhiều việc vào một dòng checklist thì dòng đó mất khả năng báo tin.**
"Icon app, splash, ảnh chụp store" đứng chưa tick suốt nhiều tuần trong khi
icon đã xong — và che luôn việc splash chưa ai đụng tới.
