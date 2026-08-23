import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/data/local/badge_dao.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/goal_dao.dart';
import 'package:beong/data/local/jar_dao.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/reward_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/repositories/badge_repository.dart';
import 'package:beong/domain/repositories/goal_repository.dart';
import 'package:beong/domain/repositories/jar_repository.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/reward_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:beong/domain/services/day_start_service.dart';
import 'package:beong/domain/services/goal_service.dart';
import 'package:beong/domain/services/mat_khau_ho_so.dart';
import 'package:beong/domain/services/notification_service.dart';
import 'package:beong/domain/services/penalty_service.dart';
import 'package:beong/domain/services/redemption_service.dart';
import 'package:beong/domain/services/streak_service.dart';
import 'package:beong/domain/services/sync_engine.dart';
import 'package:beong/domain/services/task_review_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
}

@riverpod
TaskDao taskDao(Ref ref) => TaskDao(ref.watch(appDatabaseProvider));

@riverpod
WalletDao walletDao(Ref ref) => WalletDao(ref.watch(appDatabaseProvider));

@riverpod
RewardDao rewardDao(Ref ref) => RewardDao(ref.watch(appDatabaseProvider));

@riverpod
MemberDao memberDao(Ref ref) => MemberDao(ref.watch(appDatabaseProvider));

@riverpod
JarDao jarDao(Ref ref) => JarDao(ref.watch(appDatabaseProvider));

@riverpod
BadgeDao badgeDao(Ref ref) => BadgeDao(ref.watch(appDatabaseProvider));

@riverpod
GoalDao goalDao(Ref ref) => GoalDao(ref.watch(appDatabaseProvider));

// ---- Repository ----
//
// Tầng UI đọc ghi qua đây, **không** qua DAO. Vì sao: `lib/domain/repositories/README.md`.
// Sprint 3 chỉ cần đổi bảy dòng dưới đây sang bản có sync; `lib/features` không đổi.

@riverpod
TaskRepository taskRepository(Ref ref) =>
    LocalTaskRepository(ref.watch(taskDaoProvider));

@riverpod
WalletRepository walletRepository(Ref ref) =>
    LocalWalletRepository(ref.watch(walletDaoProvider));

@riverpod
RewardRepository rewardRepository(Ref ref) =>
    LocalRewardRepository(ref.watch(rewardDaoProvider));

@riverpod
MemberRepository memberRepository(Ref ref) =>
    LocalMemberRepository(ref.watch(memberDaoProvider));

@riverpod
JarRepository jarRepository(Ref ref) =>
    LocalJarRepository(ref.watch(jarDaoProvider));

@riverpod
BadgeRepository badgeRepository(Ref ref) =>
    LocalBadgeRepository(ref.watch(badgeDaoProvider));

@riverpod
GoalRepository goalRepository(Ref ref) =>
    LocalGoalRepository(ref.watch(goalDaoProvider));

@riverpod
GoalService goalService(Ref ref) => GoalService(
  goalDao: ref.watch(goalDaoProvider),
  walletDao: ref.watch(walletDaoProvider),
);

@riverpod
MatKhauHoSo matKhauHoSo(Ref ref) =>
    MatKhauHoSo(memberDao: ref.watch(memberDaoProvider));

@riverpod
PenaltyService penaltyService(Ref ref) => PenaltyService(
  taskDao: ref.watch(taskDaoProvider),
  walletDao: ref.watch(walletDaoProvider),
  memberDao: ref.watch(memberDaoProvider),
);

@riverpod
TaskReviewService taskReviewService(Ref ref) => TaskReviewService(
  taskDao: ref.watch(taskDaoProvider),
  walletDao: ref.watch(walletDaoProvider),
  memberDao: ref.watch(memberDaoProvider),
  penaltyService: ref.watch(penaltyServiceProvider),
  badgeDao: ref.watch(badgeDaoProvider),
);

@riverpod
RedemptionService redemptionService(Ref ref) => RedemptionService(
  rewardDao: ref.watch(rewardDaoProvider),
  walletDao: ref.watch(walletDaoProvider),
);

@riverpod
StreakService streakService(Ref ref) => StreakService(
  taskDao: ref.watch(taskDaoProvider),
  memberDao: ref.watch(memberDaoProvider),
);

@riverpod
DayStartService dayStartService(Ref ref) => DayStartService(
  taskDao: ref.watch(taskDaoProvider),
  memberDao: ref.watch(memberDaoProvider),
  settingsDao: ref.watch(settingsDaoProvider),
  penaltyService: ref.watch(penaltyServiceProvider),
  jarDao: ref.watch(jarDaoProvider),
  rewardDao: ref.watch(rewardDaoProvider),
  badgeDao: ref.watch(badgeDaoProvider),
  streakService: ref.watch(streakServiceProvider),
  goalService: ref.watch(goalServiceProvider),
);

@riverpod
SyncEngine syncEngine(Ref ref) => SyncEngine(
  db: ref.watch(appDatabaseProvider),
);

@riverpod
NotificationService notificationService(Ref ref) => NotificationService();
