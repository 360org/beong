import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/jar_dao.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hũ do bố mẹ tự lập — ADR-024.
///
/// Bảng `jars` có từ schema v5 nhưng cho tới giờ **không có gì đọc hay ghi nó**.
/// Nhóm test cuối cùng là quan trọng nhất: nó chốt rằng xu trong hũ tự lập vẫn
/// được đếm. Bản `WalletBalance` trước chỉ biết bốn khoá cứng, nên xu vào hũ tự
/// lập nằm yên trong sổ cái mà **không hiện ở bất cứ màn hình nào** — mất xu mà
/// không có thông báo lỗi nào cả.
void main() {
  late AppDatabase db;
  late JarDao jarDao;
  late WalletDao walletDao;
  late MemberDao memberDao;

  const familyId = 'fam-1';
  const childId = 'con-1';

  setUp(() async {
    db = AppDatabase.memory();
    jarDao = JarDao(db);
    walletDao = WalletDao(db);
    memberDao = MemberDao(db);

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
    );
    await memberDao.addMember(
      MembersCompanion.insert(
        id: childId,
        familyId: familyId,
        kind: MemberKind.child.name,
        displayName: 'Minh',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('gieo hũ mặc định', () {
    test('gia đình mới có đúng ba hũ mặc định, đúng thứ tự', () async {
      await jarDao.seedDefaults(familyId);

      final jars = await jarDao.activeJars(familyId);
      expect(jars.map((j) => j.key), [kJarSpend, kJarSave, kJarGive]);
      expect(jars.map((j) => j.pct), [50, 40, 10]);
      expect(jars.every((j) => j.emoji.isNotEmpty), isTrue);
    });

    test('gọi hai lần không nhân đôi hũ', () async {
      await jarDao.seedDefaults(familyId);
      await jarDao.seedDefaults(familyId);

      expect((await jarDao.activeJars(familyId)).length, 3);
    });

    test('gia đình chưa gieo thì vẫn thấy ba hũ mặc định, không rỗng', () async {
      // Dữ liệu tạo trước v5 không có hàng nào trong bảng. Trả rỗng thì màn chia
      // xu không có hũ nào để con chia vào.
      expect(
        (await jarDao.watchActiveJars(familyId).first).map((j) => j.key),
        [kJarSpend, kJarSave, kJarGive],
      );
    });
  });

  group('thêm, sửa, xếp lại', () {
    setUp(() => jarDao.seedDefaults(familyId));

    test('thêm hũ mới thì nó nằm cuối danh sách', () async {
      final jar = await jarDao.addJar(
        familyId: familyId,
        title: 'Học tập',
        emoji: '📚',
      );

      final jars = await jarDao.activeJars(familyId);
      expect(jars.length, 4);
      expect(jars.last.key, jar.key);
      expect(jars.last.title, 'Học tập');
    });

    test('khoá hũ không sinh từ tên, nên đổi tên không đổi khoá', () async {
      final jar = await jarDao.addJar(
        familyId: familyId,
        title: 'Học tập',
        emoji: '📚',
      );
      await jarDao.updateJar(
        familyId: familyId,
        jarKey: jar.key,
        title: 'Sách vở',
      );

      final found = (await jarDao.activeJars(
        familyId,
      )).firstWhere((j) => j.key == jar.key);
      expect(found.title, 'Sách vở');
      expect(found.key, jar.key, reason: 'khoá đã vào sổ cái, không được đổi');
    });

    test('tên rỗng bị từ chối', () async {
      expect(
        () => jarDao.addJar(familyId: familyId, title: '   ', emoji: '📚'),
        throwsA(isA<JarException>()),
      );
    });

    test('tỷ lệ ngoài 0–100 bị từ chối', () async {
      expect(
        () => jarDao.updateJar(
          familyId: familyId,
          jarKey: kJarSave,
          pct: 120,
        ),
        throwsA(isA<JarException>()),
      );
    });

    test('xếp lại hũ thì nó rời danh sách đang dùng nhưng không mất', () async {
      await jarDao.setArchived(
        familyId: familyId,
        jarKey: kJarGive,
        archived: true,
      );

      expect((await jarDao.activeJars(familyId)).map((j) => j.key), [
        kJarSpend,
        kJarSave,
      ]);
      expect((await jarDao.watchAllJars(familyId).first).length, 3);
    });

    test('không xếp lại được hũ Tiêu', () async {
      // Phần thưởng trừ xu từ hũ Tiêu (ADR-016). Cho xếp lại nó thì con không
      // đổi được gì mà lỗi hiện ra lại nói "hũ không tồn tại".
      expect(
        () => jarDao.setArchived(
          familyId: familyId,
          jarKey: kJarSpend,
          archived: true,
        ),
        throwsA(isA<JarException>()),
      );
    });

    test('không xếp lại tới mức không còn hũ nào', () async {
      await jarDao.setArchived(
        familyId: familyId,
        jarKey: kJarGive,
        archived: true,
      );
      await jarDao.setArchived(
        familyId: familyId,
        jarKey: kJarSave,
        archived: true,
      );

      expect((await jarDao.activeJars(familyId)).length, 1);
    });

    test('xếp lại rồi mở lại thì hũ về đúng chỗ cũ', () async {
      await jarDao.setArchived(
        familyId: familyId,
        jarKey: kJarSave,
        archived: true,
      );
      await jarDao.setArchived(
        familyId: familyId,
        jarKey: kJarSave,
        archived: false,
      );

      expect((await jarDao.activeJars(familyId)).map((j) => j.key), [
        kJarSpend,
        kJarSave,
        kJarGive,
      ]);
    });

    test('đổi thứ tự ghi lại đúng như danh sách truyền vào', () async {
      await jarDao.reorder(
        familyId: familyId,
        jarKeys: [kJarGive, kJarSpend, kJarSave],
      );

      expect((await jarDao.activeJars(familyId)).map((j) => j.key), [
        kJarGive,
        kJarSpend,
        kJarSave,
      ]);
    });
  });

  group('xu trong hũ tự lập không được biến mất', () {
    test('số dư đếm cả hũ có khoá ngoài ba hũ mặc định', () async {
      await jarDao.seedDefaults(familyId);
      final jar = await jarDao.addJar(
        familyId: familyId,
        title: 'Học tập',
        emoji: '📚',
        pct: 20,
      );

      await walletDao.creditToJarKey(
        familyId: familyId,
        memberId: childId,
        jarKey: jar.key,
        amount: 30,
        reason: TxReason.taskApproved,
        clientOpId: 'test:hoc-tap',
      );

      final balance = await walletDao.balanceOf(childId);
      expect(balance.ofKey(jar.key), 30);
      expect(
        balance.total,
        30,
        reason: 'bản cũ trả 0 vì chỉ đếm spend/save/give/inbox',
      );
      expect(
        balance.allocated,
        30,
        reason: 'đã vào hũ thật, không phải hũ chờ',
      );
    });

    test('theo dõi số dư cũng đếm hũ tự lập', () async {
      await jarDao.seedDefaults(familyId);
      final jar = await jarDao.addJar(
        familyId: familyId,
        title: 'Học tập',
        emoji: '📚',
      );

      await walletDao.creditToJarKey(
        familyId: familyId,
        memberId: childId,
        jarKey: jar.key,
        amount: 7,
        reason: TxReason.taskApproved,
        clientOpId: 'test:theo-doi',
      );

      expect((await walletDao.watchBalance(childId).first).ofKey(jar.key), 7);
    });
  });

  group('chia tự động theo hũ của gia đình', () {
    test('hũ tự lập nhận được xu từ việc nhà', () async {
      // Trước đây `credit` chỉ đọc `families.jar_split` (ba hũ cứng), nên hũ tự
      // lập vĩnh viễn rỗng dù bố mẹ đã đặt tỷ lệ cho nó.
      await jarDao.seedDefaults(familyId);
      await jarDao.updateJar(familyId: familyId, jarKey: kJarSpend, pct: 40);
      await jarDao.updateJar(familyId: familyId, jarKey: kJarSave, pct: 30);
      await jarDao.updateJar(familyId: familyId, jarKey: kJarGive, pct: 10);
      final hocTap = await jarDao.addJar(
        familyId: familyId,
        title: 'Học tập',
        emoji: '📚',
        pct: 20,
      );

      await walletDao.credit(
        familyId: familyId,
        memberId: childId,
        amount: 100,
        reason: TxReason.taskApproved,
        clientOpId: 'test:chia-4-hu',
      );

      final balance = await walletDao.balanceOf(childId);
      expect(balance.ofKey(hocTap.key), 20);
      expect(balance.spend, 40);
      expect(balance.save, 30);
      expect(balance.give, 10);
      expect(balance.total, 100, reason: 'không được mất xu nào khi chia');
    });

    test('tổng xu luôn đúng dù tỷ lệ chia lẻ', () async {
      await jarDao.seedDefaults(familyId);
      await jarDao.updateJar(familyId: familyId, jarKey: kJarSpend, pct: 34);
      await jarDao.updateJar(familyId: familyId, jarKey: kJarSave, pct: 33);
      await jarDao.updateJar(familyId: familyId, jarKey: kJarGive, pct: 33);

      await walletDao.credit(
        familyId: familyId,
        memberId: childId,
        amount: 10,
        reason: TxReason.taskApproved,
        clientOpId: 'test:chia-le',
      );

      expect((await walletDao.balanceOf(childId)).total, 10);
    });

    test(
      'tỷ lệ chưa cộng đủ 100 thì rơi về mặc định, không chặn cộng xu',
      () async {
        // Bố mẹ đang sửa dở tỷ lệ giữa lúc con làm xong việc: chặn ở đây thì con
        // mất xu vì lỗi của người khác.
        await jarDao.seedDefaults(familyId);
        await jarDao.updateJar(familyId: familyId, jarKey: kJarSave, pct: 5);

        await walletDao.credit(
          familyId: familyId,
          memberId: childId,
          amount: 10,
          reason: TxReason.taskApproved,
          clientOpId: 'test:ty-le-sai',
        );

        final balance = await walletDao.balanceOf(childId);
        expect(balance.total, 10);
        expect(balance.spend, 5, reason: 'tỷ lệ mặc định 50/40/10');
      },
    );

    test('hũ đã xếp lại không nhận xu mới nữa', () async {
      await jarDao.seedDefaults(familyId);
      await jarDao.setArchived(
        familyId: familyId,
        jarKey: kJarGive,
        archived: true,
      );
      await jarDao.updateJar(familyId: familyId, jarKey: kJarSpend, pct: 60);
      await jarDao.updateJar(familyId: familyId, jarKey: kJarSave, pct: 40);

      await walletDao.credit(
        familyId: familyId,
        memberId: childId,
        amount: 100,
        reason: TxReason.taskApproved,
        clientOpId: 'test:hu-xep-lai',
      );

      final balance = await walletDao.balanceOf(childId);
      expect(balance.give, 0);
      expect(balance.spend, 60);
      expect(balance.save, 40);
    });
  });

  group('hũ riêng cho từng bé (v9)', () {
    // Chủ dự án 30/08/2026: "các hũ cho mỗi bé là khác nhau". Một bé để dành
    // mua xe đạp trong khi bé kia để dành mua sách.
    const beKia = 'con-2';

    setUp(() async {
      await memberDao.addMember(
        MembersCompanion.insert(
          id: beKia,
          familyId: familyId,
          kind: MemberKind.child.name,
          displayName: 'Simba',
        ),
      );
      await jarDao.seedDefaults(familyId);
    });

    test('bé chưa có bộ riêng thì dùng bộ chung của nhà', () async {
      final cua = await jarDao.activeJars(familyId, memberId: childId);
      final chung = await jarDao.activeJars(familyId);

      expect(cua.map((j) => j.key), chung.map((j) => j.key));
      expect(await jarDao.coHuRieng(childId), isFalse);
    });

    test('thêm hũ cho một bé thì bé kia KHÔNG có hũ đó', () async {
      await jarDao.addJar(
        familyId: familyId,
        title: 'Mua xe đạp',
        emoji: '🚲',
        pct: 10,
        memberId: childId,
      );

      final cuaMinh = await jarDao.activeJars(familyId, memberId: childId);
      final cuaSimba = await jarDao.activeJars(familyId, memberId: beKia);
      final cuaNha = await jarDao.activeJars(familyId);

      expect(cuaMinh.map((j) => j.title), contains('Mua xe đạp'));
      expect(
        cuaSimba.map((j) => j.title),
        isNot(contains('Mua xe đạp')),
        reason: 'hũ riêng của Minh rò sang Simba là hỏng đúng thứ đang làm',
      );
      expect(cuaNha.map((j) => j.title), isNot(contains('Mua xe đạp')));
    });

    test(
      'thêm hũ riêng thì bé được sao chép cả bộ chung, không mất hũ nào',
      () async {
        final truoc = await jarDao.activeJars(familyId);

        await jarDao.addJar(
          familyId: familyId,
          title: 'Mua sách',
          emoji: '📚',
          memberId: childId,
        );

        final sau = await jarDao.activeJars(familyId, memberId: childId);
        expect(
          sau.map((j) => j.key),
          containsAll(truoc.map((j) => j.key)),
          reason:
              'không sao chép bộ chung thì bé chỉ còn đúng một hũ, và 100% xu '
              'không biết chảy đi đâu',
        );
        expect(sau, hasLength(truoc.length + 1));
      },
    );

    test('sửa tỷ lệ hũ của một bé không đụng tới bé kia', () async {
      await jarDao.tachBoRieng(familyId: familyId, memberId: childId);

      await jarDao.updateJar(
        familyId: familyId,
        jarKey: kJarSave,
        pct: 90,
        memberId: childId,
      );

      final cuaMinh = await jarDao.activeJars(familyId, memberId: childId);
      final cuaNha = await jarDao.activeJars(familyId);

      expect(cuaMinh.firstWhere((j) => j.key == kJarSave).pct, 90);
      expect(
        cuaNha.firstWhere((j) => j.key == kJarSave).pct,
        isNot(90),
        reason: 'thiếu vế member_id ở câu UPDATE là sửa một bé sửa luôn cả nhà',
      );
    });

    test('xu của bé chảy theo bộ hũ riêng, không theo bộ chung', () async {
      await jarDao.tachBoRieng(familyId: familyId, memberId: childId);
      // Minh dồn hết vào Để dành; nhà vẫn 50/40/10.
      await jarDao.updateJar(
        familyId: familyId,
        jarKey: kJarSpend,
        pct: 0,
        memberId: childId,
      );
      await jarDao.updateJar(
        familyId: familyId,
        jarKey: kJarSave,
        pct: 100,
        memberId: childId,
      );
      await jarDao.updateJar(
        familyId: familyId,
        jarKey: kJarGive,
        pct: 0,
        memberId: childId,
      );

      await walletDao.credit(
        familyId: familyId,
        memberId: childId,
        amount: 100,
        reason: TxReason.taskApproved,
        clientOpId: 'test:hu-rieng-minh',
      );
      await walletDao.credit(
        familyId: familyId,
        memberId: beKia,
        amount: 100,
        reason: TxReason.taskApproved,
        clientOpId: 'test:hu-chung-simba',
      );

      final cuaMinh = await walletDao.balanceOf(childId);
      final cuaSimba = await walletDao.balanceOf(beKia);

      expect(cuaMinh.save, 100, reason: 'Minh dùng bộ riêng 0/100/0');
      expect(cuaSimba.save, 40, reason: 'Simba vẫn theo bộ chung 50/40/10');
    });

    test('tách bộ riêng hai lần không nhân đôi hũ', () async {
      await jarDao.tachBoRieng(familyId: familyId, memberId: childId);
      final lan1 = await jarDao.activeJars(familyId, memberId: childId);
      await jarDao.tachBoRieng(familyId: familyId, memberId: childId);
      final lan2 = await jarDao.activeJars(familyId, memberId: childId);

      expect(lan2, hasLength(lan1.length));
    });
  });
}
