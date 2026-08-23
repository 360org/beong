import 'dart:async';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/domain/services/pairing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sheet hiển thị mã ghép cặp (QR code / text code) cho phụ huynh cấp cho máy con.
///
/// Tuân thủ spec `docs/09-onboarding-pairing.md` §4:
/// - Mã 128-bit ngẫu nhiên.
/// - Đếm ngược 10 phút.
/// - Định dạng URI `beong://pair?v=1&c=<code>`.
/// - Nút làm mới/tạo lại mã.
Future<void> showPairingCodeSheet(
  BuildContext context, {
  required String childName,
  required String childMemberId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (ctx) => _PairingCodeSheet(
      childName: childName,
      childMemberId: childMemberId,
    ),
  );
}

class _PairingCodeSheet extends StatefulWidget {
  const _PairingCodeSheet({
    required this.childName,
    required this.childMemberId,
  });

  final String childName;
  final String childMemberId;

  @override
  State<_PairingCodeSheet> createState() => _PairingCodeSheetState();
}

class _PairingCodeSheetState extends State<_PairingCodeSheet> {
  static const _pairingService = PairingService();

  late String _code;
  late String _uri;
  late DateTime _createdAt;
  late Timer _timer;
  int _secondsLeft = 600;

  @override
  void initState() {
    super.initState();
    _generateNewCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final left = 600 - DateTime.now().difference(_createdAt).inSeconds;
      if (left <= 0) {
        setState(() {
          _secondsLeft = 0;
        });
      } else {
        setState(() {
          _secondsLeft = left;
        });
      }
    });
  }

  void _generateNewCode() {
    _code = _pairingService.generateCode();
    _uri = _pairingService.buildPairingUri(_code);
    _createdAt = DateTime.now();
    _secondsLeft = 600;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _secondsLeft <= 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ghép cặp máy của ${widget.childName}',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Mở ứng dụng Bé Ong trên máy của bé, chọn vai "Con" rồi quét mã này để hoàn tất kết nối.',
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isExpired ? AppColors.dangerLight : AppColors.brand360Blue,
                    width: 2,
                  ),
                ),
                child: isExpired
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_off_outlined, size: 64, color: AppColors.dangerLight),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Mã đã hết hạn', style: context.text.titleSmall?.copyWith(color: AppColors.dangerLight)),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SelectableText(
                            _code.substring(0, 8).toUpperCase(),
                            style: context.text.titleLarge?.copyWith(
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brand360Blue,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: isExpired ? AppColors.dangerLight : context.semantic.onSurfaceMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  isExpired ? 'Đã hết hạn' : 'Hiệu lực còn: ${_formatTime(_secondsLeft)}',
                  style: context.text.bodyMedium?.copyWith(
                    color: isExpired ? AppColors.dangerLight : context.semantic.onSurfaceMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                setState(_generateNewCode);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tạo mã mới'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _uri));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép liên kết ghép cặp!')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Sao chép liên kết'),
            ),
          ],
        ),
      ),
    );
  }
}
