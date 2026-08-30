import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/domain/services/money_exchange.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tự nhập tỷ giá quy đổi xu ra tiền, thay vì chỉ chọn trong sáu mức có sẵn.
///
/// Chủ dự án nêu 30/08/2026: *"chỗ quy đổi xu phải có option cho người dùng
/// chọn nhập số quy đổi."* Sáu mức 1/2/5/10/20/50 phủ được nhiều nhà nhưng
/// không phủ được nhà nào đặt 3, 15 hay 100 — và một danh sách đóng thì nhà
/// đó không có cách nào nói ra con số của mình.
///
/// Trả về số **xu đổi được [kDongPerUnit] đồng**, hoặc `null` khi bố mẹ đóng
/// bảng mà không đặt gì.
Future<int?> showTyGiaSheet(BuildContext context, {int? dangDat}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _TyGiaSheet(dangDat: dangDat),
    ),
  );
}

/// Trần trên của tỷ giá tự nhập.
///
/// Không phải con số thần thánh, chỉ là mốc mà quá nó thì tỷ giá thôi mang
/// nghĩa: 100.000 xu mới đổi được 1.000 đ nghĩa là mỗi xu đáng 0,01 đồng — con
/// làm cả năm không mua nổi cái kẹo, và mọi số tiền hiện ra đều là 0 đ.
const int kTyGiaToiDa = 100000;

/// Đọc tỷ giá bố mẹ gõ vào. `null` nghĩa là **chưa dùng được**, không phải 0.
///
/// Tách khỏi giao diện để kiểm được: đây là chỗ duy nhất một con số do người
/// dùng gõ đi thẳng vào `families.exchange_rate_xu`, và một số 0 lọt qua sẽ
/// làm `dongFor` chia cho 0 ở mọi màn có hiện tiền.
int? docTyGia(String nhap) {
  final sach = nhap.trim().replaceAll('.', '').replaceAll(' ', '');
  if (sach.isEmpty) return null;
  final so = int.tryParse(sach);
  if (so == null || so <= 0 || so > kTyGiaToiDa) return null;
  return so;
}

class _TyGiaSheet extends StatefulWidget {
  const _TyGiaSheet({required this.dangDat});

  final int? dangDat;

  @override
  State<_TyGiaSheet> createState() => _TyGiaSheetState();
}

class _TyGiaSheetState extends State<_TyGiaSheet> {
  late final _controller = TextEditingController(
    text: widget.dangDat?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final so = docTyGia(_controller.text);
    // Xem trước bằng một số xu **có thật trong đời sống của con**, không phải
    // 1 xu: ở tỷ giá 10 xu = 1.000 đ thì 1 xu ra 100 đ, con số đúng nhưng
    // không nói được điều bố mẹ muốn biết là "một tuần con kiếm được bao nhiêu".
    const xuMau = 100;
    final xem = so == null ? null : MoneyExchange(so).labelFor(xuMau);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(
              title: 'Tự nhập tỷ giá',
              subtitle: 'Bao nhiêu xu thì đổi được 1.000 đ?',
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                suffixText: 'xu = 1.000 đ',
                hintText: 'Ví dụ: 15',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (so != null) Navigator.of(context).pop(so);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              xem == null
                  ? 'Nhập một số từ 1 đến ${dinhDangDong(kTyGiaToiDa)}.'
                  : 'Con có $xuMau xu thì $xem.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // Nút tắt khi số chưa dùng được, thay vì cho bấm rồi báo lỗi:
                // ở đây chỉ có đúng một ô để sai, nên không cần một câu báo lỗi
                // để chỉ ra sai ở đâu.
                onPressed: so == null
                    ? null
                    : () => Navigator.of(context).pop(so),
                child: const Text('LƯU'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
