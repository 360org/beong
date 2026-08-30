import 'dart:async';
import 'dart:io';

import 'package:beong/core/diagnostics/bao_cao_loi.dart';
import 'package:beong/core/diagnostics/chup_man_hinh.dart';
import 'package:beong/core/diagnostics/gui_bao_cao.dart';
import 'package:beong/core/diagnostics/nhat_ky_loi.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Phiên bản app hiện lên báo cáo.
///
/// Chép tay từ `pubspec.yaml`. Đọc tự động cần `package_info_plus` — một gói
/// nữa cho đúng một chuỗi; test `bao_cao_loi_test.dart` canh hai chỗ không lệch.
const kPhienBanApp = '0.7.7';

/// Màn báo lỗi: gom nhật ký + thiết bị + ảnh màn hình rồi **gửi thẳng** cho
/// nhà phát triển.
///
/// Màn này cố ý không nhắc tới GitHub, token hay máy chủ. Bố mẹ đang bực vì
/// app hỏng; bắt họ hiểu quy trình nội bộ của đội phát triển là đẩy việc của
/// mình sang cho người dùng.
class BaoLoiScreen extends StatefulWidget {
  const BaoLoiScreen({required this.duongDanAnh, super.key});

  /// Ảnh chụp lúc mở màn này, `null` nếu chụp hỏng.
  final String? duongDanAnh;

  @override
  State<BaoLoiScreen> createState() => _BaoLoiScreenState();
}

/// Trạng thái của màn, quyết định người dùng thấy gì.
enum _TrangThai {
  dangSoan,
  dangGui,

  /// App đã gửi xong, người dùng không phải làm gì nữa.
  daGui,

  /// Bản dựng thiếu endpoint nên **không gửi được**.
  ///
  /// Tách khỏi [daGui] vì gộp lại là nói dối, và tách khỏi [guiHong] vì bấm
  /// "thử lại" cũng không đổi được gì — đây là thiếu cấu hình của bản dựng,
  /// không phải mạng chập chờn.
  chuaCauHinh,

  guiHong,
}

class _BaoLoiScreenState extends State<BaoLoiScreen> {
  final _moTa = TextEditingController();
  late final List<MucNhatKy> _nhatKy = nhatKyLoi.muc;
  late bool _kemAnh = widget.duongDanAnh != null;
  _TrangThai _trangThai = _TrangThai.dangSoan;

  @override
  void initState() {
    super.initState();
    _moTa.addListener(_onMoTaChanged);
  }

  void _onMoTaChanged() => setState(() {});

  @override
  void dispose() {
    _moTa
      ..removeListener(_onMoTaChanged)
      ..dispose();
    super.dispose();
  }

  BaoCaoLoi _dungBaoCao() {
    final media = MediaQuery.of(context);
    return BaoCaoLoi(
      moTaNguoiDung: _moTa.text,
      thietBi: ThongTinThietBi.thuThap(
        phienBanApp: kPhienBanApp,
        kichThuocManHinh: media.size,
        tyLePhongChu: media.textScaler.scale(14) / 14,
      ),
      nhatKy: _nhatKy,
      duongDanAnh: _kemAnh ? widget.duongDanAnh : null,
    );
  }

