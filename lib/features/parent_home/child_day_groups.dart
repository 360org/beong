import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:flutter/material.dart';

/// Việc của một bé trong ngày, **nhóm theo buổi**.
///
/// Trước v0.3.2 chỗ này xổ ra một danh sách phẳng: 23 dòng liền nhau, "Đánh
/// răng buổi sáng" nằm cạnh "Làm bài tập" nằm cạnh "Tắm rửa", không theo thứ tự
/// nào của một ngày. Bố mẹ phải tự đọc hết mới biết buổi sáng đã xong chưa.
///
/// Mỗi nhóm hiện **đã xong / tổng**, và liệt kê cả việc đã xong lẫn chưa xong —
/// chỉ hiện việc chưa xong thì nhóm làm hết việc sẽ biến mất, và "biến mất" là
/// tín hiệu tệ cho thứ đáng ra phải là một lời khen.
class ChildDayGroups extends StatelessWidget {
  const ChildDayGroups({
    required this.memberId,
    required this.familyId,
    required this.date,
    required this.taskDao,
    super.key,
  });

  final String memberId;
  final String familyId;
  final CalendarDate date;
  final TaskRepository taskDao;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskInstance>>(
      stream: taskDao.watchInstancesForMember(memberId: memberId, date: date),
      builder: (context, snap) {
        final luot = snap.data ?? const <TaskInstance>[];
        if (luot.isEmpty) return const SizedBox.shrink();

        // Một lần đọc cho cả danh sách, không phải mỗi dòng một truy vấn — đúng
        // bài học của bản sửa giật cục 0.2.5.
        return FutureBuilder<_DuLieuNhom>(
          future: _nap(luot),
          builder: (context, duLieu) {
            final data = duLieu.data;
            if (data == null) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LinearProgressIndicator(),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final nhom in data.nhom)
                  _NhomBuoi(nhom: nhom, tenViec: data.tenViec),
              ],
            );
          },
        );
      },
    );
  }

  Future<_DuLieuNhom> _nap(List<TaskInstance> luot) async {
    final viec = await taskDao.activeTasks(familyId);
    final buoi = await taskDao.activeRoutines(familyId);

    final viecTheoId = {for (final t in viec) t.id: t};
    final buoiTheoId = {for (final r in buoi) r.id: r};

    // Giữ thứ tự buổi theo `dayPart` rồi tới tên, để danh sách đọc xuôi theo
    // một ngày thay vì theo thứ tự bản ghi trong DB.
    final theoBuoi = <String, List<TaskInstance>>{};
    for (final i in luot) {
      final routineId = viecTheoId[i.taskId]?.routineId ?? _khongBuoi;
      theoBuoi.putIfAbsent(routineId, () => []).add(i);
    }

    int thuTu(String routineId) {
      if (routineId == _khongBuoi) return 99;
      final part = buoiTheoId[routineId]?.dayPart;
      return switch (part) {
        'morning' => 0,
        'afternoon' => 1,
        'evening' => 2,
        _ => 3,
      };
    }

    final nhom =
        theoBuoi.entries
            .map(
              (e) => _Nhom(
                ten: e.key == _khongBuoi
                    ? 'Chưa xếp buổi'
                    : buoiTheoId[e.key]?.title ?? 'Buổi',
                iconKey: e.key == _khongBuoi
                    ? 'clipboard'
                    : buoiTheoId[e.key]?.iconKey,
                thuTu: thuTu(e.key),
                luot: e.value,
              ),
            )
            .toList()
          ..sort((a, b) {
            final c = a.thuTu.compareTo(b.thuTu);
            return c != 0 ? c : a.ten.compareTo(b.ten);
          });

    return _DuLieuNhom(
      nhom: nhom,
      tenViec: {
        for (final t in viec) t.id: (title: t.title, iconKey: t.iconKey),
      },
    );
  }

  static const _khongBuoi = '';
}

