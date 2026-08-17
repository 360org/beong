# Báo Cáo Audit Toàn Diện Dự Án Bé Ong (v0.2.0)

* **Ngày thực hiện**: 2026-08-16
* **Phiên bản**: `v0.2.0+1`
* **Người thực hiện**: Claude (360org AIaC Engine)
* **Phạm vi audit**: Toàn bộ codebase (Data, Domain, Presentation, Diagnostics, CI/CD, ADRs, Security, Accessibility)

---

## 1. Tóm Tắt Trạng Thái Dự Án

Dự án **Bé Ong** (DailyChildren) là ứng dụng quản lý việc nhà, xây dựng thói quen và giáo dục tài chính cho trẻ em, phát triển trên nền tảng **Flutter** (hỗ trợ iOS, Android, macOS, Windows, Linux) theo kiến trúc **Offline-first**.

### Các mốc tiến độ chính:
* **Sprint 0 (Nền móng)**: Hoàn thành (Responsive layout, Design System, CI build 5 nền tảng).
  **Ngoại lệ — đa ngôn ngữ**: hạ tầng ARB (`app_vi.arb`, `app_en.arb`) có sẵn nhưng `lib/features`
  chỉ gọi `L10n.of(context)` ở **3** chỗ trong khi có **95** chuỗi tiếng Việt viết cứng. Thực chất
  app đang là **tiếng Việt một ngôn ngữ**; đây là lý do ô chọn ngôn ngữ đã bị gỡ ra (xem
  `05-roadmap.md` Sprint 5).
* **Sprint 1 (Dữ liệu Local & Ledger)**: Hoàn thành 100% (Drift SQLite schema, DAO phân lập, bộ sinh task tự động theo chu kỳ, tính streak, thưởng trọn bộ).
* **Sprint 2 & 4 (Giao diện & Nghiệp vụ cốt lõi)**: Hoàn thành 95% (Parent/Child Home, Onboarding, Quản lý thói quen kéo thả, Mục tiêu tiết kiệm, Duyệt thưởng an toàn, Phạt xu, Mã PIN phụ huynh, 8 huy hiệu MVP).
* **Sprint 5 (Thông báo)**: **Chưa bắt đầu.** FCM push, 7 loại thông báo và bộ điều tiết
  "nhắc nhẹ, không cằn nhằn" đều chưa có dòng mã nào.
* **Diagnostics & Báo lỗi** (việc **ngoài kế hoạch**, không thuộc Sprint 5): đã có thu thập nhật
  ký lỗi, chụp màn hình và tầng gửi. **Chưa chạy được thật**: `BEONG_REPORT_ENDPOINT` chưa được
  dựng và chưa có trong workflow, nên mọi bản dựng hiện tại rơi về đường dự phòng (mở trang
  điền sẵn). Xem `11-bao-loi-endpoint.md`.
* **Sprint 6 (Chuẩn bị phát hành)**: Đã có kịch bản CI/CD release cho Android (App Bundle →
  Google Play Internal) và iOS (IPA → TestFlight). **Chưa chạy lần nào**: thiếu 8 secret iOS,
  chưa có tài khoản store cấu hình xong, chưa có icon app / splash / ảnh chụp store.
  Chính sách quyền riêng tư (`10-privacy-policy.md`) mới là **bản thảo chưa qua rà soát pháp
  lý**, còn trống email liên hệ và đơn vị phát hành, và chưa được đăng ở URL công khai — mà
  thiếu URL đó thì **không điền xong nổi form** của cả hai store.

---

## 2. Kết Quả Kiểm Tra Chi Tiết Theo Quy Chuẩn

### A. Quy chuẩn Kiến trúc (Clean Architecture & ADRs)
* **ADR-002 (Offline-First)**: Giao diện hoàn toàn đọc và ghi thông qua tầng Drift Local DB. Không có lời gọi mạng chặn UI.
* **ADR-005 (Ledger Append-only)**: Mọi thao tác cộng/trừ xu đều ghi qua bảng
  `point_transactions` (chỉ một bảng — schema **không** có bảng `ledgers`), nhóm theo
  `op_group_id` để "Sổ của con" hiện một thao tác là một mục.
