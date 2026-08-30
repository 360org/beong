import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/features/stats/jar_add_sheet.dart';
import 'package:flutter/material.dart';

/// Chọn bé mới dùng những hũ nào trong bộ hũ của nhà.
///
/// Chủ dự án nêu 30/08/2026: *"khi tạo profile cho trẻ thì phải có option để
/// chọn bao nhiêu hũ — ví dụ tổng hũ đã tạo có 8 hũ, chọn 3 hũ cho profile cần
/// tạo."*
///
/// Vì sao cần: từ v9 mỗi bé có bộ hũ riêng, và nhà có thể đã lập tới 8 hũ cho
/// bé lớn. Bé ba tuổi không cần hũ "Học tập" hay "Mua xe đạp" — 8 ô hũ trên màn
/// của bé chỉ làm loãng thứ bé thật sự hiểu. Trước bản này bé mới **luôn** nhận
/// nguyên bộ của nhà, không có đường nào bớt đi lúc tạo.
///
/// Chọn ít hơn cả bộ thì phần trăm của các hũ được chọn **chia lại cho đủ
/// 100%** theo đúng tỷ lệ hiện có của chúng. Không chia lại thì tổng hụt đúng
/// bằng phần của những hũ bị bỏ, và `wallet_dao.planFor` lặng lẽ rơi về kế
/// hoạch mặc định — bé nhận một bộ hũ không ai đặt.
class ChonHuChoBe extends StatelessWidget {
  const ChonHuChoBe({
    required this.huCuaNha,
    required this.dangChon,
    required this.onDoi,
    super.key,
  });

  /// Bộ hũ đang dùng của cả nhà.
  final List<JarDef> huCuaNha;

  /// Khoá các hũ bé sẽ dùng.
  final Set<String> dangChon;

  final ValueChanged<Set<String>> onDoi;

  @override
  Widget build(BuildContext context) {
    // Một hũ thì không có gì để chọn — bé nào cũng dùng đúng hũ đó.
    if (huCuaNha.length <= 1) return const SizedBox.shrink();

    final tyLe = tyLeSauKhiChon(huCuaNha, dangChon);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'BÉ NÀY DÙNG HŨ NÀO',
          style: context.text.labelSmall?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Nhà đang có ${huCuaNha.length} hũ. Bỏ bớt hũ bé chưa cần — phần '
          'trăm của các hũ còn lại tự chia cho đủ 100%.',
          style: context.text.bodySmall?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final hu in huCuaNha)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: dangChon.contains(hu.key),
            // Bỏ hết thì bé không có chỗ nào chứa xu. Khoá ô cuối cùng lại
            // thay vì cho bỏ rồi báo lỗi sau khi bấm THÊM BÉ.
            onChanged: dangChon.length == 1 && dangChon.contains(hu.key)
                ? null
                : (chon) {
                    final moi = {...dangChon};
                    if (chon ?? false) {
                      moi.add(hu.key);
                    } else {
                      moi.remove(hu.key);
                    }
                    onDoi(moi);
                  },
            secondary: AppIcon(iconKeyForEmoji(hu.emoji), size: 26),
            title: Text(hu.title),
            subtitle: Text(
              dangChon.contains(hu.key)
                  ? '${hu.pct}% → ${tyLe[hu.key] ?? hu.pct}%'
                  : 'Bé này không dùng',
            ),
          ),
        if (dangChon.length == 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Phải giữ ít nhất một hũ.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Tỷ lệ mới của các hũ **được chọn**, chia lại cho tổng đúng 100%.
///
/// Chia theo tỷ lệ hiện có, dùng lại [chiaLaiTyLeHu] — cùng phép chia với bảng
/// "Thêm hũ" và "Sửa hũ", để ba chỗ không cho ra ba kết quả khác nhau trên
/// cùng một bộ số.
Map<String, int> tyLeSauKhiChon(List<JarDef> huCuaNha, Set<String> chon) {
  final duocChon = [
    for (final j in huCuaNha)
      if (chon.contains(j.key)) j,
  ];
  if (duocChon.isEmpty) return const {};
  return chiaLaiTyLeHu(duocChon, 0);
}
