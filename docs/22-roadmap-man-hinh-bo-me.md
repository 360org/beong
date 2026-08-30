# 22 — Lộ trình sửa màn hình bố mẹ

*Chủ dự án nêu ngày 26/08/2026 kèm 5 ảnh chụp trên máy thật. Soát lại từng mục
bằng code trước khi ghi — `file:dòng` để kiểm lại.*

## Việc phải làm trước tất cả: **việc bị nhân đôi**

Ảnh 2 và ảnh 3 cho thấy một chuyện không nằm trong danh sách anh nêu, nhưng nó
là **gốc** của mục 1.2 và làm hỏng cả trải nghiệm:

> NEO: **0 / 36 việc hôm nay** · Simba: **0 / 23 việc hôm nay**

Mở danh sách của Simba ra thì thấy rõ: **"Đánh răng buổi sáng" hiện hai lần**
(+10 xu, rồi lại +10 xu), **"Tắm rửa" hai lần**, "Đọc sách 15 phút" vừa nằm
trong thói quen *Sau giờ học* vừa đứng riêng.

Không đứa trẻ nào có 36 việc một ngày. Con số đó là **cùng một việc được tạo
hai lần** từ hai đường khác nhau:

- đường **Cài đặt → hồ sơ bé → gán việc mẫu** (ảnh 5), và
- đường **thói quen** trong tab Nhiệm vụ (ảnh 1).

Hai đường cùng sinh ra bản ghi `Task` riêng biệt, không ai kiểm trùng. Nên bé
mở app ra thấy một danh sách dài vô lý, phải đánh răng hai lần mới hết việc, và
xu cộng gấp đôi cho cùng một hành động.

**Đây là việc số 0 — làm trước mọi thứ khác trong tài liệu này.** Sửa giao diện
mà dữ liệu vẫn nhân đôi thì chỉ là làm đẹp một danh sách sai.

Cần: dọn trùng cho dữ liệu đang có, và chặn sinh trùng về sau (một việc chỉ tồn
tại một bản ghi, thuộc về một thói quen **hoặc** đứng lẻ, không cả hai).

---

## Hình 1 — Tab Nhiệm vụ

### 1.0 · Việc lẻ và việc trong thói quen phải cùng một kiểu thẻ

**Anh nêu:** *"task lẻ đang có layout khác với task thói quen, làm giống nhau
hết."*

**Hiện tại:** hai widget khác hẳn nhau — `_RoutineGroupCard`
(`tasks_screen.dart:256`) vẽ một thẻ nhóm có tiêu đề, đếm số việc, và các dòng
việc bên trong; `_TaskTile` (`:348`) vẽ một thẻ độc lập có avatar tròn và nhãn
"Hằng ngày". Cùng một thứ — một việc nhà — mà hai hình thức, nên mắt phải học
hai lần.

**Làm:** một `TaskRow` dùng chung cho cả hai chỗ. Thẻ nhóm chỉ còn khác ở phần
**vỏ** (tiêu đề buổi + số việc), còn từng dòng việc bên trong thì giống hệt dòng
việc lẻ.

### 1.1 · 🔴 Trong thói quen chưa thấy +/− xu

**Anh nêu:** *"trong màn hình task thói quen chưa thấy +- số xu khi đưa vào task
thói quen."*

