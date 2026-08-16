import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ô báo lỗi khi một luồng dữ liệu hỏng.
///
/// Trước widget này, **không một `StreamBuilder` nào trong app kiểm
/// `snapshot.hasError`**: luồng hỏng thì `snap.data` là `null`, màn hình rơi về
/// giá trị mặc định và hiện ra như thể nhà chưa có việc nào, chưa có phần
/// thưởng nào, ví 0 xu. Người dùng thấy dữ liệu **sai** chứ không thấy lỗi —
/// tệ hơn hẳn một dòng báo lỗi thật thà.
///
/// App là offline-first (ADR-002) nên đây không phải "mất mạng": lỗi ở đây là
/// file DB hỏng hoặc một truy vấn sai. Chữ vì thế không hứa "thử lại lát nữa".
class LoiManHinh extends StatelessWidget {
  const LoiManHinh({required this.error, this.onRetry, super.key});

  final Object error;

  /// Có cách thử lại thì hiện nút. Luồng drift tự phát lại nên phần lớn chỗ
  /// gọi không cần.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: context.semantic.danger,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chỗ này đang trục trặc',
            style: context.text.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Dữ liệu không đọc được nên phần này đang trống. Số liệu của con '
            'vẫn còn nguyên.',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
            textAlign: TextAlign.center,
          ),
          // Chi tiết kỹ thuật chỉ hiện ở bản debug: bố mẹ không đọc được nó, mà
          // lập trình viên thì cần nó ngay trên màn hình chứ không phải đi lục
          // log.
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$error',
              style: context.text.labelSmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('THỬ LẠI')),
          ],
        ],
      ),
    );
  }
}

/// `StreamBuilder` có sẵn ba trạng thái: đang tải, lỗi, có dữ liệu.
///
/// Dùng cái này thay cho `StreamBuilder` trần ở những chỗ mà **hiện sai còn tệ
/// hơn hiện lỗi** — danh sách việc, danh sách phần thưởng, sổ cái. Chỗ nào chỉ
/// hiện một con số phụ thì `StreamBuilder` trần vẫn ổn.
class LuongDuLieu<T> extends StatelessWidget {
  const LuongDuLieu({
    required this.stream,
    required this.builder,
    this.dangTai,
    super.key,
  });

  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;

  /// Hiện trong lúc chờ dữ liệu đầu tiên. Mặc định là vòng xoay.
  final Widget? dangTai;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return LoiManHinh(error: snap.error!);
        if (!snap.hasData) {
          return dangTai ??
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xxxl),
                child: Center(child: CircularProgressIndicator()),
              );
        }
        return builder(context, snap.data as T);
      },
    );
  }
}
