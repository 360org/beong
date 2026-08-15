import 'dart:async';

import 'package:beong/app/router.dart';
import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/providers/theme_mode_provider.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ngôn ngữ mặc định khi máy không dùng ngôn ngữ nào app hỗ trợ.
const Locale kFallbackLocale = Locale('vi');

/// Chọn ngôn ngữ: ưu tiên theo thứ tự người dùng đặt trên máy, hết thì về
/// tiếng Việt.
///
/// Tách ra ngoài để test được mà không cần dựng cả cây widget.
Locale resolveAppLocale(
  List<Locale>? deviceLocales,
  Iterable<Locale> supported,
) {
  for (final wanted in deviceLocales ?? const <Locale>[]) {
    for (final candidate in supported) {
      if (candidate.languageCode == wanted.languageCode) return candidate;
    }
  }
  return kFallbackLocale;
}

class BeOngApp extends ConsumerStatefulWidget {
  const BeOngApp({super.key});

  @override
  ConsumerState<BeOngApp> createState() => _BeOngAppState();
}

class _BeOngAppState extends ConsumerState<BeOngApp>
    with WidgetsBindingObserver {
  final _sessionNotifier = _SessionChangeNotifier();
  late final GoRouter _router = createRouter(
    getSession: () => ref.read(sessionProvider),
    refreshListenable: _sessionNotifier,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;

    // Ngày của gia đình có thể đã đổi trong lúc app ngủ — điện thoại để qua đêm
    // là ca thường gặp nhất, không phải ngoại lệ. `runIfNeeded` tự bỏ qua nếu
    // hôm nay đã chạy, nên gọi mỗi lần quay lại app là vô hại.
    final session = ref.read(sessionProvider);
    if (session == null) return;
    unawaited(
      ref.read(dayStartServiceProvider).runIfNeeded(familyId: session.familyId),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (prev, next) {
      _sessionNotifier.notify();
    });

    return MaterialApp.router(
      onGenerateTitle: (context) => L10n.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeSettingProvider),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      // Máy đặt ngôn ngữ ngoài danh sách hỗ trợ thì rơi về tiếng Việt, không
      // phải tiếng Anh: Bé Ong là app cho gia đình Việt, và mặc định của
      // Flutter là lấy locale đầu danh sách — dễ ra tiếng Anh ngoài ý muốn.
      localeListResolutionCallback: resolveAppLocale,
      routerConfig: _router,
      builder: (context, child) {
        final scale = MediaQuery.textScalerOf(
          context,
        ).clamp(maxScaleFactor: AppTypography.maxTextScale);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _SessionChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
