import 'package:beong/core/diagnostics/bao_cao_loi.dart';

/// Repo nhận báo cáo lỗi.
///
/// Để ở đây chứ không trong `--dart-define`: đây là địa chỉ công khai của dự
/// án, không phải bí mật, và giấu nó đi chỉ làm người đọc mã phải đi tìm.
const kGitHubOwner = '360org';
const kGitHubRepo = 'beong';

/// Trần độ dài URL.
///
/// GitHub trả 414 với URL quá dài, và trình duyệt cũng có trần riêng. 6.000 ký
/// tự là ngưỡng an toàn ở mọi nền tảng. Vượt thì cắt bớt nhật ký chứ **không**
/// cắt phần người dùng tự kể — đó mới là phần không tái tạo được.
const kToiDaDoDaiUrl = 6000;

/// Dựng URL mở sẵn form tạo issue trên GitHub với tiêu đề và thân đã điền.
///
/// **Cố ý không gọi API GitHub.** Gọi API cần token, mà token nhúng trong
/// APK/IPA thì ai cũng rút ra được và nó có quyền ghi vào repo — một lỗ hổng
/// thật, không phải chuyện lý thuyết. Đường này không cần bí mật nào, và còn
/// được thêm một điều đúng đắn: **người dùng nhìn thấy toàn bộ nội dung trước
/// khi bấm gửi**. Báo cáo có tên con và thói quen sinh hoạt của gia đình, nên
/// đăng lên một nơi công khai phải là hành động có ý thức của họ.
///
/// Khi có backend (Sprint 3) thì thay bằng một endpoint giữ token phía máy chủ
/// — lúc đó gửi được cả ảnh và không cần rời app.
Uri urlTaoIssue(BaoCaoLoi baoCao) {
  final than = _catVuaUrl(baoCao);
  return Uri.https(
    'github.com',
    '/$kGitHubOwner/$kGitHubRepo/issues/new',
    <String, String>{
      'title': baoCao.tieuDe,
      'body': than,
      // Nhãn ASCII, không dấu: nhãn có dấu phải tạo sẵn đúng từng ký tự trong
      // repo mới khớp, sai một dấu là GitHub bỏ qua lặng lẽ. Hai nhãn này cần
      // được tạo trong repo trước — GitHub không tự tạo nhãn từ URL.
      'labels': 'bug,from-app',
    },
  );
}

/// Cắt thân báo cáo cho vừa trần URL.
///
/// Cắt từ **cuối** nhật ký trở lên: lỗi mới nhất thường là lỗi người dùng vừa
/// gặp, nhưng chuỗi dẫn tới nó nằm ở trên — nên giữ đầu, bỏ đuôi, và nói rõ là
/// đã bỏ.
String _catVuaUrl(BaoCaoLoi baoCao) {
  final than = baoCao.than;
  // Ký tự tiếng Việt thành 9 ký tự sau khi mã hoá URL, nên đo trên chuỗi đã mã
  // hoá chứ không đo trên chuỗi gốc — đo sai chỗ này là ra URL dài gấp ba.
  if (Uri.encodeComponent(than).length <= kToiDaDoDaiUrl) return than;

  final dong = than.split('\n');
  final giu = <String>[];
  var doDai = 0;
  for (final d in dong) {
    final them = Uri.encodeComponent('$d\n').length;
    if (doDai + them > kToiDaDoDaiUrl - 200) break;
    giu.add(d);
    doDai += them;
  }
  return '${giu.join('\n')}\n```\n\n_(nhật ký đã bị cắt bớt cho vừa đường dẫn '
      '— đính kèm file báo cáo nếu cần đầy đủ)_';
}
