# 02 — Kiến trúc kỹ thuật

## 1. Tổng quan

Offline-first. Nguồn sự thật khi chạy là **database local (Drift/SQLite)**; backend chỉ là
lớp đồng bộ. Mọi thao tác ghi local trước → UI phản hồi tức thì → hàng đợi sync đẩy lên server.

```
┌──────────────────────── Flutter App ────────────────────────┐
│  Presentation   Widgets · Screens · Router (go_router)      │
│       ↓ đọc state / gọi lệnh                                │
│  Application    Riverpod providers · Use cases              │
│       ↓                                                     │
│  Domain         Entities · Value objects · Repo interfaces  │
│       ↓                                                     │
│  Data           Drift (SQLite)  ·  SyncEngine  ·  API client│
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTPS / WebSocket
                    ┌──────────┴──────────┐
                    │  Backend (Supabase) │
                    │  Postgres + RLS     │
                    │  Auth · Realtime    │
                    │  Storage (ảnh)      │
                    │  Edge Functions     │
                    └─────────────────────┘
```

## 2. Lựa chọn công nghệ

| Hạng mục | Chọn | Lý do |
|---|---|---|
| Framework | Flutter 3.44.x (stable) | Một codebase cho iOS/Android/macOS/Windows |
| Ngôn ngữ | Dart 3.12, sound null-safety | — |
| State | **Riverpod 3** (codegen) | Test được, không phụ thuộc BuildContext, hợp desktop |
| Điều hướng | **go_router** | Deep link, hỗ trợ tốt desktop/web, khai báo tường minh |
| DB local | **Drift** (SQLite, qua `sqlite3` 3.x) | Type-safe, migration rõ ràng, chạy mọi nền tảng |
| Backend | **Supabase** | Postgres + RLS + Auth + Realtime + Storage; self-host được |
| Model/DTO | freezed + json_serializable | Immutable, copyWith, union type cho state |
| DI | Riverpod providers | Không cần get_it |
| i18n | flutter_localizations + ARB | vi, en |
| Push | firebase_messaging (mobile) + local_notifications | Desktop dùng local notification |
| Ảnh | Supabase Storage + cached_network_image | — |
| Analytics | PostHog self-host hoặc tắt hoàn toàn | Không tracking bên thứ ba cho trẻ |
| CI | GitHub Actions | analyze → test → build |

> **Vì sao Supabase mà không Firebase:** Postgres cho phép mô hình quan hệ (ledger, RLS theo
> `family_id`) rõ ràng hơn Firestore; RLS đủ mạnh để chặn chéo gia đình mà không cần Cloud
> Functions; chi phí dự đoán được; có thể self-host nếu vấn đề pháp lý dữ liệu trẻ em phát sinh.
> Xem thêm `06-decisions.md`.

## 3. Cấu trúc thư mục

```
lib/
  main.dart
  app/
    app.dart                  # MaterialApp.router, theme, locale
    router.dart               # go_router routes + guards
    di.dart                   # provider overrides khi khởi động
  core/
    theme/                    # colors, typography, spacing, component themes
    l10n/                     # arb + generated
    error/                    # Failure, AppException
    utils/                    # date, formatter, extensions
    widgets/                  # nút, card, empty state dùng chung
  domain/
    entities/                 # Family, Member, Task, TaskInstance, Reward, ...
    repositories/             # abstract class (interface)
    usecases/                 # CompleteTask, ApproveTask, RedeemReward, ...
  data/
    local/
      database.dart           # Drift database
      tables/                 # định nghĩa bảng
      daos/
    remote/
      supabase_client.dart
      dto/
    sync/
      sync_engine.dart
      outbox.dart
    repositories/             # implement interface của domain
  features/
    onboarding/
    auth/
    parent_home/
    child_home/
    task_editor/
    rewards/
    stats/
    settings/
      # mỗi feature: presentation/ (screens, widgets) + application/ (providers)
test/
  unit/ widget/ integration/
```

