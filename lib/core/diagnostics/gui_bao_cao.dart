import 'dart:convert';
import 'dart:io';

import 'package:beong/core/diagnostics/bao_cao_loi.dart';
import 'package:http/http.dart' as http;

/// Địa chỉ nhận báo cáo lỗi, nạp lúc dựng bằng
/// `--dart-define=BEONG_REPORT_ENDPOINT=https://...`.
///
/// **Không nhúng token GitHub vào app.** Token trong APK/IPA thì ai cũng rút ra
/// được bằng `unzip`, và nó có quyền ghi vào repo — lỗ hổng thật, không phải
/// chuyện lý thuyết. Endpoint này là một hàm nhỏ do nhà phát triển tự dựng, nó
/// giữ token phía máy chủ và tạo issue hộ. Xem `docs/11-bao-loi-endpoint.md`
/// để dựng, mất khoảng năm phút.
///
/// Rỗng nghĩa là bản dựng này chưa cấu hình endpoint — lúc đó [guiBaoCao] rơi
/// về đường dự phòng, xem [KetQuaGui].
const kEndpointBaoCao = String.fromEnvironment('BEONG_REPORT_ENDPOINT');

/// Repo nhận báo cáo, dùng cho đường dự phòng khi chưa có endpoint.
///
/// Để ở đây chứ không trong `--dart-define`: đây là địa chỉ công khai của dự
/// án, không phải bí mật.
const kGitHubOwner = '360org';
const kGitHubRepo = 'beong';

/// Trần độ dài URL cho đường dự phòng.
///
/// GitHub trả 414 với URL quá dài, và trình duyệt cũng có trần riêng. 6.000 ký
/// tự là ngưỡng an toàn ở mọi nền tảng.
const kToiDaDoDaiUrl = 6000;

/// Thời gian chờ máy chủ. Ngắn có chủ ý: người dùng vừa gặp lỗi, bắt họ nhìn
/// vòng xoay thêm nửa phút nữa là hỏng nốt phần còn lại của trải nghiệm.
const kThoiGianChoGui = Duration(seconds: 20);

/// Kết quả một lần gửi.
enum KetQuaGui {
  /// Máy chủ đã nhận. Không cần người dùng làm gì thêm.
  thanhCong,

  /// Gửi hỏng — mất mạng, máy chủ lỗi, hoặc quá hạn chờ.
  that,

  /// Bản dựng này chưa cấu hình endpoint.
  ///
  /// Không phải lỗi của người dùng và cũng không im lặng bỏ qua: chỗ gọi sẽ mở
  /// đường dự phòng. Tách riêng khỏi [that] vì hai ca cần hai cách xử lý khác
  /// hẳn nhau.
  chuaCauHinh,
}

/// Gửi báo cáo lên máy chủ nhận lỗi.
///
/// Không ném exception: màn báo lỗi mà tự nó ném lỗi thì người dùng hết đường.
///
/// [endpoint] và [client] cho tiêm vào để test được — mặc định là cấu hình
/// thật. Không tiêm được thì nhánh xử lý mã trạng thái, thứ dễ sai nhất ở đây,
/// sẽ không bao giờ có test nào chạm tới.
Future<KetQuaGui> guiBaoCao(
  BaoCaoLoi baoCao, {
  http.Client? client,
  String endpoint = kEndpointBaoCao,
}) async {
  if (endpoint.isEmpty) return KetQuaGui.chuaCauHinh;

  final tuTao = client == null;
  final c = client ?? http.Client();
  try {
    final res = await c
        .post(
          Uri.parse(endpoint),
          headers: const {'content-type': 'application/json; charset=utf-8'},
          body: jsonEncode(await taoGoiGui(baoCao)),
        )
        .timeout(kThoiGianChoGui);

    // 2xx là nhận. Máy chủ trả gì trong thân thì kệ — app không cần biết số
    // issue, và bắt nó phụ thuộc vào định dạng phản hồi chỉ tạo thêm chỗ vỡ.
    return res.statusCode >= 200 && res.statusCode < 300
        ? KetQuaGui.thanhCong
        : KetQuaGui.that;
  } on Object {
    // Mất mạng, DNS hỏng, quá hạn, JSON lỗi — với người dùng đều là một chuyện:
    // "chưa gửi được". Phân biệt kỹ hơn cũng không giúp họ làm gì khác.
    return KetQuaGui.that;
  } finally {
    if (tuTao) c.close();
  }
}

/// Gói JSON gửi lên máy chủ.
///
/// Ảnh đi kèm dạng base64 trong cùng một request thay vì upload riêng: một
/// lượt gọi thì hoặc thành công cả gói hoặc hỏng cả gói, không có trạng thái
/// nửa vời "đã có issue nhưng thiếu ảnh".
Future<Map<String, Object?>> taoGoiGui(BaoCaoLoi baoCao) async {
  final duongDan = baoCao.duongDanAnh;
  String? anhBase64;
  if (duongDan != null) {
    try {
      anhBase64 = base64Encode(await File(duongDan).readAsBytes());
    } on Object {
      // Đọc ảnh hỏng thì gửi báo cáo không ảnh, hơn là không gửi được gì.
      anhBase64 = null;
    }
  }

  return {
    'tieu_de': baoCao.tieuDe,
    'than': baoCao.than,
    'phien_ban_app': baoCao.thietBi.phienBanApp,
    'he_dieu_hanh': baoCao.thietBi.heDieuHanh,
    'anh_png_base64': ?anhBase64,
  };
}

/// Đường **dự phòng**: mở form tạo issue GitHub với nội dung điền sẵn.
///
/// Chỉ dùng khi bản dựng chưa cấu hình endpoint. Người dùng thường không bao
/// giờ thấy đường này — bản phát hành luôn có endpoint.
Uri urlTaoIssue(BaoCaoLoi baoCao) {
  return Uri.https(
    'github.com',
    '/$kGitHubOwner/$kGitHubRepo/issues/new',
    <String, String>{
      'title': baoCao.tieuDe,
      'body': _catVuaUrl(baoCao),
      // Nhãn ASCII, không dấu: nhãn có dấu phải tạo sẵn đúng từng ký tự trong
      // repo mới khớp, sai một dấu là GitHub bỏ qua lặng lẽ.
      'labels': 'bug,from-app',
    },
  );
}

/// Cắt thân báo cáo cho vừa trần URL.
///
/// Cắt từ **cuối** nhật ký trở lên: lỗi mới nhất thường là lỗi người dùng vừa
/// gặp, nhưng chuỗi dẫn tới nó nằm ở trên — nên giữ đầu, bỏ đuôi, và nói rõ là
/// đã bỏ. Phần người dùng tự kể nằm ở đầu nên không bao giờ bị cắt: log tái
/// tạo được, câu người ta kể thì không.
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
  return '${giu.join('\n')}\n```\n\n_(nhật ký đã bị cắt bớt cho vừa đường dẫn)_';
}
