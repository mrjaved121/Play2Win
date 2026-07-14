import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/theme.dart';

/// Root widget. Riverpod's [ProviderScope] is installed once in `main.dart`
/// around this widget; everything below reads state through it.
class PremiumSlotsApp extends ConsumerWidget {
  const PremiumSlotsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
    );
  }
}
