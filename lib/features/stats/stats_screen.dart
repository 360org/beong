import 'dart:async';

import 'package:beong/app/router.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/utils/ngay_viet.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/reward_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/badge_def.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/features/goals/goal_section.dart';
import 'package:beong/features/goals/goal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberDaoProvider);
    final walletDao = ref.watch(walletDaoProvider);
    final taskDao = ref.watch(taskDaoProvider);
    final rewardDao = ref.watch(rewardDaoProvider);

    if (session.isParent) {
      return _ParentStats(
        session: session,
        memberDao: memberDao,
        walletDao: walletDao,
      );
    }

    return _ChildStats(
      memberId: session.activeMemberId,
      familyId: session.familyId,
      walletDao: walletDao,
      memberDao: memberDao,
      taskDao: taskDao,
      rewardDao: rewardDao,
    );
  }
}

class _ParentStats extends StatelessWidget {
  const _ParentStats({
    required this.session,
    required this.memberDao,
    required this.walletDao,
  });

  final AppSession session;
  final MemberDao memberDao;
  final WalletDao walletDao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê', style: context.text.titleLarge),
      ),
      body: StreamBuilder<List<Member>>(
        stream: memberDao.watchMembers(session.familyId),
        builder: (context, snap) {
          final members = snap.data ?? [];
          final children = members
              .where((m) => m.kind == MemberKind.child.name)
              .toList();

          if (children.isEmpty) {
            return Center(
              child: Text(
                'Chưa có bé nào.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: children.map((child) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: _ChildStatsCard(
                  child: child,
                  walletDao: walletDao,
                  memberDao: memberDao,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ChildStatsCard extends ConsumerWidget {
  const _ChildStatsCard({
    required this.child,
    required this.walletDao,
    required this.memberDao,
  });

  final Member child;
  final WalletDao walletDao;
  final MemberDao memberDao;

  Future<void> _editGoal(BuildContext context, WidgetRef ref) async {
    final current = await ref.read(goalDaoProvider).activeGoal(child.id);
    if (!context.mounted) return;
    await showGoalSheet(
      context,
      familyId: child.familyId,
      memberId: child.id,
      childName: child.displayName,
      current: current,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(child.displayName, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<WalletBalance>(
          stream: walletDao.watchBalance(child.id),
          builder: (context, snap) {
            final balance = snap.data ?? WalletBalance.zero;
            return _JarOverview(
              balance: balance,
              familyId: child.familyId,
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<Streak?>(
          stream: memberDao.watchStreak(child.id),
          builder: (context, snap) {
            final streak = snap.data;
            if (streak == null) return const SizedBox.shrink();
            return _StreakCard(streak: streak);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        GoalSection(
          memberId: child.id,
          onTap: () => unawaited(_editGoal(context, ref)),
        ),
        // Nút riêng khi chưa có mục tiêu: [GoalSection] cố ý không hiện gì lúc
        // đó, nên không có chỗ nào bấm vào để đặt mục tiêu đầu tiên.
        StreamBuilder<SavingsGoal?>(
          stream: ref.watch(goalDaoProvider).watchActiveGoal(child.id),
          builder: (context, snap) {
            if (snap.data != null) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => unawaited(_editGoal(context, ref)),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Đặt mục tiêu để dành'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ChildStats extends StatelessWidget {
  const _ChildStats({
    required this.memberId,
    required this.familyId,
    required this.walletDao,
    required this.memberDao,
    required this.taskDao,
    required this.rewardDao,
  });

  final String memberId;
  final String familyId;
  final WalletDao walletDao;
  final MemberDao memberDao;
  final TaskDao taskDao;
  final RewardDao rewardDao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sổ của con', style: context.text.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingMobile,
          vertical: AppSpacing.lg,
        ),
        children: [
          StreamBuilder<WalletBalance>(
            stream: walletDao.watchBalance(memberId),
            builder: (context, snap) {
              final balance = snap.data ?? WalletBalance.zero;
              return _JarOverview(balance: balance, familyId: familyId);
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          StreamBuilder<Streak?>(
            stream: memberDao.watchStreak(memberId),
            builder: (context, snap) {
              final streak = snap.data;
              if (streak == null) return const SizedBox.shrink();
              return _StreakCard(streak: streak);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // Không truyền `onTap`: con xem được tiến độ nhưng không tự đổi mục
          // tiêu. Đổi mục tiêu mỗi khi thấy còn xa là đúng cái thói quen tính
          // năng này muốn dạy ngược lại.
          GoalSection(memberId: memberId),
          const SizedBox(height: AppSpacing.xl),
          _BadgesEntry(memberId: memberId),
          const SizedBox(height: AppSpacing.xxl),
          Text('Lịch sử', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          // Tên hũ tra từ bảng `jars`: sổ cái chỉ lưu `jar_key`, nên không có
          // bảng tra thì dòng chia xu hiện ra khoá thô kiểu
          // "jar1786289533739171 14" — con đọc không hiểu gì.
          _JarTitles(
            familyId: familyId,
            builder: (context, jarTitles) => StreamBuilder<List<LedgerEntry>>(
              // Đã gộp: một việc là **một** mục, không phải ba dòng theo hũ.
              stream: walletDao.watchGroupedHistory(memberId),
              builder: (context, snap) {
                final txns = snap.data ?? [];
                if (txns.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Center(
                      child: Text(
                        'Chưa có giao dịch nào.',
                        style: context.text.bodyMedium?.copyWith(
                          color: context.semantic.onSurfaceMuted,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final tx in txns)
                      _TransactionTile(
                        // Key theo nhóm: thiếu key thì State bị tái dùng theo vị
                        // trí và dòng hiện tên của giao dịch cũ.
                        key: ValueKey(tx.groupId),
                        tx: tx,
                        taskDao: taskDao,
                        rewardDao: rewardDao,
                        jarTitles: jarTitles,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Lối vào bảng huy hiệu, kèm số đã đạt.
///
/// Đặt ngay trên "Lịch sử" chứ không giấu trong Cài đặt: huy hiệu là phần thưởng
/// tinh thần, phải nằm ở chỗ con hay nhìn.
class _BadgesEntry extends ConsumerWidget {
  const _BadgesEntry({required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Set<String>>(
      stream: ref.watch(badgeDaoProvider).watchEarnedKeys(memberId),
      builder: (context, snap) {
        final earned = snap.data?.length ?? 0;
        return Card(
          child: InkWell(
            onTap: () => context.go(Routes.badges),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const AppIcon('star', size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Huy hiệu · $earned/${kBadges.length}',
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
        );
      },
    );
  }
}

/// Bảng tra `jar_key` -> tên hũ, đọc từ bảng `jars`.
class _JarTitles extends ConsumerWidget {
  const _JarTitles({required this.familyId, required this.builder});

  final String familyId;
  final Widget Function(BuildContext, Map<String, String>) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<JarDef>>(
      // Lấy **cả hũ đã xếp lại**: sổ cái vẫn còn dòng của chúng, và một hũ xếp
      // lại rồi vẫn phải đọc được tên trong lịch sử.
      stream: ref
          .watch(jarDaoProvider)
          .watchAllJars(familyId)
          .map((rows) => [for (final r in rows) r.jar]),
      builder: (context, snap) => builder(context, {
        for (final jar in snap.data ?? kDefaultJars) jar.key: jar.title,
      }),
    );
  }
}

/// Số dư từng hũ của gia đình.
///
/// Đọc danh sách hũ từ bảng `jars` chứ không dựng cứng ba ô: bản trước hiện đúng
/// Tiêu / Để dành / Cho đi, nên hũ do bố mẹ tự lập **không có ô nào** và xu trong
/// đó mất khỏi màn hình. Con cộng ba ô lại thấy 11 trong khi tổng ghi 25 — không
/// có cách nào hiểu được chuyện gì xảy ra.
class _JarOverview extends ConsumerWidget {
  const _JarOverview({required this.balance, required this.familyId});

  final WalletBalance balance;
  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<JarDef>>(
      stream: ref.watch(jarDaoProvider).watchActiveJars(familyId),
      builder: (context, snap) {
        final jars = snap.data ?? kDefaultJars;

        // Hũ chờ không nằm trong bảng `jars` nhưng vẫn phải hiện khi còn xu:
        // không hiện thì con thấy tổng lớn hơn tổng các ô mà không biết vì sao.
        final tiles = <Widget>[
          for (final jar in jars)
            _JarCard(
              label: jar.title,
              iconKey: iconKeyForEmoji(jar.emoji),
              amount: balance.ofKey(jar.key),
            ),
          if (balance.inbox > 0)
            _JarCard(
              label: 'Chờ chia',
              iconKey: 'jar_inbox',
              amount: balance.inbox,
            ),
        ];

        // Wrap chứ không Row: bốn hũ trở lên thì Row bóp mỗi ô còn quá hẹp để
        // đọc số.
        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppSpacing.sm;
            final perRow = tiles.length <= 3 ? tiles.length : 3;
            final width = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final tile in tiles) SizedBox(width: width, child: tile),
              ],
            );
          },
        );
      },
    );
  }
}

class _JarCard extends StatelessWidget {
  const _JarCard({
    required this.label,
    required this.amount,
    required this.iconKey,
  });

  final String label;
  final int amount;

  /// Khoá icon của hũ, suy từ emoji bố mẹ đã chọn. Thay cho bộ icon cứng ba hũ
  /// trước đây — hũ tự lập không có icon nào trong bộ đó.
  final String iconKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            AppIcon(iconKey, size: 26),
            const SizedBox(height: AppSpacing.sm),
            XuBadge(amount: amount),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
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

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: context.semantic.warning,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${streak.currentLen} ngày liên tiếp',
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Kỷ lục: ${streak.bestLen} ngày',
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Một mục trong Sổ của con.
///
/// Hiện **tên việc / tên phần thưởng** chứ không chỉ "Hoàn thành việc": trước
/// đây mọi dòng đều mang cùng một chữ, nên sổ chín việc trông như chín dòng
/// giống hệt nhau và trẻ không tra được xu đến từ đâu.
class _TransactionTile extends StatefulWidget {
  const _TransactionTile({
    required this.tx,
    required this.taskDao,
    required this.rewardDao,
    required this.jarTitles,
    super.key,
  });

  final LedgerEntry tx;
  final TaskDao taskDao;
  final RewardDao rewardDao;

  /// `jar_key` -> tên hũ do bố mẹ đặt.
  final Map<String, String> jarTitles;

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

/// Trạng thái của mục lịch sử, để cột bên trái nói được điều gì.
@immutable
class _EntryStatus {
  const _EntryStatus(this.label, this.icon, this.tone);

  final String label;
  final IconData icon;

  /// Sắc thái: `ok` xanh, `wait` cam, `bad` đỏ, `neutral` xám.
  final String tone;
}

class _TransactionTileState extends State<_TransactionTile> {
  String? _subject;

  /// Tạo **một lần**, không tạo trong `build`.
  ///
  /// `StreamBuilder` nhận stream mới là huỷ đăng ký cũ rồi đăng ký lại; gọi
  /// `_statusStream()` trong `build` nghĩa là mỗi lần dựng lại chạy lại truy vấn
  /// drift và nháy về trạng thái rỗng một khung hình.
  late Stream<_EntryStatus?> _status = _statusStream();

  @override
  void initState() {
    super.initState();
    unawaited(_loadSubject());
  }

  @override
  void didUpdateWidget(_TransactionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tx.refId == widget.tx.refId) return;
    unawaited(_loadSubject());
    setState(() => _status = _statusStream());
  }

  /// Trạng thái đọc từ **thực thể gốc**, không đoán từ lý do giao dịch.
  ///
  /// Một dòng `rewardRedeemed` không nói được phiếu đó đã được duyệt hay chưa —
  /// chỉ bảng `redemptions` biết. Đó là lý do phải tra ngược, và cũng là lý do
  /// dòng lịch sử phải giữ `ref_type` / `ref_id`.
  _EntryStatus? _statusOf(String? instanceStatus, String? redemptionStatus) {
    if (instanceStatus != null) {
      return switch (instanceStatus) {
        'approved' => const _EntryStatus('Đã xong', Icons.check_circle, 'ok'),
        'pendingReview' => const _EntryStatus(
          'Chờ duyệt',
          Icons.hourglass_bottom_rounded,
          'wait',
        ),
        // Lượt đã bị bố mẹ mở lại: xu vẫn còn nhưng việc phải làm lại (ADR-022).
        'scheduled' => const _EntryStatus(
          'Phải làm lại',
          Icons.replay_rounded,
          'wait',
        ),
        'missed' => const _EntryStatus(
          'Bỏ lỡ',
          Icons.remove_circle_outline,
          'bad',
        ),
        'rejected' => const _EntryStatus(
          'Bị từ chối',
          Icons.close_rounded,
          'bad',
        ),
        _ => null,
      };
    }

    if (redemptionStatus != null) {
      return switch (redemptionStatus) {
        'pending' => const _EntryStatus(
          'Chờ bố mẹ duyệt',
          Icons.hourglass_bottom_rounded,
          'wait',
        ),
        'fulfilled' => const _EntryStatus(
          'Dùng được',
          Icons.check_circle,
          'ok',
        ),
        'used' => const _EntryStatus(
          'Đã dùng',
          Icons.task_alt_rounded,
          'neutral',
        ),
        'rejected' => const _EntryStatus(
          'Bị từ chối',
          Icons.close_rounded,
          'bad',
        ),
        _ => null,
      };
    }

    return null;
  }

  /// Tra tên của thứ giao dịch này nói về.
  ///
  /// Không tra được thì để `null` và chỉ hiện nhãn theo lý do — dữ liệu cũ hoặc
  /// việc đã bị xoá không được làm dòng lịch sử biến mất.
  /// Tên thì tra một lần (không đổi), còn **trạng thái phải theo dõi**.
  ///
  /// Bố mẹ duyệt hoặc mở lại không ghi dòng sổ cái nào, nên stream lịch sử
  /// không phát lại và widget không dựng lại. Tra một lần là cách chắc chắn để
  /// dòng "Chờ bố mẹ duyệt" đứng nguyên sau khi phiếu đã bị từ chối — đúng lỗi
  /// đã gặp.
  Stream<_EntryStatus?> _statusStream() {
    final tx = widget.tx;
    final refId = tx.refId;
    if (refId == null) return Stream.value(null);

    switch (tx.refType) {
      case 'task_instance':
        return widget.taskDao
            .watchInstance(refId)
            .map((i) => _statusOf(i?.status, null));
      case 'reward':
        // Dòng trừ xu khi đổi thưởng trỏ vào `reward`, nhưng trạng thái nằm ở
        // phiếu — mà phiếu dùng chính `client_op_id` làm id, tức `groupId`.
        return widget.rewardDao
            .watchRedemption(tx.groupId)
            .map((r) => _statusOf(null, r?.status));
      case 'redemption':
        return widget.rewardDao
            .watchRedemption(refId)
            .map((r) => _statusOf(null, r?.status));
      default:
        return Stream.value(null);
    }
  }

  Future<void> _loadSubject() async {
    final tx = widget.tx;
    final refId = tx.refId;
    if (refId == null) return;

    String? name;
    switch (tx.refType) {
      case 'task_instance':
        final instance = await widget.taskDao.getInstanceById(refId);
        if (instance != null) {
          name = (await widget.taskDao.getTaskById(instance.taskId)).title;
        }
      case 'reward':
        name = (await widget.rewardDao.getReward(refId))?.title;
      case 'redemption':
        final redemption = await widget.rewardDao.getRedemption(refId);
        if (redemption != null) {
          name = (await widget.rewardDao.getReward(redemption.rewardId))?.title;
        }
      default:
        name = null;
    }

    if (mounted && name != null) setState(() => _subject = name);
  }

  Color _toneColor(BuildContext context, String tone) => switch (tone) {
    'ok' => context.semantic.success,
    'wait' => context.semantic.warning,
    'bad' => context.semantic.danger,
    _ => context.semantic.onSurfaceMuted,
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<_EntryStatus?>(
      stream: _status,
      builder: (context, snap) => _buildRow(context, snap.data),
    );
  }

  Widget _buildRow(BuildContext context, _EntryStatus? status) {
    final tx = widget.tx;
    final isPositive = tx.delta > 0;
    final subject = _subject;
    // Ghép trước để biết dòng phụ có nội dung hay không: dòng phụ rỗng vẫn
    // chiếm chỗ và làm các thẻ cao thấp không đều.
    final subtitle = [
      // Mốc thời gian đứng đầu dòng phụ: một quyển sổ không có ngày thì không tra
      // được "hôm qua con được bao nhiêu". Ghi `10/08 14:05` chứ không ghi cả năm
      // — gần như mọi dòng đều của năm nay, thêm năm chỉ chiếm chỗ.
      ngayGio(tx.createdAt),
      if (status == null && subject != null) _reasonLabel(tx.reason),
      if (tx.note != null) tx.note!,
      if (tx.byJar.length > 1)
        _jarBreakdown(
          tx.byJar,
          // Lần chia xu có hai chân bù nhau; hiện cả hai thành
          // "Tiêu 5, Chờ chia 5" làm người đọc tưởng có 10 xu.
          onlyPositive: tx.reason == 'jarTransfer',
        ),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Cột trạng thái: icon + màu nói ngay việc/phiếu này đang thế
              // nào. Trước đây cột này chỉ nhắc lại lý do giao dịch, tức là
              // lặp lại thông tin đã có ở dòng chữ bên cạnh.
              Icon(
                status?.icon ?? _reasonIcon(tx.reason),
                color: status == null
                    ? context.semantic.onSurfaceMuted
                    : _toneColor(context, status.tone),
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject ?? _reasonLabel(tx.reason),
                      style: context.text.bodyMedium,
                    ),
                    if (subtitle.isNotEmpty || status != null)
                      Text.rich(
                        // Trạng thái trước, rồi lý do và chi tiết hũ. Trạng thái
                        // tô màu **và** có chữ: icon 22px một mình không đủ, và
                        // màu một mình cũng không đủ (WCAG 1.4.1 — không dùng
                        // màu hay hình làm phương tiện truyền đạt duy nhất).
                        TextSpan(
                          children: [
                            if (status != null)
                              TextSpan(
                                text: status.label,
                                style: context.text.bodySmall?.copyWith(
                                  color: _toneColor(context, status.tone),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (subtitle.isNotEmpty)
                              TextSpan(
                                text: status == null
                                    ? subtitle
                                    : ' · $subtitle',
                              ),
                          ],
                        ),
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                // Chuyển hũ có delta 0: không cộng cũng không mất, nên không
                // dùng màu xanh hay đỏ — tô đỏ số 0 làm con tưởng bị trừ.
                switch (tx.delta) {
                  0 => '↔',
                  final d when d > 0 => '+$d',
                  final d => '$d',
                },
                style: context.text.titleSmall?.copyWith(
                  color: tx.delta == 0
                      ? context.semantic.onSurfaceMuted
                      : isPositive
                      ? context.semantic.success
                      : context.semantic.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Tiêu 5, Để dành 4, Cho đi 1" — gọn, không cần mở thêm.
  ///
  /// Thứ tự **cố định**, không theo thứ tự dòng trả về từ DB: thứ tự đổi giữa
  /// các mục làm sổ trông như dữ liệu lộn xộn, dù số vẫn đúng.
  String _jarBreakdown(Map<String, int> byJar, {bool onlyPositive = false}) {
    const order = ['spend', 'save', 'give'];
    final keys = [
      ...order.where(byJar.containsKey),
      // Hũ do bố mẹ tự lập (ADR-024) xếp sau, theo thứ tự chữ cái cho ổn định.
      ...byJar.keys.where((k) => !order.contains(k)).toList()..sort(),
    ];

    final parts = <String>[];
    for (final key in keys) {
      final value = byJar[key] ?? 0;
      if (value == 0) continue;
      // Với lần chia xu, chân trừ ở hũ chờ chỉ là mặt sau của chân cộng — hiện
      // cả hai thành "Tiêu 5, Chờ chia 5" làm người đọc tưởng có 10 xu.
      if (onlyPositive && value < 0) continue;
      parts.add('${_jarLabel(key)} ${value.abs()}');
    }
    return parts.join(', ');
  }

  /// Tên hũ để hiện trong sổ.
  ///
  /// Ưu tiên tên bố mẹ đặt trong bảng `jars`; ba hũ dựng sẵn có tên cố định để
  /// dòng cũ vẫn đọc được kể cả khi hũ đã bị xếp lại và đổi tên.
  String _jarLabel(String jarKey) {
    final title = widget.jarTitles[jarKey];
    if (title != null && title.isNotEmpty) return title;
    return switch (jarKey) {
      kJarSpend => 'Tiêu',
      kJarSave => 'Để dành',
      kJarGive => 'Cho đi',
      kJarInbox => 'Chờ chia',
      // Hũ đã bị xoá khỏi bảng bằng tay: thà hiện khoá còn hơn hiện chuỗi rỗng.
      _ => jarKey,
    };
  }

  IconData _reasonIcon(String reason) => switch (reason) {
    'taskApproved' => Icons.check_circle_outline,
    'routineBonus' => Icons.stars_rounded,
    'streakBonus' => Icons.local_fire_department,
    'rewardRedeemed' => Icons.card_giftcard,
    'rewardRefund' => Icons.replay,
    'manualAdjust' => Icons.edit,
    'bonus' => Icons.add_circle_outline,
    'penalty' => Icons.remove_circle_outline,
    'jarTransfer' => Icons.pie_chart_outline_rounded,
    _ => Icons.receipt_long,
  };

  String _reasonLabel(String reason) => switch (reason) {
    'taskApproved' => 'Hoàn thành việc',
    'routineBonus' => 'Thưởng trọn bộ',
    'streakBonus' => 'Thưởng liên tiếp',
    'rewardRedeemed' => 'Đổi thưởng',
    'rewardRefund' => 'Hoàn xu',
    'manualAdjust' => 'Điều chỉnh',
    'bonus' => 'Thưởng thêm',
    'penalty' => 'Trừ xu',
    'jarTransfer' => 'Con chia xu vào hũ',
    _ => reason,
  };
}
