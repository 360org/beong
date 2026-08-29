import 'dart:async';

import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/repositories/jar_repository.dart';
import 'package:flutter/material.dart';

/// Thêm một hũ mới cho cả nhà, và chỉnh lại tỷ lệ cho tổng vẫn bằng 100%.
///
/// Chủ dự án chốt 26/08/2026: *"thêm hũ mới thì có option để điều chỉnh — tuỳ
/// chọn điều chỉnh riêng hoặc nguyên tắc chung — miễn sao số hũ trong 1 profile
/// có tổng = 100%."* Nên có đúng hai cách, và cách nào cũng phải về 100%:
///
/// - **Trừ đều các hũ khác** — hũ mới lấy N%, phần thiếu chia đều cho các hũ
///   đang có theo tỷ lệ hiện tại của chúng. Không ai phải tính nhẩm.
/// - **Tự chỉnh** — tạo hũ với 0% rồi mở màn quản lý hũ để bố mẹ tự phân.
///
/// Không có cách thứ ba là "cứ tạo rồi tính sau": hũ tổng khác 100% thì tầng
/// chia xu rơi về kế hoạch mặc định (`wallet_dao.dart:243`) và mọi con số bố mẹ
/// vừa đặt biến mất không một lời báo.
Future<bool?> showJarAddSheet(
  BuildContext context, {
  required JarRepository jarDao,
  required String familyId,
  required VoidCallback onMoQuanLyHu,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _JarAddSheet(
        jarDao: jarDao,
        familyId: familyId,
        onMoQuanLyHu: onMoQuanLyHu,
      ),
    ),
  );
}

/// Tỷ lệ mới của các hũ đang có sau khi nhường [pctHuMoi] cho hũ mới.
///
/// Chia theo **tỷ lệ hiện có**, không chia đều tuyệt đối: hũ Tiêu đang 50% phải
/// gánh nhiều hơn hũ Cho đi đang 10%, không thì hũ nhỏ về 0 trước khi hũ lớn
/// kịp nhường. Phần dư do làm tròn dồn vào hũ **lớn nhất** — dồn vào hũ nhỏ có
/// thể đẩy nó xuống dưới 0.
///
/// Hậu điều kiện quan trọng nhất: `tổng kết quả + pctHuMoi == 100`. Tổng khác
/// 100 thì tầng chia xu lặng lẽ rơi về kế hoạch mặc định
/// (`wallet_dao.dart:243`) và mọi con số bố mẹ vừa đặt biến mất.
Map<String, int> chiaLaiTyLeHu(List<JarDef> huDangCo, int pctHuMoi) {
  final conLai = 100 - pctHuMoi;
  final tong = huDangCo.fold(0, (t, j) => t + j.pct);
  if (huDangCo.isEmpty || tong <= 0) return const {};

  final moi = <String, int>{};
  var daChia = 0;
  for (final hu in huDangCo) {
    final phan = (hu.pct * conLai / tong).floor();
    moi[hu.key] = phan;
    daChia += phan;
  }
  if (daChia < conLai) {
    final lonNhat = huDangCo.reduce((a, b) => a.pct >= b.pct ? a : b);
    moi[lonNhat.key] = moi[lonNhat.key]! + (conLai - daChia);
  }
  return moi;
}

enum _CachChinh { truDeu, tuChinh }

class _JarAddSheet extends StatefulWidget {
  const _JarAddSheet({
    required this.jarDao,
    required this.familyId,
    required this.onMoQuanLyHu,
  });

  final JarRepository jarDao;
  final String familyId;
  final VoidCallback onMoQuanLyHu;

  @override
  State<_JarAddSheet> createState() => _JarAddSheetState();
}

class _JarAddSheetState extends State<_JarAddSheet> {
  final _titleController = TextEditingController();
  String _emoji = kJarEmojis.first;
  int _pct = 10;
  _CachChinh _cach = _CachChinh.truDeu;
  bool _busy = false;
  List<JarDef> _huDangCo = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_napHu());
  }

  Future<void> _napHu() async {
    final hu = await widget.jarDao.activeJars(widget.familyId);
    if (mounted) setState(() => _huDangCo = hu);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Map<String, int> _tinhLaiTyLe() => chiaLaiTyLeHu(_huDangCo, _pct);

  Future<void> _luu() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _busy = true);

    final tuChinh = _cach == _CachChinh.tuChinh;
    await widget.jarDao.addJar(
      familyId: widget.familyId,
      title: title,
      emoji: _emoji,
      pct: tuChinh ? 0 : _pct,
    );

    if (!tuChinh) {
      final moi = _tinhLaiTyLe();
      for (final entry in moi.entries) {
        await widget.jarDao.updateJar(
          familyId: widget.familyId,
          jarKey: entry.key,
          pct: entry.value,
        );
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
    if (tuChinh) widget.onMoQuanLyHu();
  }

  @override
  Widget build(BuildContext context) {
    final tyLeMoi = _cach == _CachChinh.truDeu
        ? _tinhLaiTyLe()
        : const <String, int>{};
    final coTheLuu = !_busy && _titleController.text.trim().isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Thêm hũ mới', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.lg),

            Text('Tên hũ', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleController,
              autofocus: true,
              maxLength: 40,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: Mua sách, Đi chơi',
              ),
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
            Text('Chỉnh tỷ lệ thế nào', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<_CachChinh>(
              segments: const [
                ButtonSegment(
                  value: _CachChinh.truDeu,
                  label: Text('Trừ đều hũ khác'),
                ),
                ButtonSegment(
                  value: _CachChinh.tuChinh,
                  label: Text('Tự chỉnh'),
                ),
              ],
              selected: {_cach},
              onSelectionChanged: (chon) => setState(() => _cach = chon.first),
            ),

            if (_cach == _CachChinh.truDeu) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Hũ mới nhận $_pct%', style: context.text.titleSmall),
              Slider(
                value: _pct.toDouble(),
                max: 90,
                divisions: 18,
                label: '$_pct%',
                onChanged: (v) => setState(() => _pct = v.round()),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Các hũ đang có sẽ thành:',
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final hu in _huDangCo)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text(hu.title)),
                            Text(
                              '${hu.pct}% → ${tyLeMoi[hu.key] ?? hu.pct}%',
                              style: context.text.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(child: Text('Tổng')),
                        Text(
                          '${tyLeMoi.values.fold(_pct, (t, v) => t + v)}%',
                          style: context.text.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.semantic.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Hũ mới tạo với 0%. Màn quản lý hũ mở ra ngay sau đó để bố mẹ '
                'tự phân — nhớ để tổng đủ 100%.',
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: coTheLuu ? _luu : null,
                child: const Text('THÊM HŨ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
