import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/parent_pin_service.dart';
import 'package:beong/features/settings/parent_pin_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sheet nhập PIN.
///
/// Test dịch vụ ở `test/unit/domain/parent_pin_test.dart` đã canh phần đúng/sai
/// của PIN. Chỗ này canh phần **người dùng nhìn thấy**: gõ sai thì phải hiện
/// chữ báo sai. Đã có lúc `clear()` ô nhập chạy listener và tắt luôn chữ đỏ vừa
/// bật, nên nhập sai mà màn hình không nói gì cả — chỉ thấy ô trống.
void main() {
  late AppDatabase db;
  late MemberDao memberDao;
  late ParentPinService service;

  const familyId = 'fam-1';

  setUp(() async {
    db = AppDatabase.memory();
    memberDao = MemberDao(db);
    service = ParentPinService(memberDao: memberDao);

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
    );
    await memberDao.addMember(
      MembersCompanion.insert(
        id: 'bo-me-1',
        familyId: familyId,
        kind: MemberKind.parent.name,
        displayName: 'Bố mẹ',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// Dựng một màn hình chỉ có nút mở sheet, và ghi lại kết quả sheet trả về.
  Future<List<bool?>> pumpAsker(WidgetTester tester) async {
    final results = <bool?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                results.add(
                  await askParentPin(
                    context,
                    familyId: familyId,
                    service: service,
                  ),
                );
              },
              child: const Text('mở'),
            ),
          ),
        ),
      ),
    );
    return results;
  }

  testWidgets('nhà chưa đặt PIN thì không hiện sheet, cho qua luôn', (
    tester,
  ) async {
    final results = await pumpAsker(tester);

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();

    expect(find.text('Nhập PIN của bố mẹ'), findsNothing);
    expect(results, [true]);
  });

  testWidgets('gõ đúng PIN thì đóng sheet và trả true', (tester) async {
    await service.setPin(familyId: familyId, pin: '1357');
    final results = await pumpAsker(tester);

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập PIN của bố mẹ'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1357');
    await tester.pumpAndSettle();

    expect(find.text('Nhập PIN của bố mẹ'), findsNothing);
    expect(results, [true]);
  });

  testWidgets('gõ sai PIN thì hiện chữ báo sai và giữ sheet lại', (
    tester,
  ) async {
    await service.setPin(familyId: familyId, pin: '1357');
    final results = await pumpAsker(tester);

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9999');
    await tester.pumpAndSettle();

    expect(
      find.text('PIN chưa đúng, thử lại nhé'),
      findsOneWidget,
      reason: 'nhập sai mà màn hình im lặng thì người ta tưởng máy đơ',
    );
    expect(find.text('Nhập PIN của bố mẹ'), findsOneWidget);
    expect(results, isEmpty, reason: 'sai thì chưa trả kết quả gì cả');

    // Ô đã được xoá sẵn để gõ lại ngay, không phải tự xoá bằng tay.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '',
    );
  });

  testWidgets('gõ lại sau khi sai thì chữ báo sai biến mất', (tester) async {
    await service.setPin(familyId: familyId, pin: '1357');
    await pumpAsker(tester);

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9999');
    await tester.pumpAndSettle();
    expect(find.text('PIN chưa đúng, thử lại nhé'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1');
    await tester.pumpAndSettle();
    expect(find.text('PIN chưa đúng, thử lại nhé'), findsNothing);
  });

  testWidgets('bấm HUỶ thì trả false', (tester) async {
    await service.setPin(familyId: familyId, pin: '1357');
    final results = await pumpAsker(tester);

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('HUỶ'));
    await tester.pumpAndSettle();

    expect(results, [false]);
  });
}
