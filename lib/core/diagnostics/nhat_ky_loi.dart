import 'package:flutter/foundation.dart';

/// Một lỗi đã xảy ra trong phiên chạy này.
@immutable
class MucNhatKy {
  const MucNhatKy({
    required this.thoiDiem,
    required this.moTa,
    this.nguon,
    this.stack,
  });

  final DateTime thoiDiem;

  /// Thông điệp lỗi, đã cắt ngắn.
  final String moTa;

  /// Chỗ lỗi phát ra: `flutter`, `platform`, hoặc tên do chỗ gọi đặt.
  final String? nguon;

  final String? stack;
}

/// Vòng đệm lỗi trong bộ nhớ, để đính vào báo cáo lỗi người dùng gửi.
///
/// **Chỉ trong RAM, mất khi đóng app.** Ghi xuống đĩa thì log lỗi sống lâu hơn
/// phiên chạy và thành một tệp dữ liệu cá nhân phải khai báo với store, phải có
/// đường xoá, phải nói trong chính sách quyền riêng tư — cái giá quá đắt cho
/// một tính năng chỉ cần biết "vừa nãy có gì hỏng".
///
/// Không ghi bất cứ thứ gì từ dữ liệu gia đình: chỉ thông điệp lỗi và stack.
class NhatKyLoi {
  NhatKyLoi({this.sucChua = 50});

  /// Số lỗi giữ lại. Vượt thì lỗi cũ nhất rơi ra.
  ///
  /// 50 đủ để thấy chuỗi sự kiện dẫn tới lỗi cuối, mà vẫn ngắn để báo cáo đọc
  /// được. Một vòng lặp lỗi thì hàng nghìn dòng giống nhau không nói thêm gì.
  final int sucChua;

  final _muc = <MucNhatKy>[];

  /// Bản chụp danh sách, mới nhất **cuối cùng** — đọc như một dòng thời gian.
  List<MucNhatKy> get muc => List.unmodifiable(_muc);

  bool get rong => _muc.isEmpty;

  void ghi(
    Object error, {
    StackTrace? stack,
    String? nguon,
  }) {
    _muc.add(
      MucNhatKy(
        thoiDiem: DateTime.now(),
        moTa: _catNgan('$error'),
        nguon: nguon,
        stack: stack == null ? null : _catNgan('$stack', toiDa: 1500),
      ),
    );
    if (_muc.length > sucChua) _muc.removeAt(0);
  }

  void xoa() => _muc.clear();

  /// Cắt bớt chuỗi quá dài.
  ///
  /// Một exception có thể mang theo cả nội dung một truy vấn hoặc một chuỗi
  /// JSON dài hàng chục nghìn ký tự; để nguyên thì báo cáo phình tới mức không
  /// dán nổi vào GitHub.
  static String _catNgan(String s, {int toiDa = 400}) =>
      s.length <= toiDa ? s : '${s.substring(0, toiDa)}… (đã cắt bớt)';
}

/// Vòng đệm dùng chung cho cả app.
///
/// Là biến toàn cục chứ không phải provider Riverpod: `FlutterError.onError`
/// được gắn trong `main()` **trước** khi có `ProviderScope`, và lỗi lúc dựng
/// cây widget cũng phải ghi được khi container chưa sẵn sàng.
final nhatKyLoi = NhatKyLoi();

/// Gắn vòng đệm vào các đường báo lỗi của Flutter. Gọi một lần trong `main()`.
///
/// Vẫn gọi tiếp handler mặc định: nuốt lỗi đi thì bảng đỏ lúc debug và log lúc
/// release đều biến mất, và ta mất đúng thứ đang cố thu thập.
void ganBatLoiToanCuc() {
  final macDinh = FlutterError.onError;
  FlutterError.onError = (details) {
    nhatKyLoi.ghi(
      details.exception,
      stack: details.stack,
      nguon: 'flutter',
    );
    macDinh?.call(details);
  };

  final macDinhNen = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    nhatKyLoi.ghi(error, stack: stack, nguon: 'platform');
    return macDinhNen?.call(error, stack) ?? false;
  };
}