* **ADR-008 (Đồng hồ gia đình & Rollover 4h sáng)**: `DayStartService` định tuyến qua `FamilyClock` để thống nhất khái niệm "ngày hôm nay".
* **ADR-014 (Miễn phí hoàn toàn)**: Không chứa bất kỳ mã nguồn, SDK thanh toán, IAP hay SDK quảng cáo bên thứ 3 nào.
* **ADR-017 (Quy đổi tiền thật)**: Tách biệt logic làm tròn xuống an toàn tại `MoneyExchange`, mặc định tắt.
* **ADR-025 (Bắt buộc duyệt đổi thưởng)**: Mọi giao dịch đổi quà đều chuyển vào trạng thái `pending` và yêu cầu xác nhận từ bố mẹ.
* **Clean Architecture — chưa đạt**: `lib/domain/repositories/` **rỗng**; UI và service gọi
  thẳng DAO. Chấp nhận được ở giai đoạn local-only, nhưng phải có trước khi thêm sync, vì lúc đó
  "đọc ở đâu" mới thành câu hỏi thật. Không nên tuyên bố tuân thủ Clean Architecture khi còn
  thiếu đúng tầng ở giữa.

### B. Chất Lượng Mã Nguồn (Code Quality & Flutter Best Practices)
* **Null Safety**: unwrap cưỡng chế trong router đã xử lý bằng `redirect` — `routineId` rỗng
  đưa về danh sách Nhiệm vụ, không crash mà cũng không mở ra một màn trống trơn. (Bản sửa
  trung gian `?? ''` đổi crash lấy im lặng sai, còn khó lần ra hơn.)
* **Asynchronous Safety**: Các màn hình BottomSheet (`adjust_xu_sheet.dart`, `parent_pin_sheet.dart`, `goal_sheet.dart`) đã đảm bảo kiểm tra `mounted` sau `await` trước khi điều hướng hoặc gọi context.
* **Immutability**: Các entity và state provider đều sử dụng thuộc tính `final` và cập nhật thông qua phương thức `copyWith`.

### C. Khả Năng Tiếp Cận (Accessibility / WCAG AA)
* Bảng màu 8 hồ sơ trẻ em (`AppColors.profilePalette`) đạt độ tương phản **>= 4.5:1** với chữ
  trắng — đúng ngưỡng WCAG AA và đúng ngưỡng `test/unit/app_theme_test.dart` đang canh. (Con số
  4.8 ở bản audit trước không có nguồn.)
* Chặn trần kích thước chữ `maxTextScale = 1.6` giúp giữ nguyên bố cục giao diện ngay cả khi hệ điều hành phóng to font tối đa.
* Vùng chạm tối thiểu đạt chuẩn >= 48dp (`AppSpacing.minTouchTarget`).

### D. Hệ Thống Kiểm Thử (Testing Coverage)
* **46 file test, 483 test** đều xanh; `flutter analyze --fatal-infos` sạch.
* Kiểm thử tích hợp toàn trình tại `integration_test/luong_day_du_test.dart` (3 luồng), có job
  CI riêng chạy trên Linux desktop dưới Xvfb.
* Ràng buộc khả dụng đã thành test tự động (`test/unit/kha_dung_test.dart`) thay vì chỉ là lời
  hứa trong tài liệu.
* Ràng buộc tương phản nay canh **cả nền thẻ**, không chỉ nền trắng thuần — chỗ hở này từng
  để lọt ba màu ngữ nghĩa cùng dưới ngưỡng 4.5:1.
* **Khoảng trống**: `flutter analyze` sạch và toàn bộ test xanh vẫn **không** thay được việc
  chạy app thật và soi ảnh chụp. Ba lỗi nghiêm trọng nhất của bản này đều được tìm ra bằng
  cách đó, không phải bằng test — xem `screenshot/README.md`.

---

## 3. Danh Sách Tính Năng Hoàn Chỉnh Ở Bản v0.2.0

1. **Giao diện Trẻ Em**:
   - Vòng tròn tiến độ hoàn thành nhiệm vụ theo ngày.
   - Linh vật Bé Ong hoạt ảnh biểu cảm theo mức độ hoàn thành.
   - Danh sách công việc chia rõ: Cần làm / Đã xong / Bỏ lỡ.
   - Hiệu ứng pháo hoa ăn mừng khi hoàn thành nhiệm vụ, và khi **nhận huy hiệu mới** thì nổ kèm SnackBar nêu tên huy hiệu.
   - Quản lý mục tiêu tiết kiệm và thanh tiến độ tích lũy xu.
   - Màn hình đổi phần thưởng và xem các phiếu thưởng đã được duyệt.
   - Giao diện tự chia xu từ hũ Chờ vào các hũ của gia đình. Số hũ **không cố định ba**: từ ADR-024 bố mẹ tự lập, sửa tên/emoji/tỷ lệ và xếp lại hũ.

