/// Định nghĩa bảng cho DB local — `docs/03-data-model.md`.
///
/// Cùng một schema với Postgres trên Supabase, chỉ khác kiểu dữ liệu:
/// `uuid` → `TEXT`, `timestamptz` → `INTEGER` (epoch ms), `date` → `TEXT`
/// dạng `YYYY-MM-DD`.
///
/// Quy ước chung:
/// - Khoá chính là TEXT chứa UUID sinh ở client — cần cho offline-first,
///   không chờ server cấp id (ADR-002)
/// - Mọi bảng sửa được đều có `deletedAt` (soft delete) và `version` (LWW)
/// - Enum lưu bằng `name`, không lưu index — đổi thứ tự enum không phá dữ liệu
library;

import 'package:drift/drift.dart';

/// Cột dùng lại ở mọi bảng thuộc về một gia đình.
mixin FamilyScoped on Table {
  TextColumn get id => text()();
  TextColumn get familyId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Bảng sửa được: thêm soft delete và version cho Last-Write-Wins.
mixin Syncable on Table {
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
}

class Families extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Tên múi giờ IANA, vd `Asia/Ho_Chi_Minh`.
  TextColumn get timezone => text().withDefault(const Constant('UTC'))();

  /// Giờ bắt đầu ngày mới — ADR-008.
  IntColumn get dayRolloverHour => integer().withDefault(const Constant(4))();

  /// Bao nhiêu xu bằng một đơn vị tiền. NULL = tắt quy đổi (ADR-017).
  IntColumn get exchangeRateXu => integer().nullable()();
  TextColumn get currency => text().withDefault(const Constant('VND'))();

  /// Tỷ lệ ba hũ dạng JSON `{"spend":50,"save":40,"give":10}` — ADR-016.
  TextColumn get jarSplit =>
      text().withDefault(const Constant('{"spend":50,"save":40,"give":10}'))();

  /// Phần trăm điểm bị trừ khi hết ngày mà việc chưa làm — ADR-022.
  /// 0 = tắt, và đây là **mặc định** của mọi gia đình mới.
  IntColumn get missedPenaltyPct => integer().withDefault(const Constant(0))();

  /// Phần trăm điểm bị trừ mỗi lần bố mẹ mở lại việc con bấm xong nhưng chưa
  /// làm — ADR-022. 0 = tắt.
  IntColumn get reopenPenaltyPct => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Hồ sơ hiển thị — cả bố mẹ lẫn trẻ. Trẻ **không** có tài khoản đăng nhập
/// (ADR-006): `userId` để NULL.
class Members extends Table with FamilyScoped, Syncable {
  TextColumn get userId => text().nullable()();

  /// `parent` hoặc `child` — `MemberKind`.
  TextColumn get kind => text()();
  TextColumn get displayName => text().withLength(min: 1, max: 40)();

  /// Khoá avatar dựng sẵn hoặc đường dẫn ảnh.
  TextColumn get avatarKey => text().nullable()();

  /// Chỉ số trong `AppColors.profilePalette`.
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  IntColumn get birthYear => integer().nullable()();

  /// Hash Argon2 của PIN. Chỉ lưu local, không đồng bộ lên server.
  TextColumn get pinHash => text().nullable()();

  /// Tỷ lệ chia riêng của trẻ lớn; NULL = theo gia đình.
  TextColumn get jarSplitOverride => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Routine là thực thể bậc nhất, sở hữu lịch và danh sách người — ADR-011.
class Routines extends Table with FamilyScoped, Syncable {
  TextColumn get title => text().withLength(min: 1, max: 60)();
  TextColumn get iconKey => text().nullable()();

  /// `DayPart` hoặc NULL.
  TextColumn get dayPart => text().nullable()();

  /// Giờ bắt đầu dạng `HH:mm`, dùng để nhắc.
  TextColumn get startTime => text().nullable()();

  /// `RepeatType` — routine không dùng `once`.
  TextColumn get repeatType => text().withDefault(const Constant('daily'))();

  /// Các thứ trong tuần, dạng `1,3,5`. Rỗng khi không phải `custom`.
  TextColumn get repeatDays => text().withDefault(const Constant(''))();

  /// Xu thưởng khi làm trọn bộ trong ngày. 0 = tắt.
  IntColumn get completionBonus => integer().withDefault(const Constant(10))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RoutineAssignees extends Table {
  TextColumn get routineId => text()();
  TextColumn get memberId => text()();

  @override
  Set<Column<Object>> get primaryKey => {routineId, memberId};
}

class Tasks extends Table with FamilyScoped, Syncable {
  TextColumn get title => text().withLength(min: 1, max: 60)();
  TextColumn get iconKey => text().nullable()();
  TextColumn get presetKey => text().nullable()();
  IntColumn get points => integer().withDefault(const Constant(10))();

  /// Không NULL nghĩa là task thuộc routine: lịch và người giao lấy theo
  /// routine, các cột lịch bên dưới bị bỏ qua (ADR-011).
  TextColumn get routineId => text().nullable()();
  IntColumn get orderIndex => integer().nullable()();

  TextColumn get repeatType => text().withDefault(const Constant('daily'))();
  TextColumn get repeatDays => text().withDefault(const Constant(''))();

  /// Ngày dạng `YYYY-MM-DD`, chỉ dùng khi `repeatType = once`.
  TextColumn get onceDate => text().nullable()();
  TextColumn get dayPart => text().nullable()();

  /// Mốc nhắc nhở dạng `HH:mm`.
  TextColumn get dueTime => text().nullable()();

  /// `ApprovalMode`. Mặc định `manual` — ADR-009.
  TextColumn get approvalMode => text().withDefault(const Constant('manual'))();
  TextColumn get proofMode => text().withDefault(const Constant('none'))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get createdBy => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TaskAssignees extends Table {
  TextColumn get taskId => text()();
  TextColumn get memberId => text()();

  @override
  Set<Column<Object>> get primaryKey => {taskId, memberId};
}

/// Một lượt việc: task × trẻ × ngày.
class TaskInstances extends Table with FamilyScoped {
  TextColumn get taskId => text()();
  TextColumn get memberId => text()();

  /// `YYYY-MM-DD` theo ngày của gia đình (ADR-008).
  TextColumn get dueDate => text()();

  /// `InstanceStatus`.
  TextColumn get status => text().withDefault(const Constant('scheduled'))();

  /// Xu chốt lúc sinh lượt — ADR-007.
  IntColumn get pointsSnapshot => integer()();

  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  TextColumn get reviewedBy => text().nullable()();
  TextColumn get proofUrl => text().nullable()();
  TextColumn get proofNote => text().nullable()();

  /// Số lần bố mẹ mở lại lượt này — ADR-022. Mỗi lần mở lại là một khoản trừ,
  /// nên phải đếm chứ không chỉ ghi cờ boolean.
  IntColumn get reopenCount => integer().withDefault(const Constant(0))();

  /// Lúc đã áp khoản trừ "bỏ việc" cho lượt này. NULL = chưa áp.
  ///
  /// Có cột này thì bộ chạy cuối ngày chỉ cần quét những lượt chưa xử lý, thay
  /// vì quét lại toàn bộ lịch sử mỗi lần mở app.
  DateTimeColumn get missedPenaltyAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  /// Chặn sinh trùng khi nhiều thiết bị cùng chạy bộ lập lịch.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {taskId, memberId, dueDate},
  ];
}

/// Sổ cái xu — append-only. Không bao giờ UPDATE hay DELETE (ADR-005).
///
/// Số dư mỗi hũ là tổng `delta` của hũ đó. Sửa sai bằng cách ghi một dòng bù,
/// không sửa dòng cũ — đó là điều làm nên giá trị "minh bạch".
class PointTransactions extends Table with FamilyScoped {
  TextColumn get memberId => text()();

  /// `Jar` — mỗi dòng thuộc đúng một hũ (ADR-016).
  TextColumn get jar => text()();

  /// Số xu, dương hoặc âm.
  IntColumn get delta => integer()();

  /// `TxReason`.
  TextColumn get reason => text()();
  TextColumn get refType => text().nullable()();
  TextColumn get refId => text().nullable()();

  /// Bắt buộc khi `reason = manualAdjust` — bố mẹ sửa xu phải nói lý do, và
  /// lý do đó hiện cho trẻ thấy. Ràng buộc được áp ở tầng repository.
  TextColumn get note => text().nullable()();
  TextColumn get createdBy => text().nullable()();

  /// Idempotency: gửi lại cùng một thao tác không nhân đôi xu.
  TextColumn get clientOpId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {clientOpId},
  ];
}

class Rewards extends Table with FamilyScoped, Syncable {
  TextColumn get title => text().withLength(min: 1, max: 60)();
  TextColumn get iconKey => text().nullable()();

  /// `RewardType`.
  TextColumn get rewardType => text().withDefault(const Constant('custom'))();
  IntColumn get costPoints => integer()();

  /// Trường riêng theo loại, dạng JSON: `{"minutes":30}` hoặc `{"amount":20000}`.
  TextColumn get metaJson => text().nullable()();

  /// NULL = không giới hạn.
  IntColumn get stock => integer().nullable()();
  BoolColumn get requiresApproval =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Redemptions extends Table with FamilyScoped {
  TextColumn get rewardId => text()();
  TextColumn get memberId => text()();

  /// Chốt giá lúc đổi, cùng lý do với `pointsSnapshot` (ADR-007).
  IntColumn get costSnapshot => integer()();
  TextColumn get metaSnapshot => text().nullable()();

  /// `RedemptionStatus`.
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get resolvedBy => text().nullable()();

  /// Trẻ bấm "đã dùng" trên phiếu.
  DateTimeColumn get usedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SavingsGoals extends Table with FamilyScoped {
  TextColumn get memberId => text()();
  TextColumn get title => text().withLength(min: 1, max: 60)();
  TextColumn get imagePath => text().nullable()();
  IntColumn get targetXu => integer()();

  /// `GoalStatus`.
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get reachedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Cache streak — tính lại được từ `task_instances`, chỉ để không quét lịch sử
/// mỗi lần mở app.
class Streaks extends Table {
  TextColumn get memberId => text()();
  IntColumn get currentLen => integer().withDefault(const Constant(0))();
  IntColumn get bestLen => integer().withDefault(const Constant(0))();
  TextColumn get lastQualifiedDate => text().nullable()();
  TextColumn get graceUsedMonth => text().nullable()();
  IntColumn get graceCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {memberId};
}

class BadgesEarned extends Table with FamilyScoped {
  TextColumn get memberId => text()();
  TextColumn get badgeKey => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {memberId, badgeKey},
  ];
}

/// Hàng đợi đẩy lên server. Chỉ tồn tại ở local, không đồng bộ.
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get op => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get clientOpId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

/// Cấu hình của **thiết bị này**, dạng khoá–giá trị. Chỉ ở local, không đồng bộ.
///
/// Dùng cho những thứ thuộc về cái máy đang cầm chứ không thuộc về gia đình:
/// đang mở hồ sơ nào, vai đã chọn. Cấu hình gia đình thì nằm ở tài khoản bố mẹ
/// (ADR-021), không ở đây.
///
/// **Không** đặt bí mật vào bảng này. Token ghép cặp phải nằm ở Keychain /
/// Keystore (`09-onboarding-pairing.md` §4), vì file SQLite đọc được trên máy
/// đã root hoặc qua bản sao lưu.
class DeviceSettings extends Table {
  TextColumn get settingKey => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column<Object>> get primaryKey => {settingKey};
}
