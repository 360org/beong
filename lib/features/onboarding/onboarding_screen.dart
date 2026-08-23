import 'dart:async';

import 'package:beong/app/router.dart';
import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/du_lieu_may_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/bee_mascot.dart';
import 'package:beong/core/widgets/responsive_scaffold.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/presets.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/services/age_band.dart';
import 'package:beong/features/members/child_profile_form.dart';
import 'package:beong/features/members/mat_khau_sheet.dart';
import 'package:beong/features/members/scan_pairing_dialog.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _familyNameController = TextEditingController(text: 'Nhà mình');
  final _childNameController = TextEditingController();
  int _childColorIndex = 0;
  String _childAvatar = kAvatarEmojis.first;

  /// Không chọn sẵn năm nào: đoán tuổi của trẻ là bịa dữ liệu, và
  /// [ageBandFor] đã có sẵn nhóm mặc định cho trường hợp `null`.
  int? _childBirthYear;
  final _selectedRoutines = <String>{'morning', 'bedtime'};

  @override
  void dispose() {
    _pageController.dispose();
    _familyNameController.dispose();
    _childNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      unawaited(
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
      setState(() => _currentPage++);
    }
  }

  Future<void> _finish() async {
    final familyName = _familyNameController.text.trim();
    final childName = _childNameController.text.trim();
    if (familyName.isEmpty || childName.isEmpty) return;

    final memberDao = ref.read(memberRepositoryProvider);
    final taskDao = ref.read(taskRepositoryProvider);

    // Lưới an toàn cuối (`docs/13-audit-luong-vao-app.md` §2 P4). Router đã lo
    // không cho vào đây khi máy có dữ liệu, nhưng hỏi lại ngay trước lúc ghi
    // vẫn đáng: chỗ hỏng duy nhất còn lại — đọc DB lúc khởi động thất bại — làm
    // đúng cái cờ của router sai, và cái giá của việc lọt qua là một gia đình
    // trùng cùng toàn bộ dữ liệu cũ thành mồ côi.
    final daCo = await memberDao.allFamilies();
    if (daCo.isNotEmpty) {
      if (!mounted) return;
      final tiepTuc = await _hoiTruocKhiTaoTrung(daCo.first.name);
      if (tiepTuc != true) {
        if (mounted) context.go(Routes.chonNguoiDung);
        return;
      }
    }

    // UUID sinh ở client, không dùng ID cứng — mỗi lần onboarding phải tạo
    // được family mới (ADR-002). Onboarding lặp lại vẫn xảy ra sau khi đăng
    // xuất, nên không được dùng ID cố định.
    const uuid = Uuid();
    final familyId = uuid.v4();
    final parentId = uuid.v4();
    final childId = uuid.v4();

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: familyName),
    );

    // Ba hũ mặc định vào **bảng** `jars` ngay từ đầu (ADR-024), để màn quản lý hũ
    // có thứ thật mà sửa. Không gieo thì gia đình mới chạy bằng đường rơi về
    // `kDefaultJars`, và bố mẹ sửa tỷ lệ xong thấy không có gì thay đổi.
    await ref.read(jarRepositoryProvider).seedDefaults(familyId);

    await memberDao.addMember(
      MembersCompanion.insert(
        id: parentId,
        familyId: familyId,
        kind: MemberKind.parent.name,
        displayName: 'Bố mẹ',
      ),
    );

    await memberDao.addMember(
      MembersCompanion.insert(
        id: childId,
        familyId: familyId,
        kind: MemberKind.child.name,
        displayName: childName,
        colorIndex: Value(_childColorIndex),
        avatarKey: Value(_childAvatar),
        birthYear: Value(_childBirthYear),
      ),
    );

    for (final routineKey in _selectedRoutines) {
      final preset = kRoutinePresets.firstWhere((r) => r.key == routineKey);
      final routineId = uuid.v4();

      final routineTasks = <TasksCompanion>[];
      for (var i = 0; i < preset.taskKeys.length; i++) {
        final tp = presetByKey(preset.taskKeys[i]);
        if (tp == null) continue;
        routineTasks.add(
          TasksCompanion.insert(
            id: '$routineId-task-$i',
            familyId: familyId,
            title: tp.titleVi,
            iconKey: Value(tp.iconKey),
            presetKey: Value(tp.key),
            points: Value(tp.defaultPoints),
            routineId: Value(routineId),
            orderIndex: Value(i),
          ),
        );
      }

      await taskDao.createRoutine(
        routine: RoutinesCompanion.insert(
          id: routineId,
          familyId: familyId,
          title: preset.titleVi,
          iconKey: Value(preset.iconKey),
          dayPart: Value(preset.dayPart),
          completionBonus: const Value(10),
        ),
        assigneeIds: [childId],
        routineTasks: routineTasks,
      );
    }

    // Bước cuối của onboarding theo ADR-027: **mọi** hồ sơ vừa tạo phải có mật
    // khẩu, không bỏ qua được. Đặt ở đây chứ không phải trong Cài đặt, vì mật
    // khẩu giờ là cách định danh ai đang dùng máy — thiếu nó thì luồng "chọn vai
    // → chọn hồ sơ → điền mật khẩu" không có gì để hỏi.
    //
    // Thứ tự ở đây **quan trọng và đã từng sai**: phải hỏi mật khẩu *trước*
    // `login()`. Đăng nhập là đặt session, mà session đổi thì router đá ngay
    // khỏi onboarding sang Trang chính — màn này unmount, `mounted` thành
    // `false`, và cả vòng lặp dưới đây bị nuốt trong im lặng. Bản đầu đặt sau
    // `login()` và onboarding chạy xong với hai hồ sơ `pin_hash = NULL`, không
    // một lời báo nào.
    //
    // Đặt **sau** khi ghi xong dữ liệu thì vẫn đúng: hỏng ở giữa thì nhà vẫn
    // còn, và lần vào sau màn chọn hồ sơ bắt đặt nốt. Ghi trước rồi hỏng thì
    // mất cả nhà.
    // Bố mẹ bắt buộc có mật khẩu để bảo vệ cài đặt. Bé thì cho phép tuỳ chọn
    // đặt mật khẩu hoặc không (bỏ qua được).
    final matKhau = ref.read(matKhauHoSoProvider);
    if (!mounted) return;
    await datMatKhauMoi(
      context,
      memberId: parentId,
      tenHienThi: 'Bố mẹ',
      service: matKhau,
      batBuoc: true,
      moTa: 'Bốn chữ số cho hồ sơ Bố mẹ. Dùng để khoá cài đặt và duyệt việc.',
    );

    if (!mounted) return;
    await datMatKhauMoi(
      context,
      memberId: childId,
      tenHienThi: childName,
      service: matKhau,
      moTa:
          'Bốn chữ số cho hồ sơ của $childName (tuỳ chọn). Bé nhập nó để mở hồ sơ '
          'của mình; bạn có thể bấm HUỶ nếu không cần mật khẩu.',
    );

    // Máy vừa có gia đình đầu tiên — router phải biết, nếu không lần khoá máy
    // sau lại rơi về onboarding.
    ref.read(mayDaCoDuLieuProvider.notifier).danhDauDaCo();

    await ref
        .read(sessionProvider.notifier)
        .login(
          AppSession(
            familyId: familyId,
            activeMemberId: parentId,
          ),
        );

    // Sinh việc cho hôm nay ngay, `force` vì routine vừa được tạo xong: chờ tới
    // lần mở app sau thì bố mẹ thấy "0 / 0 việc hôm nay" ngay sau onboarding.
    await ref
        .read(dayStartServiceProvider)
        .runIfNeeded(familyId: familyId, force: true);

    if (mounted) context.go('/');
  }

  /// Hỏi trước khi tạo nhà thứ hai trên cùng một máy.
  ///
  /// `true` = vẫn tạo nhà mới. Bất cứ gì khác = về màn chọn người dùng.
  Future<bool?> _hoiTruocKhiTaoTrung(String tenNhaCu) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Máy này đã có nhà rồi'),
        content: Text(
          'Trong máy đang có nhà «$tenNhaCu» cùng toàn bộ việc, xu và huy hiệu '
          'của con. Tạo nhà mới thì nhà cũ vẫn còn nhưng bắt đầu lại từ số 0.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('TẠO NHÀ MỚI'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('VÀO NHÀ CŨ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScreenPadding(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              _StepIndicator(current: _currentPage, total: 3),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _FamilyStep(controller: _familyNameController),
                    ChildProfileForm(
                      controller: _childNameController,
                      colorIndex: _childColorIndex,
                      onColorChanged: (i) =>
                          setState(() => _childColorIndex = i),
                      avatar: _childAvatar,
                      onAvatarChanged: (a) => setState(() => _childAvatar = a),
                      birthYear: _childBirthYear,
                      onBirthYearChanged: (y) =>
                          setState(() => _childBirthYear = y),
                    ),
                    _RoutineStep(
                      selected: _selectedRoutines,
                      onToggle: (key) {
                        setState(() {
                          if (_selectedRoutines.contains(key)) {
                            _selectedRoutines.remove(key);
                          } else {
                            _selectedRoutines.add(key);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentPage < 2 ? _nextPage : _finish,
                  child: Text(
                    _currentPage < 2 ? 'TIẾP TỤC' : 'BẮT ĐẦU',
                  ),
                ),
              ),
              if (_currentPage == 0) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () async {
                    final code = await showScanPairingDialog(context);
                    if (code != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã nhận mã: ${code.substring(0, 8).toUpperCase()}. '
                            'Tính năng đồng bộ qua mạng đang được hoàn thiện.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Máy của con? Quét mã ghép cặp'),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= current;
        return Container(
          width: active ? 32 : 12,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: active ? context.colors.primary : context.colors.outline,
          ),
        );
      }),
    );
  }
}

