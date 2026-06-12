enum PrinterConnectionState {
  disconnected,
  connecting,
  connected,
}

class PrinterData {
  final PrinterConnectionState connectionState;
  final String? connectedPort;
  final int? connectedBaudRate;
  final double nozzleTemp;
  final double nozzleTarget;
  final double bedTemp;
  final double bedTarget;
  final double x;
  final double y;
  final double z;
  final int speed;
  final int flow;
  final List<String> terminalLog;
  final String? autoDisconnectReason;

  const PrinterData({
    this.connectionState = PrinterConnectionState.disconnected,
    this.connectedPort,
    this.connectedBaudRate,
    this.nozzleTemp = 0,
    this.nozzleTarget = 0,
    this.bedTemp = 0,
    this.bedTarget = 0,
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.speed = 100,
    this.flow = 100,
    this.terminalLog = const [],
    this.autoDisconnectReason,
  });

  PrinterData copyWith({
    PrinterConnectionState? connectionState,
    String? connectedPort,
    int? connectedBaudRate,
    double? nozzleTemp,
    double? nozzleTarget,
    double? bedTemp,
    double? bedTarget,
    double? x,
    double? y,
    double? z,
    int? speed,
    int? flow,
    List<String>? terminalLog,
    String? autoDisconnectReason,
  }) =>
      PrinterData(
        connectionState: connectionState ?? this.connectionState,
        connectedPort: connectedPort ?? this.connectedPort,
        connectedBaudRate: connectedBaudRate ?? this.connectedBaudRate,
        nozzleTemp: nozzleTemp ?? this.nozzleTemp,
        nozzleTarget: nozzleTarget ?? this.nozzleTarget,
        bedTemp: bedTemp ?? this.bedTemp,
        bedTarget: bedTarget ?? this.bedTarget,
        x: x ?? this.x,
        y: y ?? this.y,
        z: z ?? this.z,
        speed: speed ?? this.speed,
        flow: flow ?? this.flow,
        terminalLog: terminalLog ?? this.terminalLog,
        autoDisconnectReason: autoDisconnectReason,
      );
}
