import 'dart:async';

import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/core/widgets/thong_bao.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/repositories/jar_repository.dart';
import 'package:beong/features/stats/jar_add_sheet.dart';
import 'package:flutter/material.dart';

/// Sửa hoặc ngừng dùng **một hũ của một bé**.
///
/// Chủ dự án nêu 30/08/2026: *"màn hình hũ không có option sửa/xoá hũ không
/// dùng"*. Màn quản lý hũ ở Cài đặt vẫn còn, nhưng nó làm việc với bộ hũ
/// **chung của nhà** — từ v9 mỗi bé có bộ riêng, nên nó không với tới được cái
/// hũ bố mẹ đang nhìn trên màn Thống kê của một bé.
///
/// ## Tổng phải luôn đúng 100%
///
/// Đây là ràng buộc chi phối cả màn này. Tổng khác 100 thì `wallet_dao.planFor`
/// lặng lẽ rơi về kế hoạch mặc định và **mọi con số bố mẹ vừa đặt biến mất
/// không một lời báo**. Nên:
///
/// - Đổi tỷ lệ hũ này thành N% ⇒ các hũ còn lại chia nhau `100 − N` theo đúng
///   tỷ lệ hiện có của chúng ([chiaLaiTyLeHu]).
/// - Ngừng dùng hũ này ⇒ các hũ còn lại chia nhau trọn 100%. Không trả phần
///   của nó về đâu cả là để lại một lỗ thủng đúng bằng tỷ lệ nó từng giữ.
///
/// ## Ngừng dùng, không xoá
///
/// ADR-005: sổ cái chỉ ghi thêm, và `point_transactions.jar` trỏ tới khoá hũ.
/// Xoá hũ đi là "Sổ của con" còn số dư mà mất tên hũ.
Future<bool?> showJarEditSheet(
  BuildContext context, {
  required JarRepository jarDao,
  required String familyId,
  required String memberId,
  required String tenBe,
  required JarDef hu,
  required List<JarDef> tatCaHu,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _JarEditSheet(
        jarDao: jarDao,
        familyId: familyId,
        memberId: memberId,
        tenBe: tenBe,
        hu: hu,
        tatCaHu: tatCaHu,
      ),
    ),
  );
}

class _JarEditSheet extends StatefulWidget {
  const _JarEditSheet({
    required this.jarDao,
    required this.familyId,
    required this.memberId,
    required this.tenBe,
    required this.hu,
    required this.tatCaHu,
  });

  final JarRepository jarDao;
  final String familyId;
  final String memberId;
  final String tenBe;
  final JarDef hu;
  final List<JarDef> tatCaHu;

  @override
  State<_JarEditSheet> createState() => _JarEditSheetState();
}

class _JarEditSheetState extends State<_JarEditSheet> {
  late final _titleController = TextEditingController(text: widget.hu.title);
  late String _emoji = widget.hu.emoji;
  late int _pct = widget.hu.pct;
  bool _busy = false;

  /// Các hũ khác của cùng bé — bên nhận phần chênh lệch.
  List<JarDef> get _huKhac =>
      widget.tatCaHu.where((j) => j.key != widget.hu.key).toList();

  bool get _laHuCuoi => _huKhac.isEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Map<String, int> _tyLeMoi() => chiaLaiTyLeHu(_huKhac, _pct);

