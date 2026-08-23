import 'dart:async';

import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/domain/services/mat_khau_ho_so.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hỏi mật khẩu của **một hồ sơ** trước khi mở nó (ADR-027).
///
/// Trả `true` nếu đúng, hoặc nếu hồ sơ chưa từng đặt mật khẩu — máy cài từ bản
/// trước ADR-027 còn hồ sơ như vậy, và khoá cứng chúng là khoá người dùng ra
/// khỏi dữ liệu của chính họ.
Future<bool> hoiMatKhau(
  BuildContext context, {
  required String memberId,
  required String tenHienThi,
  required MatKhauHoSo service,
  String? moTa,
}) async {
  if (!await service.daDat(memberId)) return true;
  if (!context.mounted) return false;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _MatKhauSheet(
        tieuDe: 'Mật khẩu của $tenHienThi',
        // Lời nhắc thay được: xác minh để **mở hồ sơ** và xác minh để **xoá cả
        // gia đình** là hai việc khác hẳn nhau, không nên nói cùng một câu.
        moTa: moTa ?? 'Nhập 4 chữ số để mở hồ sơ này.',
        onSubmit: (matKhau) =>
            service.dung(memberId: memberId, matKhau: matKhau),
        onQuen: () => _quenMatKhau(
          sheetContext,
          memberId: memberId,
          tenHienThi: tenHienThi,
          service: service,
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// Đặt mật khẩu mới cho một hồ sơ. Trả `true` nếu đã đặt xong.
///
/// [batBuoc] = không cho đóng sheet nếu chưa đặt. Onboarding dùng cờ này:
/// ADR-027 nói không hồ sơ nào được để trống, mà một cái nút HUỶ là đủ để lời
/// đó thành nói suông.
Future<bool> datMatKhauMoi(
  BuildContext context, {
  required String memberId,
  required String tenHienThi,
  required MatKhauHoSo service,
  bool batBuoc = false,
  String? moTa,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: !batBuoc,
    enableDrag: !batBuoc,
    builder: (sheetContext) => PopScope(
      canPop: !batBuoc,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _MatKhauSheet(
          tieuDe: 'Đặt mật khẩu cho $tenHienThi',
          moTa:
              moTa ??
              'Bốn chữ số. Lần sau mở hồ sơ này sẽ phải nhập đúng nó.\n'
                  'Quên thì đặt lại được ngay trên máy, không mất dữ liệu.',
          batBuoc: batBuoc,
          onSubmit: (matKhau) async {
            await service.dat(memberId: memberId, matKhau: matKhau);
            return true;
          },
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// Lối thoát khi quên mật khẩu — **đổi**, không phải **gỡ**.
///
/// Gỡ sẽ để lại một hồ sơ không mật khẩu, tức vi phạm chính ADR-027. Nó cũng
/// dựng lại đúng cái bẫy mà `docs/13-audit-luong-vao-app.md` §3 vừa gỡ, chỉ
/// đổi chiều: trước là quên thì mất đường vào, giờ là quên thì mất luôn khoá.
///
/// Vì sao cho đổi mà không đòi gì thêm: mật khẩu này chưa bao giờ là bảo mật
/// thật (xem [MatKhauHoSo]). Người đang cầm máy vốn đã đọc được thẳng file dữ
/// liệu, nên "đổi mật khẩu cần có máy trong tay" không hạ mức bảo vệ đi chút
/// nào. Nó chỉ bỏ đi cái bẫy mất dữ liệu.
Future<void> _quenMatKhau(
  BuildContext context, {
  required String memberId,
  required String tenHienThi,
  required MatKhauHoSo service,
}) async {
  final dongY = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Đặt lại mật khẩu?'),
      content: Text(
        'Hồ sơ «$tenHienThi» sẽ nhận mật khẩu mới ngay ở bước sau. Dữ liệu vẫn '
        'còn nguyên — xu, huy hiệu và sổ của hồ sơ này không mất gì cả.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('THÔI'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('ĐẶT LẠI'),
        ),
      ],
    ),
  );
  if (dongY != true || !context.mounted) return;

  final xong = await datMatKhauMoi(
    context,
    memberId: memberId,
    tenHienThi: tenHienThi,
    service: service,
    batBuoc: true,
    moTa: 'Bốn chữ số mới. Đặt xong là vào được hồ sơ ngay.',
  );
  if (!xong || !context.mounted) return;

  // Đặt xong thì vào luôn: bắt nhập lại mật khẩu vừa đặt là thêm một bước
  // không phục vụ ai.
  Navigator.of(context).pop(true);
}

class _MatKhauSheet extends StatefulWidget {
  const _MatKhauSheet({
    required this.tieuDe,
    required this.moTa,
    required this.onSubmit,
    this.onQuen,
    this.batBuoc = false,
  });

  final String tieuDe;
  final String moTa;

  /// Trả `true` là đóng sheet với kết quả thành công.
  final Future<bool> Function(String matKhau) onSubmit;

  /// Có thì hiện đường "Quên mật khẩu?". Chỉ sheet *nhập* mới cần — sheet *đặt*
  /// thì chưa có gì để quên.
  final VoidCallback? onQuen;

  /// Bỏ nút HUỶ. Dùng cho bước bắt buộc của onboarding.
  final bool batBuoc;

  @override
  State<_MatKhauSheet> createState() => _MatKhauSheetState();
}

class _MatKhauSheetState extends State<_MatKhauSheet> {
  final _controller = TextEditingController();
  bool _sai = false;
  bool _dangGui = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    // Xoá thông báo sai ngay khi người ta gõ lại: để nguyên chữ đỏ trong lúc
    // đang sửa thì đọc như đang tiếp tục sai.
    if (_sai) setState(() => _sai = false);
    if (_controller.text.length == MatKhauHoSo.doDai) {
      unawaited(_submit());
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_dangGui) return;
    setState(() => _dangGui = true);

    final ok = await widget.onSubmit(_controller.text);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      // Xoá ô **trước** rồi mới bật chữ đỏ, không gộp vào cùng một `setState`.
      // `clear()` chạy listener ngay lập tức, mà listener lại tắt `_sai` — gộp
      // lại thì báo lỗi bị xoá ngay trong cùng khung hình và người nhập sai
      // không thấy thông báo nào cả.
      _controller.clear();
      setState(() {
        _sai = true;
        _dangGui = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.tieuDe, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.moTa,
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            // Che số: người đứng cạnh không đọc trộm được.
            obscureText: true,
            maxLength: MatKhauHoSo.doDai,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: context.text.titleLarge?.copyWith(letterSpacing: 12),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              errorText: _sai ? 'Mật khẩu chưa đúng, thử lại nhé' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!widget.batBuoc)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('HUỶ'),
              ),
            ),
          if (widget.onQuen != null)
            Align(
              child: TextButton(
                onPressed: widget.onQuen,
                child: const Text('Quên mật khẩu?'),
              ),
            ),
        ],
      ),
    );
  }
}
