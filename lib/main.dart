import 'package:ebikemanager/core/domain/app_settings_providers.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:ebikemanager/core/router/app_router.dart';
import 'package:ebikemanager/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: EBikeManagerApp()));
}

class EBikeManagerApp extends ConsumerWidget {
  const EBikeManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themePreference =
        ref.watch(appSettingsProvider).value?.themePreference ??
        ThemePreference.system;

    return MaterialApp.router(
      title: 'EBike Manager',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (themePreference) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      routerConfig: router,
    );
  }
}
