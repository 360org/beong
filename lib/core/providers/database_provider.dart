import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/reward_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/services/penalty_service.dart';
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
PenaltyService penaltyService(Ref ref) => PenaltyService(
  taskDao: ref.watch(taskDaoProvider),
  walletDao: ref.watch(walletDaoProvider),
  memberDao: ref.watch(memberDaoProvider),
);
