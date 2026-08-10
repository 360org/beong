import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/jar_dao.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/reward_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/services/day_start_service.dart';
import 'package:beong/domain/services/penalty_service.dart';
import 'package:beong/domain/services/redemption_service.dart';
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
);

@riverpod
RedemptionService redemptionService(Ref ref) => RedemptionService(
  rewardDao: ref.watch(rewardDaoProvider),
  walletDao: ref.watch(walletDaoProvider),
);

@riverpod
DayStartService dayStartService(Ref ref) => DayStartService(
  taskDao: ref.watch(taskDaoProvider),
  memberDao: ref.watch(memberDaoProvider),
  settingsDao: ref.watch(settingsDaoProvider),
  penaltyService: ref.watch(penaltyServiceProvider),
  jarDao: ref.watch(jarDaoProvider),
  rewardDao: ref.watch(rewardDaoProvider),
);
