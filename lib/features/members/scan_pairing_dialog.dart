import 'dart:async';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/domain/services/pairing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Màn hình/Dialog quét hoặc nhập mã ghép cặp cho thiết bị của con.
///
/// Tuân thủ quy trình tại `docs/09-onboarding-pairing.md` §1 & §4:
/// - Thiết bị con quét QR hoặc dán URI `beong://pair?v=1&c=<code>`.
/// - Trích xuất mã ghép cặp và tiến hành đổi credential.
Future<String?> showScanPairingDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => const _ScanPairingDialog(),
  );
}

class _ScanPairingDialog extends ConsumerStatefulWidget {
  const _ScanPairingDialog();

  @override
  ConsumerState<_ScanPairingDialog> createState() => _ScanPairingDialogState();
}

class _ScanPairingDialogState extends ConsumerState<_ScanPairingDialog> {
  static const _pairingService = PairingService();
  final _inputController = TextEditingController();
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handlePairing(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Thử phân tích dạng URI QR hoặc mã code trực tiếp
    String? code = _pairingService.parsePairingUri(text);
    if (code == null && RegExp(r'^[0-9a-fA-F]{8,32}$').hasMatch(text)) {
      code = text.toLowerCase();
    }

    if (code == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Mã ghép cặp không hợp lệ. Vui lòng quét lại mã QR trên máy bố mẹ.';
      });
      return;
    }

    // Giả lập hoặc gọi logic kết nối
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLg),
      ),
      title: Row(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, color: AppColors.amberDark),
          const SizedBox(width: AppSpacing.sm),
          Text('Ghép cặp máy con', style: context.text.titleMedium),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hướng camera về phía mã QR trên máy bố mẹ (trong mục Cài đặt -> Thành viên -> Ghép cặp) hoặc nhập mã liên kết bên dưới.',
              style: context.text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusMd),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.black54),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Khung quét QR Camera',
                      style: context.text.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'Hoặc dán liên kết/mã ghép cặp',
                hintText: 'beong://pair?v=1&c=...',
                errorText: _errorMessage,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: _isProcessing
                      ? null
                      : () => _handlePairing(_inputController.text),
                ),
              ),
              onSubmitted: _isProcessing ? null : _handlePairing,
            ),
            if (_isProcessing) ...[
              const SizedBox(height: AppSpacing.md),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('ĐÓNG'),
        ),
        FilledButton(
          onPressed: _isProcessing
              ? null
              : () => _handlePairing(_inputController.text),
          child: const Text('KẾT NỐI'),
        ),
      ],
    );
  }
}
