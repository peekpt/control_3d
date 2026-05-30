import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/macro.dart';
import 'printer_config_provider.dart';

final macrosProvider = StateNotifierProvider<MacrosNotifier, List<Macro>>((ref) {
  return MacrosNotifier(ref);
});

class MacrosNotifier extends StateNotifier<List<Macro>> {
  final Ref _ref;

  MacrosNotifier(this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final storage = _ref.read(storageServiceProvider);
    state = await storage.loadMacros();
  }

  Future<void> addMacro(Macro macro) async {
    final newMacro = macro.copyWith(id: const Uuid().v4());
    state = [...state, newMacro];
    await _save();
  }

  Future<void> updateMacro(Macro macro) async {
    state = state.map((m) => m.id == macro.id ? macro : m).toList();
    await _save();
  }

  Future<void> removeMacro(String id) async {
    state = state.where((m) => m.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    final storage = _ref.read(storageServiceProvider);
    await storage.saveMacros(state);
  }
}
