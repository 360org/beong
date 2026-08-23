import 'dart:convert';

import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:crypto/crypto.dart';

/// Mật khẩu của **từng hồ sơ** — ADR-027.
///
/// Trước ADR-027 đây là một PIN chung cho cả nhà, đặt trên hồ sơ bố mẹ, và
/// **tuỳ chọn**. Nay mỗi `member` — cả bố mẹ lẫn từng bé — có mật khẩu riêng,
/// và không hồ sơ nào được để trống.
///
/// Vai trò của nó cũng đổi theo, đây là chỗ dễ hiểu nhầm nhất: nó không còn chỉ
/// là cái chốt cửa Cài đặt, mà là cách **định danh ai đang dùng máy** — bước
/// "điền pass → vào đúng hồ sơ" của luồng vào app. Trên một máy dùng chung, đó
/// cũng là thứ giữ sổ xu của bé này khỏi tay bé kia.
///
/// **Vẫn không phải bảo mật thật.** Bốn chữ số băm SHA-256 không muối: ai cầm
/// được file dữ liệu thì dò ra trong tích tắc. Nó chặn người trong nhà mở nhầm
/// hồ sơ của nhau, không chặn kẻ tấn công. Quyền thật vẫn suy ra từ credential
/// khi có backend (ADR-018).
class MatKhauHoSo {
  const MatKhauHoSo({required MemberDao memberDao}) : _members = memberDao;

  final MemberDao _members;

  /// Độ dài mật khẩu. Bốn số: đủ để người khác trong nhà không đoán bừa ra, đủ
  /// ngắn để một đứa trẻ nhớ được — mà từ ADR-027 thì trẻ cũng phải nhớ.
  static const doDai = 4;

  /// Hồ sơ này đã có mật khẩu chưa.
  Future<bool> daDat(String memberId) async {
    final member = await _members.getMember(memberId);
    return (member.pinHash ?? '').isNotEmpty;
  }

  /// Những hồ sơ **chưa** có mật khẩu.
  ///
  /// ADR-027 nói không hồ sơ nào được để trống, nhưng máy cài từ bản cũ thì
  /// đang có đúng loại đó. Đây là chỗ luồng vào app hỏi để biết còn nợ ai.
  Future<List<Member>> chuaDat(String familyId) async {
    final all = await _members.watchMembers(familyId).first;
    return all.where((m) => (m.pinHash ?? '').isEmpty).toList();
  }

  /// Đặt hoặc đổi mật khẩu của **một** hồ sơ.
  Future<void> dat({required String memberId, required String matKhau}) async {
    if (!dungDinhDang(matKhau)) {
      throw ArgumentError.value(
        matKhau,
        'matKhau',
        'Mật khẩu phải gồm $doDai chữ số',
      );
    }
    await _members.setPinHash(memberId: memberId, pinHash: bam(matKhau));
  }

  /// Mật khẩu nhập vào có đúng của hồ sơ này không.
  ///
  /// Hồ sơ **chưa** đặt mật khẩu thì trả `true`: máy cài từ bản trước ADR-027
  /// còn hồ sơ trống, và khoá cứng chúng lại là khoá luôn người dùng ra khỏi dữ
  /// liệu của chính họ. Luồng vào app chịu trách nhiệm bắt đặt ngay sau đó.
  Future<bool> dung({required String memberId, required String matKhau}) async {
    final member = await _members.getMember(memberId);
    final hash = member.pinHash ?? '';
    if (hash.isEmpty) return true;
    return hash == bam(matKhau);
  }

  /// `true` nếu [matKhau] đủ [doDai] ký tự và toàn chữ số.
  static bool dungDinhDang(String matKhau) =>
      matKhau.length == doDai && RegExp(r'^\d+$').hasMatch(matKhau);

  /// Băm bằng SHA-256.
  ///
  /// Không thêm muối: muối phải lưu ở đâu đó, mà chỗ duy nhất có là chính DB
  /// này — kẻ đọc được DB thì đọc được cả muối. Với 10.000 khả năng của 4 chữ
  /// số thì băm gì cũng dò ra ngay; giá trị thật của lớp này là phân biệt người
  /// trong nhà, và điều đó thì SHA-256 trần làm được.
  static String bam(String matKhau) =>
      sha256.convert(utf8.encode('beong-pin:$matKhau')).toString();
}
