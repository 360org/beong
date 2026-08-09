# Hướng dẫn phát triển

## Yêu cầu

- Flutter **3.44.8** (stable) — xem `FLUTTER_VERSION` trong `.github/workflows/ci.yml`
- Dart 3.12

Đừng để SDK tụt lại quá xa bản stable. Ngoài lý do thông thường, `flutter build windows`
hỏng khi SDK cũ hơn Visual Studio trên máy build: Flutter chỉ ánh xạ được những phiên bản
VS nó biết, gặp bản mới hơn thì im lặng rơi về generator `Visual Studio 16 2019` và CMake
báo không tìm thấy Visual Studio nào.

## Chạy lần đầu

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # sinh *.g.dart
flutter gen-l10n                                           # sinh L10n
flutter run -d <thiết-bị>
```

**Mã sinh tự động không được commit** (`.gitignore` loại `*.g.dart`, `*.freezed.dart`
và `lib/core/l10n/gen/`), nên clone xong phải chạy đủ hai lệnh sinh code ở trên —
không thì IDE báo thiếu `L10n`, `AppDatabase` và các lớp Drift.

Sửa bảng trong `lib/data/local/tables/` hay thêm `@DriftAccessor` thì chạy lại
`build_runner`. Dùng `dart run build_runner watch` nếu sửa liên tục.

Build desktop trên Linux cần thêm: `ninja-build libgtk-3-dev pkg-config clang cmake`.

## Trước khi commit

```bash
dart format lib test
flutter analyze          # phải sạch, CI chạy với --fatal-infos
flutter test
```

## Quy ước

**Kiến trúc** — `docs/02-architecture.md` §3. Feature không import trực tiếp `data/`;
mọi truy cập dữ liệu đi qua interface trong `domain/repositories/`.

**Màu và khoảng cách** — không hard-code. Dùng `AppColors`, `AppSpacing`, `AppRadius`,
hoặc đọc qua `context.colors` / `context.semantic` / `context.text`.

**Chuỗi hiển thị** — luôn nằm trong `lib/core/l10n/arb/`. `app_vi.arb` là bản gốc
(template), `app_en.arb` phải có đủ key tương ứng. Không viết hoa sẵn trong chuỗi —
viết hoa ở tầng widget để bản dịch còn tự nhiên.

**Ngày tháng** — không dùng `DateTime.now().day` để tính "hôm nay". Ngày của một gia đình
phụ thuộc `families.timezone` và `day_rollover_hour` (mặc định 4h sáng) — xem ADR-008.
Từ Sprint 1 sẽ có hàm `familyToday()`, mọi phép tính ngày phải đi qua đó.

**Điểm thưởng** — không sửa số dư trực tiếp. Mọi thay đổi là một dòng trong
`point_transactions`; số dư là tổng của sổ cái — xem ADR-005.

**Không có khái niệm trả phí ở v1** — không thêm `isPremium`, `plan`, `entitlement` vào
domain hay database. Xem ADR-014.

**Ràng buộc khả dụng phải có test.** Contrast, cỡ chạm, breakpoint — nếu tài liệu ghi một
con số thì phải có test giữ con số đó (xem `test/unit/app_theme_test.dart`).

## Cấu trúc thư mục

Xem `docs/02-architecture.md` §3. Tóm tắt:

```
lib/
  app/        # MaterialApp, router
  core/       # theme, l10n, widget dùng chung, tiện ích
  domain/     # entity, repository interface, use case  (Sprint 1)
  data/       # Drift, Supabase, sync, repository impl  (Sprint 1, 4)
  features/   # mỗi feature: presentation/ + application/
```

## Tài liệu

Quyết định kiến trúc nằm ở `docs/06-decisions.md`. Trước khi đổi một lựa chọn nền tảng
(state management, backend, cách tính điểm…), đọc ADR tương ứng — phần "Hệ quả" thường đã
ghi sẵn cái giá phải trả.
