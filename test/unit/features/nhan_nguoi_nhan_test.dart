import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/features/tasks/tasks_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canh nhãn "buổi này giao cho ai" trên thẻ buổi ở tab Nhiệm vụ.
///
/// Chủ dự án 30/08/2026: *"mỗi session phải thể hiện đang apply cho profile
/// trẻ nào."* Không có nhãn thì hai buổi trông y hệt nhau trong khi một buổi
/// chỉ của Simba và buổi kia của cả nhà — và buổi **không giao cho ai** cũng
/// trông y hệt, dù không bé nào thấy việc trong đó (`schedule.dart:148`).
void main() {
  Member be(String id, String ten) => Member(
    id: id,
    familyId: 'fam-1',
    kind: MemberKind.child.name,
    displayName: ten,
    colorIndex: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    version: 1,
  );

  final neo = be('neo', 'NEO');
  final simba = be('simba', 'Simba');

  test('không giao cho ai thì cảnh báo, kể cả nhà một bé', () {
    for (final ds in [
      <Member>[],
      [neo],
      [neo, simba],
    ]) {
      final nhan = nhanNguoiNhan(const [], ds);
      expect(nhan?.canhBao, isTrue, reason: 'nhà ${ds.length} bé');
      expect(nhan?.nhan, 'Chưa giao cho bé nào');
    }
  });

  test('nhà một bé thì KHÔNG hiện tên — lặp mà không nói thêm gì', () {
    expect(nhanNguoiNhan(['neo'], [neo]), isNull);
  });

  test('giao cho mọi bé thì gọi là "Tất cả", không liệt kê tên', () {
    final nhan = nhanNguoiNhan(['neo', 'simba'], [neo, simba]);
    expect(nhan?.nhan, 'Tất cả');
    expect(nhan?.canhBao, isFalse);
  });

  test('giao cho một bé thì hiện đúng tên bé đó', () {
    final nhan = nhanNguoiNhan(['simba'], [neo, simba]);
    expect(nhan?.nhan, 'Simba');
    expect(nhan?.canhBao, isFalse);
  });

  test('tên xếp theo thứ tự danh sách bé, không theo thứ tự id truyền vào', () {
    // Hai buổi giao cho cùng hai bé phải đọc ra cùng một chuỗi, dù thứ tự bản
    // ghi trong bảng gán khác nhau — chuỗi nhảy chỗ giữa hai thẻ trông như hai
    // nhóm người khác nhau.
    final a = nhanNguoiNhan(['simba', 'neo'], [neo, simba]);
    final b = nhanNguoiNhan(['neo', 'simba'], [neo, simba]);
    expect(a?.nhan, b?.nhan);
  });

  test('bé đã rời nhà không làm nhãn thành "Tất cả" oan', () {
    // `ids` còn giữ một bé đã bị gỡ khỏi danh sách. Số lượng bằng nhau nhưng
    // không phải cùng một tập.
    final nhan = nhanNguoiNhan(['simba', 'da-roi'], [neo, simba]);
    expect(
      nhan?.nhan,
      'Simba',
      reason: 'chỉ đếm số lượng thì nhãn thành "Tất cả" trong khi NEO không có',
    );
  });
}
