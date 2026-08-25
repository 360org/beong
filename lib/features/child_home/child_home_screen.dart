import 'dart:async';
import 'package:beong/app/router.dart';
import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/family_clock_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/kid_scale.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/bee_mascot.dart';
import 'package:beong/core/widgets/celebration.dart';
import 'package:beong/core/widgets/loi_man_hinh.dart';
import 'package:beong/core/widgets/progress_ring.dart';
import 'package:beong/core/widgets/task_card.dart';
import 'package:beong/domain/entities/badge_def.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/jar_repository.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/features/goals/goal_section.dart';
import 'package:beong/features/members/mat_khau_sheet.dart';
import 'package:beong/features/rewards/allocate_xu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChildHomeScreen extends ConsumerStatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  ConsumerState<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends ConsumerState<ChildHomeScreen> {
  /// Hoa giấy nổ ở **cấp màn hình**, không ở trong thẻ việc.
  ///
  /// Đặt trong thẻ thì hiệu ứng không bao giờ được thấy: bấm xong là việc rời
  /// mục "Cần làm" xuống "Đã xong" ngay, thẻ bị tháo và mang theo cả hoa giấy.
  /// Ở cấp màn hình thì hiệu ứng sống qua lần xếp lại danh sách, và nổ giữa màn
  /// còn dễ thấy hơn nổ trong một hàng cao 70px.
  bool _celebrate = false;

  // ---------------------------------------------------------------------------
  // Luồng dữ liệu giữ lại giữa các lần dựng.
  //
  // Đây là nguyên nhân của "bấm xong việc thì giật cục". Trước bản này cả bốn
  // luồng dưới đây được **tạo mới ngay trong `build()`**:
  //
  //     stream: taskDao.watchInstancesForMember(memberId: ..., date: today)
  //
  // Drift trả một `Stream` **mới** mỗi lần gọi. `StreamBuilder` so sánh theo
  // *danh tính* đối tượng, thấy khác là huỷ đăng ký rồi đăng ký lại — và lúc đó
  // nó quay về `ConnectionState.waiting` với `data == null`. Danh sách việc bị
  // thay bằng vòng xoay rồi mới dựng lại.
  //
  // Mà mỗi lần con bấm xong một việc thì màn hình `setState` để nổ hoa giấy —
  // hai lần, bật rồi tắt. Nên **mỗi cú chạm là hai lần xé cả danh sách đi dựng
  // lại**. Đúng thứ người dùng mô tả.
  //
  // Giữ lại ở đây, chỉ dựng lại khi thứ *thật sự* quyết định nội dung đổi: đổi
  // bé, đổi nhà, hoặc sang ngày mới.
  String? _khoaLuong;
  late Stream<List<TaskInstance>> _luongLuotViec;
  late Stream<List<Task>> _luongViec;
  late Stream<Member> _luongThanhVien;
  late Stream<WalletBalance> _luongVi;
  late Stream<Streak?> _luongChuoi;

  void _dungLuongNeuCan({
    required String memberId,
    required String familyId,
    required CalendarDate today,
  }) {
    final khoa = '$memberId|$familyId|$today';
    if (khoa == _khoaLuong) return;
    _khoaLuong = khoa;

    final tasks = ref.read(taskRepositoryProvider);
    final members = ref.read(memberRepositoryProvider);
    final wallet = ref.read(walletRepositoryProvider);

    _luongLuotViec = tasks.watchInstancesForMember(
      memberId: memberId,
      date: today,
    );
    _luongViec = tasks.watchActiveTasks(familyId);
    _luongThanhVien = members.watchMember(memberId);
    _luongChuoi = members.watchStreak(memberId);
    _luongVi = wallet.watchBalance(memberId);
  }

  /// Con bấm xong một lượt việc.
  ///
  /// Ở **cấp màn hình** chứ không trong thẻ việc: thẻ bị tháo ngay khi việc đổi
  /// mục, nên `mounted` của nó đã `false` lúc `complete()` trả về và huy hiệu
  /// vừa nhận sẽ rơi vào im lặng.
  Future<void> _hoanThanhViec(String instanceId, Task? task) async {
    String? proofNote;
    String? proofUrl;

    if (task != null) {
      if (task.proofMode == ProofMode.note.name) {
        final noteController = TextEditingController();
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ghi chú cho bố mẹ'),
            content: TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Nhập lời nhắn hoặc kết quả làm việc...',
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Huỷ'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Xong'),
              ),
            ],
          ),
        );
        if (ok != true || !mounted) return;
        proofNote = noteController.text.trim();
      } else if (task.proofMode == ProofMode.photo.name) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Bằng chứng chụp ảnh'),
            content: const Text(
              'Việc này yêu cầu chụp ảnh xác nhận. Hãy đưa bố mẹ kiểm tra sau khi bấm xong nhé!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Để sau'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Đã xong'),
              ),
            ],
          ),
        );
        if (ok != true || !mounted) return;
        proofUrl = 'local_captured_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    final ketQua = await ref.read(taskReviewServiceProvider).complete(
      instanceId,
      proofNote: proofNote,
      proofUrl: proofUrl,
    );
    if (!mounted || ketQua.huyHieuMoi.isEmpty) return;
    _khoeHuyHieu(ketQua.huyHieuMoi);
  }

  /// Khoe huy hiệu vừa nhận.
  ///
  /// Nổ hoa giấy **và** hiện tên huy hiệu: hoa giấy một mình thì con tưởng là
  /// hiệu ứng của việc vừa bấm, không biết mình vừa đạt được thứ gì.
  void _khoeHuyHieu(List<BadgeDef> huyHieu) {
    unawaited(_celebrateOnce());
    final ten = huyHieu.map((b) => b.title).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Con vừa nhận huy hiệu "$ten"!'),
        action: SnackBarAction(
          label: 'XEM',
          onPressed: () => context.go(Routes.badges),
        ),
      ),
    );
  }

  Future<void> _celebrateOnce() async {
    setState(() => _celebrate = true);
    // Nhả cờ sau khi hiệu ứng chạy xong để lần bấm sau nổ lại được.
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (mounted) setState(() => _celebrate = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberId = session.activeMemberId;
    final taskDao = ref.watch(taskRepositoryProvider);
    final penaltyService = ref.watch(penaltyServiceProvider);

    final today =
        (ref.watch(familyClockProvider(session.familyId)).value ??
                fallbackFamilyClock())
            .today();

    _dungLuongNeuCan(
      memberId: memberId,
      familyId: session.familyId,
      today: today,
    );

    return Scaffold(
      body: ConfettiBurst(
        play: _celebrate,
        child: SafeArea(
          child: StreamBuilder<List<TaskInstance>>(
            stream: _luongLuotViec,
            builder: (context, instSnap) {
              // Danh sách việc là chỗ hiện sai tệ nhất: luồng hỏng mà rơi về
              // rỗng thì con thấy "chưa có việc nào hôm nay" và tin là thật.
              if (instSnap.hasError) {
                return LoiManHinh(error: instSnap.error!);
              }
              final instances = instSnap.data ?? [];
              final total = instances.length;
              final completedCount = instances
                  .where(
                    (i) =>
                        i.status == InstanceStatus.approved.name ||
                        i.status == InstanceStatus.pendingReview.name,
                  )
                  .length;

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingMobile,
                  vertical: AppSpacing.lg,
                ),
                children: [
                  StreamBuilder<Member>(
                    stream: _luongThanhVien,
                    builder: (context, memberSnap) {
                      final member = memberSnap.data;
                      // Giao diện điều chỉnh theo tuổi của chính bé đang xem —
                      // xem `core/theme/kid_scale.dart`.
                      final scale = KidScale.forBirthYear(
                        member?.birthYear,
                        currentYear: today.year,
                      );

                      return KidScaleScope(
                        scale: scale,
                        child: Column(
                          children: [
                            _ChildHeader(member: member),
                            const SizedBox(height: AppSpacing.lg),
                            StreamBuilder<WalletBalance>(
                              stream: _luongVi,
                              builder: (context, balSnap) {
                                final balance =
                                    balSnap.data ?? WalletBalance.zero;
                                return StreamBuilder<Streak?>(
                                  stream: _luongChuoi,
                                  builder: (context, streakSnap) {
                                    return _DashboardCard(
                                      scale: scale,
                                      points: balance.total,
                                      unallocated: balance.inbox,
                                      onAllocate: balance.inbox > 0
                                          ? () => unawaited(
                                              _openAllocateSheet(
                                                context: context,
                                                familyId: session.familyId,
                                                memberId: memberId,
                                                inbox: balance.inbox,
                                                walletDao: ref.read(
                                                  walletRepositoryProvider,
                                                ),
                                                jarDao: ref.read(
                                                  jarRepositoryProvider,
                                                ),
                                              ),
                                            )
                                          : null,
                                      streak: streakSnap.data?.currentLen ?? 0,
                                      completed: completedCount,
                                      total: total,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Mục tiêu nằm ngay dưới ví, trên danh sách việc: nó là lý do
                  // con làm việc hôm nay, nên phải thấy trước khi cuộn.
                  const SizedBox(height: AppSpacing.lg),
                  GoalSection(memberId: memberId),
                  const SizedBox(height: AppSpacing.xl),
                  if (instSnap.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xxxl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (instances.isEmpty)
                    _EmptyState(
                      onGenerate: () async {
                        await taskDao.generateInstances(
                          familyId: session.familyId,
                          today: today,
                        );
                        // generateInstances đánh dấu missed cho lượt quá hạn;
                        // khoản trừ phải chạy ngay sau đó, không để tới lần mở
                        // app sau (ADR-022). Gọi lại nhiều lần vô hại.
                        await penaltyService.applyMissedPenalties(
                          familyId: session.familyId,
                        );
                      },
                    )
                  else
                    // Nạp **một** lần cho cả danh sách, thay vì để mỗi thẻ tự
                    // hỏi `getTaskById` trong `initState`. Cách cũ vừa là 12
                    // truy vấn rời rạc, vừa làm thẻ trả `SizedBox.shrink()`
                    // trong lúc chờ — tức **cao 0** — nên danh sách co lại rồi
                    // bung ra mỗi khi một thẻ phải nạp lại. Cú giật thứ hai,
                    // ngay sau cú giật do stream bị đăng ký lại.
                    StreamBuilder<List<Task>>(
                      stream: _luongViec,
                      builder: (context, taskSnap) {
                        final byId = {
                          for (final t in taskSnap.data ?? const <Task>[])
                            t.id: t,
                        };
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildTaskSections(instances, byId),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTaskSections(
    List<TaskInstance> instances,
    Map<String, Task> byId,
  ) {
    final scheduled = instances
        .where((i) => i.status == InstanceStatus.scheduled.name)
        .toList();
    // Chờ duyệt là mục **riêng**, không gộp vào "Đã xong". Gộp lại thì việc con
    // vừa bấm trông y hệt việc đã được duyệt — cùng gạch ngang, cùng dấu tích
    // xanh — trong khi xu chưa cộng và bố mẹ vẫn có thể mở lại. Con thấy tích
    // xanh mà số xu không nhích là lúc con thôi tin vào cái tích đó.
    final choDuyet = instances
        .where((i) => i.status == InstanceStatus.pendingReview.name)
        .toList();
    final done = instances
        .where((i) => i.status == InstanceStatus.approved.name)
        .toList();
    final missed = instances
        .where((i) => i.status == InstanceStatus.missed.name)
        .toList();

    return [
      if (scheduled.isNotEmpty) ...[
        _SectionHeader(title: 'Cần làm', count: scheduled.length),
        const SizedBox(height: AppSpacing.sm),
        ...scheduled.map(
          (instance) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InstanceCard(
              // Key theo id: không có key, Flutter tái dùng State theo
              // vị trí khi việc chuyển mục và thẻ hiện tên của việc cũ.
              key: ValueKey(instance.id),
              instance: instance,
              task: byId[instance.taskId],
              onCompleted: _celebrateOnce,
              onComplete: _hoanThanhViec,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
      if (choDuyet.isNotEmpty) ...[
        _SectionHeader(title: 'Chờ bố mẹ duyệt', count: choDuyet.length),
        const SizedBox(height: AppSpacing.sm),
        ...choDuyet.map(
          (instance) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InstanceCard(
              // Key theo id: không có key, Flutter tái dùng State theo
              // vị trí khi việc chuyển mục và thẻ hiện tên của việc cũ.
              key: ValueKey(instance.id),
              instance: instance,
              task: byId[instance.taskId],
              onCompleted: _celebrateOnce,
              onComplete: _hoanThanhViec,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
      if (done.isNotEmpty) ...[
        _SectionHeader(title: 'Đã xong', count: done.length),
        const SizedBox(height: AppSpacing.sm),
        ...done.map(
          (instance) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InstanceCard(
              // Key theo id: không có key, Flutter tái dùng State theo
              // vị trí khi việc chuyển mục và thẻ hiện tên của việc cũ.
              key: ValueKey(instance.id),
              instance: instance,
              task: byId[instance.taskId],
              onCompleted: _celebrateOnce,
              onComplete: _hoanThanhViec,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
      if (missed.isNotEmpty) ...[
        _SectionHeader(title: 'Bỏ lỡ', count: missed.length),
        const SizedBox(height: AppSpacing.sm),
        ...missed.map(
          (instance) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InstanceCard(
              // Key theo id: không có key, Flutter tái dùng State theo
              // vị trí khi việc chuyển mục và thẻ hiện tên của việc cũ.
              key: ValueKey(instance.id),
              instance: instance,
              task: byId[instance.taskId],
              onCompleted: _celebrateOnce,
              onComplete: _hoanThanhViec,
            ),
          ),
        ),
      ],
    ];
  }
}

/// Đầu màn hình con: avatar + tên, bấm vào để **đổi người dùng**.
///
/// Vai con không có tab Cài đặt (chỗ vốn chứa nút chuyển hồ sơ), nên nếu không
/// có đường này thì máy dùng chung bị kẹt ở vai con — bố mẹ không về lại được.
///
/// Cố ý đặt ở avatar chứ không thành một nút riêng: nó là đường cho người lớn,
/// không phải thứ cần mời con bấm.
class _ChildHeader extends ConsumerWidget {
  const _ChildHeader({required this.member});

  final Member? member;

  /// Đổi sang hồ sơ [member], hỏi mật khẩu của **chính hồ sơ đó** (ADR-027).
  ///
  /// Đây là **cửa duy nhất** con có thể tự đi vào vai bố mẹ. Không chặn ở đây
  /// thì cả vòng "bố mẹ duyệt" (ADR-023, ADR-025) chỉ là hình thức: con đổi vai
  /// rồi tự duyệt việc của mình.
  ///
  /// Từ ADR-027 thì cửa này còn chặn thêm một chiều nữa: bé không mở được hồ sơ
  /// của anh chị em mình, vì mỗi hồ sơ một mật khẩu.
  static Future<void> _switchTo(
    BuildContext context,
    WidgetRef ref, {
    required Member member,
    required String familyId,
  }) async {
    final isParent = member.kind == MemberKind.parent.name;
    final ok = await hoiMatKhau(
      context,
      memberId: member.id,
      tenHienThi: member.displayName,
      service: ref.read(matKhauHoSoProvider),
    );
    if (!ok || !context.mounted) return;

    Navigator.of(context).pop();
    await ref
        .read(sessionProvider.notifier)
        .switchMember(member.id, isParent: isParent);
  }

  Future<void> _switchProfile(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final members = await ref
        .read(memberRepositoryProvider)
        .watchMembers(session.familyId)
        .first;
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Đổi người dùng', style: context.text.titleMedium),
            ),
            for (final m in members)
              ListTile(
                leading: AppIcon(
                  iconKeyForEmoji(avatarForKey(m.avatarKey)),
                  size: 30,
                ),
                title: Text(m.displayName),
                subtitle: Text(
                  m.kind == MemberKind.parent.name ? 'Bố mẹ' : 'Trẻ',
                ),
                trailing: m.id == session.activeMemberId
                    ? Icon(Icons.check_circle, color: context.colors.primary)
                    : null,
                onTap: () => unawaited(
                  _switchTo(
                    context,
                    ref,
                    member: m,
                    familyId: session.familyId,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = this.member;
    final color = member == null
        ? context.colors.primary
        : AppColors.profileColor(member.colorIndex);

    return GestureDetector(
      onTap: () => unawaited(_switchProfile(context, ref)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              iconKeyForEmoji(avatarForKey(member?.avatarKey)),
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            member?.displayName ?? '',
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.expand_more_rounded,
            size: 20,
            color: context.semantic.onSurfaceMuted,
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.scale,
    required this.points,
    required this.unallocated,
    required this.onAllocate,
    required this.streak,
    required this.completed,
    required this.total,
  });

  final KidScale scale;

  /// Tổng xu của con, **tính cả phần chưa chia** (ADR-024).
  final int points;

  /// Phần chưa chia. 0 khi nhà đặt chế độ chia tự động.
  final int unallocated;

  /// Mở màn chia xu. Null khi không có gì để chia.
  final VoidCallback? onAllocate;
  final int streak;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    // Danh hiệu chỉ hiện khi thật sự xong hết — `total > 0` chặn trường hợp
    // ngày chưa có việc nào cũng được khen.
    final allDone = total > 0 && completed == total;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: context.dashboardGradient,
        borderRadius: BorderRadius.circular(scale.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allDone) ...[
            _BusyBeeBadge(label: L10n.of(context).badgeBusyBee),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              // Tiến độ là hình tròn, không phải con số: bé chưa đọc số vẫn
              // thấy được vòng đã đầy tới đâu.
              ProgressRing(
                progress: progress,
                size: scale.showMascot ? 104 : 84,
                strokeWidth: scale.showMascot ? 11 : 9,
                trackColor: Colors.white.withValues(alpha: 0.25),
                valueColor: Colors.white,
                child: scale.showMascot
                    ? BeeMascot(
                        mood: BeeMood.fromProgress(
                          completed: completed,
                          total: total,
                        ),
                        size: 62,
                      )
                    : Text(
                        '$completed/$total',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  // Hai ô thống kê phải bằng chiều rộng nhau, không co theo
                  // độ dài nội dung.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Một ô duy nhất cho xu. Trước đây có "ĐIỂM" ở đây và một
                    // banner "Có N xu chờ chia" riêng bên dưới — hai chỗ nói về
                    // cùng một số tiền, mà điểm **chính là** xu (ADR-015), nên
                    // người đọc phải tự cộng trừ để biết mình có bao nhiêu.
                    //
                    // Nhãn cũ ghi "ĐIỂM" là tự trái ADR-015: đơn vị trong app
                    // gọi là **xu**, không gọi điểm.
                    _StatTile(
                      // Nhãn luôn chỉ là "XU": phần chưa chia đã nói ngay bên
                      // cạnh con số, thêm vào nhãn là lặp lại lần thứ ba.
                      label: 'XU',
                      onTap: unallocated > 0 ? onAllocate : null,
                      // Phần chưa chia xuống dòng riêng, không nằm cạnh con
                      // số: đứng cùng dòng thì hai con số dính nhau và ô bị
                      // chật ở 412dp. Thứ tự đọc: bao nhiêu xu → còn bao nhiêu
                      // chưa chia.
                      footer: unallocated > 0
                          ? Text(
                              '$unallocated chưa chia ›',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            )
                          : null,
                      child: XuBadgeStat(amount: points),
                    ),
                    if (scale.showStreakFlame) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _StatTile(
                        label: 'NGÀY LIÊN TIẾP',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon('fire', size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '$streak',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: AppSpacing.sm),
                      _StatTile(
                        label: 'HÔM NAY',
                        child: Text(
                          '$completed/$total',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Danh hiệu "Ong chăm chỉ" — slogan của app dùng làm phần thưởng tinh thần
/// khi bé làm xong hết việc trong ngày.
class _BusyBeeBadge extends StatelessWidget {
  const _BusyBeeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.semantic.xu,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon('bee', size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.semantic.onXu,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.child,
    required this.label,
    this.onTap,
    this.footer,
  });

  final Widget child;
  final String label;

  /// Dòng phụ dưới nhãn. Null = ô chỉ có số và nhãn.
  final Widget? footer;

  /// Bấm được thì ô thành nút. Null = chỉ để đọc.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = _tile(context);
    if (onTap == null) return tile;

    // Bọc InkWell **bên trong** để hiệu ứng gợn nằm trong bo góc của ô, và giữ
    // được vùng chạm bằng cả ô chứ không chỉ phần chữ.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: tile,
      ),
    );
  }

  Widget _tile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nhãn nằm **cùng hàng** với con số, không xuống dòng riêng: "60"
          // rồi "XU" ở dòng dưới đọc như hai thông tin rời, trong khi nó là
          // một cụm — sáu mươi xu.
          Row(
            children: [
              child,
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.xs),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Số điểm hiển thị trắng trên nền gradient — dùng emoji 💎 giống XuBadge
/// nhưng cỡ chữ lớn hơn cho thẻ dashboard.
class XuBadgeStat extends StatelessWidget {
  const XuBadgeStat({required this.amount, super.key});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppIcon('gem', size: 22),
        const SizedBox(width: 4),
        Text(
          '$amount',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: context.text.titleSmall?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$count',
            style: context.text.labelSmall?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstanceCard extends StatelessWidget {
  const _InstanceCard({
    required this.instance,
    required this.task,
    required this.onCompleted,
    required this.onComplete,
    super.key,
  });

  final TaskInstance instance;

  /// Việc tương ứng, do màn hình nạp sẵn cho cả danh sách.
  ///
  /// `null` chỉ ở khung hình đầu, trước khi luồng việc kịp phát.
  final Task? task;

  /// Gọi khi con vừa bấm xong việc, để màn hình nổ hoa giấy. Thẻ không tự nổ:
  /// nó bị tháo ngay sau khi bấm vì danh sách xếp lại theo trạng thái.
  final VoidCallback onCompleted;

  /// Báo lên màn hình rằng con vừa bấm xong lượt này. Màn hình gọi service và
  /// xử lý kết quả — nó sống qua lần xếp lại danh sách, còn thẻ thì không.
  final Future<void> Function(String instanceId, Task? task) onComplete;

  @override
  Widget build(BuildContext context) {
    final task = this.task;
    final scale = KidScaleScope.of(context);

    // Chỗ trống **có chiều cao**, không co về 0: chỗ trống có kích thước thì
    // danh sách đứng yên, chỗ trống cao 0 thì nó nhảy.
    if (task == null) {
      return SizedBox(height: scale.tapTarget + AppSpacing.lg);
    }

    return TaskCard(
      title: task.title,
      points: task.points,
      iconKey: task.iconKey,
      isCompleted: instance.status == InstanceStatus.approved.name,
      isPending: instance.status == InstanceStatus.pendingReview.name,
      isMissed: instance.status == InstanceStatus.missed.name,
      // Đi qua TaskReviewService chứ không gọi thẳng DAO: nó là chỗ duy nhất
      // biết nhà này có bật duyệt hay không, và là chỗ cộng xu (ADR-023).
      onToggle: () {
        // `celebrateOnTap` tắt với tuổi teen: hoa giấy với bé 14 tuổi là rườm rà.
        if (scale.celebrateOnTap) onCompleted();
        // Gọi lên **màn hình**, không tự `await` ở đây: bấm xong là việc rời mục
        // "Cần làm" xuống "Đã xong" ngay, thẻ này bị tháo, và mọi
        // `if (!mounted) return` sau `await` sẽ nuốt mất kết quả — đúng cái bẫy
        // đã làm hoa giấy không bao giờ hiện.
        unawaited(onComplete(instance.id, task));
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon('party', size: 60),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Chưa có việc nào hôm nay',
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bấm nút bên dưới để tạo việc mới.',
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: onGenerate,
              child: const Text('TẠO VIỆC HÔM NAY'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mở màn chia xu — ADR-024, chế độ `manual`.
///
/// Vào bằng cách bấm chính ô xu, không phải một banner riêng: banner riêng là
/// chỗ thứ hai nói về cùng một số tiền.
Future<void> _openAllocateSheet({
  required BuildContext context,
  required String familyId,
  required String memberId,
  required int inbox,
  required WalletRepository walletDao,
  required JarRepository jarDao,
}) async {
  // Đọc hũ **trước khi** mở sheet: mở rồi mới đọc thì con thấy một khung trống
  // nháy lên, và trên máy chậm thì đủ lâu để bấm vào chỗ chưa có gì.
  final jars = await jarDao.activeJars(familyId);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AllocateXuSheet(
      familyId: familyId,
      memberId: memberId,
      inbox: inbox,
      walletDao: walletDao,
      jars: jars,
    ),
  );
}
