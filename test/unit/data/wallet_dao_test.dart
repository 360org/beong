import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/jar_splitter.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sổ cái là chỗ nhạy cảm nhất trong app: nó quyết định trẻ có tin app hay không.
/// ADR-005 (append-only) và ADR-016 (ba hũ) được kiểm ở đây.
void main() {
  late AppDatabase db;
  late WalletDao dao;

  const familyId = 'fam-1';
  const memberId = 'an';

  setUp(() async {
    db = AppDatabase.memory();
    dao = WalletDao(db);

    await db
        .into(db.families)
        .insert(FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'));
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: memberId,
            familyId: familyId,
            kind: MemberKind.child.name,
            displayName: 'An',
          ),
        );
  });

  tearDown(() async => db.close());

  group('balanceOf', () {
    test('ví mới hoàn toàn rỗng', () async {
      expect(await dao.balanceOf(memberId), WalletBalance.zero);
    });

    test('cộng xu chia đúng ba hũ theo mặc định 50/40/10', () async {
      await dao.credit(
        familyId: familyId,
        memberId: memberId,
        amount: 100,
        reason: TxReason.taskApproved,
        clientOpId: 'op-1',
      );

      final balance = await dao.balanceOf(memberId);
      expect(balance.spend, 50);
      expect(balance.save, 40);
      expect(balance.give, 10);
      expect(balance.total, 100);
    });

    test('tổng ba hũ luôn khớp kể cả khi chia lẻ', () async {
      for (var i = 0; i < 20; i++) {
        await dao.credit(
          familyId: familyId,
          memberId: memberId,
          amount: 7,
          reason: TxReason.taskApproved,
          clientOpId: 'op-$i',
        );
      }
      expect((await dao.balanceOf(memberId)).total, 140);
    });
  });

  group('idempotency — ADR sync', () {
    test('gọi lại cùng clientOpId không nhân đôi xu', () async {
      final first = await dao.credit(
        familyId: familyId,
        memberId: memberId,
        amount: 50,
        reason: TxReason.taskApproved,
        clientOpId: 'op-trung',
      );
      final second = await dao.credit(
        familyId: familyId,
        memberId: memberId,
        amount: 50,
        reason: TxReason.taskApproved,
        clientOpId: 'op-trung',
      );

      expect(first, greaterThan(0));
      expect(second, 0, reason: 'Lần hai không được ghi thêm dòng nào');
      expect((await dao.balanceOf(memberId)).total, 50);
    });

    test('gọi lại nhiều lần vẫn giữ nguyên số dư', () async {
      for (var i = 0; i < 5; i++) {
        await dao.credit(
          familyId: familyId,
          memberId: memberId,
          amount: 30,
          reason: TxReason.routineBonus,
          clientOpId: 'bonus-cung-mot-ngay',
        );
      }
      expect((await dao.balanceOf(memberId)).total, 30);
    });
  });

  group('debit', () {
    setUp(() async {
      await dao.credit(
        familyId: familyId,
        memberId: memberId,
        amount: 200,
        reason: TxReason.taskApproved,
        clientOpId: 'nap-dau',
      );
    });

    test('trừ xu từ đúng hũ được chỉ định', () async {
      await dao.debit(
        familyId: familyId,
        memberId: memberId,
        jar: Jar.spend,
        amount: 40,
        reason: TxReason.rewardRedeemed,
        clientOpId: 'doi-thuong-1',
      );

      final balance = await dao.balanceOf(memberId);
      expect(balance.spend, 60); // 100 - 40
      expect(balance.save, 80, reason: 'Hũ Để dành không bị đụng vào');
    });

    test('không cho tiêu quá số dư của hũ', () async {
      expect(
        () => dao.debit(
          familyId: familyId,
          memberId: memberId,
          jar: Jar.spend,
          amount: 999,
          reason: TxReason.rewardRedeemed,
          clientOpId: 'qua-tay',
        ),
        throwsA(isA<WalletException>()),
      );
    });

    test('hũ Để dành nhiều xu không cứu được hũ Tiêu đã cạn', () async {
      // Đây chính là điểm dạy dỗ của ADR-016: để dành thì không tiêu vặt được.
      await dao.debit(
        familyId: familyId,
        memberId: memberId,
        jar: Jar.spend,
        amount: 100,
        reason: TxReason.rewardRedeemed,
        clientOpId: 'tieu-het',
      );
      expect(
        () => dao.debit(
          familyId: familyId,
          memberId: memberId,
          jar: Jar.spend,
          amount: 1,
          reason: TxReason.rewardRedeemed,
          clientOpId: 'them-mot-xu',
        ),
        throwsA(isA<WalletException>()),
      );
      expect((await dao.balanceOf(memberId)).save, 80);
    });

    test('giao dịch thất bại không để lại dòng nào', () async {
      final before = await dao.balanceOf(memberId);
      try {
        await dao.debit(
          familyId: familyId,
          memberId: memberId,
          jar: Jar.give,
          amount: 5000,
          reason: TxReason.rewardRedeemed,
          clientOpId: 'that-bai',
        );
      } on WalletException {
        // mong đợi
      }
      expect(await dao.balanceOf(memberId), before);
    });
  });

  group('manualAdjust — minh bạch', () {
    test('bắt buộc có lý do', () async {
      expect(
        () => dao.manualAdjust(
          familyId: familyId,
          memberId: memberId,
          jar: Jar.spend,
          delta: 10,
          reasonNote: '   ',
          clientOpId: 'sua-1',
          createdBy: 'bo',
        ),
        throwsA(isA<WalletException>()),
      );
    });

    test('lý do được lưu lại để trẻ đọc được', () async {
      await dao.manualAdjust(
        familyId: familyId,
        memberId: memberId,
        jar: Jar.spend,
        delta: 20,
        reasonNote: 'Con giúp bà xách đồ',
        clientOpId: 'sua-2',
        createdBy: 'me',
      );

      final history = await dao.watchHistory(memberId).first;
      expect(history.single.note, 'Con giúp bà xách đồ');
      expect(history.single.reason, TxReason.manualAdjust.name);
    });

    test('không cho trừ xuống âm', () async {
      expect(
        () => dao.manualAdjust(
          familyId: familyId,
          memberId: memberId,
          jar: Jar.spend,
          delta: -10,
          reasonNote: 'Phạt',
          clientOpId: 'sua-3',
          createdBy: 'bo',
        ),
        throwsA(isA<WalletException>()),
      );
    });
  });

  group('splitFor', () {
    test('dùng tỷ lệ của gia đình khi trẻ không đặt riêng', () async {
      expect(await dao.splitFor(memberId), JarSplit.defaultSplit);
    });

    test('trẻ lớn tự đặt tỷ lệ thì ưu tiên tỷ lệ đó', () async {
      const custom = JarSplit(spend: 20, save: 70, give: 10);
      await (db.update(db.members)..where((m) => m.id.equals(memberId))).write(
        const MembersCompanion(
          jarSplitOverride: Value('{"spend":20,"save":70,"give":10}'),
        ),
      );

      expect(await dao.splitFor(memberId), custom);

      await dao.credit(
        familyId: familyId,
        memberId: memberId,
        amount: 100,
        reason: TxReason.taskApproved,
        clientOpId: 'op-rieng',
      );
      expect((await dao.balanceOf(memberId)).save, 70);
    });

    test('báo lỗi rõ ràng khi không có hồ sơ', () async {
      expect(
        () => dao.splitFor('khong-ton-tai'),
        throwsA(isA<WalletException>()),
      );
    });
  });

  group('sổ cái append-only — ADR-005', () {
    test('hoàn xu ghi thêm dòng chứ không xoá dòng cũ', () async {
      await dao.credit(
        familyId: familyId,
        memberId: memberId,
        amount: 100,
        reason: TxReason.taskApproved,
        clientOpId: 'kiem',
      );
      await dao.debit(
        familyId: familyId,
        memberId: memberId,
        jar: Jar.spend,
        amount: 50,
        reason: TxReason.rewardRedeemed,
        clientOpId: 'doi',
      );
      await dao.credit(
        familyId: familyId,
        memberId: memberId,
        amount: 50,
        reason: TxReason.rewardRefund,
        clientOpId: 'hoan',
        split: JarSplit.spendOnly,
      );

      final history = await dao.watchHistory(memberId).first;
      expect(history.length, 5, reason: '3 dòng cộng + 1 trừ + 1 hoàn');
      // 50 (chia từ 100) - 50 (đổi thưởng) + 50 (hoàn về hũ Tiêu) = 50.
      expect((await dao.balanceOf(memberId)).spend, 50);
      expect((await dao.balanceOf(memberId)).total, 100);
    });

    test('lịch sử sắp xếp mới nhất trước và lọc được theo hũ', () async {
      await dao.credit(
        familyId: familyId,
        memberId: memberId,
        amount: 100,
        reason: TxReason.taskApproved,
        clientOpId: 'op-a',
      );

      final saveOnly = await dao.watchHistory(memberId, jar: Jar.save).first;
      expect(saveOnly.length, 1);
      expect(saveOnly.single.delta, 40);
    });
  });

  group('kiểm tra đầu vào', () {
    test('từ chối cộng số không dương', () async {
      expect(
        () => dao.credit(
          familyId: familyId,
          memberId: memberId,
          amount: 0,
          reason: TxReason.bonus,
          clientOpId: 'op-0',
        ),
        throwsA(isA<WalletException>()),
      );
    });

    test('từ chối trừ số không dương', () async {
      expect(
        () => dao.debit(
          familyId: familyId,
          memberId: memberId,
          jar: Jar.spend,
          amount: -5,
          reason: TxReason.rewardRedeemed,
          clientOpId: 'op-am',
        ),
        throwsA(isA<WalletException>()),
      );
    });
  });
}
