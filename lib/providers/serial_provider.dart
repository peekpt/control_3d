import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/printer_data.dart';
import '../models/temperature_record.dart';
import '../services/serial_service.dart';

final serialServiceProvider = Provider<SerialService>((ref) {
  final service = SerialService();
  ref.onDispose(() => service.dispose());
  return service;
});

final serialConnectionProvider =
    StateNotifierProvider<SerialConnectionNotifier, PrinterData>((ref) {
  return SerialConnectionNotifier(ref);
});

final temperatureHistoryProvider =
    StateNotifierProvider<TemperatureHistoryNotifier, List<TemperatureRecord>>(
  (ref) => TemperatureHistoryNotifier(),
);

class SerialConnectionNotifier extends StateNotifier<PrinterData> {
  final Ref _ref;
  StreamSubscription? _dataSub;
  StreamSubscription? _messageSub;
  Timer? _tempPollTimer;
  Timer? _coordPollTimer;
  bool _hideSystemCommands = false;

  SerialConnectionNotifier(this._ref) : super(const PrinterData());

  Future<bool> connect(String portName, int baudRate) async {
    state = state.copyWith(
      connectionState: PrinterConnectionState.connecting,
      connectedPort: portName,
      connectedBaudRate: baudRate,
    );

    final service = _ref.read(serialServiceProvider);
    final success = await service.connect(portName, baudRate);

    if (success) {
      state = state.copyWith(connectionState: PrinterConnectionState.connected);
      _startListening();
      _startTempPolling();
      _startCoordPolling();
    } else {
      state = state.copyWith(connectionState: PrinterConnectionState.disconnected);
    }

    return success;
  }

  void disconnect() {
    _tempPollTimer?.cancel();
    _tempPollTimer = null;
    _coordPollTimer?.cancel();
    _coordPollTimer = null;
    _dataSub?.cancel();
    _messageSub?.cancel();
    _ref.read(serialServiceProvider).disconnect();
    state = const PrinterData();
  }

  void setHideSystemCommands(bool v) {
    _hideSystemCommands = v;
  }

  void _startTempPolling() {
    _tempPollTimer?.cancel();
    _tempPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      sendGcode('M105', silent: _hideSystemCommands);
    });
  }

  void _startCoordPolling() {
    _coordPollTimer?.cancel();
    _coordPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      sendGcode('M114', silent: _hideSystemCommands);
    });
  }

  void _startListening() {
    final service = _ref.read(serialServiceProvider);

    _dataSub = service.dataStream.listen((data) {
      if (data['type'] == 'disconnected') {
        disconnect();
        return;
      }

      final updates = <String, dynamic>{};

      if (data.containsKey('nozzleTemp')) {
        updates['nozzleTemp'] = data['nozzleTemp'];
      }
      if (data.containsKey('nozzleTarget')) {
        updates['nozzleTarget'] = data['nozzleTarget'];
      }
      if (data.containsKey('bedTemp')) {
        updates['bedTemp'] = data['bedTemp'];
      }
      if (data.containsKey('bedTarget')) {
        updates['bedTarget'] = data['bedTarget'];
      }
      if (data.containsKey('x')) updates['x'] = data['x'];
      if (data.containsKey('y')) updates['y'] = data['y'];
      if (data.containsKey('z')) updates['z'] = data['z'];

      _ref.read(temperatureHistoryProvider.notifier).addRecord(
            nozzleTemp: (updates['nozzleTemp'] as double?) ?? state.nozzleTemp,
            nozzleTarget:
                (updates['nozzleTarget'] as double?) ?? state.nozzleTarget,
            bedTemp: (updates['bedTemp'] as double?) ?? state.bedTemp,
            bedTarget: (updates['bedTarget'] as double?) ?? state.bedTarget,
          );

      if (updates.isNotEmpty) {
        state = state.copyWith(
          nozzleTemp: updates['nozzleTemp'] as double?,
          nozzleTarget: updates['nozzleTarget'] as double?,
          bedTemp: updates['bedTemp'] as double?,
          bedTarget: updates['bedTarget'] as double?,
          x: updates['x'] as double?,
          y: updates['y'] as double?,
          z: updates['z'] as double?,
        );
      }
    });

    _messageSub = service.messageStream.listen((msg) {
      final updatedLog = List<String>.from(state.terminalLog)
        ..add(msg);
      if (updatedLog.length > 1000) {
        updatedLog.removeRange(0, updatedLog.length - 1000);
      }
      state = state.copyWith(terminalLog: updatedLog);
    });
  }

  void sendGcode(String gcode, {bool silent = false}) {
    _ref.read(serialServiceProvider).sendGcode(gcode, silent: silent);
  }

  void setSpeed(int speed) {
    state = state.copyWith(speed: speed);
    sendGcode('M220 S$speed');
  }

  void setSpeedRaw(int speed) {
    state = state.copyWith(speed: speed);
  }

  void setFlow(int flow) {
    state = state.copyWith(flow: flow);
    sendGcode('M221 S$flow');
  }

  void setFlowRaw(int flow) {
    state = state.copyWith(flow: flow);
  }

  void setNozzleTemp(double temp) {
    sendGcode('M104 S${temp.toStringAsFixed(1)}');
  }

  void setBedTemp(double temp) {
    sendGcode('M140 S${temp.toStringAsFixed(1)}');
  }

  void home(PrinterAxis axis) {
    switch (axis) {
      case PrinterAxis.x:
        sendGcode('G28 X');
      case PrinterAxis.y:
        sendGcode('G28 Y');
      case PrinterAxis.z:
        sendGcode('G28 Z');
      case PrinterAxis.all:
        sendGcode('G28');
    }
  }

  void move(PrinterAxis axis, double distance) {
    sendGcode('G91');
    final axisChar = switch (axis) {
      PrinterAxis.x => 'X',
      PrinterAxis.y => 'Y',
      PrinterAxis.z => 'Z',
      PrinterAxis.all => '',
    };
    if (axisChar.isEmpty) return;
    sendGcode('G1 $axisChar${distance.toStringAsFixed(2)} F${state.speed * 60}');
    sendGcode('G90');
  }

  void extrude(double distance, {double feedRate = 300}) {
    sendGcode('G91');
    sendGcode('G1 E${distance.toStringAsFixed(2)} F${feedRate.round()}');
    sendGcode('G90');
  }

  @override
  void dispose() {
    _tempPollTimer?.cancel();
    _coordPollTimer?.cancel();
    _dataSub?.cancel();
    _messageSub?.cancel();
    super.dispose();
  }
}

enum PrinterAxis { x, y, z, all }

class TemperatureHistoryNotifier extends StateNotifier<List<TemperatureRecord>> {
  TemperatureHistoryNotifier() : super([]);

  void addRecord({
    required double nozzleTemp,
    required double nozzleTarget,
    required double bedTemp,
    required double bedTarget,
  }) {
    final record = TemperatureRecord(
      timestamp: DateTime.now(),
      nozzleTemp: nozzleTemp,
      nozzleTarget: nozzleTarget,
      bedTemp: bedTemp,
      bedTarget: bedTarget,
    );
    state = [...state, record];
    if (state.length > 500) {
      state = state.sublist(state.length - 500);
    }
  }

  void clear() => state = [];
}
