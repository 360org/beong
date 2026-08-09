import 'dart:convert';

import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/tables/tables.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/services/jar_splitter.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

part 'wallet_dao.g.dart';

/// Số dư từng hũ của một trẻ.
///
/// Khoá là `jar_key` — **không** phải `enum Jar`. Ba hũ mặc định vẫn có getter
/// riêng cho tiện đọc, nhưng lớp này không giới hạn ở chúng: từ ADR-024 bố mẹ tự
/// lập được hũ với khoá bất kỳ, và bản trước của lớp này chỉ đếm bốn khoá cứng
/// nên xu trong hũ tự lập **biến mất khỏi mọi màn hình** dù vẫn nằm trong sổ cái.
/// Số dư đọc hết những gì sổ cái có là cách duy nhất không âm thầm mất xu.
@immutable
class WalletBalance {
  const WalletBalance.fromKeys(this._byKey);

  static const zero = WalletBalance.fromKeys(<String, int>{});

  final Map<String, int> _byKey;

  /// Số dư từng hũ, chỉ những hũ đã có giao dịch.
  Map<String, int> get byKey => Map.unmodifiable(_byKey);

  int ofKey(String jarKey) => _byKey[jarKey] ?? 0;
  int of(Jar jar) => ofKey(jar.name);

  int get spend => ofKey(kJarSpend);
  int get save => ofKey(kJarSave);
  int get give => ofKey(kJarGive);

  /// Xu đã kiếm nhưng con chưa chia vào hũ nào — ADR-024, chế độ `manual`.
  int get inbox => ofKey(kJarInbox);

  /// **Tính cả hũ chờ.** Con làm việc xong là xu thuộc về con, dù chưa chia.
  /// Bỏ hũ chờ ra khỏi tổng thì màn hình con hiện 0 điểm sau khi làm xong việc.
  int get total => _byKey.values.fold(0, (a, b) => a + b);

  /// Tổng đã chia — dùng khi cần phân biệt với phần chưa chia.
  int get allocated => total - inbox;

  @override
  bool operator ==(Object other) =>
      other is WalletBalance &&
      const MapEquality<String, int>().equals(other._byKey, _byKey);

  @override
  int get hashCode => const MapEquality<String, int>().hash(_byKey);

  @override
  String toString() {
    final parts = _byKey.entries.map((e) => '${e.key} ${e.value}').join(', ');
    return 'WalletBalance($parts)';
  }
}

/// Lỗi khi thao tác ví.
class WalletException implements Exception {
  const WalletException(this.message);
  final String message;

  @override
  String toString() => 'WalletException: $message';
}

