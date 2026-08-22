import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/parent_pin_service.dart';
import 'package:beong/features/settings/parent_pin_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Đường thoát khi quên PIN.
///
/// Trước bản này màn nhập PIN chỉ có ô nhập và nút HUỶ. "Đổi PIN" và "Bỏ PIN"
/// nằm bên trong Cài đặt, mà Cài đặt chỉ vai bố mẹ vào được, mà vào vai bố mẹ
/// thì phải qua đúng cái PIN vừa quên. Lối ra duy nhất là gỡ app — tức là mất
/// sạch dữ liệu (`docs/13-audit-luong-vao-app.md` §3).
///
/// Cái giá lệch hẳn: rủi ro là "trẻ mò được vào Cài đặt", hình phạt là "mất hết
/// sổ xu của con".
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

  Future<void> moSheet(WidgetTester tester) async {
    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
  }

  testWidgets('màn nhập PIN có đường "Quên PIN?"', (tester) async {
    await service.setPin(familyId: familyId, pin: '1357');
    await pumpAsker(tester);
    await moSheet(tester);

    expect(find.text('Quên PIN?'), findsOneWidget);
  });

  testWidgets('gỡ PIN qua đường đó thì vào lại vai bố mẹ được ngay', (
    tester,
  ) async {
    await service.setPin(familyId: familyId, pin: '1357');
    final results = await pumpAsker(tester);
    await moSheet(tester);

    await tester.tap(find.text('Quên PIN?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GỠ PIN'));
    await tester.pumpAndSettle();

    // Gỡ xong mà vẫn bắt nhập lại chính cái PIN vừa xoá thì chẳng gỡ được gì.
    expect(results, [true]);
    expect(await service.isSet(familyId), isFalse);
  });

  testWidgets('bấm THÔI thì PIN còn nguyên và sheet vẫn đứng đó', (
    tester,
  ) async {
    await service.setPin(familyId: familyId, pin: '1357');
    final results = await pumpAsker(tester);
    await moSheet(tester);

    await tester.tap(find.text('Quên PIN?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('THÔI'));
    await tester.pumpAndSettle();

    expect(await service.isSet(familyId), isTrue);
    expect(results, isEmpty, reason: 'chưa trả kết quả nào, sheet còn mở');
    expect(find.text('Nhập PIN của bố mẹ'), findsOneWidget);
  });

  testWidgets('màn ĐẶT PIN nói trước cách gỡ khi quên', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await askNewParentPin(
                  context,
                  familyId: familyId,
                  service: service,
                );
              },
              child: const Text('mở'),
            ),
          ),
        ),
      ),
    );
    await moSheet(tester);

    // Nói trước thì không ai hoảng — và cũng không ai tự dựng bẫy cho mình.
    expect(
      find.textContaining('Quên PIN thì gỡ được ngay trên máy này'),
      findsOneWidget,
    );
  });

  testWidgets('sheet ĐẶT PIN không có "Quên PIN?" — chưa có gì để quên', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await askNewParentPin(
                  context,
                  familyId: familyId,
                  service: service,
                );
              },
              child: const Text('mở'),
            ),
          ),
        ),
      ),
    );
    await moSheet(tester);

    expect(find.text('Quên PIN?'), findsNothing);
  });
}
