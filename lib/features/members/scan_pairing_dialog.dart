import 'dart:async';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/domain/services/pairing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  MobileScannerController? _scannerController;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    unawaited(_scannerController?.dispose());
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handlePairing(String rawText) async {
    if (_isProcessing) return;
    final text = rawText.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Thử phân tích dạng URI QR hoặc mã code trực tiếp
    var code = _pairingService.parsePairingUri(text);
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

    // Dừng camera nếu đang quét
    await _scannerController?.stop();
    if (!mounted) return;

    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Row(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, color: AppColors.brand360Blue),
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
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                height: 200,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_scannerController != null)
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            final rawVal = barcode.rawValue;
                            if (rawVal != null && rawVal.isNotEmpty) {
                              unawaited(_handlePairing(rawVal));
                              break;
                            }
                          }
                        },
                      ),
                    // Khung ngắm quét QR
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.brand360Blue, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                  tooltip: 'Gửi mã kết nối',
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