**Hiện tại:** `child_profile_form.dart:13` ghi rõ màn gán việc mẫu **đã có**
"+- xu" cho từng việc. Nhưng ở thói quen thì không: `routine_editor_screen.dart`
chỉ có thanh trượt **thưởng trọn bộ** (`:495` — *"Thưởng khi làm trọn bộ: N
xu"*), không có chỗ chỉnh xu của từng việc trong đó.

Nên cùng một việc, chỉnh xu được ở màn này mà không chỉnh được ở màn kia — bố mẹ
phải nhớ đi đường nào mới sửa được.

**Làm:** mỗi dòng việc trong thói quen có nút −/+ chỉnh xu tại chỗ, đúng như màn
gán việc mẫu. Giữ nguyên thưởng trọn bộ, đó là thứ khác.

### 1.2 · 🔴 Việc đã vào thói quen phải biến mất khỏi danh sách việc lẻ

**Anh nêu:** *"mỗi task từ task lẻ đã thêm vào thói quen rồi thì phải mất luôn
để không chọn phải 2 lần."*

**Hiện tại — và đây là chỗ cần nói rõ.** Tab Nhiệm vụ **đã** tách đúng:
`tasks_screen.dart:198–206` chia theo `task.routineId != null`, nên một việc đã
vào thói quen thì không hiện lại ở mục "Việc lẻ". Trong màn sửa thói quen cũng
vậy — danh sách `outside` (`routine_editor_screen.dart:184`) chỉ đưa ra việc
chưa thuộc thói quen nào.

Nghĩa là **giao diện không sai**. Thứ sai là **dữ liệu**: có hai bản ghi `Task`
riêng cho cùng một việc, một cái `routineId = null` và một cái có `routineId`.
Cả hai đều đúng luật lọc, nên cả hai cùng hiện — một ở "Thói quen", một ở "Việc
lẻ" — và bố mẹ thấy như bị chọn hai lần.

**Làm:** đây chính là **việc số 0** ở đầu tài liệu. Sửa ở tầng dữ liệu, không
phải ở bộ lọc.

### 1.3 · 🟠 Tạo buổi thói quen ngay trong tab Nhiệm vụ, và gán cho bé tại chỗ

**Anh nêu:** *"trong tab tasks phải tạo thêm được session thói quen ví dụ: buổi
sáng, buổi trưa, buổi xế > và gán cho profile của bé ngay ở đây thay vì đưa vào
setting > profile > config (bỏ phần task trong profile config)."*

**Hiện tại:** nút "+" ở tab Nhiệm vụ (`tasks_screen.dart:52`) chỉ mở
`_AddTaskSheet` — **thêm một việc**, không tạo được thói quen mới. Muốn có thói
quen mới thì không có đường nào từ đây.

**Và một điều phải chốt trước khi code:** bảng `Routines`
(`tables.dart:108–124`) **không có cột nào gán cho thành viên**. Nó có `title`,
`iconKey`, `dayPart`, `repeatType`, `repeatDays` — hết. Việc mới được gán cho
bé, thói quen thì không.

Nên "gán thói quen cho hồ sơ bé" có hai cách làm, và **cần anh chốt**:

- **(a) Gán gián tiếp** — chọn bé ở màn tạo thói quen, rồi mọi việc sinh ra
  trong thói quen đó gán cho bé ấy. Không đụng lược đồ. Nhược: hai bé dùng chung
  một "Buổi sáng" thì phải tạo hai thói quen trùng tên.
- **(b) Thêm cột `memberId` vào `Routines`** — một thói quen thuộc về một bé.
  Sạch hơn, nhưng cần migration và phải quyết dữ liệu cũ đi về đâu.

**Làm:** nút "+" ở tab Nhiệm vụ cho chọn **Thêm việc** hay **Thêm buổi thói
quen**; màn tạo thói quen có tên, hình, buổi, và chọn bé. Sau đó **bỏ hẳn phần
việc mẫu khỏi `child_profile_form.dart`** — đó cũng là nội dung ảnh 5.

Lưu ý thứ tự: **bỏ đường cũ sau khi đường mới chạy được**, không phải trước.
Bỏ trước thì có một khoảng không ai gán việc được.

### 1.4 · 🟠 Việc lẻ đã tạo phải sửa được

**Anh nêu:** *"task lẻ đã tạo ra rồi thì cũng phải sửa được, hiện tại không sửa
được."*

**Hiện tại:** đúng như anh nói. `_RoutineGroupCard` có `InkWell` +
`onTap: onEdit` (`tasks_screen.dart:277–278`), còn `_TaskTile` (`:348`) **không
có `onTap`, không `InkWell`, không vuốt xoá** — một thẻ trơ. Việc lẻ tạo xong là
không sửa được tên, xu, hình, hay lịch lặp.

**Làm:** `_TaskTile` mở lại `_AddTaskSheet` ở chế độ sửa (sheet đã có sẵn mọi
trường cần). Kèm đường xoá, có bước xác nhận.

---

## Hình 2 & 3 — Trang chính, thẻ của con

### 2.1 · 🟠 Xổ ra phải nhóm theo buổi, không phải một danh sách phẳng

**Anh nêu:** *"click chọn profile của con > xổ ra list task theo thói quen
(sáng/trưa/chiều...) hoàn thành/chưa hoàn thành."*

**Hiện tại:** `parent_home_screen.dart:764` xổ ra đúng một khối *"Chưa hoàn
thành (23)"* — danh sách **phẳng**, không nhóm. Grep cả file không có chỗ nào
dùng `routineId` hay `dayPart` để nhóm.

Ảnh 2 cho thấy hậu quả: 23 dòng liền nhau, "Đánh răng buổi sáng" nằm cạnh "Làm
bài tập" nằm cạnh "Tắm rửa", không thứ tự nào theo thời gian trong ngày.

**Làm:** nhóm theo thói quen / buổi, mỗi nhóm có tiêu đề và số **đã xong /
tổng**. Việc không thuộc thói quen nào gom vào một nhóm "Việc lẻ" ở cuối.

### 2.2 · 🟠 Vuốt ngang để xem lịch sử, thay cho biểu tượng lịch

**Anh nêu:** *"vuốt ngang sang thì phải quay về lịch sử ngày/tuần chứ không phải
click vào biểu tượng lịch như hiện tại."*

**Hiện tại:** phải bấm biểu tượng lịch (`:671` `Icons.calendar_today_rounded`),
và dòng phụ đang phải đi giải thích chính nó: *"0 / 23 việc hôm nay · **Bấm xem
lịch sử**"* (`:695`). Một giao diện phải dặn người dùng cách bấm là một giao diện
chưa nói được bằng hình.

Cả file **không có** `PageView`, `Dismissible`, hay `onHorizontalDrag` — chưa có
cử chỉ vuốt nào.

**Làm:** thẻ của con thành `PageView` ngang: hôm nay ở giữa, vuốt phải về hôm
qua / tuần trước. Giữ biểu tượng lịch làm đường đi nhanh (vuốt là cử chỉ không
nhìn thấy được, người mới cần một nút), nhưng **bỏ chữ "Bấm xem lịch sử"** —
thay bằng chỉ báo trang.

> **Chủ dự án chốt lại ngày 30/08/2026: bỏ hẳn biểu tượng lịch.** Vuốt ngang là
> đường duy nhất tới lịch sử, còn cú chạm vào header chuyển sang gập/mở danh
> sách việc (mục 2.4). Lý do giữ nút lịch ở trên vẫn đúng về nguyên tắc — cử chỉ
> vuốt không nhìn thấy được — nên phần khả kiến chuyển sang **mũi tên gập/mở**:
> nó cho thấy header bấm được, và ai đã bấm thử một lần thì tìm ra cú vuốt.

### 2.4 · 🟠 Chạm header để gập / mở danh sách việc

**Anh nêu ngày 30/08/2026 kèm ảnh chụp:** *"Click vào header expand/collapse
details tasks."*

**Vì sao:** ảnh cho thấy thẻ của NEO có **37 việc trong một ngày**. Nhân với số
con trong nhà thì màn hình chính cuộn mãi không tới đáy, và phần "chờ duyệt" ở
trên — thứ bố mẹ vào đây để làm — bị đẩy đi mất khi có nhiều con.

**Làm:** `_ChildSummaryCard` giữ trạng thái `_moRong`, mặc định **mở**. Gập hết
sẵn thì mở app lên không thấy việc nào của con — mất đúng thứ màn hình này sinh
ra để cho xem. Thẻ có State thì bắt buộc có `key: ValueKey(child.id)`: thiếu key
thì Flutter tái dùng State theo vị trí, gập thẻ NEO rồi danh sách đổi thứ tự là
thẻ Simba gập theo.

### 2.3 · Áp cho **mọi** hồ sơ con

**Anh nêu ở hình 3.** Ảnh cho thấy NEO và Simba nằm cạnh nhau, nên 2.1 và 2.2
phải dựng ở **thẻ con dùng chung**, không phải chỉ cho bé đầu tiên. Không có
việc riêng ở đây — chỉ là ràng buộc khi làm 2.1/2.2.

---

## Hình 4 — Màn Thống kê

### 4.1 · 🟠 Nút "+" tạo hũ mới và gán cho bé

**Anh nêu:** *"màn hình stats có thêm + button để tạo thêm hũ & add vào profile
cho trẻ."*

**Hiện tại:** `stats_screen.dart` không có `FloatingActionButton`, không có nút
thêm hũ nào. Bộ hũ hiện ra trong ảnh (Tiêu · Để dành · Cho đi · Học tập · Mua đồ
chơi) là danh sách cố định — bố mẹ không tự thêm được hũ mới.

**Làm:** nút "+" ở màn Thống kê mở bảng tạo hũ: tên, hình, và chọn bé được dùng
hũ đó.

**Một chuyện phải cẩn thận:** hũ dính tới việc chia xu. Thêm hũ giữa chừng thì
tỷ lệ chia của bé phải cộng lại đủ 100%. Bảng tạo hũ phải nói rõ tỷ lệ mới lấy
từ đâu ra, không được tự lặng lẽ chia lại phần của các hũ cũ.

---

## Hình 5 — Cài đặt → gán việc mẫu

Anh đã nói: **bỏ đi**, gộp vào 1.3. Không có việc riêng.

Nhắc lại ràng buộc thứ tự: `child_profile_form.dart` hiện là **đường duy nhất**
gán việc mẫu cho bé, và nó cũng là nơi có sẵn phần +/− xu mà 1.1 đang thiếu. Nên
bỏ nó **sau** khi tab Nhiệm vụ làm được cả hai việc đó.

---

## Trạng thái — làm xong 26/08/2026

| Mục | Xong | Ghi chú |
|---|---|---|
| 0 · Dọn việc trùng | ✅ | `DonViecLe`, chạy một lần mỗi nhà trong `DayStartService` |
| 1.0 · Thẻ dùng chung | ✅ | `TaskRow`; `_TaskTile` gỡ hẳn |
| 1.1 · −/+ xu trong buổi | ✅ | Bước 5, không xuống dưới 0 |
| 1.2 · Việc vào buổi thì mất khỏi việc lẻ | ✅ | Giải ở tầng dữ liệu, không phải bộ lọc |
| 1.3 · Tạo buổi & gán hồ sơ ở tab Nhiệm vụ | ✅ | `routine_create_sheet.dart` |
| 1.4 · Sửa việc | ✅ | `task_edit_sheet.dart`, kèm đường ngừng dùng |
| Ảnh 5 · Bỏ việc mẫu khỏi hồ sơ | ✅ | Gỡ cả giao diện lẫn đoạn tạo việc |
| 2.1 · Nhóm theo buổi | ✅ | `ChildDayGroups`, có đã xong/tổng |
| 2.2 · Vuốt ngang xem lịch sử | ✅ | Bỏ nút lịch; cử chỉ ở **cả thẻ**, nhận cả vuốt chậm, và đổi ngày **ngay trên thẻ** chứ không mở hộp thoại (chốt lại 30/08) |
| 2.4 · Chạm header gập/mở | ✅ | Mặc định mở; mũi tên là chỉ dấu bấm được |
| 2.5 · Bỏ mục "Chưa xếp buổi" | ✅ | `DonViecLe.nhanNuoi` chạy mỗi lần mở app thay cho nó |
| 2.6 · Dòng "Tạo thêm thói quen" | ✅ | Cuối danh sách buổi; popup thêm được việc luôn |
| 2.7 · Nút LƯU ở Sửa thói quen | ✅ | Bảng cuộn được, nút dính đáy — trước bị 125 hình đẩy khỏi màn hình |
| 2.3 · Áp cho mọi hồ sơ | ✅ | Dùng chung thẻ con |
| 4.1 · Nút thêm hũ | ✅ | Xong cả phần gán riêng cho từng bé (v9, 30/08/2026) |

### ⚠️ Giới hạn của 4.1: chưa gán hũ riêng cho từng bé được

Nút "+" tạo hũ và chia lại tỷ lệ cho **cả nhà**, đúng hai cách chủ dự án chốt
(trừ đều hũ khác, hoặc tự chỉnh), và luôn về đúng 100% — có test canh với mọi
tỷ lệ từ 0 tới 90.

Phần *"add vào profile cho trẻ"* thì **chưa làm được**, và lý do đáng biết: hệ
thống hũ đang có **hai cách biểu diễn song song**, đúng kiểu vấn đề vừa gặp với
việc nhà.

- Bảng `jars` — **n hũ**, tỷ lệ theo gia đình. Đây là thứ nút "+" ghi vào.
- `JarSplit` (`jar_splitter.dart:10`) — **cố định ba hũ** `spend/save/give`, là
  thứ `members.jar_split_override` lưu.

`wallet_dao.dart:217` cho thấy hệ quả: bé nào có `jarSplitOverride` thì
`planFor` trả về kế hoạch dựng **chỉ từ ba hũ cũ** — mọi hũ tuỳ chỉnh của gia
đình **biến mất với riêng bé đó**. Nên gán hũ mới cho một bé bằng cơ chế
override hiện tại là gán vào một mô hình không chứa nổi nó.

Sửa cho đúng thì `JarSplit` phải thôi cố định ba hũ và chuyển sang map
`jarKey -> pct` như bảng `jars`, kèm migration cho các override đang có. Đó là
quyết định về mô hình dữ liệu, không phải chuyện giao diện — nên để chủ dự án
chốt thay vì đoán.

## Thứ tự đề nghị

| # | Việc | Vì sao đứng ở đây |
|---|---|---|
| 0 | **Dọn việc trùng + chặn sinh trùng** | Gốc của 1.2; sửa giao diện trước là làm đẹp một danh sách sai |
| 1 | 1.4 việc lẻ sửa được | Nhỏ, độc lập, dùng lại sheet đã có |
| 2 | 1.0 + 1.1 thẻ dùng chung + −/+ xu | Cùng đụng `tasks_screen`, làm một lượt |
| 3 | 1.3 tạo buổi thói quen & gán bé | Cần anh chốt (a) hay (b) trước khi viết code |
| 4 | Bỏ việc mẫu khỏi hồ sơ (ảnh 5) | **Sau** khi 1.3 chạy được |
| 5 | 2.1 + 2.2 + 2.3 thẻ con | Cùng đụng `parent_home_screen` |
| 6 | 4.1 nút thêm hũ | Độc lập, nhưng cần chốt chuyện tỷ lệ chia |

## Chủ dự án đã chốt (26/08/2026)

1. **Buổi thói quen là của chung, gán cho hồ sơ nào thì hồ sơ đó thấy.** Chọn
   được nhiều bé cùng lúc (Neo *và* Simba). → quan hệ **nhiều–nhiều**.
2. **Việc tạo ra là gán thẳng vào một buổi, không để lẻ.** Khái niệm "việc lẻ"
   biến mất.
3. **Thêm hũ mới thì cho chọn cách chỉnh** — chỉnh riêng từng hũ, hoặc theo một
   nguyên tắc chung — miễn tổng các hũ trong một hồ sơ bằng **100%**.

### Hệ quả của quyết định 1: không cần đổi lược đồ

Soát lại thì bảng nối **đã có sẵn**: `RoutineAssignees`
(`tables.dart:134`), khoá chính `{routineId, memberId}` — đúng nhiều–nhiều.
`createRoutine` cũng đã ghi vào đó (`task_dao.dart:421`), và `schedulableTasks`
đã đọc ra (`:151`).

Vấn đề không phải thiếu lược đồ, mà là **chỉ onboarding gọi `createRoutine`**
(`onboarding_screen.dart:153`). Xong onboarding là không tạo được buổi nào nữa
— nên bố mẹ buộc phải đi đường Cài đặt → hồ sơ bé → gán việc mẫu, và đường đó
sinh ra việc **nằm ngoài mọi buổi**. Hai đường song song chính là gốc của việc
bị nhân đôi.

Nên quyết định 1 và 2 gặp nhau ở cùng một chỗ: **mở đường tạo buổi trong tab
Nhiệm vụ, rồi bỏ đường gán việc mẫu.**

### Hệ quả của quyết định 2: một ràng buộc phải giữ

`schedule.dart:148` bỏ qua mọi việc có `assigneeIds` rỗng. Với việc trong buổi,
danh sách đó lấy từ `RoutineAssignees`. Nên **buổi không gán cho bé nào thì
không đứa trẻ nào nhìn thấy việc trong đó** — mà trên màn quản lý thì buổi vẫn
trông bình thường. Bảng tạo buổi phải chặn nút lưu khi chưa chọn bé, và có test
canh đúng hệ quả này.
