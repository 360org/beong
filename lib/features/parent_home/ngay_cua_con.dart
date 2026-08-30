import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:flutter/material.dart';

/// Một ngày của một bé: thẻ tóm tắt + việc chia theo buổi.
///
/// Tách ra khỏi `child_history_sheet.dart` ngày 30/08/2026, khi chủ dự án yêu
/// cầu thẻ con ở Trang chính **trông y hệt** màn lịch sử chi tiết. Hai chỗ
/// dựng lại cùng một bố cục bằng hai đoạn code khác nhau là cách chắc chắn để
/// chúng lệch nhau sau vài lần sửa — nên chỉ còn **một** bố cục, dùng ở cả hai.
///
/// Không tự cuộn: bên gọi quyết định. Màn chi tiết bọc nó trong `ListView`,
/// thẻ ở Trang chính nhét thẳng vào `Column` của thẻ.
class NgayCuaCon extends StatelessWidget {
  const NgayCuaCon({
    required this.memberId,
    required this.familyId,
    required this.date,
    required this.taskDao,
    super.key,
    this.onMoLai,
  });

  final String memberId;
  final String familyId;
  final CalendarDate date;
  final TaskRepository taskDao;

  /// Mở lại một việc đã xong. `null` thì hàng chỉ để đọc — màn lịch sử dùng
  /// kiểu đó, thẻ ở Trang chính thì truyền vào để bố mẹ sửa được ngay tại chỗ.
  final void Function(TaskInstance instance)? onMoLai;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskInstance>>(
      stream: taskDao.watchInstancesForMember(memberId: memberId, date: date),
      builder: (context, snap) {
        final luot = snap.data;
        // `null` = chưa đọc xong. Hiện "không có việc nào" lúc này là nói sai
        // rồi tự sửa lại sau một nhịp — nháy một câu phủ định vào mắt người
        // đọc còn tệ hơn là để trống.
        if (luot == null) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (luot.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Text(
                'Không có công việc nào trong ngày này',
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            ),
          );
        }

        return StreamBuilder<List<Task>>(
          stream: taskDao.watchActiveTasks(familyId),
          builder: (context, taskSnap) {
            final taskMap = {
              for (final t in taskSnap.data ?? const <Task>[]) t.id: t,
            };

            final sang = <TaskInstance>[];
            final chieu = <TaskInstance>[];
            final toi = <TaskInstance>[];
            final caNgay = <TaskInstance>[];
            for (final i in luot) {
              switch (taskMap[i.taskId]?.dayPart) {
                case 'morning':
                  sang.add(i);
                case 'afternoon':
                  chieu.add(i);
                case 'evening':
                  toi.add(i);
                case _:
                  caNgay.add(i);
              }
            }

            final xong = luot.where((i) => daLamXong(i.status)).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TheTomTat(tong: luot.length, xong: xong),
                const SizedBox(height: AppSpacing.lg),
                for (final (ten, ds) in [
                  ('🌅 Buổi Sáng', sang),
                  ('☀️ Buổi Trưa / Chiều', chieu),
                  ('🌙 Buổi Tối', toi),
                  ('🔄 Cả Ngày & Thói Quen', caNgay),
                ])
                  if (ds.isNotEmpty)
                    _KhoiBuoi(
                      ten: ten,
                      luot: ds,
                      taskMap: taskMap,
                      onMoLai: onMoLai,
                    ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Lượt việc này có thật sự **đã làm xong** không.
///
/// Chỉ `approved` và `pendingReview`. `missed` và `rejected` đã qua nhưng
/// không phải đã xong — đếm chúng là xong thì một ngày con không làm gì hiện
/// "100%".
bool daLamXong(String status) =>
    status == InstanceStatus.approved.name ||
    status == InstanceStatus.pendingReview.name;

class _TheTomTat extends StatelessWidget {
  const _TheTomTat({required this.tong, required this.xong});

  final int tong;
  final int xong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _So(
            nhan: 'Tổng việc',
            giaTri: '$tong',
            mau: context.colors.primary,
          ),
          _So(
            nhan: 'Đã hoàn thành',
            giaTri: '$xong',
            mau: context.semantic.success,
          ),
          _So(
            nhan: 'Tỷ lệ',
            giaTri: '${tong == 0 ? 0 : xong * 100 ~/ tong}%',
            mau: context.colors.secondary,
          ),
        ],
      ),
    );
  }
}

class _So extends StatelessWidget {
  const _So({required this.nhan, required this.giaTri, required this.mau});

  final String nhan;
  final String giaTri;
  final Color mau;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          giaTri,
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: mau,
          ),
        ),
        Text(
          nhan,
          style: context.text.bodySmall?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _KhoiBuoi extends StatelessWidget {
  const _KhoiBuoi({
    required this.ten,
    required this.luot,
    required this.taskMap,
    required this.onMoLai,
  });

  final String ten;
  final List<TaskInstance> luot;
  final Map<String, Task> taskMap;
  final void Function(TaskInstance instance)? onMoLai;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ten,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final i in luot) ...[
            _DongLuot(
              // Thiếu key thì Flutter tái dùng State theo vị trí khi việc đổi
              // trạng thái, và hàng hiện tên của việc cũ — lỗi đã xảy ra ở dự
              // án này một lần.
              key: ValueKey(i.id),
              luot: i,
              viec: taskMap[i.taskId],
              onMoLai: onMoLai,
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _DongLuot extends StatelessWidget {
  const _DongLuot({
    required this.luot,
    required this.viec,
    required this.onMoLai,
    super.key,
  });

  final TaskInstance luot;
  final Task? viec;
  final void Function(TaskInstance instance)? onMoLai;

  @override
  Widget build(BuildContext context) {
    final xong = luot.status == InstanceStatus.approved.name;
    final choDuyet = luot.status == InstanceStatus.pendingReview.name;
    final boLo =
        luot.status == InstanceStatus.missed.name ||
        luot.status == InstanceStatus.rejected.name;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: xong
            ? context.semantic.success.withValues(alpha: 0.15)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          AppIcon.task(viec?.iconKey ?? 'star', size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              viec?.title ?? 'Nhiệm vụ',
              style: context.text.bodyMedium?.copyWith(
                fontWeight: xong ? FontWeight.w700 : FontWeight.w500,
                decoration: xong || boLo ? TextDecoration.lineThrough : null,
                color: boLo ? context.semantic.onSurfaceMuted : null,
              ),
            ),
          ),
          if (xong) ...[
            Icon(
              Icons.check_circle_rounded,
              color: context.semantic.success,
              size: 20,
            ),
            if (onMoLai != null)
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Cho con làm lại',
                onPressed: () => onMoLai!(luot),
              ),
          ] else if (choDuyet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.semantic.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Chờ duyệt',
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.warning,
                ),
              ),
            )
          else if (boLo)
            Icon(
              Icons.cancel_rounded,
              size: 20,
              color: context.semantic.danger,
            )
          else
            XuBadge(amount: luot.pointsSnapshot, pill: true),
        ],
      ),
    );
  }
}
