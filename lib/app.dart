import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'theme/themes.dart';
import 'screens/home_screen.dart';

class Control3DApp extends ConsumerWidget {
  const Control3DApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Control 3D',
      debugShowCheckedModeBanner: false,
      theme: themeFromAppTheme(AppTheme.light),
      darkTheme: themeFromAppTheme(AppTheme.dark),
      themeMode: switch (appTheme) {
        AppTheme.light => ThemeMode.light,
        AppTheme.dark => ThemeMode.dark,
        AppTheme.system => ThemeMode.system,
      },
      themeAnimationCurve: Curves.easeInOut,
      themeAnimationDuration: const Duration(milliseconds: 300),
      home: const HomeScreen(),
    );
  }
}
