import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/settings_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:drift/drift.dart';

/// Dọn hậu quả của **hai đường tạo việc song song**, và đưa mọi việc về đúng
/// một buổi thói quen.
///
/// ## Chuyện đã xảy ra
///
/// Cho tới v0.3.1, việc nhà sinh ra từ hai chỗ không biết nhau:
///
/// - **Onboarding** tạo buổi thói quen kèm việc bên trong
///   (`onboarding_screen.dart:153`) — việc có `routine_id`.
/// - **Cài đặt → hồ sơ bé → gán việc mẫu** tạo việc rời — `routine_id = NULL`.
///
/// Không ai kiểm trùng, nên cùng một việc mẫu đi qua cả hai đường thành **hai
/// bản ghi**. Trên máy chủ dự án: một bé có 36 việc một ngày, "Đánh răng buổi
/// sáng" hiện hai lần, và xu cộng gấp đôi cho cùng một hành động.
///
/// ## Hai bước, và vì sao theo đúng thứ tự này
///
/// 1. **Tắt bản trùng.** Cùng một bé, cùng một tên việc, mà có cả bản trong
///    buổi lẫn bản lẻ thì **giữ bản trong buổi** — nó có thứ tự, có thưởng trọn
///    bộ, và là thứ bố mẹ nhìn thấy khi sửa thói quen.
/// 2. **Gom việc lẻ còn lại vào một buổi.** Sau bước 1, việc lẻ nào còn sống là
///    việc thật, không phải bản sao — nó cần một chỗ ở, vì từ v0.3.2 mọi việc
///    đều thuộc một buổi.
///
/// ## Không xoá gì cả
///
/// ADR-005: sổ cái chỉ ghi thêm. Lượt việc và các dòng cộng/trừ xu đều trỏ tới
/// `task_id`, nên xoá task đi là "Sổ của con" mất tên việc — con nhìn lại chỉ
/// thấy một dòng cộng xu không rõ từ đâu. Bản trùng vì thế bị **tắt**
/// (`active = false`), không bị xoá.
///
/// ## Nhóm theo *tập người nhận*, không phải theo từng bé
///
/// Một việc chỉ thuộc **một** buổi (`tasks.routine_id`), trong khi một buổi gán
/// được cho **nhiều** bé. Nên việc lẻ giao cho {Neo, Simba} không thể nhét vào
/// buổi của riêng Neo — phải có một buổi gán cho đúng cả hai. Gom theo tập
/// người nhận cho ra đúng số buổi tối thiểu cần tạo, thường là một hoặc hai.
class DonViecLe {
  const DonViecLe({
    required this.taskDao,
    required this.settingsDao,
  });

  final TaskDao taskDao;
  final SettingsDao settingsDao;

  /// Khoá đánh dấu đã dọn cho một gia đình. Dọn một lần là đủ: sau v0.3.2
  /// không còn đường nào sinh việc lẻ nữa.
  static String khoaDaDon(String familyId) => 'don-viec-le:$familyId';

  static const tenBuoiMacDinh = 'Việc khác';

  /// Chạy nếu gia đình này chưa được dọn. Trả về số việc đã đụng tới.
  Future<KetQuaDon> chayNeuCan(String familyId) async {
    final da = await settingsDao.read(khoaDaDon(familyId));
    if (da != null) return const KetQuaDon(daChay: false);

    final ketQua = await chay(familyId);
    await settingsDao.write(khoaDaDon(familyId), '1');
    return ketQua;
  }

  /// Chạy không cần cờ — dùng cho test và cho lệnh dọn thủ công.
  Future<KetQuaDon> chay(String familyId) async {
    final tatCa = await taskDao.activeTasks(familyId);

    final trongBuoi = tatCa.where((t) => t.routineId != null).toList();
    final vietLe = tatCa.where((t) => t.routineId == null).toList();
    if (vietLe.isEmpty) {
      return const KetQuaDon(daChay: true);
    }

    // --- Bước 1: tắt bản lẻ trùng với bản trong buổi ---
    //
    // "Trùng" xét theo **cùng bé + cùng tên**. Chỉ cùng tên là chưa đủ: hai bé
    // cùng phải đánh răng là hai việc khác nhau, không phải bản sao.
    final khoaTrongBuoi = <String>{};
    for (final task in trongBuoi) {
      for (final memberId in await taskDao.routineAssigneesOf(
        task.routineId!,
      )) {
        khoaTrongBuoi.add(_khoa(memberId, task.title));
      }
    }

    final conLai = <Task>[];
    var daTat = 0;
    for (final task in vietLe) {
      final nguoiNhan = await taskDao.assigneesOf(task.id);
      final trung =
          nguoiNhan.isNotEmpty &&
          nguoiNhan.every((m) => khoaTrongBuoi.contains(_khoa(m, task.title)));
      if (trung) {
        await taskDao.setTaskActive(taskId: task.id, active: false);
        daTat++;
      } else {
        conLai.add(task);
      }
    }

    // --- Bước 2: gom việc lẻ còn lại vào buổi, nhóm theo tập người nhận ---
    final ketQuaGom = await _gomVaoBuoi(familyId, conLai);

    return KetQuaDon(
      daChay: true,
      daTatTrung: daTat,
      daGomVaoBuoi: ketQuaGom.daGomVaoBuoi,
      buoiMoiTao: ketQuaGom.buoiMoiTao,
    );
  }

