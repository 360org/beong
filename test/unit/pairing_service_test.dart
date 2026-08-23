import 'package:beong/domain/services/pairing_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = PairingService();

  group('PairingService Tests', () {
    test('generateCode sinh chuỗi hex 32 ký tự hợp lệ', () {
      final code1 = service.generateCode();
      final code2 = service.generateCode();

      expect(code1.length, 32);
      expect(code2.length, 32);
      expect(code1, isNot(equals(code2)));
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(code1), isTrue);
    });

    test('hash tạo mã SHA-256 nhất quán', () {
      const code = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';
      final h1 = service.hash(code);
      final h2 = service.hash('  A1B2C3D4E5F60718293A4B5C6D7E8F90  ');

      expect(h1, equals(h2));
      expect(h1.length, 64);
    });

    test('buildPairingUri & parsePairingUri đóng gói và giải mã chính xác', () {
      const code = 'abc123def45678901234567890123456';
      final uri = service.buildPairingUri(code);

      // Universal Link chứ không phải custom scheme: Camera mặc định của máy
      // mở được https, còn `beong://` thì nó không biết là gì (commit f87ee31).
      expect(
        uri,
        equals('https://beong.net/pair?v=1&c=abc123def45678901234567890123456'),
      );

      final parsed = service.parsePairingUri(uri);
      expect(parsed, equals(code));
    });

    test('parsePairingUri từ chối các định dạng sai', () {
      expect(
        service.parsePairingUri('https://beong.net/pair?code=123'),
        isNull,
      );
      expect(service.parsePairingUri('beong://pair?v=2&c=123'), isNull);
      expect(service.parsePairingUri('beong://wrong?v=1&c=123'), isNull);
      expect(service.parsePairingUri('beong://pair?v=1'), isNull);
      expect(service.parsePairingUri('invalid_uri'), isNull);
    });

    test('isExpired kiểm tra đúng thời hạn 10 phút', () {
      final now = DateTime(2026, 8, 23, 10);
      final created9MinAgo = now.subtract(const Duration(minutes: 9));
      final created11MinAgo = now.subtract(const Duration(minutes: 11));

      expect(service.isExpired(created9MinAgo, now: now), isFalse);
      expect(service.isExpired(created11MinAgo, now: now), isTrue);
    });
  });
}
