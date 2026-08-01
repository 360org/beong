# DailyChildren

App quản lý việc nhà & phần thưởng hằng ngày cho gia đình và trẻ em.
Viết bằng **Flutter**, chạy trên **iOS, Android, macOS, Windows**.

Lấy cảm hứng từ ChoreReward, mở rộng thêm: offline-first, đồng bộ nhiều thiết bị,
app desktop cho phụ huynh, streak/huy hiệu, kho phần thưởng tự định nghĩa và thống kê tiến độ.

> **Trạng thái:** giai đoạn kế hoạch & thiết kế. Chưa có code.

## Tài liệu

| File | Nội dung |
|---|---|
| [`docs/01-product-spec.md`](docs/01-product-spec.md) | Đặc tả sản phẩm: vai trò, phạm vi MVP, yêu cầu chức năng, chỉ số |
| [`docs/02-architecture.md`](docs/02-architecture.md) | Kiến trúc, tech stack, cấu trúc thư mục, sync, bảo mật, CI |
| [`docs/03-data-model.md`](docs/03-data-model.md) | Schema, quan hệ, RLS, chỉ mục, migration |
| [`docs/04-design-system.md`](docs/04-design-system.md) | Màu, chữ, component, 24 preset, mô tả từng màn hình |
| [`docs/05-roadmap.md`](docs/05-roadmap.md) | 7 sprint, ~8.5 tuần tới v1.0, kế hoạch sau v1 |
| [`docs/06-decisions.md`](docs/06-decisions.md) | 10 ADR + câu hỏi còn mở |

## Ý tưởng cốt lõi

```
Phụ huynh tạo task  →  Trẻ hoàn thành  →  Phụ huynh duyệt
                                              ↓
                                        Điểm vào ví trẻ
                                              ↓
                                       Đổi lấy phần thưởng
```

## Bắt đầu từ đâu

Đọc `01` → `05`. Việc code bắt đầu ở **Sprint 0** trong `docs/05-roadmap.md`.
