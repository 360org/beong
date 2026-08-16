import 'dart:io';

import 'package:beong/core/diagnostics/nhat_ky_loi.dart';
import 'package:beong/core/utils/ngay_viet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Thông tin thiết bị đính vào báo cáo lỗi.
///
/// Đọc từ `dart:io` chứ không thêm gói `device_info_plus`: những gì gói đó cho
/// thêm (tên thương mại của máy) không đáng một phụ thuộc mới, mà mỗi gói mới
/// còn là một dòng phải khai trong chính sách quyền riêng tư.
@immutable
class ThongTinThietBi {
  const ThongTinThietBi({
    required this.heDieuHanh,
    required this.phienBanHeDieuHanh,
    required this.phienBanApp,
    required this.chieuRong,
    required this.chieuCao,
    required this.tyLePhongChu,
    required this.banDebug,
  });

  /// Gom thông tin hiện tại.
  ///
  /// [phienBanApp] truyền vào chứ không tự đọc: `package_info_plus` là một gói
  /// nữa, mà số này đã nằm sẵn trong `pubspec.yaml` lúc dựng.
  factory ThongTinThietBi.thuThap({
    required String phienBanApp,
    required Size kichThuocManHinh,
    required double tyLePhongChu,
  }) {
    return ThongTinThietBi(
      heDieuHanh: Platform.operatingSystem,
      phienBanHeDieuHanh: Platform.operatingSystemVersion,
      phienBanApp: phienBanApp,
      chieuRong: kichThuocManHinh.width,
      chieuCao: kichThuocManHinh.height,
      tyLePhongChu: tyLePhongChu,
      banDebug: kDebugMode,
    );
  }

  final String heDieuHanh;
  final String phienBanHeDieuHanh;
  final String phienBanApp;

  /// Kích thước màn hình theo logical pixel. Rất nhiều lỗi bố cục chỉ xảy ra ở
  /// một cỡ màn nhất định, và đây là thứ đầu tiên cần biết để dựng lại.
  final double chieuRong;
  final double chieuCao;

  /// Cỡ chữ hệ thống người dùng đang đặt — nguồn của cả một lớp lỗi tràn chữ.
  final double tyLePhongChu;

  final bool banDebug;
}

/// Một báo cáo lỗi hoàn chỉnh, chưa gửi.
@immutable
class BaoCaoLoi {
  const BaoCaoLoi({
    required this.moTaNguoiDung,
    required this.thietBi,
    required this.nhatKy,
    this.duongDanAnh,
  });

  /// Người dùng tự kể chuyện gì đã xảy ra. Đây là phần **giá trị nhất** của cả
  /// báo cáo: stack trace nói lỗi ở đâu, còn dòng này nói người ta đang cố làm
  /// gì — thứ không suy ra được từ log.
  final String moTaNguoiDung;

  final ThongTinThietBi thietBi;
  final List<MucNhatKy> nhatKy;

  /// Ảnh màn hình đã lưu ra file, `null` nếu người dùng bỏ chọn.
  final String? duongDanAnh;

  /// Tiêu đề issue. Cắt ngắn vì GitHub cắt tiêu đề dài trong danh sách.
  String get tieuDe {
    final dong = moTaNguoiDung.trim().split('\n').first.trim();
    if (dong.isEmpty) return 'Báo lỗi từ app';
    return dong.length <= 70 ? dong : '${dong.substring(0, 70)}…';
  }

  /// Thân issue dạng Markdown.
  String get than {
    final b = StringBuffer()
      ..writeln('### Chuyện gì đã xảy ra')
      ..writeln()
      ..writeln(
        moTaNguoiDung.trim().isEmpty ? '_(chưa mô tả)_' : moTaNguoiDung.trim(),
      )
      ..writeln()
      ..writeln('### Thiết bị')
      ..writeln()
      ..writeln('| | |')
      ..writeln('|---|---|')
      ..writeln(
        '| App | ${thietBi.phienBanApp}${thietBi.banDebug ? ' (debug)' : ''} |',
      )
      ..writeln('| Hệ điều hành | ${thietBi.heDieuHanh} |')
      ..writeln('| Phiên bản HĐH | ${thietBi.phienBanHeDieuHanh} |')
      ..writeln(
        '| Màn hình | ${thietBi.chieuRong.round()}×${thietBi.chieuCao.round()} dp |',
      )
      ..writeln(
        '| Cỡ chữ hệ thống | ×${thietBi.tyLePhongChu.toStringAsFixed(2)} |',
      )
      ..writeln()
      ..writeln('### Nhật ký lỗi')
      ..writeln();

    if (nhatKy.isEmpty) {
      // Nói rõ "không có lỗi nào" thay vì để trống: khối trống đọc như phần thu
      // thập bị hỏng, và người xử lý sẽ đi tìm nhầm chỗ.
      b.writeln('_Không có lỗi nào được ghi trong phiên này._');
    } else {
      b.writeln('```');
      for (final muc in nhatKy) {
        b.writeln(
          '[${ngayGio(muc.thoiDiem)}] ${muc.nguon ?? '?'}: ${muc.moTa}',
        );
        if (muc.stack != null) b.writeln(muc.stack);
      }
      b.writeln('```');
    }

    if (duongDanAnh != null) {
      b
        ..writeln()
        ..writeln('### Ảnh màn hình')
        ..writeln()
        ..writeln(
          '_Ảnh đã được lưu vào máy; kéo thả vào ô này để đính kèm._',
        );
    }

    return b.toString();
  }
}
