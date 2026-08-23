import 'dart:convert';
import 'package:beong/data/local/database.dart';
import 'package:beong/domain/services/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase.memory();
    engine = SyncEngine(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncEngine Tests', () {
    test('enqueue đẩy bản ghi vào bảng Outbox', () async {
      await engine.enqueue(
        op: 'insert',
        entity: 'tasks',
        entityId: 'task-123',
        payload: {'title': 'Rửa bát', 'points': 10},
        clientOpId: 'client-op-1',
      );

      final ops = await engine.getPendingOps();
      expect(ops.length, 1);
      expect(ops.first.op, 'insert');
      expect(ops.first.entity, 'tasks');
      expect(ops.first.entityId, 'task-123');
      expect(ops.first.clientOpId, 'client-op-1');

      final decoded = jsonDecode(ops.first.payloadJson) as Map<String, dynamic>;
      expect(decoded['title'], 'Rửa bát');
      expect(decoded['points'], 10);
    });

    test('processQueue xử lý và dọn dẹp Outbox khi thành công', () async {
      await engine.enqueue(
        op: 'update',
        entity: 'task_instances',
        entityId: 'inst-1',
        payload: {'status': 'completed'},
        clientOpId: 'client-op-2',
      );

      final processed = await engine.processQueue(
        uploader: (op) async => true,
      );

      expect(processed, 1);

      final remaining = await engine.getPendingOps();
      expect(remaining, isEmpty);
    });

    test(
      'processQueue tăng retryCount và giữ lại bản ghi khi thất bại',
      () async {
        await engine.enqueue(
          op: 'update',
          entity: 'task_instances',
          entityId: 'inst-2',
          payload: {'status': 'completed'},
          clientOpId: 'client-op-3',
        );

        final processed = await engine.processQueue(
          uploader: (op) async => throw Exception('Network timeout'),
        );

        expect(processed, 0);

        final remaining = await engine.getPendingOps();
        expect(remaining.length, 1);
        expect(remaining.first.retryCount, 1);
        expect(remaining.first.lastError, contains('Network timeout'));
      },
    );
  });
}
