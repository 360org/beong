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
/// Rỗng nghĩa là bản dựng này chưa cấu hình endpoint — xem [KetQuaGui].
const kEndpointBaoCao = String.fromEnvironment('BEONG_REPORT_ENDPOINT');

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
  /// Tách riêng khỏi [that] vì nguyên nhân khác hẳn: không phải mạng hỏng mà là
  /// bản dựng thiếu cấu hình, và người dùng không tự sửa được. Bản phát hành
  /// luôn có endpoint (`docs/08-release-cicd.md`), nên ca này chỉ gặp ở bản
  /// dựng nội bộ.
  ///
  /// Trước đây chỗ gọi phản ứng bằng cách **mở trang tạo issue GitHub**. Đã bỏ:
  /// đẩy quy trình nội bộ của đội phát triển sang cho một phụ huynh đang bực vì
  /// app hỏng là bắt họ làm việc của mình, và nó kéo theo `url_launcher` cùng
  /// `androidx.browser` — thứ từng làm đỏ CI Android vì đòi AGP >= 8.9.
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
