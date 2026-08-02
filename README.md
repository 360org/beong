# Bé Ong

App quản lý việc nhà & phần thưởng hằng ngày cho gia đình và trẻ em.
Viết bằng **Flutter**, chạy trên **iOS, Android, macOS, Windows**.

Lấy cảm hứng từ ChoreReward, mở rộng thêm: **offline-first** (ChoreReward bắt buộc phải có
Internet), app desktop cho phụ huynh, nhiều phụ huynh, bằng chứng hoàn thành, thống kê xuất được
và tiếng Việt.

**Miễn phí hoàn toàn** — không thuê bao, không mua trong app, không quảng cáo, không giới hạn
số trẻ hay số task.

> **Trạng thái:** Sprint 0 xong (nền dự án, design system, điều hướng, i18n, CI).
> Sprint 1 (dữ liệu local) là bước tiếp theo — xem `docs/05-roadmap.md`.

## Chạy thử

```bash
flutter pub get
flutter gen-l10n
flutter run
```

Chi tiết quy ước phát triển: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Tài liệu

| File | Nội dung |
|---|---|
| [`docs/01-product-spec.md`](docs/01-product-spec.md) | Đặc tả sản phẩm: vai trò, phạm vi MVP, yêu cầu chức năng, chỉ số |
| [`docs/02-architecture.md`](docs/02-architecture.md) | Kiến trúc, tech stack, cấu trúc thư mục, sync, bảo mật, CI |
| [`docs/03-data-model.md`](docs/03-data-model.md) | Schema, quan hệ, RLS, chỉ mục, migration |
| [`docs/04-design-system.md`](docs/04-design-system.md) | Màu, chữ, component, 24 preset, mô tả từng màn hình |
| [`docs/05-roadmap.md`](docs/05-roadmap.md) | 7 sprint, ~9 tuần tới v1.0, kế hoạch sau v1 |
| [`docs/06-decisions.md`](docs/06-decisions.md) | 14 ADR + câu hỏi còn mở |
| [`docs/07-competitive-analysis.md`](docs/07-competitive-analysis.md) | Phân tích ChoreReward từ App Store listing + việc phải làm |

## Ý tưởng cốt lõi

```
Phụ huynh tạo routine/task  →  Trẻ hoàn thành  →  Phụ huynh duyệt
                                                       ↓
                                          Điểm vào ví trẻ (+ bonus trọn bộ, streak)
                                                       ↓
                                                Đổi lấy phần thưởng
```

## Bắt đầu từ đâu

Đọc `01` → `05`. Việc code bắt đầu ở **Sprint 0** trong `docs/05-roadmap.md`.
