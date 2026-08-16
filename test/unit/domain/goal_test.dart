import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/goal_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/services/goal_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mục tiêu tiết kiệm.
///
/// Điểm dễ sai nhất không phải phép chia mà là **đo bằng hũ nào**: đo bằng tổng
/// xu thì mục tiêu tự tới đích nhờ số xu con sắp tiêu, và thanh tiến độ tụt
/// xuống mỗi lần con đổi phần thưởng.
void main() {
  late AppDatabase db;
  late GoalDao goals;
  late WalletDao wallet;
  late GoalService service;

  const familyId = 'fam-1';
  const childId = 'con-1';

  setUp(() async {
    db = AppDatabase.memory();
    goals = GoalDao(db);
    wallet = WalletDao(db);
    service = GoalService(goalDao: goals, walletDao: wallet);

    await db
        .into(db.families)
        .insert(FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'));
  });

  tearDown(() async {
    await db.close();
  });

  var opSeq = 0;

  /// Cộng xu thẳng vào một hũ, bỏ qua vòng inbox cho gọn.
  Future<void> credit(String jarKey, int amount) => wallet.creditToJarKey(
    familyId: familyId,
    memberId: childId,
    jarKey: jarKey,
    amount: amount,
    reason: TxReason.taskApproved,
    clientOpId: 'op-${opSeq++}',
  );

  group('đặt mục tiêu', () {
    test('mục tiêu rỗng hoặc 0 xu bị từ chối', () async {
      expect(
        () => goals.setGoal(
          familyId: familyId,
          memberId: childId,
          title: '   ',
          targetXu: 100,
        ),
        throwsA(isA<GoalException>()),
      );
      expect(
        () => goals.setGoal(
          familyId: familyId,
          memberId: childId,
          title: 'Xe đạp',
          targetXu: 0,
        ),
        throwsA(isA<GoalException>()),
      );
    });

    test('đặt mục tiêu mới thì mục tiêu cũ thành bỏ dở, không có hai cái '
        'cùng chạy', () async {
      await goals.setGoal(
        familyId: familyId,
        memberId: childId,
        title: 'Xe đạp',
        targetXu: 500,
      );
      await goals.setGoal(
        familyId: familyId,
        memberId: childId,
        title: 'Lego',
        targetXu: 300,
      );

      final active = await goals.activeGoal(childId);
      expect(active?.title, 'Lego');

      final all = await db.select(db.savingsGoals).get();
      expect(all, hasLength(2), reason: 'giữ lịch sử, không xoá');
      expect(
        all.where((g) => g.status == GoalStatus.active.name),
        hasLength(1),
        reason: 'mỗi trẻ chỉ một mục tiêu đang chạy',
      );
    });

    test('bỏ mục tiêu thì không còn cái nào đang chạy', () async {
      await goals.setGoal(
        familyId: familyId,
        memberId: childId,
        title: 'Xe đạp',
        targetXu: 500,
      );
      await goals.abandonActive(childId);

      expect(await goals.activeGoal(childId), isNull);
    });
  });

  group('tiến độ', () {
    test('chưa đặt mục tiêu thì không có tiến độ nào', () async {
      expect(await service.progressFor(childId), isNull);
    });

    test('đo bằng hũ Để dành, không phải tổng xu', () async {
      await goals.setGoal(
        familyId: familyId,
        memberId: childId,
        title: 'Xe đạp',
        targetXu: 100,
      );
      await credit(kJarSpend, 90);
      await credit(kJarSave, 40);

      final progress = await service.progressFor(childId);
      expect(progress!.saved, 40, reason: 'xu hũ Tiêu không tính vào mục tiêu');
      expect(progress.remaining, 60);
      expect(progress.percent, 40);
      expect(progress.reached, isFalse);
    });

    test('tỷ lệ chặn trên ở 1.0 để thanh không tràn', () async {
      await goals.setGoal(
        familyId: familyId,
        memberId: childId,
        title: 'Xe đạp',
        targetXu: 100,
      );
      await credit(kJarSave, 250);

      final progress = await service.progressFor(childId);
      expect(progress!.ratio, 1.0);
      expect(progress.percent, 100);
      expect(progress.remaining, 0, reason: 'không hiện số âm');
      expect(progress.reached, isTrue);
    });

    test('nhà xếp hũ Để dành lại thì đo bằng tổng xu đã chia', () async {
      await goals.setGoal(
        familyId: familyId,
        memberId: childId,
        title: 'Xe đạp',
        targetXu: 100,
      );
      await credit(kJarSpend, 30);
      await credit(kJarGive, 20);

      // Còn hũ Để dành: 0 xu trong đó, thanh đứng yên.
      expect((await service.progressFor(childId))!.saved, 0);
      // Không còn hũ Để dành: lấy tổng đã chia, còn hơn đứng yên ở 0 mãi mãi.
      expect(
        (await service.progressFor(childId, hasSaveJar: false))!.saved,
        50,
      );
    });
  });

  group('tới đích', () {
    test('đủ xu thì đánh dấu tới đích và **không** trừ xu', () async {
      await goals.setGoal(
        familyId: familyId,
        memberId: childId,
        title: 'Xe đạp',
        targetXu: 100,
      );
      await credit(kJarSave, 100);

      final reached = await service.checkReached(childId);
      expect(reached?.title, 'Xe đạp');

      // Điểm quan trọng: tới đích chỉ là cái mốc. Xu vẫn của con cho tới khi
      // nhà thật sự mua món đồ đó; tự trừ ở đây là xoá tiền của con để đổi lấy
      // một dòng chữ trong app.
      final balance = await wallet.balanceOf(childId);
      expect(balance.ofKey(kJarSave), 100);

      final row = await db.select(db.savingsGoals).getSingle();
      expect(row.status, GoalStatus.reached.name);
      expect(row.reachedAt, isNotNull);
    });

    test('chưa đủ xu thì không đánh dấu gì', () async {
      await goals.setGoal(
        familyId: familyId,
        memberId: childId,
        title: 'Xe đạp',
        targetXu: 100,
      );
      await credit(kJarSave, 99);

      expect(await service.checkReached(childId), isNull);
      expect(await goals.activeGoal(childId), isNotNull);
    });

    test('gọi lại lần hai không ghi đè mốc thời gian đã có', () async {
      await goals.setGoal(
        familyId: familyId,
        memberId: childId,
        title: 'Xe đạp',
        targetXu: 100,
      );
      await credit(kJarSave, 100);

      await service.checkReached(childId);
      final first = (await db.select(db.savingsGoals).getSingle()).reachedAt;

      expect(
        await service.checkReached(childId),
        isNull,
        reason: 'không còn mục tiêu đang chạy nên không ăn mừng lần hai',
      );
      expect((await db.select(db.savingsGoals).getSingle()).reachedAt, first);
    });

    test('mục tiêu đã tới đích vẫn đọc lại được để khoe', () async {
      await goals.setGoal(
        familyId: familyId,
        memberId: childId,
        title: 'Xe đạp',
        targetXu: 100,
      );
      await credit(kJarSave, 100);
      await service.checkReached(childId);

      expect(await goals.watchReachedGoals(childId).first, hasLength(1));
    });
  });
}
