import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nhãn tab là chỗ đầu tiên người dùng đọc, và đã đổi một lần từ "Việc nhà"
/// sang "Nhiệm vụ" vì app không chỉ dùng cho việc nhà — học bài, đi chơi, thể
/// dục đều là nhiệm vụ. Test này giữ để không ai đổi ngược lại cho "gọn".
void main() {
  test('tab thứ hai gọi là Nhiệm vụ, không phải Việc nhà', () {
    final vi = lookupL10n(const Locale('vi'));

    expect(vi.navTasks, 'Nhiệm vụ');
    expect(vi.tasksTitle, 'Nhiệm vụ');
  });

  test('mọi nhãn tab tiếng Việt đều có nội dung', () {
    final vi = lookupL10n(const Locale('vi'));

    for (final label in [
      vi.navHome,
      vi.navTasks,
      vi.navRewards,
      vi.navBadges,
      vi.navJourney,
      vi.navStats,
      vi.navSettings,
    ]) {
      expect(label.trim(), isNotEmpty);
    }
  });
}
