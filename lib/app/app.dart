import 'package:dailychildren/app/router.dart';
import 'package:dailychildren/core/l10n/gen/app_localizations.dart';
import 'package:dailychildren/core/theme/app_theme.dart';
import 'package:dailychildren/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyChildrenApp extends ConsumerStatefulWidget {
  const DailyChildrenApp({super.key});

  @override
  ConsumerState<DailyChildrenApp> createState() => _DailyChildrenAppState();
}

class _DailyChildrenAppState extends ConsumerState<DailyChildrenApp> {
  late final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => L10n.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      routerConfig: _router,
      builder: (context, child) {
        // Tôn trọng cỡ chữ hệ thống nhưng chặn trần để layout của trẻ không vỡ.
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
