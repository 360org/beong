import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Canh quy tắc chủ dự án nêu ngày 30/08/2026: **mọi bảng trượt lên đều phải
/// có nút tắt.**
///
/// Vì sao cần test chứ không chỉ cần nhớ: app đang có **30 chỗ** gọi
/// `showModalBottomSheet`, rải khắp 21 file. Rà tay một lượt thì được; giữ cho
/// đúng qua từng lần thêm màn hình mới thì không. Cái sót ra chỉ lộ khi có
/// người thật bị kẹt trong một bảng có bàn phím che hết chỗ bấm ra ngoài.
///
/// Cách canh: file nào gọi `showModalBottomSheet` thì phải dùng `SheetHeader`
/// — trừ những file chỉ *mở* bảng mà thân bảng nằm ở widget khác. Danh sách
/// ngoại lệ đó nằm ngay dưới đây kèm lý do, và test kiểm luôn rằng widget
/// được uỷ thác **thật sự** có `SheetHeader`.
void main() {
  /// file gọi `showModalBottomSheet` -> file chứa thân bảng.
  ///
  /// Thêm dòng vào đây nghĩa là "bảng này có nút đóng, nhưng nút nằm ở chỗ
  /// khác" — phải chỉ ra được chỗ khác đó, không được ghi suông.
  const uyThac = <String, String>{
    // Cả hai chỗ đều mở `AllocateXuSheet`.
    'lib/features/stats/stats_screen.dart':
        'lib/features/rewards/allocate_xu_sheet.dart',
    // Hai bảng hồ sơ bé dùng chung `ChildProfileForm`.
    'lib/features/members/add_child_sheet.dart':
        'lib/features/members/child_profile_form.dart',
    'lib/features/members/edit_child_sheet.dart':
        'lib/features/members/child_profile_form.dart',
  };

  test('mọi bảng trượt lên đều đi qua SheetHeader', () {
    final thieu = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final noiDung = entity.readAsStringSync();
      if (!noiDung.contains('showModalBottomSheet')) continue;
      if (noiDung.contains('SheetHeader')) continue;

      final nguoiGiuHo = uyThac[entity.path];
      if (nguoiGiuHo == null) {
        thieu.add(entity.path);
        continue;
      }
      expect(
        File(nguoiGiuHo).readAsStringSync(),
        contains('SheetHeader'),
        reason:
            '${entity.path} khai là uỷ thác nút đóng cho $nguoiGiuHo, nhưng '
            'file đó không còn SheetHeader',
      );
    }

    expect(
      thieu,
      isEmpty,
      reason:
          'Các file này mở bảng trượt mà không có SheetHeader — người dùng có '
          'thể bị kẹt khi bàn phím che hết chỗ bấm ra ngoài. Thêm SheetHeader, '
          'hoặc khai vào bản đồ `uyThac` ở đầu file test này nếu thân bảng nằm '
          'ở widget khác:\n  ${thieu.join('\n  ')}',
    );
  });

  test('SheetHeader chỉ cho ẩn nút đóng ở đúng chỗ có ADR chống lưng', () {
    // `anNutDong` là lỗ hổng duy nhất của quy tắc trên. Mở rộng nó ra chỗ khác
    // là vô hiệu hoá cả quy tắc mà không ai thấy, nên chỗ dùng phải đếm được.
    final dungONhungDau = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('sheet_header.dart')) continue;
      if (entity.readAsStringSync().contains('anNutDong')) {
        dungONhungDau.add(entity.path);
      }
    }

    expect(
      dungONhungDau,
      ['lib/features/members/mat_khau_sheet.dart'],
      reason:
          'Chỉ bảng đặt mật khẩu lần đầu ở onboarding được ẩn nút đóng, vì '
          'ADR-027 nói không hồ sơ nào được để trống mật khẩu và bảng đó đã '
          'tắt cả vuốt lẫn bấm-ra-ngoài. Chỗ nào khác muốn ẩn thì phải có ADR '
          'riêng, và phải sửa test này một cách tường minh.',
    );
  });
}
