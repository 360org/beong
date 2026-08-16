import 'dart:async';
import 'dart:io';

import 'package:beong/core/diagnostics/bao_cao_loi.dart';
import 'package:beong/core/diagnostics/chup_man_hinh.dart';
import 'package:beong/core/diagnostics/gui_bao_cao.dart';
import 'package:beong/core/diagnostics/nhat_ky_loi.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Phiên bản app hiện lên báo cáo.
///
/// Chép tay từ `pubspec.yaml`. Đọc tự động cần `package_info_plus` — một gói
/// nữa cho đúng một chuỗi; test `bao_loi_test.dart` canh hai chỗ không lệch.
const kPhienBanApp = '0.2.0';

/// Màn báo lỗi: gom nhật ký + thiết bị + ảnh màn hình rồi mở issue GitHub.
///
/// Chụp ảnh **trước khi** màn này được đẩy lên, không phải sau: người dùng muốn
/// báo cái màn hình đang hỏng, mà mở màn báo lỗi là màn đó đã bị che.
class BaoLoiScreen extends StatefulWidget {
  const BaoLoiScreen({required this.duongDanAnh, super.key});

  /// Ảnh chụp lúc mở màn này, `null` nếu chụp hỏng.
  final String? duongDanAnh;

  @override
  State<BaoLoiScreen> createState() => _BaoLoiScreenState();
}

class _BaoLoiScreenState extends State<BaoLoiScreen> {
  final _moTa = TextEditingController();
  late final List<MucNhatKy> _nhatKy = nhatKyLoi.muc;
  late bool _kemAnh = widget.duongDanAnh != null;
  bool _dangGui = false;

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
    setState(() => _dangGui = true);
    final baoCao = _dungBaoCao();
    final anh = baoCao.duongDanAnh;

    // Chia sẻ ảnh **trước** khi mở trình duyệt: mở GitHub trước thì app rơi
    // xuống nền và bảng chia sẻ có thể không hiện lên.
    if (anh != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(anh)],
          text: 'Ảnh màn hình kèm báo lỗi Bé Ong — lưu lại để đính vào issue.',
        ),
      );
    }
    if (!mounted) return;

    final url = urlTaoIssue(baoCao);
    final moDuoc = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!mounted) return;

    setState(() => _dangGui = false);
    if (!moDuoc) {
      // Máy không mở được trình duyệt thì báo cáo vẫn phải tới được tay người
      // xử lý — chép vào clipboard còn hơn để người dùng gõ lại bằng tay.
      await Clipboard.setData(ClipboardData(text: baoCao.than));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không mở được trình duyệt. Nội dung báo lỗi đã chép vào bộ nhớ '
            'tạm, anh chị dán vào GitHub giúp nhé.',
          ),
        ),
      );
    }
  }

  Future<void> _chep() async {
    await Clipboard.setData(ClipboardData(text: _dungBaoCao().than));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chép nội dung báo lỗi')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'App sẽ mở trang tạo báo lỗi trên GitHub với nội dung điền sẵn. '
            'Anh chị xem lại rồi mới bấm gửi — không có gì được gửi đi trước '
            'lúc đó.',
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
            onChanged: (v) => setState(() => _kemAnh = v),
          ),
          const SizedBox(height: AppSpacing.xl),
          _KhoiNhatKy(nhatKy: _nhatKy),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // Bắt buộc mô tả: một issue chỉ có stack trace mà không biết
              // người ta đang làm gì thì gần như không lần lại được.
              onPressed: _dangGui || _moTa.text.trim().isEmpty
                  ? null
                  : () => unawaited(_gui()),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('MỞ GITHUB ĐỂ GỬI'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => unawaited(_chep()),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('CHÉP NỘI DUNG'),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// Ảnh chụp kèm theo, xem trước và bật/tắt được.
///
/// Cho xem trước chứ không chỉ ghi "đã đính kèm ảnh": ảnh chụp đúng lúc màn
/// hình đang hiện tên con và số xu, nên người gửi phải **nhìn thấy** thứ mình
/// sắp đăng lên một nơi công khai.
class _KhoiAnh extends StatelessWidget {
  const _KhoiAnh({
    required this.duongDan,
    required this.kem,
    required this.onChanged,
  });

  final String? duongDan;
  final bool kem;
  final ValueChanged<bool> onChanged;

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
