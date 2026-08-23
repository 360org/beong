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

  /// Đi hết onboarding: tên nhà → tên bé → một thói quen → mật khẩu hai hồ sơ.
  ///
  /// Bước mật khẩu là **bắt buộc** từ ADR-027, và nó cũng là chỗ đã từng sai
  /// theo cách không test nào cũ bắt được: bản đầu gọi `login()` trước, session
  /// đổi thì router đá ngay khỏi onboarding, màn unmount, và cả vòng đặt mật
  /// khẩu bị nuốt trong im lặng — onboarding chạy xong với hai hồ sơ
  /// `pin_hash = NULL`. Vì vậy helper này **luôn** kết thúc bằng
  /// [khongHoSoNaoTrongMatKhau].
  Future<void> xongOnboarding(
    WidgetTester tester, {
    String tenNha = 'Nhà Bé Ong',
    String tenBe = 'Minh',
  }) async {
    await tester.enterText(find.byType(TextField).first, tenNha);
    await settle(tester);
    await tapText(tester, 'TIẾP TỤC');

    await tester.enterText(find.byType(TextField).first, tenBe);
    await settle(tester);
    await tapText(tester, 'TIẾP TỤC');

    // Không chọn thói quen nào thì nhà mới không có việc, và các test sau không
    // có gì để bấm.
    await tapText(tester, 'Buổi sáng');
    await tapText(tester, 'BẮT ĐẦU');

    // Hai sheet mật khẩu bắt buộc, đúng thứ tự onboarding tạo hồ sơ.
    for (final (ten, matKhau) in [('Bố mẹ', '1111'), (tenBe, '2222')]) {
      expect(
        find.text('Đặt mật khẩu cho $ten'),
        findsOneWidget,
        reason: 'ADR-027: onboarding phải bắt đặt mật khẩu cho $ten',
      );
      await tester.enterText(find.byType(TextField).last, matKhau);
      await settle(tester);
    }
  }

  /// ADR-027: không hồ sơ nào được để trống mật khẩu.
  Future<void> khongHoSoNaoTrongMatKhau() async {
    final trong = (await db.select(db.members).get())
        .where((m) => (m.pinHash ?? '').isEmpty)
        .map((m) => m.displayName)
        .toList();
    expect(trong, isEmpty, reason: 'hồ sơ chưa có mật khẩu: $trong');
  }

  testWidgets('onboarding tạo được gia đình và vào thẳng màn chính', (
    tester,
  ) async {
    await pumpApp(tester);

    // Chưa có session thì router đẩy về onboarding.
    expect(find.text('Đặt tên gia đình'), findsOneWidget);

    await xongOnboarding(tester);

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

    await khongHoSoNaoTrongMatKhau();
  });

  testWidgets('con bấm xong việc thì xu vào ví ngay', (tester) async {
    await pumpApp(tester);

    await xongOnboarding(tester);

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

  testWidgets('bấm xong việc thì danh sách không bị xé đi dựng lại', (
    tester,
  ) async {
    // "Bấm hoàn thành nhiệm vụ bị giật cục" — chủ dự án báo 23/08.
    //
    // Nguyên nhân: cả bốn luồng của màn hình con được tạo mới ngay trong
    // `build()`, mà Drift trả `Stream` mới mỗi lần gọi. `StreamBuilder` so sánh
    // theo danh tính đối tượng nên huỷ đăng ký rồi đăng ký lại, và quay về
    // `ConnectionState.waiting` với `data == null` — danh sách việc bị thay
    // bằng vòng xoay. Mỗi cú chạm lại `setState` hai lần để nổ hoa giấy, nên
    // mỗi lần bấm là hai lần xé cả danh sách đi dựng lại.
    //
    // Test canh đúng triệu chứng người dùng thấy, không canh cách sửa: **ngay
    // khung hình sau cú chạm**, danh sách phải còn nguyên và không có vòng
    // xoay nào.
    await pumpApp(tester);
    await xongOnboarding(tester);

    final child = (await db.select(db.members).get()).firstWhere(
      (m) => m.kind == MemberKind.child.name,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BeOngApp)),
    );
    await container
        .read(sessionProvider.notifier)
        .switchMember(child.id, isParent: false);
    await settle(tester);

    final soThe = tester.widgetList(find.byType(TaskCard)).length;
    expect(soThe, greaterThan(1), reason: 'cần vài việc mới thấy được cú giật');

    await tester.tap(find.byType(TaskCard).first);
    // **Một** khung hình, không `settle`: `settle` chạy tới lúc mọi thứ yên
    // nên nó nuốt mất đúng cái nháy cần bắt.
    await tester.pump();

    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'danh sách không được nháy thành vòng xoay sau mỗi cú chạm',
    );
    expect(
      tester.widgetList(find.byType(TaskCard)).length,
      soThe,
      reason: 'các thẻ khác phải đứng yên, không bị tháo rồi dựng lại',
    );

    await settle(tester);
    await khongHoSoNaoTrongMatKhau();
  });

  testWidgets('đổi phần thưởng phải qua bố mẹ duyệt (ADR-025)', (tester) async {
    await pumpApp(tester);

    await xongOnboarding(tester);

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
