import 'dart:async';
import 'dart:io';

import 'package:beong/app/router.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/family_clock_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/loi_man_hinh.dart';
import 'package:beong/core/widgets/thong_bao.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/reward_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/task_review_service.dart';
import 'package:beong/features/members/mat_khau_sheet.dart';
import 'package:beong/features/parent_home/child_history_sheet.dart';
import 'package:beong/features/parent_home/ngay_cua_con.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberRepositoryProvider);
    final taskDao = ref.watch(taskRepositoryProvider);
    final walletDao = ref.watch(walletRepositoryProvider);
    final reviewService = ref.watch(taskReviewServiceProvider);

    Future<void> switchMember(Member member) async {
      final hopLe = await hoiMatKhau(
        context,
        memberId: member.id,
        tenHienThi: member.displayName,
        service: ref.read(matKhauHoSoProvider),
        moTa: 'Bốn chữ số của ${member.displayName}',
      );
      if (!hopLe || !context.mounted) return;

      await ref
          .read(sessionProvider.notifier)
          .switchMember(
            member.id,
            isParent: member.kind == MemberKind.parent.name,
          );
      if (context.mounted) context.go('/');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chính', style: context.text.titleLarge),
      ),
      body: StreamBuilder<List<Member>>(
        stream: memberDao.watchMembers(session.familyId),
        builder: (context, membersSnap) {
          // Không có thành viên nào **có thể** là lỗi luồng chứ không phải nhà
          // trống: rơi về rỗng lặng lẽ thì bố mẹ tưởng hồ sơ con bị mất.
          if (membersSnap.hasError) {
            return LoiManHinh(error: membersSnap.error!);
          }
          final members = membersSnap.data ?? [];
          final children = members
              .where((m) => m.kind == MemberKind.child.name)
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: [
              _PendingReviewSection(
                familyId: session.familyId,
                children: children,
                taskDao: taskDao,
                walletDao: walletDao,
                reviewService: reviewService,
                reviewerId: session.activeMemberId,
              ),
              _PendingRedemptionBanner(familyId: session.familyId),
              const SizedBox(height: AppSpacing.xxl),
              Text('Con của bạn', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ...children.map(
                (child) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ChildSummaryCard(
                    // Thẻ giữ trạng thái mở/gập, nên phải có key: thiếu key thì
                    // Flutter tái dùng State theo **vị trí**, gập thẻ của NEO
                    // rồi danh sách đổi thứ tự là thẻ của Simba gập theo.
                    key: ValueKey(child.id),
                    child: child,
                    taskDao: taskDao,
                    walletDao: walletDao,
                    reviewService: reviewService,
                    reviewerId: session.activeMemberId,
                    onTapProfile: () => unawaited(switchMember(child)),
                  ),
                ),
              ),
              if (children.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Text(
                      'Chưa thêm bé nào.',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.semantic.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Nhắc bố mẹ có phiếu đổi thưởng đang chờ.
///
/// Hàng chờ phiếu nằm ở tab **Phần thưởng**, đúng về mặt phân loại, nhưng bố mẹ
/// mở app là vào Trang chính — không có dòng này thì họ **không biết** có việc
/// cần mình, và con thì cứ chờ. Chỉ hiện khi thật sự có phiếu chờ, để trang chính
/// không thêm một dòng luôn nằm đó mà chẳng nói gì.
class _PendingRedemptionBanner extends ConsumerWidget {
  const _PendingRedemptionBanner({required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Redemption>>(
      stream: ref
          .watch(rewardRepositoryProvider)
          .watchPendingRedemptions(familyId),
      builder: (context, snap) {
        final count = snap.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Card(
            color: context.colors.primaryContainer,
            child: InkWell(
              onTap: () => context.go(Routes.rewards),
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const AppIcon('jar_gift', size: 26),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        count == 1
                            ? 'Con xin đổi 1 phần thưởng'
                            : 'Con xin đổi $count phần thưởng',
                        style: context.text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Câu mô tả hàng chờ trước khi bố mẹ bấm "Duyệt hết".
///
/// Cùng lý do với [beCuaLuot]: nút này cộng xu cho **nhiều bé cùng lúc**, nên
/// câu xác nhận phải nói ra là những bé nào. "5 việc sẽ được duyệt và cộng xu
/// cho con" ở nhà hai bé là một câu không xác nhận được điều gì.
///
/// Tên bé theo đúng thứ tự trong danh sách nhà, không theo thứ tự hàng chờ:
/// mở hộp thoại hai lần mà thứ tự tên đổi chỗ thì bố mẹ phải đọc lại từ đầu.
String moTaDuyetHet({
  required List<TaskInstance> hangCho,
  required List<Member> children,
}) {
  final soViec = hangCho.length;
  if (children.length <= 1) {
    return '$soViec việc sẽ được duyệt và cộng xu cho con.';
  }
  final coViec = {for (final i in hangCho) i.memberId};
  final ten = [
    for (final c in children)
      if (coViec.contains(c.id)) c.displayName,
  ];
  if (ten.isEmpty) return '$soViec việc sẽ được duyệt và cộng xu.';
  return '$soViec việc của ${ten.join(', ')} sẽ được duyệt và cộng xu.';
}

/// Bé đứng sau một lượt việc trong hàng chờ duyệt.
///
/// Chủ dự án nêu 30/08/2026: *"phần approve công việc không hiển thị là duyệt
/// cho profile nào?"* Nhà hai bé mà thẻ chỉ ghi "Cất đồ chơi +5 xu" thì bố mẹ
/// đang duyệt mù — cộng xu cho một đứa trẻ mà không biết là đứa nào.
///
/// Trả `null` khi nhà **chỉ có một bé**: lúc đó tên bé lặp lại một điều đã
/// hiển nhiên, và một dòng chữ không mang tin nào là một dòng người đọc học
/// cách bỏ qua. Cũng trả `null` khi không tra ra bé — hồ sơ đã xoá chẳng hạn;
/// thà thiếu tên còn hơn hiện một cái tên đoán bừa.
Member? beCuaLuot(String memberId, List<Member> children) {
  if (children.length <= 1) return null;
  for (final c in children) {
    if (c.id == memberId) return c;
  }
  return null;
}

class _PendingReviewSection extends StatefulWidget {
  const _PendingReviewSection({
    required this.familyId,
    required this.children,
    required this.taskDao,
    required this.walletDao,
    required this.reviewService,
    required this.reviewerId,
  });

  final String familyId;

  /// Các bé trong nhà — để mỗi thẻ nói được nó là việc của ai.
  final List<Member> children;

  final TaskRepository taskDao;
  final WalletRepository walletDao;
  final TaskReviewService reviewService;
  final String reviewerId;

  @override
  State<_PendingReviewSection> createState() => _PendingReviewSectionState();
}

class _PendingReviewSectionState extends State<_PendingReviewSection> {
  List<TaskInstance> _pending = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Duyệt cả hàng đợi. Xác nhận trước vì đây là thao tác cộng xu cho nhiều
  /// việc cùng lúc và không có nút hoàn tác.
  Future<void> _approveAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duyệt tất cả?'),
        content: Text(
          moTaDuyetHet(hangCho: _pending, children: widget.children),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Thôi'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Duyệt hết'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final done = await widget.reviewService.approveAll(
      familyId: widget.familyId,
      reviewerId: widget.reviewerId,
    );
    if (!mounted) return;
    hienThongBao(context, 'Đã duyệt $done việc.');
    await _load();
  }

  Future<void> _load() async {
    final pending = await widget.taskDao.pendingReview(widget.familyId);
    if (mounted) {
      setState(() {
        _pending = pending;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    if (_pending.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              const AppIcon('book'),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Không có việc nào chờ duyệt',
                style: context.text.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Chờ duyệt', style: context.text.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.semantic.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${_pending.length}',
                style: context.text.labelSmall?.copyWith(
                  color: context.semantic.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_pending.length > 1)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _approveAll,
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: Text('Duyệt tất cả (${_pending.length})'),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        ..._pending.map(
          (instance) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _PendingCard(
              // Key theo id: không có key, Flutter tái dùng State theo vị trí
              // khi hàng đợi duyệt ngắn lại và thẻ hiện tên của việc cũ.
              key: ValueKey(instance.id),
              instance: instance,
              be: beCuaLuot(instance.memberId, widget.children),
              taskDao: widget.taskDao,
              walletDao: widget.walletDao,
              reviewService: widget.reviewService,
              reviewerId: widget.reviewerId,
              onActioned: _load,
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingCard extends StatefulWidget {
  const _PendingCard({
    required this.instance,
    required this.be,
    required this.taskDao,
    required this.walletDao,
    required this.reviewService,
    required this.reviewerId,
    required this.onActioned,
    super.key,
  });

  final TaskInstance instance;

  /// Bé đã báo xong việc này. `null` = nhà chỉ có một bé, không cần nói ra.
  final Member? be;

  final TaskRepository taskDao;
  final WalletRepository walletDao;
  final TaskReviewService reviewService;
  final String reviewerId;
  final VoidCallback onActioned;

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  Task? _task;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTask());
  }

  @override
  void didUpdateWidget(_PendingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Xem chú thích cùng loại ở `_InstanceCardState`.
    if (oldWidget.instance.taskId != widget.instance.taskId) {
      unawaited(_loadTask());
    }
  }

  Future<void> _loadTask() async {
    final task = await widget.taskDao.getTaskById(widget.instance.taskId);
    if (mounted) setState(() => _task = task);
  }

  /// Bố mẹ phát hiện con bấm xong nhưng chưa làm — ADR-022.
  Future<void> _reopen() async {
    final result = await widget.reviewService.reopen(
      instanceId: widget.instance.id,
      reviewerId: widget.reviewerId,
    );
    if (!mounted) return;

    // Nói rõ đã trừ bao nhiêu. Xu biến mất mà không ai giải thích là đúng thứ
    // làm trẻ mất niềm tin vào app.
    hienThongBao(
      context,
      result.xuDeducted > 0
          ? 'Đã mở lại việc. Trừ ${result.xuDeducted} xu.'
          : 'Đã mở lại việc cho con làm lại.',
    );
    widget.onActioned();
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (task == null) return const SizedBox.shrink();
    final be = widget.be;

    final proofUrl = widget.instance.proofUrl;
    final proofNote = widget.instance.proofNote;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên bé đứng **trên** tên việc, không nhét vào dòng phụ
                      // bên dưới: câu hỏi đầu tiên khi nhìn hàng chờ duyệt là
                      // "của đứa nào", trả lời nó rồi mới tới "việc gì".
                      if (be != null) ...[
                        Row(
                          children: [
                            AppIcon(
                              iconKeyForEmoji(avatarForKey(be.avatarKey)),
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                be.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.labelMedium?.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      Text(task.title, style: context.text.bodyLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '+${task.points} xu',
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.xuText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await widget.reviewService.reject(
                      instanceId: widget.instance.id,
                      reviewerId: widget.reviewerId,
                    );
                    widget.onActioned();
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.semantic.danger,
                  ),
                  tooltip: 'Từ chối',
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: _reopen,
                  icon: Icon(
                    Icons.replay_rounded,
                    color: context.semantic.warning,
                  ),
                  // "Chưa làm" chứ không phải "Từ chối": từ chối là đóng lượt lại,
                  // còn mở lại là trả việc về cho con làm tiếp.
                  tooltip: 'Chưa làm — mở lại',
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  onPressed: () async {
                    // Cộng xu và thưởng trọn bộ routine nằm trong service, không
                    // rải ở UI: đường tự động duyệt cũng phải chạy đúng logic đó.
                    await widget.reviewService.approve(
                      instanceId: widget.instance.id,
                      reviewerId: widget.reviewerId,
                    );
                    widget.onActioned();
                  },
                  icon: const Icon(Icons.check_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: context.semantic.success,
                    foregroundColor: Colors.white,
                  ),
                  tooltip: 'Duyệt',
                ),
              ],
            ),
            if (proofNote != null && proofNote.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        proofNote,
                        style: context.text.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (proofUrl != null && proofUrl.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () async {
                  final file = File(proofUrl);
                  if (file.existsSync()) {
                    await showDialog<void>(
                      context: context,
                      builder: (ctx) => Dialog(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBar(
                              title: const Text('Ảnh chứng thực'),
                              leading: IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.of(ctx).pop(),
                                tooltip: 'Đóng',
                              ),
                            ),
                            InteractiveViewer(
                              child: Image.file(
                                file,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    border: Border.all(
                      color: context.colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: File(proofUrl).existsSync()
                            ? Image.file(
                                File(proofUrl),
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 52,
                                height: 52,
                                color: context.colors.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image_rounded),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ảnh kết quả làm việc',
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Chạm để xem ảnh phóng to',
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.fullscreen_rounded, size: 24),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Quãng đường tối thiểu (dp) để một cú kéo ngang được tính là "vuốt".
///
/// 48dp = đúng vùng chạm tối thiểu của dự án: ngắn hơn thì không phân biệt được
/// với tay hơi lệch khi cuộn dọc.
const kQuangDuongVuot = 48.0;

/// Vận tốc tối thiểu (dp/giây) để một cú **vẩy** nhanh được tính là "vuốt",
/// kể cả khi ngón tay đi chưa đủ [kQuangDuongVuot].
const kVanTocVuot = 200.0;

/// Cú kéo ngang vừa rồi có phải là một cú vuốt có chủ ý không.
///
/// Nhận **hoặc** đi đủ xa **hoặc** vẩy đủ nhanh. Bản trước chỉ xét vận tốc, nên
/// một cú vuốt chậm mà dứt khoát — kiểu người lớn kéo từ từ sang phải rồi nhấc
/// tay — không được tính, và nhìn từ ngoài là "vuốt không ăn". Đây là nửa còn
/// lại của lỗi chủ dự án báo ngày 30/08/2026; nửa kia là cử chỉ chỉ gắn vào dải
/// chữ tên con.
bool laVuotNgangThatSu({required double quangDuong, required double vanToc}) =>
    quangDuong.abs() >= kQuangDuongVuot || vanToc.abs() >= kVanTocVuot;

/// Số ngày lùi mới sau một cú vuốt.
///
/// Vuốt sang **phải** (dx dương) = lùi về quá khứ, giống lật ngược một cuốn
/// sổ; vuốt trái quay lại phía hôm nay. Kẹp trong `[0, toiDa]`: không có
/// tương lai để xem, và lùi quá xa thì chỉ còn khoảng trắng.
int luiNgaySauVuot({
  required int hienTai,
  required double quangDuong,
  required double vanToc,
  required int toiDa,
}) {
  final sangPhai = (quangDuong != 0 ? quangDuong : vanToc) > 0;
  return (sangPhai ? hienTai + 1 : hienTai - 1).clamp(0, toiDa);
}

class _ChildSummaryCard extends ConsumerStatefulWidget {
  const _ChildSummaryCard({
    required this.child,
    required this.taskDao,
    required this.walletDao,
    required this.reviewService,
    required this.reviewerId,
    required this.onTapProfile,
    super.key,
  });

  final Member child;
  final TaskRepository taskDao;
  final WalletRepository walletDao;
  final TaskReviewService reviewService;
  final String reviewerId;
  final VoidCallback onTapProfile;

  @override
  ConsumerState<_ChildSummaryCard> createState() => _ChildSummaryCardState();
}

class _ChildSummaryCardState extends ConsumerState<_ChildSummaryCard> {
  /// Mở sẵn: gập hết ngay từ đầu thì bố mẹ mở app lên không thấy việc nào của
  /// con cả — mất đúng thứ màn hình này sinh ra để cho xem.
  bool _moRong = true;

  /// Tổng quãng đường ngón tay đã đi ngang trong cú kéo đang diễn ra.
  double _keoNgang = 0;

  /// Hướng cú vuốt gần nhất: `1` = đang đi về quá khứ, `-1` = quay lại hôm
  /// nay. Chỉ dùng để hoạt ảnh trượt **đúng chiều tay vừa đi** — trượt ngược
  /// chiều thì cảm giác như app cãi lại ngón tay.
  int _huongVao = 1;

  /// Đang xem lùi bao nhiêu ngày. 0 = hôm nay.
  ///
  /// Vuốt ngang **đổi thẳng nội dung thẻ**, không mở hộp thoại: chủ dự án nêu
  /// 30/08/2026 — *"vuốt ngang sang là quay về lịch sử chứ không phải vuốt qua
  /// rồi mới popup lên"*. Một cú vuốt mà kết quả là một lớp phủ mới thì vẫn là
  /// rời khỏi màn hình đang xem, chỉ khác cách mở.
  int _luiNgay = 0;

  /// Giới hạn lùi. Xa hơn nữa thì `watchInstancesForMember` trả rỗng và thẻ
  /// chỉ còn một khoảng trắng — vuốt mãi không tới đâu còn khó hiểu hơn là có
  /// điểm dừng.
  static const _luiToiDa = 30;

  void _vuot(double vanToc) {
    if (!laVuotNgangThatSu(quangDuong: _keoNgang, vanToc: vanToc)) return;
    // Vuốt sang **phải** (dx dương) = lùi về quá khứ, giống lật ngược một cuốn
    // sổ. Vuốt trái quay lại phía hôm nay.
    final moi = luiNgaySauVuot(
      hienTai: _luiNgay,
      quangDuong: _keoNgang,
      vanToc: vanToc,
      toiDa: _luiToiDa,
    );
    if (moi == _luiNgay) return;
    setState(() {
      _huongVao = moi > _luiNgay ? 1 : -1;
      _luiNgay = moi;
    });
  }

  /// Cho con làm lại một việc đã duyệt.
  ///
  /// Trước đây nằm trong mục "Đã xong hôm nay" gập lại ở cuối thẻ. Mục đó đi
  /// cùng bố cục cũ; giữ nó lại bên cạnh `NgayCuaCon` là hiện việc đã xong
  /// **hai lần** trên cùng một thẻ. Nên nút mở lại chuyển vào đúng hàng của
  /// việc đó.
  Future<void> _moLaiViec(TaskInstance luot) async {
    final ketQua = await widget.reviewService.reopen(
      instanceId: luot.id,
      reviewerId: widget.reviewerId,
    );
    if (!mounted) return;
    // Nói rõ đã trừ bao nhiêu. Xu biến mất mà không ai giải thích là đúng thứ
    // làm trẻ mất niềm tin vào app.
    hienThongBao(
      context,
      ketQua.xuDeducted > 0
          ? 'Đã mở lại việc. Trừ ${ketQua.xuDeducted} xu.'
          : 'Đã mở lại việc cho con làm lại.',
    );
  }

  /// Duyệt một việc con vừa báo xong, ngay trên hàng của nó.
  Future<void> _duyetViec(TaskInstance luot) async {
    await widget.reviewService.approve(
      instanceId: luot.id,
      reviewerId: widget.reviewerId,
    );
    if (mounted) hienThongBao(context, 'Đã duyệt.');
  }

  /// Trả lại một việc con báo xong **nhưng chưa xong**.
  ///
  /// Khác [_moLaiViec]: việc này chưa được duyệt nên **chưa có xu nào** để
  /// trừ. Nói rõ điều đó ra, vì "trả lại" và "làm lại" nghe giống nhau mà hậu
  /// quả về xu thì khác hẳn.
  Future<void> _traLaiViec(TaskInstance luot) async {
    await widget.reviewService.reject(
      instanceId: luot.id,
      reviewerId: widget.reviewerId,
    );
    if (mounted) {
      hienThongBao(context, 'Đã trả lại. Chưa cộng xu nên không trừ gì cả.');
    }
  }

  String _nhanNgay(CalendarDate ngay) => switch (_luiNgay) {
    0 => 'Hôm nay',
    1 => 'Hôm qua',
    _ => '$_luiNgay ngày trước · ${ngay.day}/${ngay.month}',
  };

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final taskDao = widget.taskDao;
    final walletDao = widget.walletDao;
    final color = AppColors.profileColor(child.colorIndex);

    final today =
        (ref.watch(familyClockProvider(child.familyId)).value ??
                fallbackFamilyClock())
            .today();
    final ngayXem = today.addDays(-_luiNgay);

    return Card(
      // Cử chỉ vuốt đặt ở **cả thẻ**, không chỉ ở dải chữ tên con.
      //
      // Bản trước gắn nó vào đúng cái `Expanded` bọc tên + dòng "x/y việc":
      // một dải cao chừng 40px. Bố mẹ vuốt ngang qua thân thẻ — nơi có danh
      // sách việc, tức gần như toàn bộ diện tích — thì không widget nào nhận
      // cú vuốt đó. Nhìn từ ngoài y hệt "vuốt không ăn".
      child: GestureDetector(
        // Kéo bắt đầu từ vùng đệm trắng cũng phải tính.
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => _keoNgang = 0,
        onHorizontalDragUpdate: (chiTiet) => _keoNgang += chiTiet.delta.dx,
        onHorizontalDragEnd: (chiTiet) => _vuot(chiTiet.primaryVelocity ?? 0),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Bấm avatar: chuyển hẳn sang màn hình của con
                  GestureDetector(
                    onTap: widget.onTapProfile,
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: AppIcon(
                        iconKeyForEmoji(avatarForKey(child.avatarKey)),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Bấm tên/header: gập hoặc mở danh sách việc của con.
                  // Trước đây cú bấm này mở luôn lịch sử; chủ dự án đổi ngày
                  // 30/08/2026 sau khi thấy thẻ của NEO dài 37 việc — màn hình
                  // nhiều con thì cuộn mãi không hết.
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _moRong = !_moRong),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                child.displayName,
                                style: context.text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              // Mũi tên là thứ duy nhất trên thẻ cho thấy nó
                              // bấm được. Bỏ nốt thì cú chạm gập/mở cũng thành
                              // cử chỉ vô hình y như cú vuốt.
                              Icon(
                                _moRong
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 20,
                                color: context.semantic.onSurfaceMuted,
                                semanticLabel: _moRong
                                    ? 'Thu gọn danh sách việc'
                                    : 'Mở danh sách việc',
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          StreamBuilder<List<TaskInstance>>(
                            stream: taskDao.watchInstancesForMember(
                              memberId: child.id,
                              date: ngayXem,
                            ),
                            builder: (context, snap) {
                              final instances = snap.data ?? [];
                              final done = instances
                                  .where(
                                    (i) =>
                                        i.status ==
                                            InstanceStatus.approved.name ||
                                        i.status ==
                                            InstanceStatus.pendingReview.name,
                                  )
                                  .length;
                              return Text(
                                '$done / ${instances.length} việc '
                                '${_luiNgay == 0 ? "hôm nay" : _nhanNgay(ngayXem).toLowerCase()}',
                                style: context.text.bodySmall?.copyWith(
                                  color: context.semantic.onSurfaceMuted,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  StreamBuilder<WalletBalance>(
                    stream: walletDao.watchBalance(child.id),
                    builder: (context, snap) {
                      final balance = snap.data ?? WalletBalance.zero;
                      return XuBadge(amount: balance.total);
                    },
                  ),
                ],
              ),
              if (_moRong) ...[
                if (_luiNgay > 0)
                  _ThanhNgayLui(
                    nhan: _nhanNgay(ngayXem),
                    onVeHomNay: () => setState(() => _luiNgay = 0),
                    onChiTiet: () => unawaited(
                      ChildHistoryModal.show(
                        context,
                        child: child,
                        taskDao: taskDao,
                        walletDao: walletDao,
                        initialDate: ngayXem,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                // Thân thẻ **chính là** màn lịch sử chi tiết — cùng một widget
                // `NgayCuaCon`, nên bố mẹ thấy đúng một bố cục ở cả hai chỗ
                // (chủ dự án chốt 30/08/2026).
                //
                // `AnimatedSwitcher` cho cú vuốt một hiệu ứng: ngày cũ trượt
                // ra, ngày mới trượt vào từ phía ngón tay vừa đi tới, kèm mờ
                // dần. Không có hoạt ảnh thì nội dung **nhảy** một cái — người
                // dùng không kịp thấy là mình vừa đi sang ngày khác hay app
                // vừa tải lại.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  // Đo theo widget mới, không phải cái to nhất: giữ kích thước
                  // của ngày nhiều việc trong lúc chuyển sang ngày ít việc để
                  // lại một khoảng trắng lớn dưới thẻ.
                  layoutBuilder: (hienTai, truoc) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...truoc, ?hienTai],
                  ),
                  transitionBuilder: (child, hoatAnh) {
                    final vaoTuPhai = child.key == ValueKey(_luiNgay)
                        ? _huongVao
                        : -_huongVao;
                    return FadeTransition(
                      opacity: hoatAnh,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          // 0.12 chứ không phải 1.0: đây là một cú **hé** sang
                          // ngày bên cạnh, không phải chuyển màn. Trượt trọn
                          // một bề ngang trong một cái thẻ trông giật cục.
                          begin: Offset(0.12 * vaoTuPhai, 0),
                          end: Offset.zero,
                        ).animate(hoatAnh),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_luiNgay),
                    child: NgayCuaCon(
                      memberId: child.id,
                      familyId: child.familyId,
                      date: ngayXem,
                      taskDao: taskDao,
                      onMoLai: _moLaiViec,
                      onDuyet: _duyetViec,
                      onTraLai: _traLaiViec,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Thanh nhỏ hiện khi thẻ đang xem một ngày trong quá khứ.
///
/// Có mặt vì cú vuốt là cử chỉ không nhìn thấy được: vuốt nhầm mà không có
/// dòng nào nói "đây là hôm qua" thì bố mẹ đọc số liệu cũ tưởng là hôm nay.
class _ThanhNgayLui extends StatelessWidget {
  const _ThanhNgayLui({
    required this.nhan,
    required this.onVeHomNay,
    required this.onChiTiet,
  });

  final String nhan;
  final VoidCallback onVeHomNay;

  /// Mở bảng lịch sử đầy đủ — nơi duy nhất có thống kê theo **tuần**. Vuốt
  /// ngang chỉ đi từng ngày một; bỏ hẳn đường này là mất luôn phần tuần.
  final VoidCallback onChiTiet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            size: 18,
            color: context.colors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              nhan,
              style: context.text.titleSmall?.copyWith(
                color: context.colors.primary,
              ),
            ),
          ),
          TextButton(onPressed: onChiTiet, child: const Text('Chi tiết')),
          // Vuốt ngược lại cũng về được, nhưng ai vuốt lỡ mười ngày thì phải
          // vuốt lại mười lần. Một nút là đủ.
          TextButton(onPressed: onVeHomNay, child: const Text('Về hôm nay')),
        ],
      ),
    );
  }
}

/// Câu thay cho khoảng trắng khi ngày đang xem không có việc nào.
///
/// Thẻ rỗng trơn thì không phân biệt được "hôm đó con không có việc" với "app
/// chưa tải xong".
