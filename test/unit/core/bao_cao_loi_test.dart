import 'dart:io';

import 'package:beong/core/diagnostics/bao_cao_loi.dart';
import 'package:beong/core/diagnostics/gui_bao_cao.dart';
import 'package:beong/core/diagnostics/nhat_ky_loi.dart';
import 'package:beong/features/settings/bao_loi_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Báo cáo lỗi người dùng gửi lên GitHub.
void main() {
  ThongTinThietBi thietBi() => ThongTinThietBi.thuThap(
    phienBanApp: '0.2.0',
    kichThuocManHinh: const Size(412, 900),
    tyLePhongChu: 1,
  );

  BaoCaoLoi baoCao({
    String moTa = 'Bấm xong việc mà xu không cộng',
    List<MucNhatKy> nhatKy = const [],
    String? anh,
  }) => BaoCaoLoi(
    moTaNguoiDung: moTa,
    thietBi: thietBi(),
    nhatKy: nhatKy,
    duongDanAnh: anh,
  );

  group('vòng đệm nhật ký', () {
    test('giữ đúng sức chứa, lỗi cũ nhất rơi ra trước', () {
      final log = NhatKyLoi(sucChua: 3);
      for (var i = 0; i < 5; i++) {
        log.ghi('lỗi $i');
      }

      expect(log.muc, hasLength(3));
      expect(log.muc.first.moTa, 'lỗi 2');
      expect(log.muc.last.moTa, 'lỗi 4', reason: 'mới nhất nằm cuối');
    });

    test('cắt ngắn thông điệp khổng lồ', () {
      // Một exception có thể mang cả chuỗi JSON hàng chục nghìn ký tự; để
      // nguyên thì báo cáo phình tới mức không dán nổi vào GitHub.
      final log = NhatKyLoi()..ghi('x' * 10000);
      expect(log.muc.single.moTa.length, lessThan(500));
      expect(log.muc.single.moTa, endsWith('(đã cắt bớt)'));
    });

    test('ghi lại được nguồn và stack', () {
      final log = NhatKyLoi()
        ..ghi('bùm', stack: StackTrace.current, nguon: 'flutter');
      expect(log.muc.single.nguon, 'flutter');
      expect(log.muc.single.stack, isNotNull);
    });
  });

  group('thân báo cáo', () {
    test('có đủ mô tả người dùng và thông tin thiết bị', () {
      final than = baoCao().than;

      expect(than, contains('Bấm xong việc mà xu không cộng'));
      expect(than, contains('412×900 dp'));
      expect(than, contains('0.2.0'));
      expect(than, contains(Platform.operatingSystem));
    });

    test('không có lỗi nào thì nói thẳng, không để khối trống', () {
      // Khối trống đọc như phần thu thập bị hỏng, và người xử lý đi tìm nhầm
      // chỗ.
      expect(baoCao().than, contains('Không có lỗi nào được ghi'));
    });

    test('nhật ký hiện theo dòng thời gian', () {
      final log = NhatKyLoi()
        ..ghi('lỗi đầu', nguon: 'flutter')
        ..ghi('lỗi sau', nguon: 'platform');
      final than = baoCao(nhatKy: log.muc).than;

      expect(than.indexOf('lỗi đầu'), lessThan(than.indexOf('lỗi sau')));
    });

    test('chỉ nhắc ảnh khi thật sự có ảnh', () {
      expect(baoCao().than, isNot(contains('Ảnh màn hình')));
      expect(baoCao(anh: '/tmp/a.png').than, contains('Ảnh màn hình'));
    });
  });

  group('tiêu đề', () {
    test('lấy dòng đầu của mô tả', () {
      expect(baoCao(moTa: 'Xu không cộng\nchi tiết…').tieuDe, 'Xu không cộng');
    });

    test('mô tả rỗng vẫn có tiêu đề dùng được', () {
      expect(baoCao(moTa: '   ').tieuDe, 'Báo lỗi từ app');
    });

    test('cắt ngắn tiêu đề quá dài', () {
      final t = baoCao(moTa: 'a' * 200).tieuDe;
      expect(t.length, lessThanOrEqualTo(71));
      expect(t, endsWith('…'));
    });
  });

  group('URL tạo issue', () {
    test('trỏ đúng repo và mang theo tiêu đề, thân, nhãn', () {
      final url = urlTaoIssue(baoCao());

      expect(url.host, 'github.com');
      expect(url.path, '/$kGitHubOwner/$kGitHubRepo/issues/new');
      expect(url.queryParameters['title'], 'Bấm xong việc mà xu không cộng');
      expect(url.queryParameters['body'], contains('### Thiết bị'));
      expect(url.queryParameters['labels'], 'bug,from-app');
    });

    test('URL không vượt trần dù nhật ký dài', () {
      // Đo trên chuỗi **đã mã hoá**: ký tự tiếng Việt nở ra 9 ký tự, đo trên
      // chuỗi gốc là ra URL dài gấp ba trần mà test vẫn xanh.
      final log = NhatKyLoi();
      for (var i = 0; i < 50; i++) {
        log.ghi('Lỗi rất dài với chữ tiếng Việt có dấu ${'đ' * 300}');
      }

      final url = urlTaoIssue(baoCao(nhatKy: log.muc));
      final body = url.queryParameters['body']!;

      expect(Uri.encodeComponent(body).length, lessThanOrEqualTo(6000));
      expect(body, contains('đã bị cắt bớt'));
    });

    test('cắt nhật ký nhưng **giữ nguyên** lời kể của người dùng', () {
      // Log thì tái tạo được, còn câu người ta kể thì không. Cắt nhầm đầu này
      // là mất phần giá trị nhất của cả báo cáo.
      const keChuyen = 'Con bấm xong việc Gấp chăn màn mà xu không cộng lên';
      final log = NhatKyLoi();
      for (var i = 0; i < 50; i++) {
        log.ghi('x' * 400);
      }

      final url = urlTaoIssue(baoCao(moTa: keChuyen, nhatKy: log.muc));
      expect(url.queryParameters['body'], contains(keChuyen));
    });
  });

  group('móc bắt lỗi toàn cục', () {
    late FlutterExceptionHandler? handlerCu;

    setUp(() {
      handlerCu = FlutterError.onError;
      nhatKyLoi.xoa();
    });

    tearDown(() {
      FlutterError.onError = handlerCu;
      nhatKyLoi.xoa();
    });

    test('lỗi Flutter chảy vào nhật ký', () {
      var goiHandlerCu = 0;
      FlutterError.onError = (_) => goiHandlerCu++;
      ganBatLoiToanCuc();

      FlutterError.reportError(
        FlutterErrorDetails(exception: Exception('bùm')),
      );

      expect(nhatKyLoi.muc.single.nguon, 'flutter');
      expect(nhatKyLoi.muc.single.moTa, contains('bùm'));

      // Vẫn phải gọi tiếp handler cũ: nuốt lỗi đi thì bảng đỏ lúc debug và log
      // lúc release đều biến mất — mất đúng thứ đang cố thu thập.
      expect(goiHandlerCu, 1);
    });
  });

  test('phiên bản trên báo cáo khớp với pubspec.yaml', () {
    // `kPhienBanApp` chép tay từ pubspec (để không thêm `package_info_plus`
    // cho đúng một chuỗi). Test này là cái giữ hai chỗ không lệch — báo cáo
    // ghi sai phiên bản thì mọi kết luận từ nó đều sai theo.
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;
    final version = (pubspec['version'] as String).split('+').first;
    expect(kPhienBanApp, version);
  });
}
