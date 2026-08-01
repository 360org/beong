# 05 — Lộ trình & kế hoạch triển khai

Ước lượng theo **1 dev full-time**. Có 2 dev thì chia Sprint 3–6 song song (một người backend/sync,
một người UI).

## Sprint 0 — Nền móng (1 tuần)
- [ ] `flutter create` với 4 platform (ios, android, macos, windows)
- [ ] Cấu hình lint (`very_good_analysis`), format, pre-commit
- [ ] Theme + design tokens từ `04-design-system.md`, thư viện component dùng chung
- [ ] i18n (vi/en) với ARB
- [ ] go_router + shell route (bottom nav / sidebar)
- [ ] `ResponsiveScaffold` + golden test 3 breakpoint
- [ ] CI: analyze + test + build android/macos

**Xong khi:** app chạy trên 4 nền tảng, hiển thị 5 màn hình rỗng đúng theme, CI xanh.

## Sprint 1 — Dữ liệu local (1 tuần)
- [ ] Drift schema đầy đủ theo `03-data-model.md`
- [ ] DAO + repository implementation (local-only)
- [ ] Bộ sinh `task_instances` + logic ngày theo timezone/rollover
- [ ] Ledger + tính số dư
- [ ] Seed 24 preset
- [ ] Unit test: scheduler (once/daily/custom), ledger, đổi ngày

**Xong khi:** tạo task → sinh instance đúng 7 ngày tới → đánh dấu xong → số dư tăng, toàn bộ offline.

## Sprint 2 — Luồng cốt lõi UI (1.5 tuần)
- [ ] Onboarding 3 bước
- [ ] Task Editor (đầy đủ 8 khối)
- [ ] Child Home + hoàn thành task + animation ăn mừng
- [ ] Parent Home + hàng đợi duyệt
- [ ] Chuyển hồ sơ + PIN phụ huynh
- [ ] Integration test luồng: tạo → xong → duyệt

**Xong khi:** dùng được thật trên 1 thiết bị, không cần mạng.

## Sprint 3 — Phần thưởng (1 tuần)
- [ ] CRUD phần thưởng
- [ ] Đổi thưởng + hàng chờ duyệt + hoàn điểm khi từ chối
- [ ] "Mục tiêu của con" + thanh tiến độ
- [ ] Lịch sử giao dịch điểm

## Sprint 4 — Backend & sync (2 tuần)
- [ ] Dự án Supabase, migration SQL, RLS policy
- [ ] Auth phụ huynh (email magic link, Sign in with Apple/Google)
- [ ] Mời phụ huynh thứ hai vào gia đình (mã mời)
- [ ] Outbox + SyncEngine + retry/backoff + idempotency
- [ ] Realtime subscribe theo `family_id`
- [ ] Test xung đột: 2 thiết bị offline cùng sửa → kết quả hội tụ
- [ ] Job đối soát `balance_cache`

**Xong khi:** 2 thiết bị (1 phụ huynh desktop + 1 trẻ mobile) thấy cùng dữ liệu, chịu được mất mạng.

## Sprint 5 — Thông báo & hoàn thiện (1 tuần)
- [ ] FCM push (mobile) + local notification (desktop)
- [ ] 5 loại thông báo trong bảng ở `01-product-spec.md` §4.5
- [ ] Cài đặt: ngôn ngữ, chủ đề sáng/tối, giờ đổi ngày, âm thanh
- [ ] Trang trống, trạng thái lỗi, màn hình mất mạng
- [ ] Rà soát khả dụng (TalkBack/VoiceOver, contrast, text scale)

## Sprint 6 — Phát hành v1.0 (1 tuần)
- [ ] Icon app, splash, ảnh chụp store
- [ ] Chính sách quyền riêng tư + điều khoản (bắt buộc cho app trẻ em)
- [ ] Khai báo App Store "Kids Category" / Play "Teacher Approved" nếu áp dụng
- [ ] Fastlane → TestFlight + Play Internal
- [ ] Beta 10 gia đình, thu phản hồi 2 tuần

**Tổng MVP: ~8.5 tuần.**

## Sau v1.0

| Phiên bản | Nội dung |
|---|---|
| v1.1 | Streak, huy hiệu, level; bằng chứng ảnh/ghi chú |
| v1.2 | Thống kê tuần/tháng, xuất CSV/PDF; thử thách tuần |
| v1.3 | Desktop 3 cột tối ưu, phím tắt; widget màn hình chính iOS/Android |
| v1.4 | Nhiều gia đình / ly thân (trẻ ở 2 nhà); chia sẻ task giữa 2 hộ |
| v2.0 | Web app; mục tiêu tiết kiệm dài hạn; gợi ý task bằng AI theo độ tuổi |

## Định nghĩa "Xong" (mọi task)
1. Code + test (unit ở domain, widget ở màn hình mới)
2. `flutter analyze` sạch, format chuẩn
3. Chạy được trên ít nhất 1 mobile + 1 desktop
4. Chuỗi hiển thị đều nằm trong ARB (không hard-code)
5. Tự review khả dụng: vùng chạm, contrast, semantics
