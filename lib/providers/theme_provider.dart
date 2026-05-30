import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'printer_config_provider.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier(ref);
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  final Ref _ref;

  ThemeNotifier(this._ref) : super(AppTheme.system) {
    _load();
  }

  Future<void> _load() async {
    final storage = _ref.read(storageServiceProvider);
    state = await storage.loadTheme();
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    final storage = _ref.read(storageServiceProvider);
    await storage.saveTheme(theme);
  }
}
