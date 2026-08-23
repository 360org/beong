import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Dịch vụ quản lý mã ghép cặp thiết bị con (QR Pairing).
///
/// Tuân thủ quy định tại `docs/09-onboarding-pairing.md` §4:
/// - Mã ghép cặp ngẫu nhiên 128 bit.
/// - Thời hạn hiệu lực: 10 phút.
/// - Định dạng URI mã hoá QR: `beong://pair?v=1&c=<code>` (không chứa id gia đình hay tên con).
/// - Server/Local chỉ lưu trữ chuỗi hash SHA-256 của mã.
class PairingService {
  const PairingService();

  /// Thời hạn hiệu lực mặc định của một mã ghép cặp.
  static const Duration maHieuLuc = Duration(minutes: 10);

  /// Tạo một chuỗi mã ngẫu nhiên 128-bit (32 ký tự hex) an toàn.
  String generateCode() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Băm mã bằng SHA-256 để lưu trữ an toàn.
  String hash(String code) {
    final bytes = utf8.encode(code.trim().toLowerCase());
    return sha256.convert(bytes).toString();
  }

  /// Đóng gói mã thành chuỗi Universal Link chuẩn để mở app hoặc chuyển hướng App Store / Google Play.
  String buildPairingUri(String code) {
    return 'https://beong.net/pair?v=1&c=$code';
  }

  /// Trích xuất mã ghép cặp từ chuỗi quét QR (chấp nhận cả Universal Link https://beong.net/pair lẫn Custom Scheme beong://pair).
  /// Trả về null nếu định dạng URI không hợp lệ.
  String? parsePairingUri(String rawUri) {
    try {
      final uri = Uri.parse(rawUri.trim());
      final isCustomScheme = uri.scheme == 'beong' && uri.host == 'pair';
      final isUniversalLink = (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host == 'beong.net' &&
          uri.path.startsWith('/pair');

      if (!isCustomScheme && !isUniversalLink) return null;

      final version = uri.queryParameters['v'];
      final code = uri.queryParameters['c'];
      if (version != '1' || code == null || code.isEmpty) return null;
      return code.trim().toLowerCase();
    } on FormatException {
      return null;
    }
  }

  /// Kiểm tra xem mã ghép cặp đã hết hạn hay chưa.
  bool isExpired(DateTime createdAt, {DateTime? now}) {
    final current = now ?? DateTime.now();
    return current.isAfter(createdAt.add(maHieuLuc));
  }
}
