import 'package:beong/data/local/badge_dao.dart';
import 'package:beong/data/local/jar_dao.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/reward_dao.dart';
import 'package:beong/data/local/settings_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/services/don_viec_le.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/goal_service.dart';
import 'package:beong/domain/services/penalty_service.dart';
import 'package:beong/domain/services/streak_service.dart';

/// Việc phải chạy mỗi khi bắt đầu một ngày mới của gia đình.
///
/// `03-data-model.md` §3 tả bộ sinh `task_instances` chạy "khi mở app, đổi ngày,
/// sửa task". Thực tế `generateInstances` chỉ được gọi từ **một** chỗ: nút "Tạo
/// việc hôm nay" trên màn hình con. Hệ quả thấy được ngay:
///
/// - Bố mẹ tạo routine trong onboarding rồi mở Trang chính → thấy
///   "0 / 0 việc hôm nay", tưởng routine chưa lưu.
/// - Không ai bấm nút đó thì **không có việc nào** xuất hiện, mãi mãi.
/// - Sang ngày mới không có gì tự chạy: lượt việc quá hạn không được đánh dấu
///   bỏ lỡ, nên khoản trừ cuối ngày (ADR-022) cũng không bao giờ áp.
///
/// Lớp này đóng khoảng lệch đó.
class DayStartService {
  const DayStartService({
    required TaskDao taskDao,
    required MemberDao memberDao,
    required SettingsDao settingsDao,
    required PenaltyService penaltyService,
    required JarDao jarDao,
    required RewardDao rewardDao,
    required BadgeDao badgeDao,
    required StreakService streakService,
    required GoalService goalService,
  }) : _tasks = taskDao,
       _members = memberDao,
       _settings = settingsDao,
       _penalties = penaltyService,
       _jars = jarDao,
       _rewards = rewardDao,
       _badges = badgeDao,
       _streaks = streakService,
       _goals = goalService;

  final TaskDao _tasks;
  final MemberDao _members;
  final SettingsDao _settings;
  final PenaltyService _penalties;
  final JarDao _jars;
  final RewardDao _rewards;
  final BadgeDao _badges;
  final GoalService _goals;
  final StreakService _streaks;

  /// Khoá ghi ngày đã chạy gần nhất, theo thiết bị.
  static const _lastRunKey = 'rollover.last_run_date';

  /// Chạy nếu hôm nay chưa chạy.
  ///
  /// Gọi được nhiều lần vô hại — mở app, quay lại app từ nền, xong onboarding.
  /// Chỉ thực sự làm việc **một lần mỗi ngày** để không quét lại DB mỗi lần
  /// người dùng chuyển app.
  ///
  /// [force] bỏ qua khoá ngày; dùng khi vừa tạo routine mới và cần có việc ngay,
  /// không chờ tới ngày mai.
  ///
  /// Trả về `true` nếu đã chạy lần này.
  Future<bool> runIfNeeded({
    required String familyId,
    bool force = false,
    DateTime? now,
  }) async {
    final family = await _members.getFamily(familyId);

    // Gieo ba hũ mặc định vào **bảng** `jars` nếu chưa có (ADR-024).
    //
    // Chạy ở đây, ngoài khoá một-lần-mỗi-ngày, vì đây là đường nâng cấp cho gia
    // đình tạo trước schema v5: bảng rỗng thì màn quản lý hũ **không có gì để
    // sửa** trong khi màn Cài đặt lại hiện "3 hũ · chia đủ 100%" nhờ đường rơi về
    // hằng số. Hai màn nói khác nhau về cùng một thứ, và bấm "Thêm hũ" sẽ tạo hũ
    // thứ tư bên cạnh ba hũ vô hình. Có hàng thật thì cả hai màn đọc cùng một
    // nguồn.
    await _jars.seedDefaults(familyId);

    // Dọn hậu quả của hai đường tạo việc song song, một lần cho mỗi nhà.
    //
    // Đặt ở đây, ngoài khoá một-lần-mỗi-ngày, vì đây cũng là đường nâng cấp:
    // nhà cài từ bản trước v0.3.2 đang có việc bị tạo hai lần và việc đứng
    // ngoài mọi buổi. `DonViecLe` tự giữ cờ riêng nên chạy đúng một lần.
    await DonViecLe(
      taskDao: _tasks,
      settingsDao: _settings,
    ).chayNeuCan(familyId);

    // Bù icon cho việc tạo bằng sheet cũ (chưa có ô chọn hình). Cùng lý do với
    // gieo hũ ở trên: sửa dữ liệu một lần thay vì vá chỗ hiển thị.
    await _tasks.backfillMissingIcons(familyId);
    await _rewards.backfillMissingIcons(familyId);

    // Múi giờ lấy từ thiết bị, không từ `families.timezone`: cột đó lưu tên
    // IANA và tầng data chưa quy đổi (xem ADR-008). Đây là chỗ sẽ phải sửa khi
    // gia đình dùng nhiều thiết bị ở nhiều múi giờ.
    final clock = FamilyClock(
      timeZoneOffset: (now ?? DateTime.now()).timeZoneOffset,
      dayRolloverHour: family.dayRolloverHour,
    );
    final today = clock.today(now).toString();

    // Streak và huy hiệu tính lại **mỗi lần mở app**, nằm ngoài khoá một-lần-
    // mỗi-ngày ở dưới.
    //
    // Để trong khoá thì hôm nay đã chạy một lần là thôi, mà cả hai đều đổi trong
    // ngày: bố mẹ mở lại một việc, con làm nốt việc còn thiếu. Đó cũng chính là
    // lý do bảng `streaks` vẫn rỗng sau khi nối `calculateStreak` vào lần đầu —
    // khối tính nằm sau khoá nên không bao giờ chạy tới.
    //
    // Streak **trước** huy hiệu: ba huy hiệu streak đọc `streaks.best_len`, xét
    // ngược lại thì chúng luôn đọc số của lần chạy trước.
    // Mục tiêu tới đích cũng xét ở đây: xu vào hũ Để dành qua nhiều đường (con
    // tự chia, chia tự động cuối ngày, bố mẹ cộng tay), gắn kiểm tra vào từng
    // đường thì sẽ sót đúng cái đường quên gắn.
    final hasSaveJar = (await _jars.activeJars(familyId)).any(
      (j) => j.key == kJarSave,
    );
    for (final child in await _members.children(familyId)) {
      await _streaks.recalculate(memberId: child.id, today: clock.today(now));
      await _badges.awardNewBadges(familyId: familyId, memberId: child.id);
      await _goals.checkReached(child.id, hasSaveJar: hasSaveJar);
    }

    if (!force) {
      final lastRun = await _settings.read(_lastRunKey);
      if (lastRun == today) return false;
    }

    await _tasks.generateInstances(
      familyId: familyId,
      today: clock.today(now),
    );
    // generateInstances đánh dấu bỏ lỡ cho lượt quá hạn; khoản trừ phải chạy
    // ngay sau đó, cùng một lượt (ADR-022).
    await _penalties.applyMissedPenalties(familyId: familyId);

    await _settings.write(_lastRunKey, today);
    return true;
  }

  /// Xoá dấu "đã chạy hôm nay" — dùng trong test và khi đăng xuất.
  Future<void> reset() => _settings.remove([_lastRunKey]);
}
