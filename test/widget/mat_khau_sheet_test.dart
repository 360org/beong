import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/mat_khau_ho_so.dart';
import 'package:beong/features/members/mat_khau_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sheet nhập / đặt mật khẩu hồ sơ.
///
/// Test dịch vụ ở `test/unit/domain/mat_khau_ho_so_test.dart` đã canh phần
/// đúng/sai. Chỗ này canh phần **người dùng nhìn thấy**, và ba ràng buộc của
/// ADR-027 mà chỉ giao diện mới giữ được:
///
/// 1. Gõ sai phải hiện chữ báo sai — đã có lúc `clear()` chạy listener và tắt
///    luôn chữ đỏ vừa bật, nên nhập sai mà màn hình không nói gì cả.
/// 2. Bước **bắt buộc** không được có đường thoát, nếu không "không hồ sơ nào
///    để trống" chỉ là nói suông.
/// 3. "Quên mật khẩu?" phải **đổi**, không **gỡ** — gỡ là để lại hồ sơ trống,
///    tức vi phạm chính ADR-027.
void main() {
  late AppDatabase db;
  late MemberDao memberDao;
  late MatKhauHoSo service;

  const familyId = 'fam-1';
  const minh = 'con-1';

  setUp(() async {
    db = AppDatabase.memory();
    memberDao = MemberDao(db);
    service = MatKhauHoSo(memberDao: memberDao);

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
    );
    await memberDao.addMember(
      MembersCompanion.insert(
        id: minh,
        familyId: familyId,
        kind: MemberKind.child.name,
        displayName: 'Minh',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// Dựng màn hình chỉ có một nút mở sheet, ghi lại kết quả sheet trả về.
  Future<List<bool?>> pump(
    WidgetTester tester, {
    required Future<bool> Function(BuildContext context) moSheet,
  }) async {
    final ketQua = <bool?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => ketQua.add(await moSheet(context)),
              child: const Text('mở'),
            ),
          ),
        ),
      ),
    );
    return ketQua;
  }

  Future<List<bool?>> pumpHoi(WidgetTester tester) => pump(
    tester,
    moSheet: (context) => hoiMatKhau(
      context,
      memberId: minh,
      tenHienThi: 'Minh',
      service: service,
    ),
  );

  Future<void> mo(WidgetTester tester) async {
    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
  }

  group('nhập mật khẩu', () {
    testWidgets('hồ sơ chưa đặt thì không hiện sheet, cho qua luôn', (
      tester,
    ) async {
      final ketQua = await pumpHoi(tester);
      await mo(tester);

      expect(find.text('Mật khẩu của Minh'), findsNothing);
      expect(ketQua, [true]);
    });

    testWidgets('gõ đúng thì đóng sheet và trả true', (tester) async {
      await service.dat(memberId: minh, matKhau: '1357');
      final ketQua = await pumpHoi(tester);
      await mo(tester);

      expect(find.text('Mật khẩu của Minh'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '1357');
      await tester.pumpAndSettle();

      expect(ketQua, [true]);
    });

    testWidgets('gõ sai thì hiện chữ báo sai và giữ sheet lại', (tester) async {
      await service.dat(memberId: minh, matKhau: '1357');
      final ketQua = await pumpHoi(tester);
      await mo(tester);

      await tester.enterText(find.byType(TextField), '9999');
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu chưa đúng, thử lại nhé'), findsOneWidget);
      expect(find.text('Mật khẩu của Minh'), findsOneWidget);
      expect(ketQua, isEmpty);
    });

    testWidgets('gõ lại sau khi sai thì chữ báo sai biến mất', (tester) async {
      await service.dat(memberId: minh, matKhau: '1357');
      await pumpHoi(tester);
      await mo(tester);

      await tester.enterText(find.byType(TextField), '9999');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1');
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu chưa đúng, thử lại nhé'), findsNothing);
    });

    testWidgets('bấm HUỶ thì trả false', (tester) async {
      await service.dat(memberId: minh, matKhau: '1357');
      final ketQua = await pumpHoi(tester);
      await mo(tester);

      await tester.tap(find.text('HUỶ'));
      await tester.pumpAndSettle();

      expect(ketQua, [false]);
    });
  });

  group('quên mật khẩu', () {
    testWidgets('màn nhập có đường "Quên mật khẩu?"', (tester) async {
      await service.dat(memberId: minh, matKhau: '1357');
      await pumpHoi(tester);
      await mo(tester);

      expect(find.text('Quên mật khẩu?'), findsOneWidget);
    });

    testWidgets('đặt lại xong thì vào được ngay, và hồ sơ KHÔNG bị bỏ trống', (
      tester,
    ) async {
      await service.dat(memberId: minh, matKhau: '1357');
      final ketQua = await pumpHoi(tester);
      await mo(tester);

      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ĐẶT LẠI'));
      await tester.pumpAndSettle();

      // Đây là chỗ dễ làm sai nhất: gỡ mật khẩu thì cũng "thoát" được, nhưng để
      // lại hồ sơ trống — vi phạm ADR-027 và mở hồ sơ của bé cho bất kỳ ai.
      expect(find.text('Đặt mật khẩu cho Minh'), findsOneWidget);

      // Sheet *nhập* vẫn còn nằm dưới sheet *đặt*, nên có hai ô nhập trên cây.
      // Gõ vào ô trên cùng — route đẩy sau nằm sau trong cây widget.
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).last, '2468');
      await tester.pumpAndSettle();

      expect(ketQua, [true], reason: 'đặt xong là vào luôn');
      expect(await service.daDat(minh), isTrue, reason: 'không được để trống');
      expect(await service.dung(memberId: minh, matKhau: '2468'), isTrue);
      expect(await service.dung(memberId: minh, matKhau: '1357'), isFalse);
    });

    testWidgets('bấm THÔI thì mật khẩu cũ còn nguyên', (tester) async {
      await service.dat(memberId: minh, matKhau: '1357');
      final ketQua = await pumpHoi(tester);
      await mo(tester);

      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('THÔI'));
      await tester.pumpAndSettle();

      expect(await service.dung(memberId: minh, matKhau: '1357'), isTrue);
      expect(ketQua, isEmpty, reason: 'chưa trả kết quả nào, sheet còn mở');
      expect(find.text('Mật khẩu của Minh'), findsOneWidget);
    });
  });

  group('đặt mật khẩu', () {
    Future<List<bool?>> pumpDat(WidgetTester tester, {required bool batBuoc}) =>
        pump(
          tester,
          moSheet: (context) => datMatKhauMoi(
            context,
            memberId: minh,
            tenHienThi: 'Minh',
            service: service,
            batBuoc: batBuoc,
          ),
        );

    testWidgets('sheet đặt không có "Quên mật khẩu?" — chưa có gì để quên', (
      tester,
    ) async {
      await pumpDat(tester, batBuoc: false);
      await mo(tester);

      expect(find.text('Quên mật khẩu?'), findsNothing);
    });

    testWidgets('nói trước cách gỡ khi quên', (tester) async {
      await pumpDat(tester, batBuoc: false);
      await mo(tester);

      expect(
        find.textContaining('Quên thì đặt lại được ngay trên máy'),
        findsOneWidget,
      );
    });

    testWidgets('bước bắt buộc KHÔNG có nút HUỶ', (tester) async {
      // Một cái nút HUỶ ở đây là đủ để "không hồ sơ nào để trống" thành nói
      // suông — và hồ sơ trống thì ai cũng mở được.
      await pumpDat(tester, batBuoc: true);
      await mo(tester);

      expect(find.text('HUỶ'), findsNothing);
    });

    testWidgets('bước không bắt buộc vẫn có HUỶ', (tester) async {
      await pumpDat(tester, batBuoc: false);
      await mo(tester);

      expect(find.text('HUỶ'), findsOneWidget);
    });

    testWidgets('đặt xong thì lưu đúng mật khẩu vừa gõ', (tester) async {
      final ketQua = await pumpDat(tester, batBuoc: true);
      await mo(tester);

      await tester.enterText(find.byType(TextField), '2468');
      await tester.pumpAndSettle();

      expect(ketQua, [true]);
      expect(await service.dung(memberId: minh, matKhau: '2468'), isTrue);
      expect(await service.dung(memberId: minh, matKhau: '1111'), isFalse);
    });
  });
}
