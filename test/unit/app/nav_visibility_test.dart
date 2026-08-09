import 'package:beong/core/providers/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vai con không có tab Cài đặt.
///
/// Đây là ẩn ở giao diện, **không phải cơ chế bảo vệ**: vai lưu ở local không
/// cấp quyền (ADR-018), nên đừng đọc test này như một khẳng định về bảo mật.
/// Chặn thật sẽ đến từ credential khi có backend (ADR-021).
///
/// Logic lọc nằm trong `_AppShell` (private) nên test ở đây chỉ chốt **hợp đồng**
/// mà nó dựa vào: bảng ánh xạ chỉ số phải đúng khi bỏ một tab ở giữa/cuối.
List<int> visibleBranchIndexes({
  required List<bool> parentOnly,
  required bool isParent,
}) => [
  for (var i = 0; i < parentOnly.length; i++)
    if (isParent || !parentOnly[i]) i,
];

void main() {
  // Bố cục thật: home, tasks, rewards, stats, settings(parentOnly).
  const layout = [false, false, false, false, true];

  test('bố mẹ thấy đủ 5 tab', () {
    expect(
      visibleBranchIndexes(parentOnly: layout, isParent: true),
      [0, 1, 2, 3, 4],
    );
  });

  test('con thấy 4 tab, không có Cài đặt', () {
    expect(
      visibleBranchIndexes(parentOnly: layout, isParent: false),
      [0, 1, 2, 3],
    );
  });

  test('bỏ tab ở **giữa** vẫn ánh xạ đúng nhánh', () {
    // Đây là chỗ dễ sai nhất: nếu UI dùng thẳng chỉ số của thanh nav thì bỏ một
    // tab ở giữa làm mọi tab sau nó mở sai màn hình.
    const middle = [false, true, false, false];
    final visible = visibleBranchIndexes(
      parentOnly: middle,
      isParent: false,
    );

    expect(visible, [0, 2, 3]);
    // Tab thứ hai trong thanh nav (chỉ số 1) phải mở nhánh 2, không phải nhánh 1.
    expect(visible[1], 2);
  });

  test('AppSession.isParent quyết định, không phải cờ nào khác', () {
    const parent = AppSession(familyId: 'f', activeMemberId: 'p');
    const child = AppSession(
      familyId: 'f',
      activeMemberId: 'c',
      isParent: false,
    );

    expect(parent.isParent, isTrue);
    expect(child.isParent, isFalse);
  });
}
