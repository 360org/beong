# Bé Ong

App giúp trẻ tập làm việc, tự lập và quản lý tiền của chính mình.
Viết bằng **Flutter**, chạy trên **iOS, Android, macOS, Windows, Linux**.

Trang giới thiệu: **[beong.net](https://beong.net)** · Hướng dẫn dùng:
[`docs/12-huong-dan-su-dung.md`](docs/12-huong-dan-su-dung.md)

> **Kim chỉ nam: độc lập — tự lập.** Mục tiêu cuối cùng là đứa trẻ không cần Bé Ong nữa.
> Bốn giá trị: học tập · tự lập · minh bạch · đồng hành — xem [`docs/00-brand-values.md`](docs/00-brand-values.md).

Lấy cảm hứng từ ChoreReward, mở rộng thêm: **offline-first** (ChoreReward bắt buộc phải có
Internet), app desktop cho phụ huynh, nhiều phụ huynh, thống kê xuất được và tiếng Việt.

**Miễn phí hoàn toàn** — không thuê bao, không mua trong app, không quảng cáo, không giới hạn
số trẻ hay số task.

## Trạng thái

**`v0.2.4` — chạy đủ trên một máy, chưa lên store.**

| | |
|---|---|
| Đã xong | Việc nhà, thói quen kéo thả, xu và các hũ, phần thưởng có duyệt, 8 huy hiệu, mục tiêu để dành, nhiều con, mật khẩu riêng từng hồ sơ, giao diện Sáng/Tối, báo lỗi |
| Đang làm | Đồng bộ nhiều máy — bố mẹ cấu hình xong, máy con quét QR nhận hồ sơ (Sprint 3) |
| Chưa có | Thông báo nhắc việc, chế độ chụp ảnh làm bằng chứng, bản trên store |

Lộ trình đánh dấu từng mục: [`docs/05-roadmap.md`](docs/05-roadmap.md) ·
Audit: [`docs/audit_report_v0.2.0.md`](docs/audit_report_v0.2.0.md) ·
Nhật ký: [`CHANGELOGS.md`](CHANGELOGS.md)

## Chạy thử

```bash
flutter pub get
dart run build_runner build   # bắt buộc — file *.g.dart bị gitignore
flutter gen-l10n
flutter run
```

Bỏ `build_runner` là gặp hàng loạt "Undefined name" của thứ mình vừa viết đúng.

Quy ước phát triển: [`CONTRIBUTING.md`](CONTRIBUTING.md). Quy trình 8 bước, gồm cả cách
dựng môi trường chụp màn hình: `.claude/skills/flutter-8-buoc/SKILL.md`.

## Tài liệu

| File | Nội dung |
|---|---|
| [`docs/00-brand-values.md`](docs/00-brand-values.md) | **Đọc đầu tiên** — kim chỉ nam, bốn giá trị và cách chúng chi phối thiết kế |
| [`docs/01-product-spec.md`](docs/01-product-spec.md) | Đặc tả sản phẩm: vai trò, phạm vi MVP, yêu cầu chức năng, chỉ số |
| [`docs/02-architecture.md`](docs/02-architecture.md) | Kiến trúc, tech stack, cấu trúc thư mục, sync, bảo mật, CI |
| [`docs/03-data-model.md`](docs/03-data-model.md) | Schema, quan hệ, RLS, chỉ mục, migration |
| [`docs/04-design-system.md`](docs/04-design-system.md) | Màu, chữ, component, preset, mô tả từng màn hình |
| [`docs/05-roadmap.md`](docs/05-roadmap.md) | 7 sprint tới v1.0, đánh dấu từng mục đã xong hay chưa |
| [`docs/06-decisions.md`](docs/06-decisions.md) | 27 ADR + câu hỏi còn mở |
| [`docs/07-competitive-analysis.md`](docs/07-competitive-analysis.md) | Phân tích ChoreReward từ App Store listing + việc phải làm |
| [`docs/08-release-cicd.md`](docs/08-release-cicd.md) | Ký số, secret, đưa lên TestFlight và Play Internal |
| [`docs/09-onboarding-pairing.md`](docs/09-onboarding-pairing.md) | Luồng tạo hồ sơ và ghép cặp máy con bằng QR |
| [`docs/10-privacy-policy.md`](docs/10-privacy-policy.md) | Chính sách quyền riêng tư + phụ lục khai báo cho hai store |
| [`docs/11-bao-loi-endpoint.md`](docs/11-bao-loi-endpoint.md) | Dựng endpoint nhận báo lỗi (Cloudflare Worker) |
| [`docs/12-huong-dan-su-dung.md`](docs/12-huong-dan-su-dung.md) | **Hướng dẫn cho bố mẹ** — 16 mục, kèm ảnh |
| [`docs/13-audit-luong-vao-app.md`](docs/13-audit-luong-vao-app.md) | **Audit luồng vào app** — 2 lỗi nghiêm trọng, phương án, và bản sửa ở v0.2.3 |
| [`docs/screenshot/`](docs/screenshot/) | 80 ảnh chụp toàn bộ app, có mục lục |

## Ý tưởng cốt lõi

```
Bố mẹ giao việc  →  Con tự làm  →  (bố mẹ duyệt, nếu nhà bật)
                                        ↓
                              Xu vào ví của con
                                        ↓
              Chia vào các hũ: Tiêu · Để dành · Cho đi — bố mẹ tự lập thêm được
                                        ↓
                           Đổi lấy thứ con thật sự muốn
```

Bước duyệt **mặc định tắt** (ADR-023): con bấm xong là xong, xu cộng ngay. Nhà nào muốn
kiểm thì bật trong Cài đặt, hoặc bật riêng cho từng việc.

Riêng **đổi phần thưởng thì luôn phải duyệt** (ADR-025) và không tắt được — phần thưởng
ngoài đời cần người lớn thực hiện.

## Bắt đầu từ đâu

Đọc `00` → `05`. Việc còn lại nằm ở **Sprint 3** trong [`docs/05-roadmap.md`](docs/05-roadmap.md);
phần chặn thật là dựng dự án Supabase.
