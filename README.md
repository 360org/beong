# Bé Ong

App giúp trẻ tập làm việc, tự lập và quản lý tiền của chính mình.
Viết bằng **Flutter**, chạy trên **iOS, Android, macOS, Windows**.

> **Kim chỉ nam: độc lập — tự lập.** Mục tiêu cuối cùng là đứa trẻ không cần Bé Ong nữa.
> Bốn giá trị: học tập · tự lập · minh bạch · đồng hành — xem [`docs/00-brand-values.md`](docs/00-brand-values.md).

Lấy cảm hứng từ ChoreReward, mở rộng thêm: **offline-first** (ChoreReward bắt buộc phải có
Internet), app desktop cho phụ huynh, nhiều phụ huynh, bằng chứng hoàn thành, thống kê xuất được
và tiếng Việt.

**Miễn phí hoàn toàn** — không thuê bao, không mua trong app, không quảng cáo, không giới hạn
số trẻ hay số task.

> **Trạng thái:** Phiên bản `v0.2.0` (Hoàn thành nghiệp vụ cốt lõi Local-First, Quản lý Thói quen, Mục tiêu tiết kiệm, Mã PIN phụ huynh, Báo lỗi & Diagnostics).
> Báo cáo audit chi tiết: [`docs/audit_report_v0.2.0.md`](docs/audit_report_v0.2.0.md).
> Nhật ký thay đổi: [`CHANGELOGS.md`](CHANGELOGS.md).

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
| [`docs/00-brand-values.md`](docs/00-brand-values.md) | **Đọc đầu tiên** — kim chỉ nam, bốn giá trị và cách chúng chi phối thiết kế |
| [`docs/01-product-spec.md`](docs/01-product-spec.md) | Đặc tả sản phẩm: vai trò, phạm vi MVP, yêu cầu chức năng, chỉ số |
| [`docs/02-architecture.md`](docs/02-architecture.md) | Kiến trúc, tech stack, cấu trúc thư mục, sync, bảo mật, CI |
| [`docs/03-data-model.md`](docs/03-data-model.md) | Schema, quan hệ, RLS, chỉ mục, migration |
| [`docs/04-design-system.md`](docs/04-design-system.md) | Màu, chữ, component, 24 preset, mô tả từng màn hình |
| [`docs/05-roadmap.md`](docs/05-roadmap.md) | 7 sprint, ~9 tuần tới v1.0, kế hoạch sau v1 |
| [`docs/06-decisions.md`](docs/06-decisions.md) | 17 ADR + câu hỏi còn mở |
| [`docs/07-competitive-analysis.md`](docs/07-competitive-analysis.md) | Phân tích ChoreReward từ App Store listing + việc phải làm |

## Ý tưởng cốt lõi

```
Bố mẹ giao việc  →  Con tự làm  →  Bố mẹ duyệt
                                        ↓
                              Xu vào ví của con
                                        ↓
                    Con chia vào 3 hũ: Tiêu · Để dành · Cho đi
                                        ↓
                           Đổi lấy thứ con thật sự muốn
```

## Bắt đầu từ đâu

Đọc `00` → `05`. Việc code bắt đầu ở **Sprint 0** trong `docs/05-roadmap.md`.
