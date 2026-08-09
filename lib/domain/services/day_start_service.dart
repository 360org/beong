import 'package:beong/data/local/jar_dao.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/settings_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/penalty_service.dart';

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
  }) : _tasks = taskDao,
       _members = memberDao,
       _settings = settingsDao,
       _penalties = penaltyService,
       _jars = jarDao;

  final TaskDao _tasks;
  final MemberDao _members;
  final SettingsDao _settings;
  final PenaltyService _penalties;
  final JarDao _jars;

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

    // Bù icon cho việc tạo bằng sheet cũ (chưa có ô chọn hình). Cùng lý do với
    // gieo hũ ở trên: sửa dữ liệu một lần thay vì vá chỗ hiển thị.
    await _tasks.backfillMissingIcons(familyId);

    // Múi giờ lấy từ thiết bị, không từ `families.timezone`: cột đó lưu tên
    // IANA và tầng data chưa quy đổi (xem ADR-008). Đây là chỗ sẽ phải sửa khi
    // gia đình dùng nhiều thiết bị ở nhiều múi giờ.
    final clock = FamilyClock(
      timeZoneOffset: (now ?? DateTime.now()).timeZoneOffset,
      dayRolloverHour: family.dayRolloverHour,
    );
    final today = clock.today(now).toString();

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
