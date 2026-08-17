import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/repositories/jar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quản lý hũ của gia đình — ADR-024.
///
/// Ràng buộc duy nhất mà màn này phải bảo vệ: **tổng tỷ lệ bằng 100%**. Không
/// bằng 100 thì `splitByPlan` từ chối kế hoạch và `WalletRepository.planFor` rơi về ba
/// hũ mặc định — nghĩa là bố mẹ sửa tỷ lệ xong mà xu vẫn chia theo tỷ lệ cũ, im
/// lặng. Vì vậy tổng luôn hiện ra, và lệch thì nói rõ lệch bao nhiêu.
class JarSettingsScreen extends ConsumerWidget {
  const JarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final jarDao = ref.watch(jarRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Các hũ')),
      body: StreamBuilder<List<({JarDef jar, bool archived})>>(
        stream: jarDao.watchAllJars(session.familyId),
        builder: (context, snap) {
          final rows = snap.data ?? const [];
          final active = [
            for (final r in rows)
              if (!r.archived) r.jar,
          ];
          final archived = [
            for (final r in rows)
              if (r.archived) r.jar,
          ];
          final total = active.fold(0, (sum, j) => sum + j.pct);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              _TotalBanner(total: total),
              const SizedBox(height: AppSpacing.xl),
              Text('Đang dùng', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              for (final jar in active)
                _JarTile(
                  jar: jar,
                  familyId: session.familyId,
                  jarDao: jarDao,
                  canArchive: jar.key != kJarSpend && active.length > 1,
                ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => unawaited(
                  _openEditor(
                    context,
                    familyId: session.familyId,
                    jarDao: jarDao,
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm hũ'),
              ),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                Text('Đã xếp lại', style: context.text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Hũ xếp lại không nhận xu mới, nhưng xu cũ vẫn còn trong sổ.',
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final jar in archived)
                  ListTile(
                    leading: Opacity(
                      opacity: 0.5,
                      child: AppIcon(iconKeyForEmoji(jar.emoji), size: 30),
                    ),
                    title: Text(jar.title),
                    trailing: TextButton(
                      onPressed: () => unawaited(
                        jarDao.setArchived(
                          familyId: session.familyId,
                          jarKey: jar.key,
                          archived: false,
                        ),
                      ),
                      child: const Text('Dùng lại'),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

Future<void> _openEditor(
  BuildContext context, {
  required String familyId,
  required JarRepository jarDao,
  JarDef? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _JarEditor(
        familyId: familyId,
        jarDao: jarDao,
        existing: existing,
      ),
    ),
  );
}

/// Tổng tỷ lệ, và nói thẳng khi nó chưa đủ 100%.
class _TotalBanner extends StatelessWidget {
  const _TotalBanner({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final ok = total == 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ok
            ? context.colors.primaryContainer
            : context.semantic.warning.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
      ),
      child: Row(
        children: [
          // Không chỉ dựa vào màu: icon mang cùng thông tin (WCAG 1.4.1).
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: ok ? context.colors.primary : context.semantic.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              ok
                  ? 'Tổng $total% — chia đủ'
                  : total < 100
                  ? 'Tổng $total% — còn thiếu ${100 - total}%'
                  : 'Tổng $total% — thừa ${total - 100}%',
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JarTile extends StatelessWidget {
  const _JarTile({
    required this.jar,
    required this.familyId,
    required this.jarDao,
    required this.canArchive,
  });

  final JarDef jar;
  final String familyId;
  final JarRepository jarDao;
  final bool canArchive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppIcon(iconKeyForEmoji(jar.emoji), size: 32),
      title: Text(jar.title),
      subtitle: Text('${jar.pct}% mỗi lần con kiếm xu'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Sửa',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => unawaited(
              _openEditor(
                context,
                familyId: familyId,
                jarDao: jarDao,
                existing: jar,
              ),
            ),
          ),
          IconButton(
            tooltip: canArchive
                ? 'Xếp lại'
                : jar.key == kJarSpend
                ? 'Không xếp lại được hũ Tiêu'
                : 'Phải còn ít nhất một hũ',
            icon: const Icon(Icons.archive_outlined),
            onPressed: canArchive
                ? () => unawaited(
                    jarDao.setArchived(
                      familyId: familyId,
                      jarKey: jar.key,
                      archived: true,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _JarEditor extends StatefulWidget {
  const _JarEditor({
    required this.familyId,
    required this.jarDao,
    this.existing,
  });

  final String familyId;
  final JarRepository jarDao;
  final JarDef? existing;

  @override
  State<_JarEditor> createState() => _JarEditorState();
}

class _JarEditorState extends State<_JarEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late String _emoji = widget.existing?.emoji ?? kJarEmojis.first;
  late int _pct = widget.existing?.pct ?? 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Không có listener này thì nút LƯU đọc `_title.text` lúc build rồi **không
    // bao giờ dựng lại**: gõ tên xong nút vẫn xám, và không có cách nào lưu được
    // hũ mới. Gõ chữ tự nó không kích hoạt rebuild của widget cha.
    _title.addListener(_onTitleChanged);
  }

  void _onTitleChanged() => setState(() {});

  @override
  void dispose() {
    _title
      ..removeListener(_onTitleChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final existing = widget.existing;
    try {
      if (existing == null) {
        await widget.jarDao.addJar(
          familyId: widget.familyId,
          title: _title.text,
          emoji: _emoji,
          pct: _pct,
        );
      } else {
        await widget.jarDao.updateJar(
          familyId: widget.familyId,
          jarKey: existing.key,
          title: _title.text,
          emoji: _emoji,
          pct: _pct,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on JarException catch (error) {
      // Hiện lỗi tại chỗ chứ không đóng sheet: đóng đi thì bố mẹ mất cả phần đã
      // gõ và không biết vì sao không lưu được.
      setState(() => _error = error.message);
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
          Text(
            widget.existing == null ? 'Thêm hũ' : 'Sửa hũ',
            style: context.text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _title,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tên hũ',
              hintText: 'Ví dụ: Học tập',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Chọn hình', style: context.text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final emoji in kJarEmojis)
                _EmojiChoice(
                  emoji: emoji,
                  selected: emoji == _emoji,
                  onTap: () => setState(() => _emoji = emoji),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text('Tỷ lệ: $_pct%', style: context.text.labelLarge),
              ),
            ],
          ),
          Slider(
            value: _pct.toDouble(),
            max: 100,
            divisions: 20,
            label: '$_pct%',
            onChanged: (v) => setState(() => _pct = v.round()),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.danger,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _title.text.trim().isEmpty
                  ? null
                  : () => unawaited(_save()),
              child: const Text('LƯU'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiChoice extends StatelessWidget {
  const _EmojiChoice({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSpacing.minTouchTarget,
        height: AppSpacing.minTouchTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primaryContainer
              : context.colors.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.field),
          ),
          border: selected
              ? Border.all(color: context.colors.primary, width: 2)
              : null,
        ),
        child: AppIcon(iconKeyForEmoji(emoji), size: 26),
      ),
    );
  }
}
