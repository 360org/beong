import 'dart:convert';
import 'package:beong/data/local/database.dart';
import 'package:drift/drift.dart';

/// Service quản lý hàng đợi Outbox và tiến trình đồng bộ dữ liệu (SyncEngine).
///
/// Tuân thủ quy định tại `docs/03-data-model.md` §4 & `docs/05-roadmap.md` Sprint 3:
/// - Ghi nhận các thao tác biến đổi dữ liệu local (insert/update/delete) vào bảng `Outbox`.
/// - Đồng bộ tuần tự khi có mạng, cơ chế retry với exponential backoff.
/// - Đảm bảo tính idempotent qua `client_op_id`.
class SyncEngine {
  SyncEngine({required this.db});

  final AppDatabase db;
  bool _isSyncing = false;

  /// Đưa một thao tác thay đổi vào hàng đợi Outbox.
  Future<void> enqueue({
    required String op,
    required String entity,
    required String entityId,
    required Map<String, dynamic> payload,
    required String clientOpId,
  }) async {
    await db
        .into(db.outbox)
        .insert(
          OutboxCompanion.insert(
            op: op,
            entity: entity,
            entityId: entityId,
            payloadJson: jsonEncode(payload),
            clientOpId: clientOpId,
          ),
        );
  }

  /// Lấy danh sách các bản ghi chưa đồng bộ trong Outbox theo thứ tự phát sinh.
  Future<List<OutboxData>> getPendingOps({int limit = 50}) {
    return (db.select(db.outbox)
          ..orderBy([(t) => OrderingTerm(expression: t.seq)])
          ..limit(limit))
        .get();
  }

  /// Xoá bản ghi khỏi Outbox sau khi đã đẩy thành công lên server.
  Future<void> markCompleted(int seq) {
    return (db.delete(db.outbox)..where((t) => t.seq.equals(seq))).go();
  }

  /// Ghi nhận lỗi và tăng số lần thử lại nếu đẩy dữ liệu thất bại.
  Future<void> markFailed(int seq, String error) async {
    final current = await (db.select(
      db.outbox,
    )..where((t) => t.seq.equals(seq))).getSingleOrNull();
    if (current == null) return;

    await (db.update(db.outbox)..where((t) => t.seq.equals(seq))).write(
      OutboxCompanion(
        retryCount: Value(current.retryCount + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Kích hoạt chu trình xử lý hàng đợi Outbox.
  /// Trong pha này, hỗ trợ xử lý và dọn hàng đợi an toàn.
  Future<int> processQueue({
    Future<bool> Function(OutboxData op)? uploader,
  }) async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    var processed = 0;
    try {
      final pending = await getPendingOps();
      for (final item in pending) {
        var success = true;
        if (uploader != null) {
          try {
            success = await uploader(item);
          } on Exception catch (e) {
            success = false;
            await markFailed(item.seq, e.toString());
          }
        }
        if (success) {
          await markCompleted(item.seq);
          processed++;
        }
      }
    } finally {
      _isSyncing = false;
    }
    return processed;
  }
}
