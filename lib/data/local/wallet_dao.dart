import 'dart:convert';

import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/tables/tables.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/jar_splitter.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

part 'wallet_dao.g.dart';

/// Số dư ba hũ của một trẻ.
@immutable
class WalletBalance {
  const WalletBalance({
    required this.spend,
    required this.save,
    required this.give,
  });

  static const zero = WalletBalance(spend: 0, save: 0, give: 0);

  final int spend;
  final int save;
  final int give;

  int get total => spend + save + give;

  int of(Jar jar) => switch (jar) {
    Jar.spend => spend,
    Jar.save => save,
    Jar.give => give,
  };

  @override
  bool operator ==(Object other) =>
      other is WalletBalance &&
      other.spend == spend &&
      other.save == save &&
      other.give == give;

  @override
  int get hashCode => Object.hash(spend, save, give);

  @override
  String toString() =>
      'WalletBalance(tiêu $spend, để dành $save, cho đi $give)';
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

    var spend = 0;
    var save = 0;
    var give = 0;
    for (final row in rows) {
      final total = row.read(deltaSum) ?? 0;
      switch (row.read(pointTransactions.jar)) {
        case 'spend':
          spend = total;
        case 'save':
          save = total;
        case 'give':
          give = total;
      }
    }
    return WalletBalance(spend: spend, save: save, give: give);
  }

  /// Theo dõi số dư, phát lại mỗi khi sổ cái đổi.
  Stream<WalletBalance> watchBalance(String memberId) {
    return (select(
      pointTransactions,
    )..where((t) => t.memberId.equals(memberId))).watch().map((rows) {
      var spend = 0;
      var save = 0;
      var give = 0;
      for (final row in rows) {
        switch (row.jar) {
          case 'spend':
            spend += row.delta;
          case 'save':
            save += row.delta;
          case 'give':
            give += row.delta;
        }
      }
      return WalletBalance(spend: spend, save: save, give: give);
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
          refType: refType,
          refId: refId,
          note: note,
          createdBy: createdBy,
        );
      }
      return written;
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

  /// Lịch sử giao dịch cho màn "Sổ của con" — mới nhất trước.
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
        jar: jar.name,
        delta: delta,
        reason: reason.name,
        clientOpId: clientOpId,
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
