import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/domain/services/penalty_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Các mức bố mẹ chọn được. Danh sách rời chứ không phải thanh trượt: 0–100
/// liên tục gợi ý một độ chính xác không có thật, và bố mẹ nghĩ theo "một nửa",
/// "một phần tư", không nghĩ theo 37%.
const List<int> kPenaltyLevels = [0, 10, 20, 25, 50, 75, 100];

/// Cấu hình trừ xu của gia đình — ADR-022.
class PenaltySettingsScreen extends ConsumerWidget {
  const PenaltySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberDaoProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Trừ xu', style: context.text.titleLarge)),
      body: StreamBuilder<PenaltyPolicy>(
        stream: memberDao.watchPenaltyPolicy(session.familyId),
        builder: (context, snap) {
          final policy = snap.data;
          if (policy == null) return const SizedBox.shrink();

          Future<void> save(PenaltyPolicy next) =>
              memberDao.setPenaltyPolicy(session.familyId, next);

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: [
              const _WhyThisIsOffByDefault(),
              const SizedBox(height: AppSpacing.xxl),
              _LevelPicker(
                title: 'Hết ngày mà chưa làm',
                subtitle:
                    'Cuối ngày, mỗi việc chưa làm bị trừ phần trăm này của '
                    'điểm việc đó.',
                value: policy.missedPct,
                onChanged: (v) => save(policy.copyWith(missedPct: v)),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _LevelPicker(
                title: 'Bấm xong nhưng chưa làm',
                subtitle:
                    'Khi bố mẹ mở lại việc để con làm lại, mỗi lần mở lại bị '
                    'trừ phần trăm này.',
                value: policy.reopenPct,
                onChanged: (v) => save(policy.copyWith(reopenPct: v)),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _Example(policy: policy),
            ],
          );
        },
      ),
    );
  }
}

/// Cảnh báo hiện **trước** các lựa chọn, không phải chú thích cuối trang.
class _WhyThisIsOffByDefault extends StatelessWidget {
  const _WhyThisIsOffByDefault();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Mặc định tắt, và nên cân nhắc',
                    style: context.text.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nhiều tài liệu nuôi dạy khuyên không trừ điểm: nó dễ biến '
              '"mình muốn làm" thành "làm không thì bị trừ", và động lực kiểu '
              'sợ mất mát thường tắt ngay khi bố mẹ không để ý nữa.\n\n'
              'Bé Ong không quyết thay bố mẹ, nhưng cũng không bật sẵn. Nếu '
              'nhà mình dùng, nên bắt đầu ở mức thấp và nói trước với con.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: context.text.bodySmall?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: kPenaltyLevels.map((level) {
            final selected = level == value;
            return GestureDetector(
              onTap: () => onChanged(level),
              // Không đặt `alignment` ở Container: trong Wrap ràng buộc là
              // lỏng, và Container có alignment sẽ nở ra chiếm hết bề rộng —
              // các chip xếp thành cột thay vì nằm cạnh nhau. Căn giữa bằng
              // padding dọc, và bề rộng để nó tự co theo chữ.
              child: Container(
                constraints: const BoxConstraints(minWidth: 64),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? context.colors.primary
                      : context.colors.primaryContainer,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.field),
                  ),
                ),
                child: Text(
                  level == 0 ? 'Tắt' : '$level%',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? context.colors.onPrimary
                        : context.colors.onPrimaryContainer,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Ví dụ bằng số thật, tính từ chính chính sách đang chọn.
///
/// Bố mẹ đặt phần trăm rất dễ hình dung sai nó thành bao nhiêu xu, nên trang này
/// tự tính hộ thay vì để họ phát hiện ra vào cuối ngày.
class _Example extends StatelessWidget {
  const _Example({required this.policy});

  final PenaltyPolicy policy;

  @override
  Widget build(BuildContext context) {
    if (!policy.isEnabled) {
      return Text(
        'Đang tắt — con không bị trừ xu trong trường hợp nào.',
        style: context.text.bodyMedium?.copyWith(
          color: context.semantic.onSurfaceMuted,
        ),
      );
    }

    // Cùng bộ số với ví dụ trong docs: 10 việc x 10 xu, làm 8, 3 việc làm lại.
    final summary = summarizeDay(
      tasks: [
        for (var i = 0; i < 3; i++)
          const DayTaskOutcome(points: 10, completed: true, reopenCount: 1),
        for (var i = 0; i < 5; i++)
          const DayTaskOutcome(points: 10, completed: true),
        for (var i = 0; i < 2; i++)
          const DayTaskOutcome(points: 10, completed: false),
      ],
      policy: policy,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thử một ngày', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Con có 10 việc, mỗi việc 10 xu. Làm xong 8 việc, trong đó 3 '
              'việc phải làm lại một lần.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Line(label: 'Kiếm được', value: '+${summary.earned} xu'),
            _Line(
              label: '2 việc chưa làm',
              value: '-${summary.missedPenalty} xu',
            ),
            _Line(
              label: '3 lần làm lại',
              value: '-${summary.reopenPenalty} xu',
            ),
            const Divider(height: AppSpacing.xl),
            _Line(
              label: 'Cả ngày',
              value: '${summary.net >= 0 ? '+' : ''}${summary.net} xu',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