  Future<void> _luu() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _busy = true);

    await widget.jarDao.updateJar(
      familyId: widget.familyId,
      memberId: widget.memberId,
      jarKey: widget.hu.key,
      title: title,
      emoji: _emoji,
      pct: _pct,
    );

    // Chỉ đụng tới tỷ lệ hũ khác khi tỷ lệ hũ này thật sự đổi. Đổi mỗi cái tên
    // mà cũng viết lại tỷ lệ cả bộ là sửa thứ bố mẹ không yêu cầu sửa.
    if (_pct != widget.hu.pct && !_laHuCuoi) {
      for (final entry in _tyLeMoi().entries) {
        await widget.jarDao.updateJar(
          familyId: widget.familyId,
          memberId: widget.memberId,
          jarKey: entry.key,
          pct: entry.value,
        );
      }
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _ngungDung() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ngừng dùng hũ này?'),
        // Nói rõ **xu không mất**: đó là nỗi sợ hợp lý nhất khi bấm nút này, và
        // không nói ra thì bố mẹ không dám bấm.
        content: Text(
          '"${widget.hu.title}" sẽ không nhận xu mới nữa. Số xu đang có và '
          'lịch sử vẫn còn nguyên.\n\n'
          'Phần ${widget.hu.pct}% của nó chia lại cho các hũ khác của '
          '${widget.tenBe}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ngừng dùng'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      // Chia lại **trước** khi xếp hũ: xếp trước rồi mới chia thì có một
      // khoảnh khắc tổng khác 100, và nếu con vừa làm xong việc đúng lúc đó
      // thì xu chảy theo kế hoạch mặc định.
      for (final entry in chiaLaiTyLeHu(_huKhac, 0).entries) {
        await widget.jarDao.updateJar(
          familyId: widget.familyId,
          memberId: widget.memberId,
          jarKey: entry.key,
          pct: entry.value,
        );
      }
      await widget.jarDao.setArchived(
        familyId: widget.familyId,
        memberId: widget.memberId,
        jarKey: widget.hu.key,
        archived: true,
      );
    } on JarException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        hienThongBao(context, e.message);
      }
      return;
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tyLeMoi = _tyLeMoi();
    final coTheLuu = !_busy && _titleController.text.trim().isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: 'Sửa hũ',
              subtitle: 'Hũ của ${widget.tenBe}. Các bé khác không đổi.',
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Tên hũ', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleController,
              maxLength: 40,
              onChanged: (_) => setState(() {}),
            ),

            Text('Chọn hình', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final emoji in kJarEmojis)
                  InkWell(
                    onTap: () => setState(() => _emoji = emoji),
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    child: Container(
                      width: AppSpacing.minTouchTarget,
                      height: AppSpacing.minTouchTarget,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _emoji == emoji
                            ? context.colors.primaryContainer
                            : null,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                      ),
                      child: AppIcon(iconKeyForEmoji(emoji), size: 26),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            Text('Hũ này nhận $_pct%', style: context.text.titleSmall),
            Slider(
              value: _pct.toDouble(),
              max: 90,
              divisions: 18,
              label: '$_pct%',
              // Hũ duy nhất thì không có ai nhận phần còn lại — khoá thanh
              // trượt ở 100 thay vì cho tạo ra một tổng không bao giờ đúng.
              onChanged: _laHuCuoi
                  ? null
                  : (v) => setState(() => _pct = v.round()),
            ),

            if (_pct != widget.hu.pct && !_laHuCuoi) ...[
              const SizedBox(height: AppSpacing.sm),
              _BangXemTruoc(huKhac: _huKhac, tyLeMoi: tyLeMoi, pctHuNay: _pct),
            ],

            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: coTheLuu ? () => unawaited(_luu()) : null,
                child: const Text('LƯU'),
              ),
            ),
            Align(
              child: TextButton.icon(
                onPressed: _busy || _laHuCuoi
                    ? null
                    : () => unawaited(_ngungDung()),
                icon: const Icon(Icons.archive_outlined),
                label: Text(
                  _laHuCuoi ? 'Phải còn ít nhất một hũ' : 'Ngừng dùng hũ này',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: context.semantic.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bảng "trước → sau" cho các hũ còn lại, kèm tổng.
///
/// Có mặt vì con số tự đổi mà không ai báo là thứ làm người dùng mất tin: bố mẹ
/// kéo tỷ lệ một hũ rồi phát hiện hũ khác cũng khác đi, không hiểu vì sao.
class _BangXemTruoc extends StatelessWidget {
  const _BangXemTruoc({
    required this.huKhac,
    required this.tyLeMoi,
    required this.pctHuNay,
  });

  final List<JarDef> huKhac;
  final Map<String, int> tyLeMoi;
  final int pctHuNay;

  @override
  Widget build(BuildContext context) {
    final tong = pctHuNay + tyLeMoi.values.fold(0, (t, v) => t + v);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Các hũ khác sẽ thành:', style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          for (final jar in huKhac)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(jar.title)),
                  Text('${jar.pct}% → ${tyLeMoi[jar.key] ?? jar.pct}%'),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              const Expanded(child: Text('Tổng')),
              Text(
                '$tong%',
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tong == 100
                      ? context.semantic.success
                      : context.semantic.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
