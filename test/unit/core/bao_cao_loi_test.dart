import 'dart:convert';
import 'dart:io';

import 'package:beong/core/diagnostics/bao_cao_loi.dart';
import 'package:beong/core/diagnostics/gui_bao_cao.dart';
import 'package:beong/core/diagnostics/nhat_ky_loi.dart';
import 'package:beong/features/settings/bao_loi_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Báo cáo lỗi người dùng gửi cho nhà phát triển.
void main() {
  ThongTinThietBi thietBi() => ThongTinThietBi.thuThap(
    phienBanApp: '0.2.1',
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
      expect(than, contains('0.2.1'));
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

  group('gói gửi lên máy chủ', () {
    test('mang đủ tiêu đề, thân và thông tin bản dựng', () async {
      final goi = await taoGoiGui(baoCao());

      expect(goi['tieu_de'], 'Bấm xong việc mà xu không cộng');
      expect(goi['than'], contains('### Thiết bị'));
      expect(goi['phien_ban_app'], '0.2.1');
      expect(goi['he_dieu_hanh'], Platform.operatingSystem);
    });

    test('không có ảnh thì không có khoá ảnh', () async {
      expect(
        (await taoGoiGui(baoCao())).containsKey('anh_png_base64'),
        isFalse,
      );
    });

    test('ảnh đọc hỏng thì vẫn gửi được, chỉ là không kèm ảnh', () async {
      // Mất ảnh còn hơn mất cả báo cáo.
      final goi = await taoGoiGui(baoCao(anh: '/khong/ton/tai.png'));

      expect(goi.containsKey('anh_png_base64'), isFalse);
      expect(goi['than'], isNotEmpty);
    });

    test('ảnh có thật thì đi kèm dạng base64', () async {
      final file = File(
        p.join(Directory.systemTemp.path, 'beong-test-anh.png'),
      )..writeAsBytesSync([1, 2, 3, 4]);
      addTearDown(file.deleteSync);

      final goi = await taoGoiGui(baoCao(anh: file.path));
      expect(goi['anh_png_base64'], base64Encode([1, 2, 3, 4]));
    });
  });

  group('gửi', () {
    const diaChi = 'https://vi-du.test/bao-loi';

    test('bản dựng chưa cấu hình endpoint thì báo đúng như vậy', () async {
      // Không lẫn với `that`: hai ca cần hai cách xử lý khác hẳn nhau — một cái
      // mở đường dự phòng, một cái hiện nút thử lại.
      expect(
        kEndpointBaoCao,
        isEmpty,
        reason: 'test chạy không có dart-define',
      );
      expect(await guiBaoCao(baoCao()), KetQuaGui.chuaCauHinh);
    });

    test('máy chủ nhận (2xx) là thành công', () async {
      for (final ma in [200, 201, 204]) {
        final ketQua = await guiBaoCao(
          baoCao(),
          endpoint: diaChi,
          client: MockClient((_) async => http.Response('', ma)),
        );
        expect(ketQua, KetQuaGui.thanhCong, reason: 'mã $ma');
      }
    });

    test('máy chủ từ chối hoặc hỏng là thất bại', () async {
      for (final ma in [400, 401, 429, 500, 502]) {
        final ketQua = await guiBaoCao(
          baoCao(),
          endpoint: diaChi,
          client: MockClient((_) async => http.Response('lỗi', ma)),
        );
        expect(ketQua, KetQuaGui.that, reason: 'mã $ma');
      }
    });

    test('mất mạng là thất bại, không ném ra ngoài', () async {
      // Màn báo lỗi mà tự nó ném lỗi thì người dùng hết đường.
      final ketQua = await guiBaoCao(
        baoCao(),
        endpoint: diaChi,
        client: MockClient((_) async => throw const SocketException('rớt')),
      );
      expect(ketQua, KetQuaGui.that);
    });

    test('gửi đúng JSON lên đúng địa chỉ, chữ tiếng Việt nguyên vẹn', () async {
      Map<String, Object?>? nhanDuoc;
      Uri? diaChiNhan;

      await guiBaoCao(
        baoCao(moTa: 'Xu không cộng lên'),
        endpoint: diaChi,
        client: MockClient((req) async {
          diaChiNhan = req.url;
          nhanDuoc =
              jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, Object?>;
          return http.Response('', 201);
        }),
      );

      expect(diaChiNhan.toString(), diaChi);
      expect(nhanDuoc!['tieu_de'], 'Xu không cộng lên');
      // Gửi sai bảng mã thì báo cáo lên tới nơi thành một mớ dấu hỏi.
      expect(nhanDuoc!['than'], contains('Xu không cộng lên'));
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
