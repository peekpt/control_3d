import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/printer_config.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final printerConfigsProvider =
    StateNotifierProvider<PrinterConfigsNotifier, List<PrinterConfig>>((ref) {
  return PrinterConfigsNotifier(ref);
});

final activePrinterIdProvider = StateProvider<String?>((ref) => null);

final activePrinterConfigProvider = Provider<PrinterConfig?>((ref) {
  final activeId = ref.watch(activePrinterIdProvider);
  final printers = ref.watch(printerConfigsProvider);
  if (activeId == null) return null;
  return printers.where((p) => p.id == activeId).firstOrNull;
});

class PrinterConfigsNotifier extends StateNotifier<List<PrinterConfig>> {
  final Ref _ref;

  PrinterConfigsNotifier(this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final storage = _ref.read(storageServiceProvider);
    final printers = await storage.loadPrinters();
    state = printers;

    final activeId = await storage.loadActivePrinterId();
    if (activeId != null && printers.any((p) => p.id == activeId)) {
      _ref.read(activePrinterIdProvider.notifier).state = activeId;
    }
  }

  Future<void> addPrinter(PrinterConfig printer) async {
    final newPrinter = printer.copyWith(id: const Uuid().v4());
    state = [...state, newPrinter];
    await _save();
  }

  Future<void> updatePrinter(PrinterConfig printer) async {
    state = state.map((p) => p.id == printer.id ? printer : p).toList();
    await _save();
  }

  Future<void> removePrinter(String id) async {
    state = state.where((p) => p.id != id).toList();
    final activeId = _ref.read(activePrinterIdProvider);
    if (activeId == id) {
      _ref.read(activePrinterIdProvider.notifier).state =
          state.isNotEmpty ? state.first.id : null;
    }
    await _save();
  }

  Future<void> setActivePrinter(String? id) async {
    _ref.read(activePrinterIdProvider.notifier).state = id;
    final storage = _ref.read(storageServiceProvider);
    await storage.saveActivePrinterId(id);
  }

  Future<void> _save() async {
    final storage = _ref.read(storageServiceProvider);
    await storage.savePrinters(state);
  }
}
