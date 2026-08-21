# Lint hay gặp khi bật `--fatal-infos`

Danh mục này ghi những lint **đã thực sự làm đỏ CI**, kèm cách sửa. Với
`very_good_analysis` + `--fatal-infos` thì mọi gợi ý mức info cũng chặn merge, nên
những lint "vô hại" ở repo khác lại là lỗi ở đây.

Tra nhanh: chạy `flutter analyze --fatal-infos` rồi tìm tên lint trong bảng.

## Bất đồng bộ

### `discarded_futures`
Gọi hàm trả `Future` trong hàm không `async`.

```dart
// ✗
void _next() { _controller.nextPage(...); }

// ✓ — bọc unawaited + import 'dart:async'
void _next() { unawaited(_controller.nextPage(...)); }
```

Cần `import 'dart:async';`. Dùng khi **thật sự** không cần chờ; nếu cần chờ thì
đổi hàm thành `async` và `await`.

### `unawaited_futures`
Trong hàm đã `async` mà gọi `Future` không `await`. Sửa: thêm `await`.

## Tham số & khai báo

### `always_put_required_named_parameters_first`
Tham số `required` phải đứng trước tham số tuỳ chọn — kể cả trước `super.key`.

```dart
// ✗
const TaskCard({super.key, required this.title});
// ✓
const TaskCard({required this.title, super.key});
```

### `sort_child_properties_last`
`child` / `children` phải là tham số cuối khi gọi widget.

```dart
// ✗
_StatTile(child: Text('0'), label: 'ĐIỂM')
// ✓
_StatTile(label: 'ĐIỂM', child: Text('0'))
```

### `specify_nonobvious_property_types`
Biến `static const` mà kiểu không hiện rõ từ vế phải (ví dụ gán bằng một hằng
khác) phải khai kiểu tường minh.

```dart
// ✗
static const primaryLight = brand360Blue;
// ✓
static const Color primaryLight = brand360Blue;
```

### `prefer_const_declarations`
`final` gán bằng giá trị hằng → đổi thành `const`. Rất hay gặp trong test.

### `unnecessary_nullable_for_final_variable_declarations`
Khai `String?` nhưng luôn có giá trị → bỏ `?`.

## Import

### `unnecessary_import`
Import `package:meta/meta.dart` khi đã import `package:flutter/material.dart`
(material đã re-export `@immutable`). Bỏ dòng meta.

### `depend_on_referenced_packages`
Dùng package chỉ có trong dependency gián tiếp. Sửa: thêm vào `pubspec.yaml`
đúng mục (`dependencies` hoặc `dev_dependencies`).

## Tài liệu & chú thích

### `comment_references`
Dùng `[TênLớp]` trong doc comment mà lớp đó không được import trong file. Sửa:
đổi sang backtick `` `TênLớp` `` hoặc import thêm.

### `document_ignores`
Mọi `// ignore:` phải kèm lý do trên cùng dòng.

```dart
// ✗
// ignore: use_setters_to_change_properties
// ✓
// ignore: use_setters_to_change_properties, giữ dạng method cho rõ ở chỗ gọi
```

## Cấu trúc lệnh

### `cascade_invocations`
Gọi liên tiếp nhiều method trên cùng một đối tượng → dùng cascade `..`.

```dart
// ✗
canvas.drawCircle(a, r, p);
canvas.drawCircle(b, r, p);
// ✓
canvas
  ..drawCircle(a, r, p)
  ..drawCircle(b, r, p);
```

### `curly_braces_in_flow_control_structures`
`if` một dòng vẫn phải có ngoặc nhọn khi thân nằm ở dòng khác.

### `use_setters_to_change_properties` / `avoid_setters_without_getters`
Hai lint này **đối nghịch nhau**: đổi method thành setter thì lint thứ hai báo.
Cách xử lý: giữ method và `// ignore:` lint thứ nhất kèm lý do.

### `dead_code` / điều kiện luôn đúng
Thường do `??` trên biến không nullable (ví dụ cột DB có `withDefault` nên
non-nullable). Bỏ `?? giá_trị_mặc_định`.

## Riverpod (bản 4.x)

Không còn các kiểu `<TênProvider>Ref` sinh tự động. Mọi provider function nhận
`Ref`:

```dart
// ✗ (Riverpod 3 trở về trước)
TaskDao taskDao(TaskDaoRef ref) => ...
// ✓ (Riverpod 4)
TaskDao taskDao(Ref ref) => ...
```

## Bẫy trong test, không phải lint nhưng cùng loại "chỉ đỏ trên CI"

### "A Timer is still pending even after the widget tree was disposed"
Có Timer còn treo lúc binding kiểm invariant. Nguồn thường gặp:

- **Stream của drift đang mở.** Binding kiểm *trước* khi `tearDown` chạy, nên
  đóng DB ở `tearDown` là quá muộn — phải đóng trong thân test.
- **Provider auto-dispose của Riverpod** hẹn giờ dọn bằng Timer 0ms. Để
  `ProviderScope` (cây widget) sở hữu container thay vì tự tạo `ProviderContainer`.

Đóng DB trong thân test lại cần `tester.runAsync(db.close)` vì đó là I/O thật,
chạy thẳng dưới đồng hồ giả sẽ treo.

Nếu thử vài cách vẫn treo: **đừng commit test treo** (nó làm đứng CI). Ghi rõ
trong commit message là lỗi đó chưa có test tự động và vì sao, hoặc chuyển sang
`integration_test` chạy trên thiết bị thật — môi trường đó không dùng đồng hồ giả.

### `pumpAndSettle()` không bao giờ dừng
Có animation `repeat()` vô hạn trong cây widget. Dùng `tester.pump(Duration(...))`
số lần cố định thay vì `pumpAndSettle`.