class _FamilyStep extends StatelessWidget {
  const _FamilyStep({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Màn hình đầu tiên là chỗ duy nhất trong app hiện tên thương hiệu
        // kèm slogan — các màn sau chỉ nói việc của gia đình.
        Center(
          child: Column(
            children: [
              // Linh vật vẽ tay, không dùng emoji 🐝: emoji đổi hình theo nền
              // tảng nên không dùng được ở chỗ nhận diện thương hiệu.
              const BeeMascot(mood: BeeMood.happy, size: 84),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.appTitle,
                style: context.text.displayLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.appSlogan,
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'Đặt tên gia đình',
          style: context.text.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tên này sẽ hiển thị trong app của cả nhà.',
          style: context.text.bodyMedium?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhà mình',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
      ],
    );
  }
}

class _RoutineStep extends StatelessWidget {
  const _RoutineStep({required this.selected, required this.onToggle});
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn thói quen', style: context.text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Chọn routine sẵn để bắt đầu nhanh. '
          'Bé có thể sửa sau.',
          style: context.text.bodyMedium?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ...kRoutinePresets.map((preset) {
          final isSelected = selected.contains(preset.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Card(
              color: isSelected ? context.colors.primaryContainer : null,
              child: InkWell(
                onTap: () => onToggle(preset.key),
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      // Icon của chính routine (`preset.iconKey`), không phải
                      // Material icon suy từ buổi trong ngày: cả app dùng một bộ
                      // hình, trộn hai kiểu ở đúng màn đầu tiên người dùng thấy
                      // là mất ngay cảm giác đồng bộ.
                      Opacity(
                        opacity: isSelected ? 1 : 0.55,
                        child: AppIcon(preset.iconKey, size: 26),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.titleVi,
                              style: context.text.titleMedium,
                            ),
                            Text(
                              '${preset.taskKeys.length} việc',
                              style: context.text.bodySmall?.copyWith(
                                color: context.semantic.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: context.colors.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
