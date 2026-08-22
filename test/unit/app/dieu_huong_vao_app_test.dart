import 'package:beong/app/router.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ba trạng thái vào app, không phải hai.
///
/// Lỗi §2 trong `docs/13-audit-luong-vao-app.md` gói gọn ở một dòng:
/// `if (session == null && !isOnboarding) return Routes.onboarding;` —
/// `session == null` bị hiểu là "máy này chưa có gì", trong khi nó cũng có thể
/// là "máy đủ dữ liệu, chỉ chưa chọn ai đang dùng". Hai trạng thái khác hẳn
/// nhau dùng chung một nhánh, nên bấm KHOÁ LẠI là rơi vào onboarding và tạo ra
/// gia đình thứ hai.
///
/// Bảng dưới đây chính là ràng buộc đó, viết ra để nó không lặng lẽ quay lại.
void main() {
  const boMe = AppSession(familyId: 'f1', activeMemberId: 'm1');
  const con = AppSession(
    familyId: 'f1',
    activeMemberId: 'm2',
    isParent: false,
  );

  group('máy trống', () {
    test('chưa chọn ai → onboarding', () {
      expect(
        diemDenDauTien(
          session: null,
          mayDaCoDuLieu: false,
          viTri: Routes.home,
        ),
        Routes.onboarding,
      );
    });

    test('đang ở onboarding thì để yên', () {
      expect(
        diemDenDauTien(
          session: null,
          mayDaCoDuLieu: false,
          viTri: Routes.onboarding,
        ),
        isNull,
      );
    });
  });

  group('máy đã có dữ liệu', () {
    test('chưa chọn ai → màn chọn người dùng, KHÔNG phải onboarding', () {
      expect(
        diemDenDauTien(
          session: null,
          mayDaCoDuLieu: true,
          viTri: Routes.home,
        ),
        Routes.chonNguoiDung,
      );
    });

    test('onboarding cũng bị đẩy về màn chọn người dùng', () {
      // Đây là chỗ dữ liệu cũ thành mồ côi: onboarding chỉ biết tạo nhà mới.
      expect(
        diemDenDauTien(
          session: null,
          mayDaCoDuLieu: true,
          viTri: Routes.onboarding,
        ),
        Routes.chonNguoiDung,
      );
    });

    test('cố ý tạo nhà mới thì vào được onboarding', () {
      // Chặn sạch đường vào onboarding là đổi cái bẫy này lấy cái bẫy khác:
      // nhà muốn làm lại từ đầu sẽ kẹt vĩnh viễn với dữ liệu cũ. Đường ra có,
      // nhưng phải nói rõ ý định — và onboarding còn hỏi lại trước khi ghi.
      expect(
        diemDenDauTien(
          session: null,
          mayDaCoDuLieu: true,
          viTri: Routes.onboarding,
          xinTaoNhaMoi: true,
        ),
        isNull,
      );
    });

    test('đường tạo nhà mới mang đúng tham số router đọc', () {
      // Hằng số và chỗ đọc phải khớp nhau; lệch một chữ thì nút im lặng không
      // làm gì, và không test nào bắt được.
      final uri = Uri.parse(Routes.taoNhaMoi);
      expect(uri.path, Routes.onboarding);
      expect(uri.queryParameters[Routes.thamSoTaoNhaMoi], '1');
    });

    test('đang ở màn chọn người dùng thì để yên', () {
      expect(
        diemDenDauTien(
          session: null,
          mayDaCoDuLieu: true,
          viTri: Routes.chonNguoiDung,
        ),
        isNull,
      );
    });
  });

  group('đã chọn người dùng', () {
    test('trang chính thì để yên', () {
      expect(
        diemDenDauTien(
          session: boMe,
          mayDaCoDuLieu: true,
          viTri: Routes.home,
        ),
        isNull,
      );
    });

    test('quay lại onboarding hay màn chọn đều về trang chính', () {
      for (final viTri in [Routes.onboarding, Routes.chonNguoiDung]) {
        expect(
          diemDenDauTien(
            session: boMe,
            mayDaCoDuLieu: true,
            viTri: viTri,
          ),
          Routes.home,
          reason: viTri,
        );
      }
    });

    test('vai con vẫn không vào được Cài đặt', () {
      for (final viTri in [
        Routes.settings,
        Routes.penaltySettings,
        Routes.jarSettings,
      ]) {
        expect(
          diemDenDauTien(
            session: con,
            mayDaCoDuLieu: true,
            viTri: viTri,
          ),
          Routes.home,
          reason: viTri,
        );
      }
    });

    test('vai bố mẹ vào Cài đặt bình thường', () {
      expect(
        diemDenDauTien(
          session: boMe,
          mayDaCoDuLieu: true,
          viTri: Routes.settings,
        ),
        isNull,
      );
    });

    test('màn chọn người dùng không bị nhầm là trang con của Cài đặt', () {
      // `startsWith` là con dao hai lưỡi: thêm đường dẫn mới mà vô tình trùng
      // tiền tố thì vai con bị đá về trang chính không rõ lý do.
      expect(Routes.chonNguoiDung.startsWith(Routes.settings), isFalse);
    });
  });
}
