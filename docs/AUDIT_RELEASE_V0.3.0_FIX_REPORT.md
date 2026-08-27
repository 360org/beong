# Audit Report — Bé Ong v0.3.0+22

Ngày audit: 2026-08-27  
Phạm vi: Release commit `7a6beeb` / tag `v0.3.0` và diff sửa lỗi audit local sau release.

---

## 1. Kết luận nhanh

Release `v0.3.0` đã lên remote/tag thành công, nhưng audit sau release phát hiện **2 lỗi test thật** và **1 điểm lệch Git policy**.

Trạng thái hiện tại sau khi sửa local:

| Hạng mục | Trạng thái |
|---|---|
| `flutter analyze --no-pub` | ✅ Pass — `No issues found` |
| `flutter test --no-pub --reporter=compact` | ✅ Pass — `523 tests passed` |
| Secret trong tracked files | ✅ Không phát hiện secret rõ ràng |
| Tag `v0.3.0` | ✅ Có tại `HEAD` |
| `origin/main` | ✅ Đã có commit `7a6beeb` |
| GitLab remote | ✅ Sẽ được đồng bộ trong release correction `v0.3.1` |
| Local correction diff | ✅ Đã gom vào release correction `v0.3.1+23` |

---

## 2. Vướng mắc đã phát hiện

### A-001 — Version báo lỗi còn hardcode `0.2.13`

- Mức độ: **High**
- File: `/Volumes/DATA/DEV/MOBILES/beong/lib/features/settings/bao_loi_screen.dart`
- Dòng liên quan: `kPhienBanApp`
- Triệu chứng test:
  - Test fail: `test/unit/core/bao_cao_loi_test.dart: phiên bản trên báo cáo khớp với pubspec.yaml`
  - Expected: `0.3.0`
  - Actual: `0.2.13`
- Tác động:
  - Báo cáo lỗi gửi về đội dev hiển thị sai version app.
  - Khi debug crash/feedback sau release sẽ dễ truy vết nhầm bản build.
- Fix local đã áp dụng:
  - Đổi `const kPhienBanApp = '0.2.13';` thành `const kPhienBanApp = '0.3.0';`
- Trạng thái: ✅ Đã sửa local, test focused pass.

---

### A-002 — Thiếu tooltip cho 3 `IconButton`

- Mức độ: **Medium**
- Test fail: `test/unit/kha_dung_test.dart: mọi IconButton đều có tooltip`
- File liên quan:
  - `/Volumes/DATA/DEV/MOBILES/beong/lib/core/widgets/icon_picker.dart`
  - `/Volumes/DATA/DEV/MOBILES/beong/lib/features/parent_home/child_history_sheet.dart`
  - `/Volumes/DATA/DEV/MOBILES/beong/lib/features/parent_home/parent_home_screen.dart`
- Tác động:
  - Không đạt checklist accessibility nội bộ.
  - Người dùng dùng screen reader hoặc long-press tooltip không biết nút đóng làm gì.
- Fix local đã áp dụng:
  - Thêm `tooltip: 'Đóng'` cho các nút đóng còn thiếu.
- Trạng thái: ✅ Đã sửa local, test focused pass.

---

### A-003 — Remote đang lệch Git policy AIaC

- Mức độ: **Medium**
- Hiện trạng:
  - `origin` = GitHub: `git@github.com:360org/beong.git`
  - `gitlab` = GitLab: `git@gitlab.com:360org_mobiles/beong.git`
  - Branch `main` đang tracking `origin/main`.
  - GitLab hiện trong log gần nhất mới thấy `gitlab/main` ở `v0.2.11`, chưa có `v0.3.0`.
- Tác động:
  - Lệch rule AIaC: mặc định phải ưu tiên GitLab private, không tự push GitHub nếu không có yêu cầu rõ.
  - Release mới có thể chỉ nằm trên GitHub, GitLab private chưa đồng bộ.
- Fix đề xuất:
  1. Push correction lên GitLab trước.
  2. Nếu Sếp vẫn muốn GitHub là mirror/public thì push GitHub sau bằng quy trình gitsync chuẩn.
- Trạng thái: ⚠️ Chưa sửa remote/push vì cần thao tác outward-facing sau audit.