2. **Giao diện Phụ Huynh**:
   - Hàng đợi duyệt nhiệm vụ (Duyệt từng việc hoặc Duyệt tất cả).
   - Danh sách "Đã xong hôm nay" hỗ trợ mở lại nhiệm vụ khi cần.
   - Trình biên tập Routine kéo thả sắp xếp thứ tự nhiệm vụ.
   - Cài đặt tỷ lệ hũ và cấu hình trừ xu khi con bỏ lỡ việc.
   - Điều chỉnh số dư xu thủ công (bắt buộc nhập lý do vào sổ cái).
   - Bảo mật vai phụ huynh bằng mã PIN 4 chữ số.

3. **Hạ Tầng & Báo Lỗi**:
   - Chụp ảnh màn hình đính kèm nhật ký lỗi, gửi về máy chủ báo cáo — **cần dựng endpoint
     trước khi dùng được**, xem `11-bao-loi-endpoint.md`.
   - Hỗ trợ chuyển đổi Theme Sáng / Tối linh hoạt.

---

## 4. Định Hướng Phát Triển Tiếp Theo (Sprint 3)
* Tích hợp Supabase (Auth phụ huynh qua Apple/Google, RLS Policy).
* Cơ chế ghép cặp thiết bị máy con thông qua quét mã QR.
* SyncEngine đồng bộ dữ liệu Realtime nền và giải quyết xung đột khi offline.

---

## 5. Khoảng Trống Đã Biết (không cần backend, làm được ngay)

Xếp theo mức chặn thật, không theo độ khó.

| # | Việc | Vì sao |
|---|---|---|
| 1 | **Dựng endpoint báo lỗi** + tạo nhãn `bug`, `from-app` | Tính năng báo lỗi đã viết xong nhưng **chưa gửi được**; cần tài khoản của chủ dự án |
| 2 | **Điền + đăng chính sách quyền riêng tư** ở URL công khai | Thiếu là không nộp được store, không phải việc để tới lúc review mới lo |
| 3 | **Icon app, splash, ảnh chụp store** | Cùng lý do, và cần thiết kế chứ không phải code |
| 4 | **Đưa chuỗi màn hình vào ARB** | Đang có 3 chỗ dùng ARB / 95 chuỗi cứng; đây là việc thật đứng sau ô chọn ngôn ngữ |
| 5 | **Tầng repository** | Phải có trước sync, và Sprint 3 là việc kế tiếp |
| 6 | ~~Widget test cho màn báo lỗi~~ ✅ | `test/widget/bao_loi_screen_test.dart`, 7 test |
| 7 | ~~Router: `routineId` rỗng~~ ✅ | Nay `redirect` về danh sách Nhiệm vụ |
| 8 | Task Editor: khối **chế độ bằng chứng** | Khối thứ 8 còn thiếu; docs xếp ở v1.1 |
| 9 | ~~Nhận huy hiệu mà không có phản hồi gì~~ ✅ | `complete()` nay trả huy hiệu vừa mở khoá; màn con nổ hoa giấy + hiện tên |
| 10 | ~~Cộng xu hai lần khi đổi chế độ chia~~ ✅ | Chốt chống trùng nay hỏi theo `op_group_id`, không theo khoá từng dòng |
| 11 | ~~Con không biết việc đang chờ duyệt~~ ✅ | Mục riêng + đồng hồ cát + nhãn chữ, thay vì dấu tích y như đã duyệt |
| 12 | ~~Ba màu ngữ nghĩa dưới ngưỡng trên nền thẻ~~ ✅ | Hạ độ sáng cả ba; test cũ chỉ canh nền trắng thuần nên để lọt |

**Cố ý chưa làm** (ghi ra để lần audit sau không đề xuất lại): ô cài đặt âm thanh — app chưa
phát âm thanh nào, thêm một công tắc không điều khiển gì là cờ chết, đúng loại lỗi dự án này đã
phải dọn năm lần.
