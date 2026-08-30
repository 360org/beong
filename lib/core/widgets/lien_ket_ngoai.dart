import 'dart:async';

import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/thong_bao.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mở một địa chỉ ra ngoài app: trang web, hộp thư.
///
/// Chủ dự án nêu 30/08/2026: *"link điều khoản / riêng tư không click được."*
/// Trước đó địa chỉ chỉ là **chữ nằm trong một đoạn văn** — trông như link,
/// đọc như link, mà bấm vào không có gì xảy ra. Địa chỉ dài kiểu
/// `beong.net/quyen-rieng-tu.html` thì không ai chép tay sang trình duyệt: coi
/// như trang đó không tồn tại.
typedef MoUri = Future<bool> Function(Uri diaChi);

Future<bool> _moThat(Uri diaChi) =>
    launchUrl(diaChi, mode: LaunchMode.externalApplication);

/// Mở [diaChi]; nếu máy không mở được thì **chép vào bộ nhớ tạm** và nói ra.
///
/// Không im lặng khi hỏng: máy không có trình duyệt mặc định, hoặc không có
/// app thư nào cho `mailto:`, là chuyện có thật. Bấm mà không thấy gì xảy ra
/// thì người dùng bấm lại vài lần rồi kết luận app hỏng — chép sẵn địa chỉ ra
/// cho họ ít nhất còn có đường đi tiếp.
///
/// [mo] để test tiêm vào; mã thật không truyền.
Future<void> moLienKetNgoai(
  BuildContext context,
  Uri diaChi, {
  MoUri? mo,
}) async {
  var xong = false;
  try {
    xong = await (mo ?? _moThat)(diaChi);
  } on Object {
    // Bất kể lỗi gì từ tầng nền: kết quả với người dùng đều là "không mở
    // được", và đường lui bên dưới giống hệt nhau.
    xong = false;
  }
  if (xong || !context.mounted) return;

  // Chép giúp, nhưng **không chờ nó xong** mới báo: bộ nhớ tạm là một kênh
  // xuống tầng nền, và trên máy không có kênh ấy lời hứa này không bao giờ về
  // — chờ nó là treo luôn câu thông báo, tức là bấm vào vẫn không thấy gì,
  // đúng cái lỗi đang sửa.
  unawaited(
    Clipboard.setData(
      ClipboardData(text: diaChi.toString()),
    ).catchError((Object _) {}),
  );

  // Câu báo có **nguyên địa chỉ**, không chỉ nói "đã chép": chép hụt mà câu
  // báo không mang địa chỉ thì người dùng đứng lại giữa đường, không có gì
  // trong tay để đi tiếp.
  hienThongBao(context, 'Máy chưa mở được. Đã chép địa chỉ: $diaChi');
}

/// Một dòng địa chỉ bấm được, đủ rộng để ngón tay trúng.
///
/// Có icon mũi tên chéo ở cuối: dấu hiệu quy ước cho "bấm vào là rời khỏi
/// app". Không có nó thì dòng này trông như một dòng chữ được tô xanh.
class DongLienKet extends StatelessWidget {
  const DongLienKet({
    required this.nhan,
    required this.diaChi,
    super.key,
    this.icon = Icons.open_in_new_rounded,
    this.mo,
  });

  /// Chữ hiện cho người đọc — nên là dạng ngắn, bỏ `https://`.
  final String nhan;
  final Uri diaChi;
  final IconData icon;
  final MoUri? mo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => moLienKetNgoai(context, diaChi, mo: mo),
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                nhan,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: context.colors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(icon, size: 18, color: context.colors.primary),
          ],
        ),
      ),
    );
  }
}