---

## 3. Kiểm tra bảo mật

### Secret scan

Đã scan tracked text files, kết quả:

- ✅ Không phát hiện secret rõ ràng trong tracked files.
- ✅ Các file key thật trong `/Volumes/DATA/DEV/MOBILES/beong/certs/` đang bị `.gitignore` chặn.
- ✅ `/Volumes/DATA/DEV/MOBILES/beong/supabase/functions/notify-fcm/index.ts` chỉ chứa logic parse PEM từ biến môi trường/service account, không chứa private key thật trong code.

Lưu ý: release commit `7a6beeb` có include `/Volumes/DATA/DEV/MOBILES/beong/.claude/aiac/sessions/last-compact.json`. Chưa thấy secret qua scan, nhưng đây là file session runtime; nên cân nhắc không đưa vào correction commit nếu không cần.

---

## 4. Bằng chứng kiểm thử sau fix local

```bash
flutter analyze --no-pub
```

Kết quả: `No issues found!`

```bash
flutter test --no-pub --reporter=compact
```

Kết quả: `00:31 +523: All tests passed!`

Focused tests đã pass:

```bash
flutter test --no-pub test/unit/core/bao_cao_loi_test.dart test/unit/kha_dung_test.dart --reporter=compact
```

Kết quả: `All tests passed!`

---

## 5. Diff fix audit hiện còn local

Các file nên commit trong correction:

- `/Volumes/DATA/DEV/MOBILES/beong/lib/features/settings/bao_loi_screen.dart`
- `/Volumes/DATA/DEV/MOBILES/beong/lib/core/widgets/icon_picker.dart`
- `/Volumes/DATA/DEV/MOBILES/beong/lib/features/parent_home/child_history_sheet.dart`
- `/Volumes/DATA/DEV/MOBILES/beong/lib/features/parent_home/parent_home_screen.dart`

File **không nên commit nếu chỉ fix audit**:

- `/Volumes/DATA/DEV/MOBILES/beong/.claude/aiac/sessions/last-compact.json`

---

## 6. Checklist fix đề xuất

- [x] Sửa version báo lỗi `kPhienBanApp` từ `0.2.13` lên `0.3.0`.
- [x] Thêm tooltip cho nút đóng modal chọn icon.
- [x] Thêm tooltip cho nút đóng modal lịch sử con.
- [x] Thêm tooltip cho nút đóng dialog xem ảnh chứng thực.
- [x] Chạy `flutter analyze --no-pub`.
- [x] Chạy focused tests cho 2 lỗi audit.
- [x] Chạy full `flutter test --no-pub --reporter=compact`.
- [ ] Commit correction fix audit.
- [ ] Push correction lên GitLab/GitHub theo policy Sếp chọn.
- [ ] Nếu cần tag mới: tạo `v0.3.1` hoặc `v0.3.0+23` thay vì sửa tag cũ.

---

## 7. Lệnh fix/ship đề xuất

Commit correction tối thiểu:

```bash
git add lib/features/settings/bao_loi_screen.dart lib/core/widgets/icon_picker.dart lib/features/parent_home/child_history_sheet.dart lib/features/parent_home/parent_home_screen.dart docs/AUDIT_RELEASE_V0.3.0_FIX_REPORT.md
git commit -m "fix: audit release v0.3.0 test regressions

- Sync bug report version with pubspec v0.3.0
- Add missing IconButton tooltips for accessibility tests
- Add release audit report

Authored-By: 360org <support@360.org.vn>"
```

Push đúng policy GitLab private:

```bash
git push gitlab main
```

Nếu Sếp muốn đồng bộ GitHub sau đó:

```bash
git push origin main
```

Tag đề xuất nếu cần release correction mới:

```bash
git tag -a v0.3.1 -m "Release v0.3.1"
```

```bash
git push gitlab v0.3.1
```

---

## 8. Khuyến nghị Ponytail

Không sửa tag `v0.3.0` đã push. Cách ít rủi ro nhất là tạo **commit correction nhỏ** và nếu cần release store/build mới thì phát hành tag mới `v0.3.1` hoặc build `0.3.0+23`.
