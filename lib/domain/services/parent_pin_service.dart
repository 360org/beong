import 'dart:convert';

import 'package:beong/data/local/member_dao.dart';
import 'package:crypto/crypto.dart';

/// PIN phụ huynh — chặn con tự đổi sang vai bố mẹ.
///
/// Trước dịch vụ này, đổi vai **không cần gì cả**: con bấm avatar, chọn "Bố mẹ",
/// và thế là tự duyệt được việc của mình, tự sửa tỷ lệ hũ, tự tắt trừ xu. Cả
/// vòng "bố mẹ duyệt" của ADR-023 và ADR-025 dựa trên giả định con không vào
/// được vai bố mẹ, mà giả định đó chưa từng được bảo vệ.
///
/// **Đây không phải bảo mật thật.** PIN 4 số băm SHA-256 chặn được một đứa trẻ
/// tò mò, không chặn được ai có file DB trong tay. Bảo vệ thật cần tài khoản
/// thật ở phía server (Sprint 3). Ghi rõ ở đây để không ai nhầm mức bảo đảm.
class ParentPinService {
  const ParentPinService({required MemberDao memberDao}) : _members = memberDao;

  final MemberDao _members;

  /// Độ dài PIN. Bốn số: đủ để một đứa trẻ không đoán bừa ra, đủ ngắn để bố mẹ
  /// nhập nhanh mỗi lần đổi vai.
  static const pinLength = 4;

  /// Gia đình này đã đặt PIN chưa.
  ///
  /// Chưa đặt thì **không chặn gì**: bật PIN là lựa chọn của bố mẹ, không phải
  /// thứ áp lên mọi nhà. Nhà một máy dùng chung, con còn nhỏ, thì thêm một lớp
  /// nhập số mỗi lần đổi vai chỉ gây phiền.
  Future<bool> isSet(String familyId) async {
    final parents = await _members.parents(familyId);
    return parents.any((p) => (p.pinHash ?? '').isNotEmpty);
  }

  /// Đặt hoặc đổi PIN cho **mọi** hồ sơ bố mẹ trong nhà.
  ///
  /// Một PIN chung cho cả nhà chứ không phải mỗi phụ huynh một PIN: mục đích là
  /// ngăn *trẻ con*, không phải phân quyền giữa bố và mẹ. Hai PIN khác nhau chỉ
  /// tạo thêm thứ để quên.
  Future<void> setPin({required String familyId, required String pin}) async {
    if (!isValidFormat(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN phải gồm $pinLength chữ số');
    }
    final hash = hashPin(pin);
    for (final parent in await _members.parents(familyId)) {
      await _members.setPinHash(memberId: parent.id, pinHash: hash);
    }
  }

  /// Bỏ PIN.
  Future<void> clearPin(String familyId) async {
    for (final parent in await _members.parents(familyId)) {
      await _members.setPinHash(memberId: parent.id, pinHash: null);
    }
  }

  /// PIN nhập vào có đúng không.
  ///
  /// Nhà chưa đặt PIN thì trả `true`: không có khoá thì không khoá ai cả. Trả
  /// `false` ở đây sẽ khoá cứng vai bố mẹ của mọi nhà chưa đặt PIN.
  Future<bool> verify({required String familyId, required String pin}) async {
    final parents = await _members.parents(familyId);
    final hashes = parents
        .map((p) => p.pinHash ?? '')
        .where((h) => h.isNotEmpty)
        .toSet();
    if (hashes.isEmpty) return true;
    return hashes.contains(hashPin(pin));
  }

  /// `true` nếu [pin] đúng dạng: đủ [pinLength] ký tự và toàn chữ số.
  static bool isValidFormat(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  /// Băm PIN bằng SHA-256.
  ///
  /// Không thêm muối: muối phải lưu ở đâu đó, mà chỗ duy nhất có là chính DB
  /// này — kẻ đọc được DB thì đọc được cả muối, nên nó không thêm bảo đảm nào
  /// mà chỉ làm code khó hơn. Với 10.000 khả năng của PIN 4 số thì băm gì cũng
  /// dò ra trong tích tắc; giá trị thật của lớp này là chặn *trẻ con*, và điều
  /// đó thì SHA-256 trần làm được.
  static String hashPin(String pin) =>
      sha256.convert(utf8.encode('beong-pin:$pin')).toString();
}