/// Truy cập sổ cái xu.
///
/// Toàn bộ tầng này tuân thủ ADR-005: sổ cái **append-only**. Không có phương
/// thức nào UPDATE hay DELETE một dòng giao dịch. Sửa sai bằng cách ghi dòng bù.
/// Số dư luôn được tính lại từ sổ cái, không đọc từ cột cache nào.
@DriftAccessor(tables: [PointTransactions, Members, Families])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.attachedDatabase);

  /// Số dư ba hũ, tính từ sổ cái.
  Future<WalletBalance> balanceOf(String memberId) async {
    final deltaSum = pointTransactions.delta.sum();
    final rows =
        await (selectOnly(pointTransactions)
              ..addColumns([pointTransactions.jar, deltaSum])
              ..where(pointTransactions.memberId.equals(memberId))
              ..groupBy([pointTransactions.jar]))
            .get();

    final byKey = <String, int>{};
    for (final row in rows) {
      final jarKey = row.read(pointTransactions.jar);
      if (jarKey == null) continue;
      byKey[jarKey] = row.read(deltaSum) ?? 0;
    }
    return WalletBalance.fromKeys(byKey);
  }

  /// Theo dõi số dư, phát lại mỗi khi sổ cái đổi.
  Stream<WalletBalance> watchBalance(String memberId) {
    return (select(
      pointTransactions,
    )..where((t) => t.memberId.equals(memberId))).watch().map((rows) {
      final byKey = <String, int>{};
      for (final row in rows) {
        byKey[row.jar] = (byKey[row.jar] ?? 0) + row.delta;
      }
      return WalletBalance.fromKeys(byKey);
    });
  }

  /// Tỷ lệ chia của một trẻ: riêng của trẻ nếu có, ngược lại theo gia đình.
  Future<JarSplit> splitFor(String memberId) async {
    final member = await (select(
      members,
    )..where((m) => m.id.equals(memberId))).getSingleOrNull();
    if (member == null) {
      throw WalletException('Không tìm thấy hồ sơ $memberId');
    }

    final override = member.jarSplitOverride;
    if (override != null && override.isNotEmpty) {
      return JarSplit.fromJson(jsonDecode(override) as Map<String, dynamic>);
    }

    final family = await (select(
      families,
    )..where((f) => f.id.equals(member.familyId))).getSingle();
    return JarSplit.fromJson(
      jsonDecode(family.jarSplit) as Map<String, dynamic>,
    );
  }

  /// Cộng xu kiếm được, chia vào ba hũ theo tỷ lệ — ADR-016.
  ///
  /// Sinh **ba dòng** sổ cái, mỗi hũ một dòng, dùng chung [clientOpId] gốc kèm
  /// hậu tố tên hũ. Gọi lại cùng [clientOpId] không nhân đôi xu: unique index
  /// trên `client_op_id` chặn, và ta bỏ qua lặng lẽ thay vì báo lỗi — thao tác
  /// đã thành công từ lần trước rồi.
  ///
  /// Trả về số dòng thực sự được ghi (0 nghĩa là đã ghi từ trước).
  Future<int> credit({
    required String familyId,
    required String memberId,
    required int amount,
    required TxReason reason,
    required String clientOpId,
    String? refType,
    String? refId,
    String? note,
    String? createdBy,
    JarSplit? split,
  }) async {
    if (amount <= 0) {
      throw WalletException('Số xu cộng vào phải dương, nhận được $amount');
    }
    final effectiveSplit = split ?? await splitFor(memberId);
    final parts = splitAmount(amount, effectiveSplit);

    return transaction(() async {
      var written = 0;
      for (final entry in parts.entries) {
        if (entry.value == 0) continue;
        written += await _insertIfNew(
          familyId: familyId,
          memberId: memberId,
          jar: entry.key,
          delta: entry.value,
          reason: reason,
          clientOpId: '$clientOpId:${entry.key.name}',
          // Ba dòng của cùng một lần cộng chung một nhóm, để "Sổ của con" hiện
          // một mục thay vì ba.
          opGroupId: clientOpId,
          refType: refType,
          refId: refId,
          note: note,
          createdBy: createdBy,
        );
      }
      return written;
    });
  }

  /// Cộng xu vào **một hũ duy nhất**, không chia.
  ///
  /// Dùng cho chế độ `manual` (ADR-024): xu vào hũ chờ, con tự chia sau. Cũng
  /// dùng cho bước chuyển hũ khi con chia.
  ///
  /// Trả về số dòng thực sự ghi (0 nghĩa là đã ghi từ trước).
  Future<int> creditToJar({
    required String familyId,
    required String memberId,
    required Jar jar,
    required int amount,
    required TxReason reason,
    required String clientOpId,
    String? opGroupId,
    String? refType,
    String? refId,
    String? note,
    String? createdBy,
  }) => creditToJarKey(
    familyId: familyId,
    memberId: memberId,
    jarKey: jar.name,
    amount: amount,
    reason: reason,
    clientOpId: clientOpId,
    opGroupId: opGroupId,
    refType: refType,
    refId: refId,
    note: note,
    createdBy: createdBy,
  );

  /// Như [creditToJar] nhưng nhận **khoá hũ** dạng chuỗi.
  ///
  /// Hũ do bố mẹ tự lập (ADR-024) không có giá trị nào trong `enum Jar` — enum
  /// chỉ có bốn hũ dựng sẵn — nên mọi đường ghi vào hũ tuỳ ý phải đi qua đây.
  Future<int> creditToJarKey({
    required String familyId,
    required String memberId,
    required String jarKey,
    required int amount,
    required TxReason reason,
    required String clientOpId,
    String? opGroupId,
    String? refType,
    String? refId,
    String? note,
    String? createdBy,
  }) async {
    if (amount <= 0) {
      throw WalletException('Số xu cộng vào phải dương, nhận được $amount');
    }
    return _insertIfNewKey(
      familyId: familyId,
      memberId: memberId,
      jarKey: jarKey,
      delta: amount,
      reason: reason,
      clientOpId: clientOpId,
      opGroupId: opGroupId,
      refType: refType,
      refId: refId,
      note: note,
      createdBy: createdBy,
    );
  }

  /// Con chuyển xu từ hũ chờ sang một hũ thật — ADR-024.
  ///
  /// Ghi **hai** dòng bù nhau trong một transaction (rút ở hũ chờ, nộp vào hũ
  /// đích), dùng chung `op_group_id` nên "Sổ của con" hiện một mục. Tổng xu
  /// không đổi — đây là đổi chỗ, không phải kiếm thêm.
  Future<void> moveFromInbox({
    required String familyId,
    required String memberId,
    required Jar toJar,
    required int amount,
    required String clientOpId,
  }) async {
    if (toJar == Jar.inbox) {
      throw const WalletException('Không chuyển hũ chờ sang chính nó');
    }
    if (amount <= 0) {
      throw WalletException('Số xu chuyển phải dương, nhận được $amount');
    }

    await transaction(() async {
      final balance = await balanceOf(memberId);
      if (balance.inbox < amount) {
        throw WalletException(
          'Hũ chờ còn ${balance.inbox} xu, không đủ $amount xu',
        );
      }

      await _insertIfNew(
        familyId: familyId,
        memberId: memberId,
        jar: Jar.inbox,
        delta: -amount,
        reason: TxReason.jarTransfer,
        clientOpId: '$clientOpId:inbox',
        opGroupId: clientOpId,
      );
      await _insertIfNew(
        familyId: familyId,
        memberId: memberId,
        jar: toJar,
        delta: amount,
        reason: TxReason.jarTransfer,
        clientOpId: '$clientOpId:${toJar.name}',
        opGroupId: clientOpId,
      );
    });
  }

  /// Trừ xu từ một hũ cụ thể — dùng khi đổi thưởng.
  ///
  /// Không cho số dư hũ xuống âm: một đứa trẻ nhìn thấy số âm sẽ không hiểu
  /// chuyện gì xảy ra, và app này không dạy nợ.
  Future<void> debit({
    required String familyId,
    required String memberId,
    required Jar jar,
    required int amount,
    required TxReason reason,
    required String clientOpId,
    String? refType,
    String? refId,
    String? note,
    String? createdBy,
  }) async {
    if (amount <= 0) {
      throw WalletException('Số xu trừ đi phải dương, nhận được $amount');
    }

    await transaction(() async {
      final balance = await balanceOf(memberId);
      if (balance.of(jar) < amount) {
        throw WalletException(
          'Hũ ${jar.name} chỉ còn ${balance.of(jar)} xu, không đủ $amount xu',
        );
      }
      await _insertIfNew(
        familyId: familyId,
        memberId: memberId,
        jar: jar,
        delta: -amount,
        reason: reason,
        clientOpId: clientOpId,
        refType: refType,
        refId: refId,
        note: note,
        createdBy: createdBy,
      );
    });
  }

  /// Trừ xu theo chính sách trừ điểm — ADR-022.
  ///
  /// Khác [debit] ở hai chỗ, và cả hai đều là quyết định có chủ ý:
  ///
  /// **1. Thứ tự hũ: Tiêu → Để dành → Cho đi.** Không chia theo tỷ lệ ba hũ
  /// như khi cộng xu. Chia theo tỷ lệ nghe công bằng nhưng nó lấy cả xu con đã
  /// dành cho hũ Cho đi — biến một khoản con tự nguyện dành để tặng thành công
  /// cụ trừng phạt. Hũ Để dành cũng cần được bảo vệ, vì nó gắn với mục tiêu dài
  /// hạn mà app đang dạy. Nên trừ từ hũ dễ nhất trước, và chỉ lấn sang hũ khác
  /// khi thật sự không đủ.
  ///
  /// **2. Không bao giờ làm số dư âm.** [debit] báo lỗi khi không đủ xu (đổi
  /// thưởng phải thất bại rõ ràng), còn ở đây trừ tối đa đến 0 rồi thôi. Một
  /// đứa trẻ nhìn thấy số âm không hiểu chuyện gì xảy ra, và app này không dạy
  /// nợ. Hệ quả cần biết: đứa trẻ đang 0 xu thì trừ bao nhiêu cũng như nhau —
  /// tính năng này mất tác dụng đúng lúc nó dễ gây tổn thương nhất.
  ///
  /// Trả về số xu **thực sự** đã trừ, có thể nhỏ hơn [amount] hoặc bằng 0. Gọi
  /// lại cùng [clientOpId] không trừ thêm lần nữa.
  Future<int> penalize({
    required String familyId,
    required String memberId,
    required int amount,
    required String clientOpId,
    String? refType,
    String? refId,
    String? note,
    String? createdBy,
  }) async {
    if (amount < 0) {
      throw WalletException('Số xu trừ không được âm, nhận được $amount');
    }
    if (amount == 0) return 0;

    return transaction(() async {
      final balance = await balanceOf(memberId);
      var remaining = amount;
      var deducted = 0;

      // Thứ tự cố định, xem doc comment ở trên. Hũ chờ đứng **đầu**: đó là xu
      // con chưa cam kết vào giá trị nào, nên lấy ở đó ít phá vỡ nhất.
      for (final jar in const [Jar.inbox, Jar.spend, Jar.save, Jar.give]) {
        if (remaining <= 0) break;
        final available = balance.of(jar);
        if (available <= 0) continue;

        final take = available < remaining ? available : remaining;
        final written = await _insertIfNew(
          familyId: familyId,
          memberId: memberId,
          jar: jar,
          delta: -take,
          reason: TxReason.penalty,
          clientOpId: '$clientOpId:${jar.name}',
          opGroupId: clientOpId,
          refType: refType,
          refId: refId,
          note: note,
          createdBy: createdBy,
        );
        // written == 0 nghĩa là lần gọi trước đã ghi dòng này rồi. Không cộng
        // vào tổng, nếu không hàm sẽ báo đã trừ hai lần cho cùng một thao tác.
        if (written == 0) return 0;
        deducted += take;
        remaining -= take;
      }

      return deducted;
    });
  }

  /// Bố mẹ tự điều chỉnh xu. **Bắt buộc có lý do** — giá trị "minh bạch"
  /// trong `docs/00-brand-values.md`: không có con số nào rơi từ trên trời
  /// xuống, và lý do này sẽ hiện cho trẻ thấy trong "Sổ của con".
  Future<void> manualAdjust({
    required String familyId,
    required String memberId,
    required Jar jar,
    required int delta,
    required String reasonNote,
    required String clientOpId,
    required String createdBy,
  }) async {
    if (reasonNote.trim().isEmpty) {
      throw const WalletException(
        'Điều chỉnh xu bắt buộc phải ghi lý do — trẻ có quyền biết vì sao',
      );
    }
    if (delta == 0) {
      throw const WalletException('Điều chỉnh 0 xu là vô nghĩa');
    }

    await transaction(() async {
      if (delta < 0) {
        final balance = await balanceOf(memberId);
        if (balance.of(jar) + delta < 0) {
          throw WalletException(
            'Trừ $delta xu sẽ làm hũ ${jar.name} âm — không cho phép',
          );
        }
      }
      await _insertIfNew(
        familyId: familyId,
        memberId: memberId,
        jar: jar,
        delta: delta,
        reason: TxReason.manualAdjust,
        clientOpId: clientOpId,
        note: reasonNote.trim(),
        createdBy: createdBy,
      );
    });
  }

  /// Lịch sử giao dịch thô, **mỗi hũ một dòng** — mới nhất trước.
  ///
  /// Màn hình nên dùng `watchGroupedHistory` để trẻ thấy một việc là một mục.
  ///
  /// Không có tham số nào giới hạn thời gian: trẻ xem lại được từ ngày đầu tiên.
  Stream<List<PointTransaction>> watchHistory(String memberId, {Jar? jar}) {
    final query = select(pointTransactions)
      ..where((t) => t.memberId.equals(memberId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    if (jar != null) {
      query.where((t) => t.jar.equals(jar.name));
    }
    return query.watch();
  }

  /// Ghi một dòng sổ cái nếu `clientOpId` chưa tồn tại. Trả về 1 nếu đã ghi.
  Future<int> _insertIfNew({
    required String familyId,
    required String memberId,
    required Jar jar,
    required int delta,
    required TxReason reason,
    required String clientOpId,
    String? opGroupId,
    String? refType,
    String? refId,
    String? note,
    String? createdBy,
  }) => _insertIfNewKey(
    familyId: familyId,
    memberId: memberId,
    jarKey: jar.name,
    delta: delta,
    reason: reason,
    clientOpId: clientOpId,
    opGroupId: opGroupId,
    refType: refType,
    refId: refId,
    note: note,
    createdBy: createdBy,
  );

  /// Như [_insertIfNew] nhưng nhận khoá hũ dạng chuỗi, để ghi được vào hũ do bố
  /// mẹ tự lập (ADR-024) — những hũ không có giá trị trong `enum Jar`.
  Future<int> _insertIfNewKey({
    required String familyId,
    required String memberId,
    required String jarKey,
    required int delta,
    required TxReason reason,
    required String clientOpId,
    String? opGroupId,
    String? refType,
    String? refId,
    String? note,
    String? createdBy,
  }) async {
    // `insertOrIgnore` trả về rowid chứ không phải số dòng thực sự được ghi, nên
    // không dùng nó để suy ra "đã tồn tại hay chưa" được. Kiểm tra tường minh.
    final existing =
        await (selectOnly(pointTransactions)
              ..addColumns([pointTransactions.id])
              ..where(pointTransactions.clientOpId.equals(clientOpId))
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return 0;

    await into(pointTransactions).insert(
      PointTransactionsCompanion.insert(
        id: clientOpId,
        familyId: familyId,
        memberId: memberId,
        jar: jarKey,
        delta: delta,
        reason: reason.name,
        clientOpId: clientOpId,
        opGroupId: Value(opGroupId),
        refType: Value(refType),
        refId: Value(refId),
        note: Value(note),
        createdBy: Value(createdBy),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    return 1;
  }
}

/// Một mục lịch sử đã gộp — xem `WalletHistory.watchGroupedHistory`.
@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.groupId,
    required this.reason,
    required this.delta,
    required this.createdAt,
    required this.byJar,
    this.refType,
    this.refId,
    this.note,
  });

  final String groupId;

  /// `TxReason` dạng chuỗi.
  final String reason;

  /// Tổng thay đổi của cả thao tác, cộng dồn các hũ.
  final int delta;

  final DateTime createdAt;

  /// Chi tiết từng hũ, để mở ra xem khi cần.
  final Map<String, int> byJar;

  final String? refType;
  final String? refId;
  final String? note;

  @override
  String toString() => 'LedgerEntry($reason $delta, ${byJar.length} hũ)';
}

extension WalletHistory on WalletDao {
  /// Lịch sử **đã gộp** cho "Sổ của con".
  ///
  /// Sổ cái ghi mỗi hũ một dòng (ADR-016), nên một việc 10 xu thành ba dòng
  /// (+5, +4, +1). Đúng về kế toán, nhưng hiện thẳng ra cho trẻ thì thành "làm
  /// một việc sao lại ba mục?". Hàm này gộp theo `op_group_id`, rơi về `id` với
  /// dòng cũ ghi trước v6.
  ///
  /// Gộp ở tầng Dart chứ không bằng GROUP BY: cần giữ chi tiết từng hũ để màn
  /// hình mở ra xem được, và số dòng một trẻ có trong một ngày là hàng chục,
  /// không phải hàng vạn.
  Stream<List<LedgerEntry>> watchGroupedHistory(String memberId) {
    return watchHistory(memberId).map(groupLedgerRows);
  }
}

/// Gộp các dòng sổ cái theo thao tác. Hàm thuần để test được không cần DB.
List<LedgerEntry> groupLedgerRows(List<PointTransaction> rows) {
  final order = <String>[];
  final buckets = <String, List<PointTransaction>>{};

  for (final row in rows) {
    final key = row.opGroupId ?? row.id;
    if (!buckets.containsKey(key)) {
      buckets[key] = [];
      order.add(key);
    }
    buckets[key]!.add(row);
  }

  return [
    for (final key in order)
      () {
        final group = buckets[key]!;
        final first = group.first;
        return LedgerEntry(
          groupId: key,
          reason: first.reason,
          delta: group.fold(0, (sum, r) => sum + r.delta),
          // Mốc thời gian sớm nhất trong nhóm: ba dòng ghi trong cùng một
          // transaction nhưng `currentDateAndTime` có thể lệch nhau một giây.
          createdAt: group
              .map((r) => r.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b),
          byJar: {for (final r in group) r.jar: r.delta},
          refType: first.refType,
          refId: first.refId,
          note: first.note,
        );
      }(),
  ];
}
