import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Canh quy tắc chủ dự án nêu ngày 30/08/2026: ở màn Nhiệm vụ, **hai vạch
/// kéo/thả chỉ được hiện khi đang nhấn giữ và kéo** một buổi, không nằm sẵn
/// trên mọi thẻ.
///
/// Vì sao canh bằng test đọc mã nguồn: đây là thứ chỉ thấy được bằng mắt trên
/// máy thật, mà `ReorderableListView` **mặc định tự vẽ tay kéo**. Chỉ cần một
/// lần sửa quên `buildDefaultDragHandles: false` là tay kéo lặng lẽ quay lại —
/// không test nào đỏ, không ai biết cho tới lần chụp màn hình sau.
void main() {
  final nguon = File('lib/features/tasks/tasks_screen.dart').readAsStringSync();

  test('không dùng tay kéo mặc định của ReorderableListView', () {
    expect(
      nguon.contains('buildDefaultDragHandles: false'),
      isTrue,
      reason:
          'bỏ dòng này thì Flutter tự gắn một tay kéo cố định vào mép phải mọi '
          'thẻ buổi — đúng thứ chủ dự án yêu cầu bỏ đi',
    );
  });

  test('hai vạch chỉ nằm trong lớp phủ lúc kéo', () {
    const vach = 'Icons.drag_handle_rounded';
    expect(
      nguon.contains(vach),
      isTrue,
      reason: 'phải có hai vạch khi đang kéo',
    );
    expect(
      RegExp(vach.replaceAll('.', r'\.')).allMatches(nguon).length,
      1,
      reason:
          'xuất hiện lần thứ hai nghĩa là hai vạch đã bị vẽ ở đâu đó ngoài '
          'lớp phủ kéo — tức là hiện cả lúc nghỉ',
    );
    // Vị trí duy nhất ấy phải nằm **sau** chỗ khai báo lớp phủ, tức là ở trong
    // thân của nó chứ không phải trong thẻ thường.
    expect(
      nguon.indexOf(vach),
      greaterThan(nguon.indexOf('Widget _theDangKeo(')),
    );
  });

  test('giữ lâu mới kéo, chạm nhanh vẫn rơi xuống các nút trong thẻ', () {
    expect(
      nguon.contains('ReorderableDelayedDragStartListener'),
      isTrue,
      reason:
          'không có tay kéo thì cả thẻ phải nhận cú kéo — nhưng chỉ khi giữ '
          'lâu, nếu không thì mỗi lần bấm nút trong thẻ là một lần kéo nhầm',
    );
  });
}
