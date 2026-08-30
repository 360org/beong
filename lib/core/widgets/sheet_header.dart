import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Đầu trang cho mọi bảng trượt lên (`showModalBottomSheet`): tiêu đề, mô tả
/// phụ, và **nút đóng ở góc phải**.
///
/// Vì sao bắt buộc có nút đóng, dù Flutter đã cho vuốt xuống và bấm ra ngoài:
///
/// - Bảng nào có `TextField` `autofocus` thì bàn phím che gần nửa màn hình
///   (ảnh chủ dự án gửi 30/08/2026: "Thêm buổi thói quen" chỉ còn thấy tới ô
///   chọn bé). Vùng trống để bấm-ra-ngoài gần như không còn, mà vuốt xuống thì
///   nhiều bảng cuộn nội dung trước khi bảng chịu đóng.
/// - Bảng `isDismissible: false` thì hai cách kia **không tồn tại** — không có
///   nút đóng là người dùng bị kẹt thật.
/// - Vuốt và bấm-ra-ngoài đều là cử chỉ không nhìn thấy được. Một nút thì thấy.
///
/// `test/unit/sheet_co_nut_dong_test.dart` canh mọi file có
/// `showModalBottomSheet` đều dùng widget này.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.onClose,
    this.actions = const [],
    this.anNutDong = false,
  });

  final String title;

  /// Dòng mô tả dưới tiêu đề. Bỏ trống thì không chiếm chỗ.
  final String? subtitle;

  /// Việc cần làm khi bấm đóng. Bỏ trống thì `Navigator.pop` — đúng cho hầu
  /// hết bảng. Truyền vào khi cần trả giá trị hoặc hỏi xác nhận trước.
  final VoidCallback? onClose;

  /// Nút phụ đặt trước nút đóng (ví dụ "Ngừng dùng việc này"). Nút đóng luôn
  /// nằm ngoài cùng bên phải để chỗ của nó không đổi giữa các bảng.
  final List<Widget> actions;

  /// Ẩn hẳn nút đóng. **Chỉ dùng khi có ADR nói bảng này không được đóng** —
  /// hiện chỉ có một chỗ: đặt mật khẩu lần đầu ở onboarding (ADR-027). Bảng
  /// đó đã tắt cả vuốt lẫn bấm-ra-ngoài; thêm nút đóng là mở lại đúng lối
  /// thoát mà ADR cố ý bịt.
  final bool anNutDong;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ...actions,
        if (!anNutDong)
          IconButton(
            onPressed: onClose ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Đóng',
            // Vùng chạm tối thiểu: nút này nằm sát mép trên, nơi ngón cái với
            // tới khó nhất trên máy màn hình lớn.
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
          ),
      ],
    );
  }
}