typedef _TenViec = Map<String, ({String title, String? iconKey})>;

class _DuLieuNhom {
  const _DuLieuNhom({required this.nhom, required this.tenViec});
  final List<_Nhom> nhom;
  final _TenViec tenViec;
}

class _Nhom {
  const _Nhom({
    required this.ten,
    required this.iconKey,
    required this.thuTu,
    required this.luot,
  });

  final String ten;
  final String? iconKey;
  final int thuTu;
  final List<TaskInstance> luot;

  int get daXong => luot.where((i) => daLamXong(i.status)).length;
}

/// Lượt việc này có thật sự **đã làm xong** không.
///
/// Chỉ `approved` và `pendingReview` mới tính. Bản trước lấy "khác
/// `scheduled`" là xong, nên `missed` và `rejected` cũng được đếm là xong —
/// lỗi này không ai thấy chừng nào thẻ chỉ hiện hôm nay, vì việc hôm nay chưa
/// kịp bị đánh dấu bỏ lỡ. Vuốt ngang xem ngày cũ (30/08/2026) là nó lộ ra
/// ngay: một ngày con **không làm gì cả** hiện "5/5" với dấu tích xanh, trong
/// khi dòng đầu thẻ ghi "0/12 việc".
bool daLamXong(String status) =>
    status == InstanceStatus.approved.name ||
    status == InstanceStatus.pendingReview.name;

/// Bỏ lỡ hoặc bị từ chối — đã qua, nhưng **không phải** đã xong.
bool daHongViec(String status) =>
    status == InstanceStatus.missed.name ||
    status == InstanceStatus.rejected.name;

class _NhomBuoi extends StatelessWidget {
  const _NhomBuoi({required this.nhom, required this.tenViec});

  final _Nhom nhom;
  final _TenViec tenViec;

  @override
  Widget build(BuildContext context) {
    final xongHet = nhom.daXong == nhom.luot.length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        // Buổi đã xong hết thì gập lại — thứ cần bố mẹ để mắt là buổi còn dở.
        initiallyExpanded: !xongHet,
        leading: AppIcon(nhom.iconKey ?? 'clipboard', size: 22),
        title: Text(
          nhom.ten,
          style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (xongHet)
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: context.semantic.success,
              ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${nhom.daXong}/${nhom.luot.length}',
              style: context.text.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: xongHet
                    ? context.semantic.success
                    : context.semantic.onSurfaceMuted,
              ),
            ),
          ],
        ),
        children: [
          for (final luot in nhom.luot)
            _DongViec(luot: luot, viec: tenViec[luot.taskId]),
        ],
      ),
    );
  }
}

class _DongViec extends StatelessWidget {
  const _DongViec({required this.luot, required this.viec});

  final TaskInstance luot;
  final ({String title, String? iconKey})? viec;

  @override
  Widget build(BuildContext context) {
    final xong = daLamXong(luot.status);
    final hong = daHongViec(luot.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          // Trạng thái nói bằng **hình lẫn chữ**, không chỉ bằng màu — WCAG
          // 1.4.1, và bố mẹ hay liếc màn hình dưới nắng.
          Icon(
            switch ((xong, hong)) {
              (true, _) => Icons.check_circle_rounded,
              (_, true) => Icons.cancel_rounded,
              _ => Icons.radio_button_unchecked_rounded,
            },
            size: 18,
            color: switch ((xong, hong)) {
              (true, _) => context.semantic.success,
              (_, true) => context.semantic.danger,
              _ => context.semantic.onSurfaceMuted,
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          AppIcon.task(viec?.iconKey, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              viec?.title ?? 'Việc đã gỡ',
              style: context.text.bodyMedium?.copyWith(
                decoration: xong || hong ? TextDecoration.lineThrough : null,
                color: xong || hong ? context.semantic.onSurfaceMuted : null,
              ),
            ),
          ),
          Text(
            '+${luot.pointsSnapshot} xu',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.xuText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
