import 'dart:async';

import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/domain/services/parent_pin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hỏi PIN trước khi vào vai bố mẹ.
///
/// Trả về `true` nếu đúng PIN hoặc nhà chưa đặt PIN.
Future<bool> askParentPin(
  BuildContext context, {
  required String familyId,
  required ParentPinService service,
}) async {
  if (!await service.isSet(familyId)) return true;
  if (!context.mounted) return false;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _PinSheet(
        title: 'Nhập PIN của bố mẹ',
        subtitle: 'Để vào phần dành cho bố mẹ.',
        onSubmit: (pin) => service.verify(familyId: familyId, pin: pin),
        onQuen: () => _quenPin(
          sheetContext,
          familyId: familyId,
          service: service,
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// Gỡ PIN cho người đã quên nó.
///
/// Trước bản này, đường duy nhất bỏ PIN nằm **bên trong** Cài đặt, mà Cài đặt
/// thì chỉ vai bố mẹ vào được, mà vào vai bố mẹ thì phải qua đúng cái PIN vừa
/// quên. Lối ra duy nhất là gỡ app — tức là **mất sạch dữ liệu**
/// (`docs/13-audit-luong-vao-app.md` §3).
///
/// Vì sao cho gỡ mà không hỏi gì thêm: PIN bốn số này chưa bao giờ là bảo mật
/// thật (xem [ParentPinService]) — nó chặn một đứa trẻ tò mò. Người đang cầm
/// máy vốn đã đọc được thẳng file dữ liệu, nên "gỡ PIN cần có máy trong tay"
/// không hạ mức bảo vệ đi chút nào. Nó chỉ bỏ đi cái bẫy mất dữ liệu.
Future<void> _quenPin(
  BuildContext context, {
  required String familyId,
  required ParentPinService service,
}) async {
  final dongY = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Gỡ PIN?'),
      content: const Text(
        'Nhà mình sẽ không còn PIN nữa: từ giờ ai cầm máy cũng vào được phần '
        'của bố mẹ. Dữ liệu vẫn còn nguyên, và bố mẹ đặt PIN mới bất cứ lúc '
        'nào trong Cài đặt.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('THÔI'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('GỠ PIN'),
        ),
      ],
    ),
  );
  if (dongY != true) return;

  await service.clearPin(familyId);
  if (!context.mounted) return;

  // Đóng luôn sheet với kết quả thành công: gỡ xong mà vẫn bắt nhập PIN vừa
  // xoá thì chẳng gỡ được gì.
  Navigator.of(context).pop(true);
}

/// Đặt PIN mới. Trả về `true` nếu đã đặt xong.
Future<bool> askNewParentPin(
  BuildContext context, {
  required String familyId,
  required ParentPinService service,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _PinSheet(
        title: 'Đặt PIN cho bố mẹ',
        // Nói trước cách thoát, ngay lúc đặt: người biết mình gỡ được thì không
        // hoảng khi quên, và cũng không tự dựng ra một cái bẫy cho chính mình.
        subtitle:
            'Bốn chữ số. Con sẽ phải nhập PIN này mới vào được phần của bố mẹ.\n'
            'Quên PIN thì gỡ được ngay trên máy này, không cần cài lại app.',
        onSubmit: (pin) async {
          await service.setPin(familyId: familyId, pin: pin);
          return true;
        },
      ),
    ),
  );
  return ok ?? false;
}

class _PinSheet extends StatefulWidget {
  const _PinSheet({
    required this.title,
    required this.subtitle,
    required this.onSubmit,
    this.onQuen,
  });

  final String title;
  final String subtitle;

  /// Có thì hiện đường "Quên PIN?". Chỉ sheet *nhập* PIN mới cần — sheet *đặt*
  /// PIN thì chưa có gì để quên.
  final VoidCallback? onQuen;

  /// Trả `true` là đóng sheet với kết quả thành công.
  final Future<bool> Function(String pin) onSubmit;

  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  final _controller = TextEditingController();
  bool _wrong = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    // Xoá thông báo sai ngay khi bố mẹ gõ lại: để nguyên chữ đỏ trong lúc người
    // ta đang sửa thì đọc như đang tiếp tục sai.
    if (_wrong) setState(() => _wrong = false);
    if (_controller.text.length == ParentPinService.pinLength) {
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
    if (_busy) return;
    setState(() => _busy = true);

    final ok = await widget.onSubmit(_controller.text);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      // Xoá ô **trước** rồi mới bật chữ đỏ, không gộp vào cùng một `setState`.
      // `clear()` chạy listener ngay lập tức, mà listener lại tắt `_wrong` —
      // gộp lại thì báo lỗi bị xoá ngay trong cùng khung hình và người nhập sai
      // PIN không thấy thông báo nào cả.
      _controller.clear();
      setState(() {
        _wrong = true;
        _busy = false;
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
          Text(widget.title, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.subtitle,
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            // Che số: người đứng cạnh — thường là chính đứa trẻ — không đọc trộm
            // được PIN khi bố mẹ nhập.
            obscureText: true,
            maxLength: ParentPinService.pinLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: context.text.titleLarge?.copyWith(letterSpacing: 12),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              errorText: _wrong ? 'PIN chưa đúng, thử lại nhé' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
                child: const Text('Quên PIN?'),
              ),
            ),
        ],
      ),
    );
  }
}
