### 360 Agent Map

- Nguồn: 81 tệp; 489 symbol; 0 tín hiệu domain.
- Mục tiêu: chọn đúng file/symbol trước khi đọc sâu; chống viết trùng/viết thừa.
- Quy tắc: đọc map trước; nếu cần flow/impact/caller/callee hoặc bug fail lần 3 thì dùng 360-codegraph.

#### Domain signals
- Chưa có tín hiệu domain chuyên biệt.

#### Hotspots
- `lib/features/stats/stats_screen.dart` — 28 tín hiệu
- `lib/features/tasks/tasks_screen.dart` — 27 tín hiệu
- `lib/features/parent_home/parent_home_screen.dart` — 26 tín hiệu
- `lib/features/child_home/child_home_screen.dart` — 25 tín hiệu
- `lib/data/local/wallet_dao.dart` — 22 tín hiệu
- `lib/features/settings/penalty_settings_screen.dart` — 21 tín hiệu
- `lib/features/rewards/rewards_screen.dart` — 19 tín hiệu
- `lib/features/rewards/redemption_queue.dart` — 18 tín hiệu
- `lib/features/settings/settings_screen.dart` — 18 tín hiệu
- `lib/data/local/tables/tables.dart` — 16 tín hiệu
- `lib/features/onboarding/onboarding_screen.dart` — 16 tín hiệu
- `lib/features/settings/jar_settings_screen.dart` — 16 tín hiệu

#### Symbol mẫu
- `BeOngApp` (class) — `lib/app/app.dart:32`
- `_BeOngAppState` (class) — `lib/app/app.dart:39`
- `initState` (function) — `lib/app/app.dart:48`
- `dispose` (function) — `lib/app/app.dart:54`
- `didChangeAppLifecycleState` (function) — `lib/app/app.dart:61`
- `build` (function) — `lib/app/app.dart:76`
- `_SessionChangeNotifier` (class) — `lib/app/app.dart:106`
- `notify` (function) — `lib/app/app.dart:107`
- `Routes` (class) — `lib/app/router.dart:17`
- `Function` (function) — `lib/app/router.dart:135`
- `_Branch` (class) — `lib/app/router.dart:137`
- `_AppShell` (class) — `lib/app/router.dart:200`
- `build` (function) — `lib/app/router.dart:206`
- `AppSession` (class) — `lib/core/providers/session_provider.dart:12`
- `Session` (class) — `lib/core/providers/session_provider.dart:42`
- `restore` (function) — `lib/core/providers/session_provider.dart:55`
- `login` (function) — `lib/core/providers/session_provider.dart:57`
- `switchMember` (function) — `lib/core/providers/session_provider.dart:62`
- `logout` (function) — `lib/core/providers/session_provider.dart:77`
- `AppColors` (class) — `lib/core/theme/app_colors.dart:25`
- `AppSemanticColors` (class) — `lib/core/theme/app_colors.dart:154`
- `AppSpacing` (class) — `lib/core/theme/app_spacing.dart:4`
- `AppNavMetrics` (class) — `lib/core/theme/app_spacing.dart:28`
- `AppRadius` (class) — `lib/core/theme/app_spacing.dart:42`
- `AppBreakpoints` (class) — `lib/core/theme/app_spacing.dart:51`
- `isCompact` (function) — `lib/core/theme/app_spacing.dart:55`
- `isMedium` (function) — `lib/core/theme/app_spacing.dart:56`
- `isExpanded` (function) — `lib/core/theme/app_spacing.dart:57`
- `AppTheme` (class) — `lib/core/theme/app_theme.dart:10`
- `AppTypography` (class) — `lib/core/theme/app_typography.dart:10`