  Future<void> _gui() async {
    setState(() => _trangThai = _TrangThai.dangGui);
    final baoCao = _dungBaoCao();
    final ketQua = await guiBaoCao(baoCao);
    if (!mounted) return;

    switch (ketQua) {
      case KetQuaGui.thanhCong:
        setState(() => _trangThai = _TrangThai.daGui);
      case KetQuaGui.that:
        setState(() => _trangThai = _TrangThai.guiHong);
      case KetQuaGui.chuaCauHinh:
        // Bản dựng nội bộ chưa cấu hình endpoint. Nói thẳng là chưa gửi được
        // thay vì mở trang GitHub — xem ghi chú ở `KetQuaGui.chuaCauHinh`.
        setState(() => _trangThai = _TrangThai.chuaCauHinh);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_trangThai == _TrangThai.daGui) {
      return const ManKetThucBaoLoi(tuGui: true);
    }
    if (_trangThai == _TrangThai.chuaCauHinh) {
      return const ManKetThucBaoLoi(tuGui: false);
    }

    final dangGui = _trangThai == _TrangThai.dangGui;
    final anh = widget.duongDanAnh;

    return Scaffold(
      appBar: AppBar(title: Text('Báo lỗi', style: context.text.titleLarge)),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingMobile,
          vertical: AppSpacing.lg,
        ),
        children: [
          Text(
            'Kể giúp chúng tôi chuyện gì đang hỏng. Báo cáo gửi kèm thông tin '
            'máy và nhật ký lỗi kỹ thuật; nhật ký chỉ có thông điệp lỗi, không '
            'có tên con hay số xu.',
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Chuyện gì đã xảy ra', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _moTa,
            maxLines: 4,
            enabled: !dangGui,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText:
                  'Ví dụ: bấm xong việc "Gấp chăn màn" thì xu không cộng lên.',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _KhoiAnh(
            duongDan: anh,
            kem: _kemAnh,
            onChanged: dangGui ? null : (v) => setState(() => _kemAnh = v),
          ),
          const SizedBox(height: AppSpacing.xl),
          _KhoiNhatKy(nhatKy: _nhatKy),
          if (_trangThai == _TrangThai.guiHong) ...[
            const SizedBox(height: AppSpacing.xl),
            _KhoiGuiHong(),
          ],
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Bắt buộc mô tả: một báo cáo chỉ có nhật ký mà không biết người
              // ta đang làm gì thì gần như không lần lại được.
              onPressed: dangGui || _moTa.text.trim().isEmpty
                  ? null
                  : () => unawaited(_gui()),
              child: dangGui
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _trangThai == _TrangThai.guiHong
                          ? 'THỬ GỬI LẠI'
                          : 'GỬI BÁO CÁO',
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// Màn kết thúc.
///
/// Thay hẳn màn soạn chứ không chỉ hiện một SnackBar rồi quay lại: người dùng
/// cần một dấu chấm hết rõ ràng, nếu không họ sẽ bấm gửi lần nữa cho chắc.
///
/// Công khai (không `_`) để test dựng thẳng được cả hai ca: phân biệt "đã gửi"
/// với "mới mở trang" là chỗ dễ sai nhất ở đây, và đi vòng qua cả luồng gửi
/// mới kiểm được thì sẽ không ai kiểm.
@visibleForTesting
class ManKetThucBaoLoi extends StatelessWidget {
  const ManKetThucBaoLoi({required this.tuGui, super.key});

  /// `true` = app đã gửi xong. `false` = mới mở trang, người dùng còn phải bấm
  /// gửi ở đó.
  final bool tuGui;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Báo lỗi', style: context.text.titleLarge)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tuGui ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              size: 64,
              color: tuGui
                  ? context.semantic.success
                  : context.semantic.warning,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              tuGui ? 'Đã gửi rồi, cảm ơn anh chị!' : 'Chưa gửi được',
              style: context.text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              tuGui
                  ? 'Chúng tôi sẽ xem và sửa. Nếu cần hỏi thêm thì chưa có '
                        'cách liên hệ lại — app không lưu email của anh chị.'
                  : 'Bản app này chưa được cấu hình để gửi báo cáo, nên báo '
                        'cáo chưa đi đâu cả. Bấm lại cũng chưa gửi được — '
                        'anh chị báo giúp cho người đưa bản app này nhé.',
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('XONG'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Báo gửi hỏng, kèm lý do người dùng làm được gì đó.
class _KhoiGuiHong extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.semantic.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.semantic.danger),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.wifi_off_rounded, color: context.semantic.danger),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Chưa gửi được. Kiểm tra kết nối mạng rồi thử lại — nội dung '
                'anh chị vừa viết vẫn còn nguyên ở trên.',
                style: context.text.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ảnh chụp kèm theo, xem trước và bật/tắt được.
///
/// Cho xem trước chứ không chỉ ghi "đã đính kèm ảnh": ảnh chụp đúng lúc màn
/// hình đang hiện tên con và số xu, nên người gửi phải **nhìn thấy** thứ mình
/// sắp gửi đi.
class _KhoiAnh extends StatelessWidget {
  const _KhoiAnh({
    required this.duongDan,
    required this.kem,
    required this.onChanged,
  });

  final String? duongDan;
  final bool kem;

  /// `null` là đang gửi, khoá công tắc lại.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final duongDan = this.duongDan;
    if (duongDan == null) {
      return Text(
        'Không chụp được ảnh màn hình lần này — báo lỗi vẫn gửi được bình '
        'thường.',
        style: context.text.bodySmall?.copyWith(
          color: context.semantic.onSurfaceMuted,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: kem,
          onChanged: onChanged,
          title: const Text('Gửi kèm ảnh màn hình'),
          subtitle: const Text(
            'Ảnh có thể chứa tên con và số xu. Xem kỹ trước khi gửi.',
          ),
        ),
        if (kem) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: Image.file(File(duongDan), fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Nhật ký lỗi, gập lại sẵn.
class _KhoiNhatKy extends StatelessWidget {
  const _KhoiNhatKy({required this.nhatKy});

  final List<MucNhatKy> nhatKy;

  @override
  Widget build(BuildContext context) {
    if (nhatKy.isEmpty) {
      return Text(
        'Phiên này chưa ghi nhận lỗi kỹ thuật nào. Anh chị cứ mô tả ở trên, '
        'phần mô tả mới là thứ giúp được nhiều nhất.',
        style: context.text.bodySmall?.copyWith(
          color: context.semantic.onSurfaceMuted,
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        title: Text('Nhật ký lỗi · ${nhatKy.length}'),
        subtitle: const Text('Gửi kèm để tìm nguyên nhân'),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: nhatKy.length,
              itemBuilder: (context, i) {
                // Mới nhất lên đầu **trong phần xem**, ngược với thứ tự trong
                // báo cáo: người dùng mở ra để kiểm "có phải lỗi tôi vừa gặp
                // không", còn người xử lý đọc theo dòng thời gian.
                final muc = nhatKy[nhatKy.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    '${muc.nguon ?? '?'}: ${muc.moTa}',
                    style: context.text.labelSmall,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Chụp màn hình rồi mở màn báo lỗi.
///
/// Chụp **trước** khi đẩy màn mới lên: chụp sau thì ảnh chỉ có chính màn báo
/// lỗi, đúng thứ vô dụng nhất trong một báo cáo lỗi.
Future<void> moManBaoLoi(BuildContext context) async {
  final anh = await chupManHinh();
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BaoLoiScreen(duongDanAnh: anh),
    ),
  );
}
