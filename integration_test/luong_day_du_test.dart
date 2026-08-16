import 'package:beong/app/app.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/widgets/task_card.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Luồng đầy đủ, chạy trên **app thật**: onboarding → con làm việc → xu vào ví
/// → đổi phần thưởng → bố mẹ duyệt.
///
/// Khác với test widget lẻ ở `test/widget/`: chỗ này dựng nguyên `BeOngApp` với
/// router thật, nên nó bắt được đúng loại lỗi mà test lẻ không thấy — màn hình
/// không điều hướng tới nơi, provider chưa nối, dữ liệu ghi một chỗ đọc một chỗ
/// khác. Phần lớn lỗi thật của dự án này đều được tìm ra bằng cách *chạy app và
/// nhìn*, và đây là bản tự động của việc đó.
///
/// DB thay bằng bản in-memory: chạy trên máy thật thì test sẽ ghi đè dữ liệu
/// gia đình thật trong `beong.sqlite`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  /// `pumpAndSettle` với trần thời gian ngắn.
  ///
  /// Mặc định của Flutter là 10 phút; một animation lặp vô hạn sẽ treo cả lượt
  /// chạy CI mà không nói gì. Mười giây là quá đủ cho mọi chuyển màn của app
  /// này, và hết giờ thì ta có ngay stack trace chỉ đúng chỗ.
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const BeOngApp(),
      ),
    );
    await settle(tester);
  }

  /// Bấm nút có nhãn [label], cuộn tới nếu nó nằm ngoài vùng nhìn thấy.
  ///
  /// Báo lỗi bằng chính nhãn thay vì để `tap` ném "Bad state: No element":
  /// thông báo mặc định không nói nhãn nào không tìm thấy, mà một luồng dài
  /// như đây thì đó là thứ duy nhất cần biết.
  Future<void> tapText(WidgetTester tester, String label) async {
    final finder = find.text(label);
    if (finder.evaluate().isEmpty) {
      final visible = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      fail('Không thấy "$label". Chữ đang có trên màn: $visible');
    }
    await tester.ensureVisible(finder.first);
    await settle(tester);
    await tester.tap(finder.first);
    await settle(tester);
  }

  testWidgets('onboarding tạo được gia đình và vào thẳng màn chính', (
    tester,
  ) async {
    await pumpApp(tester);

    // Chưa có session thì router đẩy về onboarding.
    expect(find.text('Đặt tên gia đình'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Nhà Bé Ong');
    await settle(tester);
    await tapText(tester, 'TIẾP TỤC');

    expect(find.text('Thêm bé'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Minh');
    await settle(tester);
    await tapText(tester, 'TIẾP TỤC');

    // Bước cuối: chọn một thói quen rồi bắt đầu. Không chọn gì thì nhà mới
    // không có việc nào, và các test sau không có gì để bấm.
    await tapText(tester, 'Buổi sáng');
    await tapText(tester, 'BẮT ĐẦU');

    // Gia đình và hai hồ sơ đã nằm trong DB thật.
    final members = await db.select(db.members).get();
    expect(members, hasLength(2));
    expect(
      members.where((m) => m.kind == MemberKind.child.name).single.displayName,
      'Minh',
    );

    // Ba hũ mặc định phải có hàng thật trong bảng `jars`: không gieo thì màn
    // quản lý hũ rỗng trong khi Cài đặt vẫn khoe "3 hũ".
    expect(await db.select(db.jars).get(), isNotEmpty);
  });

  testWidgets('con bấm xong việc thì xu vào ví ngay', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField).first, 'Nhà Bé Ong');
    await settle(tester);
    await tapText(tester, 'TIẾP TỤC');
    await tester.enterText(find.byType(TextField).first, 'Minh');
    await settle(tester);
    await tapText(tester, 'TIẾP TỤC');
    await tapText(tester, 'Buổi sáng');
    await tapText(tester, 'BẮT ĐẦU');

    final child = (await db.select(db.members).get()).firstWhere(
      (m) => m.kind == MemberKind.child.name,
    );

    // Đổi sang vai con qua chính session của app, không dựng tay: đây là đường
    // người dùng thật đi, và nó cũng kiểm luôn `switchMember`.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BeOngApp)),
    );
    await container
        .read(sessionProvider.notifier)
        .switchMember(child.id, isParent: false);
    await settle(tester);

    final instances = await db.select(db.taskInstances).get();
    expect(
      instances,
      isNotEmpty,
      reason: 'onboarding xong phải có việc cho hôm nay, không chờ tới mai',
    );

    final before = await WalletDao(db).balanceOf(child.id);
    expect(before.total, 0);

    // Bấm vào **cả thẻ**, không chỉ ô tròn: `TaskCard` bọc toàn bộ trong một
    // `InkWell`, và đó cũng là cách trẻ thật bấm.
    await tester.tap(find.byType(TaskCard).first);
    await settle(tester);

    final after = await WalletDao(db).balanceOf(child.id);
    expect(
      after.total,
      greaterThan(0),
      reason: 'nhà mặc định tắt duyệt (ADR-023) nên xu phải cộng ngay',
    );
  });

  testWidgets('đổi phần thưởng phải qua bố mẹ duyệt (ADR-025)', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField).first, 'Nhà Bé Ong');
    await settle(tester);
    await tapText(tester, 'TIẾP TỤC');
    await tester.enterText(find.byType(TextField).first, 'Minh');
    await settle(tester);
    await tapText(tester, 'TIẾP TỤC');
    await tapText(tester, 'Buổi sáng');
    await tapText(tester, 'BẮT ĐẦU');

    final family = (await db.select(db.families).get()).single;
    final child = (await db.select(db.members).get()).firstWhere(
      (m) => m.kind == MemberKind.child.name,
    );

    // Vốn để đổi thưởng, và một phần thưởng rẻ.
    await WalletDao(db).creditToJarKey(
      familyId: family.id,
      memberId: child.id,
      jarKey: kJarSpend,
      amount: 100,
      reason: TxReason.bonus,
      clientOpId: 'von-test',
    );
    await db
        .into(db.rewards)
        .insert(
          RewardsCompanion.insert(
            id: 'reward-1',
            familyId: family.id,
            title: 'Kem',
            costPoints: 10,
          ),
        );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BeOngApp)),
    );
    await container
        .read(sessionProvider.notifier)
        .switchMember(child.id, isParent: false);
    await settle(tester);

    await tapText(tester, 'Phần thưởng');
    // Nút "Đổi" nằm trên thẻ phần thưởng, bấm tên phần thưởng không đổi gì.
    await tapText(tester, 'Đổi');

    final redemptions = await db.select(db.redemptions).get();
    expect(redemptions, hasLength(1));
    expect(
      redemptions.single.status,
      RedemptionStatus.pending.name,
      reason:
          'ADR-025: mọi lượt đổi đều phải qua bố mẹ, không có đường tự '
          'duyệt',
    );
  });
}
