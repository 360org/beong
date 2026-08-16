import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'family_clock_provider.g.dart';

/// Đồng hồ của gia đình, theo đúng giờ đổi ngày bố mẹ đã đặt.
///
/// Trước provider này, mỗi màn hình tự dựng `FamilyClock(timeZoneOffset: ...)`
/// và **bỏ qua** `families.day_rollover_hour`, trong khi `DayStartService` thì
/// đọc cột đó. Nhà đặt giờ đổi ngày khác 4 giờ sáng sẽ rơi vào ca tệ nhất: bộ
/// sinh việc ghi lượt cho ngày X còn màn hình hỏi ngày X±1 — con mở app ra thấy
/// trống trơn và không có gì giải thích vì sao.
@riverpod
Stream<FamilyClock> familyClock(Ref ref, String familyId) {
  final offset = DateTime.now().timeZoneOffset;
  return ref
      .watch(memberDaoProvider)
      .watchFamily(familyId)
      .map(
        (family) => FamilyClock(
          timeZoneOffset: offset,
          dayRolloverHour: family.dayRolloverHour,
        ),
      );
}

/// Đồng hồ dùng khi chưa đọc xong hàng gia đình.
///
/// Lấy mặc định 4 giờ sáng — cùng giá trị mặc định của cột — nên nhà chưa đổi
/// gì thì khung hình đầu đã đúng, không nháy.
FamilyClock fallbackFamilyClock() =>
    FamilyClock(timeZoneOffset: DateTime.now().timeZoneOffset);
