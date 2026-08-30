import 'package:beong/data/local/database.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/features/parent_home/parent_home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hàng chờ duyệt phải nói rõ đang duyệt cho bé nào.
///
/// Chủ dự án nêu 30/08/2026: *"phần approve công việc không hiển thị là duyệt
/// cho profile nào?"* Nhà hai bé mà thẻ chỉ ghi "Cất đồ chơi +5 xu" thì bố mẹ
/// đang duyệt mù — cộng xu cho một đứa trẻ mà không biết là đứa nào, và không
/// có cách nào biết ngoài việc đoán.
Member be(String id, String ten) => Member(
  id: id,
  familyId: 'fam-1',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  version: 1,
  kind: MemberKind.child.name,
  displayName: ten,
  avatarKey: 'frog',
  colorIndex: 0,
);

TaskInstance luot(String id, String memberId) => TaskInstance(
  id: id,
  familyId: 'fam-1',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  taskId: 'task-$id',
  memberId: memberId,
  dueDate: '2026-08-30',
  status: InstanceStatus.pendingReview.name,
  pointsSnapshot: 5,
  reopenCount: 0,
);

void main() {
  final neo = be('con-1', 'NEO');
  final simba = be('con-2', 'Simba');

  test('nhà nhiều bé thì tra ra đúng bé của lượt việc', () {
    expect(beCuaLuot('con-1', [neo, simba])?.displayName, 'NEO');
    expect(beCuaLuot('con-2', [neo, simba])?.displayName, 'Simba');
  });

  test('nhà một bé thì không nói tên — đã hiển nhiên', () {
    expect(
      beCuaLuot('con-1', [neo]),
      isNull,
      reason:
          'một dòng chữ không mang tin nào là một dòng người đọc học cách bỏ '
          'qua, rồi bỏ qua luôn cả lúc nó có tin',
    );
  });

  test('nhà chưa có bé nào thì không có gì để nói', () {
    expect(beCuaLuot('con-1', const []), isNull);
  });

  test('không tra ra bé thì để trống, không đoán bừa', () {
    expect(
      beCuaLuot('con-da-xoa', [neo, simba]),
      isNull,
      reason:
          'hồ sơ đã xoá mà thẻ vẫn đội tên một bé khác thì bố mẹ duyệt nhầm '
          'người — thà thiếu tên còn hơn hiện sai tên',
    );
  });

  // Cùng lỗ hổng, ở chỗ nguy hơn: nút "Duyệt hết" cộng xu cho **nhiều bé cùng
  // lúc** và không có hoàn tác, nên câu xác nhận phải nói ra là những bé nào.
  group('câu xác nhận Duyệt hết', () {
    test('nhà nhiều bé thì gọi tên đúng những bé đang có việc chờ', () {
      expect(
        moTaDuyetHet(
          hangCho: [luot('i1', 'con-1'), luot('i2', 'con-2')],
          children: [neo, simba],
        ),
        '2 việc của NEO, Simba sẽ được duyệt và cộng xu.',
      );
    });

    test('bé không có việc nào chờ thì không bị gọi tên', () {
      expect(
        moTaDuyetHet(
          hangCho: [luot('i1', 'con-1'), luot('i2', 'con-1')],
          children: [neo, simba],
        ),
        '2 việc của NEO sẽ được duyệt và cộng xu.',
        reason: 'gọi tên Simba là nói bố mẹ sắp cộng xu cho bé không hề làm gì',
      );
    });

    test('thứ tự tên theo danh sách nhà, không theo thứ tự hàng chờ', () {
      final xuoi = moTaDuyetHet(
        hangCho: [luot('i1', 'con-1'), luot('i2', 'con-2')],
        children: [neo, simba],
      );
      final nguoc = moTaDuyetHet(
        hangCho: [luot('i2', 'con-2'), luot('i1', 'con-1')],
        children: [neo, simba],
      );
      expect(
        xuoi,
        nguoc,
        reason:
            'mở hộp thoại hai lần mà thứ tự tên đổi chỗ thì bố mẹ phải đọc '
            'lại từ đầu mỗi lần',
      );
    });

    test('nhà một bé thì giữ nguyên câu cũ, không chèn tên thừa', () {
      expect(
        moTaDuyetHet(hangCho: [luot('i1', 'con-1')], children: [neo]),
        '1 việc sẽ được duyệt và cộng xu cho con.',
      );
    });
  });
}
