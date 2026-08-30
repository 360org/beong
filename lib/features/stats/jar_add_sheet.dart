import 'dart:async';

import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/repositories/jar_repository.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:flutter/material.dart';

/// Thêm một hũ mới — cho cả nhà hoặc cho riêng một bé — và chỉnh lại tỷ lệ cho
/// tổng vẫn bằng 100%.
///
/// Chủ dự án chốt 26/08/2026: *"thêm hũ mới thì có option để điều chỉnh — tuỳ
/// chọn điều chỉnh riêng hoặc nguyên tắc chung — miễn sao số hũ trong 1 profile
/// có tổng = 100%."* Hũ mới lấy N%, phần thiếu trừ vào các hũ đang có **theo
/// tỷ lệ hiện tại của chúng** — bố mẹ không phải tính nhẩm, và bảng xem trước
/// nói rõ hũ nào sẽ thành bao nhiêu trước khi bấm lưu.
///
/// Không có cách "cứ tạo rồi tính sau": hũ tổng khác 100% thì tầng chia xu rơi
/// về kế hoạch mặc định (`wallet_dao.dart:243`) và mọi con số bố mẹ vừa đặt
/// biến mất không một lời báo.
///
/// Muốn một tỷ lệ khác thì sửa từng hũ bằng nút bút chì ở màn Thống kê — mỗi
/// lần sửa cũng tự cân lại phần còn lại về đúng 100%. Trước đây chỗ này còn
/// lựa chọn *"Tự chỉnh"*: tạo hũ 0% rồi nhảy sang màn quản lý hũ ở Cài đặt.
/// Màn đó đã bỏ ngày 30/08/2026 (chủ dự án: cấu hình hũ đã nằm ngay trong màn
/// Thống kê rồi), nên lựa chọn ấy chỉ còn tạo ra một hũ 0% không có chỗ sửa.
///
/// ## Chọn hồ sơ (30/08/2026)
///
/// Chủ dự án: *"các hũ cho mỗi bé là khác nhau"*. Một bé để dành mua xe đạp
/// trong khi bé kia để dành mua sách — ép cả nhà dùng chung một bộ hũ là ép hai
/// đứa trẻ tiết kiệm cho cùng một thứ.
///
/// Chọn một bé thì hũ mới vào **bộ riêng của bé đó**, và lần đầu làm vậy cả bộ
/// chung được sao chép sang cho bé (`JarDao.tachBoRieng`) rồi mới sửa. Không
/// sao chép thì bé có đúng một hũ N%, còn 100−N% không có chỗ nào chứa. Và tỷ
/// lệ trừ đi cũng chỉ trừ trong bộ của bé đó — hũ của bé kia không suy suyển.
Future<bool?> showJarAddSheet(
  BuildContext context, {
  required JarRepository jarDao,
  required String familyId,
  required List<Member> children,
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
        children: children,
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

class _JarAddSheet extends StatefulWidget {
  const _JarAddSheet({
    required this.jarDao,
    required this.familyId,
    required this.children,
  });

  final JarRepository jarDao;
  final String familyId;
  final List<Member> children;

  @override
  State<_JarAddSheet> createState() => _JarAddSheetState();
}

class _JarAddSheetState extends State<_JarAddSheet> {
  final _titleController = TextEditingController();
  String _emoji = kJarEmojis.first;
  int _pct = 10;
  bool _busy = false;
  List<JarDef> _huDangCo = const [];

  /// `null` = hũ chung cả nhà. Mặc định là chung: đó là hành vi cũ, và phần
  /// lớn hũ (Tiêu / Để dành / Cho đi) đúng là dùng chung thật.
  String? _hoSo;

  @override
  void initState() {
    super.initState();
    unawaited(_napHu());
  }

  Future<void> _napHu() async {
    // Đọc theo đúng hồ sơ đang chọn: bảng xem trước phải cho thấy tỷ lệ **của
    // bé đó** sẽ đổi thế nào, không phải tỷ lệ của nhà.
    final hu = await widget.jarDao.activeJars(
      widget.familyId,
      memberId: _hoSo,
    );
    if (mounted) setState(() => _huDangCo = hu);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Map<String, int> _tinhLaiTyLe() => chiaLaiTyLeHu(_huDangCo, _pct);

  String _tenBe(String memberId) => widget.children
      .firstWhere(
        (m) => m.id == memberId,
        orElse: () => widget.children.first,
      )
      .displayName;

  void _doiHoSo(String? memberId) {
    setState(() => _hoSo = memberId);
    // Nạp lại: bảng xem trước phải cho thấy tỷ lệ của **bộ vừa chọn**, không
    // phải bộ trước đó.
    unawaited(_napHu());
  }

  Future<void> _luu() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _busy = true);

    await widget.jarDao.addJar(
      familyId: widget.familyId,
      title: title,
      emoji: _emoji,
      pct: _pct,
      memberId: _hoSo,
    );

    for (final entry in _tinhLaiTyLe().entries) {
      await widget.jarDao.updateJar(
        familyId: widget.familyId,
        jarKey: entry.key,
        pct: entry.value,
        memberId: _hoSo,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tyLeMoi = _tinhLaiTyLe();
    final coTheLuu = !_busy && _titleController.text.trim().isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(title: 'Thêm hũ mới'),
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

            if (widget.children.isNotEmpty) ...[
              Text('Hũ này của ai', style: context.text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _hoSo == null
                    ? 'Hũ chung: mọi bé đều có hũ này.'
                    : 'Chỉ ${_tenBe(_hoSo!)} có hũ này. Các bé khác không đổi.',
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: const Text('Cả nhà'),
                    selected: _hoSo == null,
                    onSelected: (chon) {
                      if (chon) _doiHoSo(null);
                    },
                  ),
                  for (final child in widget.children)
                    ChoiceChip(
                      label: Text(child.displayName),
                      selected: _hoSo == child.id,
                      onSelected: (chon) {
                        if (chon) _doiHoSo(child.id);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

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
