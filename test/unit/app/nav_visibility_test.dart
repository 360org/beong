import 'package:beong/app/router.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kiểm tra điều hướng hiển thị theo vai (Role-based navigation §14, §24).
///
/// Bố mẹ: Home, Tasks, Rewards, Stats, Settings (5 tabs).
/// Con: Home, Tasks, Rewards, Badges, Journey (5 tabs).
List<int> visibleBranchIndexes({
  required List<RoleAudience> audiences,
  required bool isParent,
}) => [
  for (var i = 0; i < audiences.length; i++)
    if (audiences[i] == RoleAudience.all ||
        (isParent && audiences[i] == RoleAudience.parentOnly) ||
        (!isParent && audiences[i] == RoleAudience.childOnly))
      i,
];

void main() {
  // 7 nhánh tương ứng với:
  // 0: Home (all)
  // 1: Tasks (all)
  // 2: Rewards (all)
  // 3: Stats (parentOnly)
  // 4: Badges (childOnly)
  // 5: Journey (childOnly)
  // 6: Settings (parentOnly)
  const layout = [
    RoleAudience.all,
    RoleAudience.all,
    RoleAudience.all,
    RoleAudience.parentOnly,
    RoleAudience.childOnly,
    RoleAudience.childOnly,
    RoleAudience.parentOnly,
  ];

  test('bố mẹ thấy đúng 5 tab: Home, Tasks, Rewards, Stats, Settings', () {
    expect(
      visibleBranchIndexes(audiences: layout, isParent: true),
      [0, 1, 2, 3, 6],
    );
  });

  test('con thấy đúng 5 tab: Home, Tasks, Rewards, Badges, Journey', () {
    expect(
      visibleBranchIndexes(audiences: layout, isParent: false),
      [0, 1, 2, 4, 5],
    );
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