Quy ước: feature **không** import trực tiếp `data/`; chỉ đi qua `domain/repositories`.
Lint chặn bằng `import_lint` hoặc review.

## 4. Đồng bộ (SyncEngine)

### Nguyên tắc
1. Ghi local trước, luôn thành công (UI không chờ mạng).
2. Mỗi thao tác ghi sinh một bản ghi trong bảng **outbox** (`op`, `entity`, `payload`, `created_at`).
3. Worker nền đẩy outbox theo thứ tự FIFO; thất bại → retry với backoff (2s, 4s, 8s, … tối đa 5 phút).
4. Kéo về bằng Supabase Realtime (subscribe theo `family_id`) + full pull khi mở app.

### Xử lý xung đột
- **Ledger (`point_transactions`, `task_events`): append-only** → không bao giờ xung đột.
  Số dư và trạng thái task được *tính lại* từ sự kiện.
- **Entity có thể sửa (task, reward, member): Last-Write-Wins theo trường**, dựa trên
  `updated_at` server-side. Mỗi bản ghi giữ `version` để phát hiện ghi đè.
- **Xóa:** soft delete (`deleted_at`) để tránh "hồi sinh" bản ghi khi thiết bị offline lâu.

### Idempotency
Mọi op mang `client_op_id` (UUID v4). Server có unique index trên `client_op_id`
→ gửi lại an toàn, không nhân đôi điểm.

## 5. Bảo mật

- **Auth:** Supabase Auth (email + magic link, Apple/Google Sign-in). Chỉ phụ huynh có tài khoản.
- **Hồ sơ trẻ:** là *row* trong bảng `members`, không phải auth user. Trẻ dùng app qua
  chế độ chọn hồ sơ + PIN 4 số (lưu hash Argon2 local) hoặc thiết bị riêng đã ghim hồ sơ.
- **RLS:** mọi bảng có `family_id`; policy `family_id IN (SELECT family_id FROM memberships WHERE user_id = auth.uid())`.
- **Chế độ phụ huynh:** các hành động nhạy cảm (sửa điểm, duyệt, xóa task) yêu cầu PIN phụ huynh
  nếu app đang ở "chế độ trẻ".
- **Ảnh bằng chứng:** bucket private, truy cập qua signed URL hết hạn 1 giờ.
- Không SDK quảng cáo, không tracking bên thứ ba.

## 6. Đa nền tảng

| | Mobile (iOS/Android) | Desktop (macOS/Windows) |
|---|---|---|
| Layout | 1 cột, bottom nav | 2–3 cột, sidebar |
| Điểm gãy | < 600dp | 600–1024 (2 cột), > 1024 (3 cột) |
| Nhập liệu | Chạm | Chuột + phím tắt (⌘N task mới, ⌘⏎ lưu) |
| Thông báo | FCM push | flutter_local_notifications |
| Vai trò chính | Trẻ dùng nhiều | Phụ huynh quản lý, xem thống kê |

Dùng `LayoutBuilder` + `ResponsiveScaffold` dùng chung; **không** fork màn hình theo nền tảng.

## 7. Kiểm thử

| Tầng | Công cụ | Mục tiêu |
|---|---|---|
| Unit (domain, usecase, sync) | `test` + mocktail | ≥ 80% coverage domain |
| DAO / migration | drift test + in-memory sqlite | Mọi migration có test |
| Widget | `flutter_test` + golden | Màn hình chính có golden test |
| Integration | `integration_test` | 3 luồng: tạo task → trẻ xong → duyệt; đổi thưởng; onboarding |

## 8. CI/CD

```yaml
# .github/workflows/ci.yml (phác thảo)
jobs:
  analyze:   flutter analyze --fatal-infos && dart format --set-exit-if-changed .
  test:      flutter test --coverage
  build:     matrix [android, ios, macos, windows] → artifact
```
Release: `main` → tag `v*` → Fastlane đẩy TestFlight / Play Internal Testing.