  /// Nhận nuôi mọi việc lẻ còn sót về buổi "Việc khác". Chạy **mỗi lần mở app**,
  /// không có cờ chặn.
  ///
  /// Vì sao cần dù [chay] đã dọn một lần: từ 30/08/2026 màn Nhiệm vụ **không
  /// còn mục "Chưa xếp buổi"** nữa. Mà app vẫn có hai đường sinh việc lẻ sau
  /// khi đã dọn — bỏ một việc khỏi thói quen (`detachTaskFromRoutine`) và ngừng
  /// dùng cả một thói quen (`archiveRoutine`, việc bên trong tách ra). Không có
  /// lưới này thì việc rơi ra khỏi buổi là **biến mất khỏi mọi màn hình** mà
  /// vẫn nằm trong DB: bố mẹ không thấy để sửa, con không thấy để làm.
  ///
  /// Rẻ khi không có gì để làm: một truy vấn, thấy rỗng là thoát.
  Future<KetQuaDon> nhanNuoi(String familyId) async {
    final tatCa = await taskDao.activeTasks(familyId);
    final vietLe = tatCa.where((t) => t.routineId == null).toList();
    if (vietLe.isEmpty) return const KetQuaDon(daChay: true);
    return _gomVaoBuoi(familyId, vietLe);
  }

  Future<KetQuaDon> _gomVaoBuoi(String familyId, List<Task> conLai) async {
    final theoNhom = <String, List<Task>>{};
    final nguoiNhanCuaNhom = <String, List<String>>{};
    for (final task in conLai) {
      final nguoiNhan = (await taskDao.assigneesOf(task.id))..sort();
      // Việc không giao cho ai thì vốn đã không sinh lượt cho bé nào
      // (`schedule.dart:148`). Đưa nó vào buổi cũng không làm nó chạy, mà lại
      // tạo một buổi trống người nhận — để nguyên và ghi vào kết quả.
      if (nguoiNhan.isEmpty) continue;
      final khoa = nguoiNhan.join(',');
      theoNhom.putIfAbsent(khoa, () => []).add(task);
      nguoiNhanCuaNhom[khoa] = nguoiNhan;
    }

    var daGom = 0;
    var buoiMoi = 0;
    for (final entry in theoNhom.entries) {
      final nguoiNhan = nguoiNhanCuaNhom[entry.key]!;
      final routineId =
          'routine-viec-khac-${familyId.hashCode}-${entry.key.hashCode}';

      await taskDao.createRoutine(
        routine: RoutinesCompanion.insert(
          id: routineId,
          familyId: familyId,
          title: tenBuoiMacDinh,
          iconKey: const Value('star'),
        ),
        assigneeIds: nguoiNhan,
        routineTasks: const [],
      );
      buoiMoi++;

      for (final task in entry.value) {
        await taskDao.attachTaskToRoutine(
          taskId: task.id,
          routineId: routineId,
        );
        daGom++;
      }
    }

    return KetQuaDon(
      daChay: true,
      daGomVaoBuoi: daGom,
      buoiMoiTao: buoiMoi,
    );
  }

  String _khoa(String memberId, String title) =>
      '$memberId|${title.trim().toLowerCase()}';
}

/// Kết quả một lượt dọn, đủ để hiện cho bố mẹ biết app vừa đụng vào cái gì.
class KetQuaDon {
  const KetQuaDon({
    required this.daChay,
    this.daTatTrung = 0,
    this.daGomVaoBuoi = 0,
    this.buoiMoiTao = 0,
  });

  /// `false` nghĩa là gia đình này đã dọn từ lần trước, không làm lại.
  final bool daChay;
  final int daTatTrung;
  final int daGomVaoBuoi;
  final int buoiMoiTao;

  bool get coThayDoi => daTatTrung > 0 || daGomVaoBuoi > 0;
}
