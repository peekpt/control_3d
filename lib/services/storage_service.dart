import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/printer_config.dart';
import '../models/macro.dart';
import '../theme/app_theme.dart';

class StorageService {
  static const _printersKey = 'printers';
  static const _macrosKey = 'macros';
  static const _themeKey = 'theme';
  static const _activePrinterIdKey = 'activePrinterId';
  static const _commandHistoryKey = 'command_history';

  Future<List<PrinterConfig>> loadPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_printersKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => PrinterConfig.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> savePrinters(List<PrinterConfig> printers) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(printers.map((p) => p.toJson()).toList());
    await prefs.setString(_printersKey, json);
  }

  Future<List<Macro>> loadMacros() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_macrosKey);
    if (json == null) return _defaultMacros();
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => Macro.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveMacros(List<Macro> macros) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(macros.map((m) => m.toJson()).toList());
    await prefs.setString(_macrosKey, json);
  }

  Future<AppTheme> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey) ?? AppTheme.system.index;
    return AppTheme.values[index];
  }

  Future<void> saveTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }

  Future<String?> loadActivePrinterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activePrinterIdKey);
  }

  Future<void> saveActivePrinterId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activePrinterIdKey);
    } else {
      await prefs.setString(_activePrinterIdKey, id);
    }
  }

  Future<List<String>> loadCommandHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_commandHistoryKey) ?? [];
  }

  Future<void> saveCommandHistory(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_commandHistoryKey, history);
  }

  Future<void> clearCommandHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_commandHistoryKey);
  }

  List<Macro> _defaultMacros() => [
        const Macro(
          id: 'default_1',
          name: 'Auto Bed Level',
          gcodeCommand: 'G28\\nG29',
          sortOrder: 0,
        ),
        const Macro(
          id: 'default_2',
          name: 'Preheat PLA',
          gcodeCommand: 'M104 S210\\nM140 S60',
          sortOrder: 1,
        ),
        const Macro(
          id: 'default_3',
          name: 'Preheat ABS',
          gcodeCommand: 'M104 S240\\nM140 S90',
          sortOrder: 2,
        ),
        const Macro(
          id: 'default_4',
          name: 'Cool Down',
          gcodeCommand: 'M104 S0\\nM140 S0',
          sortOrder: 3,
        ),
        const Macro(
          id: 'default_5',
          name: 'Load Filament',
          gcodeCommand: 'M302 P1\\nG1 E100 F100',
          sortOrder: 4,
        ),
      ];
}
