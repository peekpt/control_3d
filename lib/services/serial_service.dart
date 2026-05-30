import 'dart:async';
import 'dart:convert';

import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription? _subscription;
  bool _disposed = false;
  int _suppressCount = 0;

  final StreamController<Map<String, dynamic>> _dataController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  Stream<String> get messageStream => _messageController.stream;

  bool get isConnected => _port?.isOpen ?? false;

  static List<String> getAvailablePorts() {
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(String portName, int baudRate) async {
    _disposed = false;
    try {
      _port = SerialPort(portName);
      _port!.openReadWrite();

      final config = SerialPortConfig();
      config.baudRate = baudRate;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = 0;
      config.dtr = 1;
      config.rts = 1;
      _port!.config = config;

      _messageController.add('Port opened: $portName @ $baudRate');

      await Future.delayed(const Duration(seconds: 2));

      _reader = SerialPortReader(_port!);

      String buffer = '';
      _subscription = _reader!.stream.listen(
        (data) {
          if (_disposed) return;
          buffer += utf8.decode(data);
          while (buffer.contains('\n')) {
            final idx = buffer.indexOf('\n');
            final line = buffer.substring(0, idx).trim();
            buffer = buffer.substring(idx + 1);
            if (line.isNotEmpty) {
              final cleaned = line.startsWith('echo:') ? line.substring(5) : line;
              _parseLine(cleaned);
              if (_suppressCount > 0) {
                if (cleaned == 'ok' || cleaned.startsWith('ok ')) {
                  _suppressCount--;
                }
              } else {
                _messageController.add(cleaned);
              }
            }
          }
        },
        onError: (error) {
          _messageController.add('Serial error: $error');
        },
        onDone: () {
          _messageController.add('Serial connection closed');
          _dataController.add({'type': 'disconnected'});
        },
      );

      _messageController.add('Reader started, waiting for data...');
      return true;
    } catch (e) {
      _messageController.add('Connection failed: $e');
      _disconnect();
      return false;
    }
  }

  void disconnect() {
    _disconnect();
  }

  void _disconnect() {
    _disposed = true;
    _suppressCount = 0;
    _subscription?.cancel();
    _reader?.close();
    try {
      _port?.close();
    } catch (_) {}
    try {
      _port?.dispose();
    } catch (_) {}
    _subscription = null;
    _reader = null;
    _port = null;
  }

  void sendGcode(String gcode, {bool silent = false}) {
    if (_port == null || !_port!.isOpen) {
      _messageController.add('Not connected');
      return;
    }
    try {
      final line = gcode.trim();
      if (line.isEmpty) return;
      _port!.write(utf8.encode('$line\n'));
      if (silent) {
        _suppressCount++;
      } else {
        _messageController.add('>>> $line');
      }
    } catch (e) {
      _messageController.add('Send failed: $e');
    }
  }

  void _parseLine(String line) {
    final data = <String, dynamic>{'raw': line};

    if (line.contains('T:')) {
      final tMatch = RegExp(r'T:\s*([\d.]+)').firstMatch(line);
      if (tMatch != null) data['nozzleTemp'] = double.parse(tMatch.group(1)!);

      final tTargetMatch =
          RegExp(r'T:\s*[\d.]+\s*/\s*([\d.]+)').firstMatch(line);
      if (tTargetMatch != null) {
        data['nozzleTarget'] = double.parse(tTargetMatch.group(1)!);
      }
    }

    if (line.contains('B:')) {
      final bMatch = RegExp(r'B:\s*([\d.]+)').firstMatch(line);
      if (bMatch != null) data['bedTemp'] = double.parse(bMatch.group(1)!);

      final bTargetMatch =
          RegExp(r'B:\s*[\d.]+\s*/\s*([\d.]+)').firstMatch(line);
      if (bTargetMatch != null) {
        data['bedTarget'] = double.parse(bTargetMatch.group(1)!);
      }
    }

    if (line.contains('X:') || line.contains('Y:') || line.contains('Z:')) {
      final xMatch = RegExp(r'X:\s*([\d.-]+)').firstMatch(line);
      if (xMatch != null) data['x'] = double.parse(xMatch.group(1)!);
      final yMatch = RegExp(r'Y:\s*([\d.-]+)').firstMatch(line);
      if (yMatch != null) data['y'] = double.parse(yMatch.group(1)!);
      final zMatch = RegExp(r'Z:\s*([\d.-]+)').firstMatch(line);
      if (zMatch != null) data['z'] = double.parse(zMatch.group(1)!);
    }

    if (line == 'ok' || line.startsWith('ok')) {
      data['type'] = 'ok';
    }

    if (line.startsWith('Error:')) {
      data['type'] = 'error';
    }

    if (line.startsWith('//')) {
      data['type'] = 'message';
    }

    if (data.length > 1 || data.containsKey('type')) {
      _dataController.add(data);
    }
  }

  void dispose() {
    _disposed = true;
    _disconnect();
    _dataController.close();
    _messageController.close();
  }
}
