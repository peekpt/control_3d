class PrinterConfig {
  final String id;
  final String name;
  final String port;
  final int baudRate;
  final int extruderCount;

  const PrinterConfig({
    required this.id,
    required this.name,
    required this.port,
    required this.baudRate,
    this.extruderCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'port': port,
        'baudRate': baudRate,
        'extruderCount': extruderCount,
      };

  factory PrinterConfig.fromJson(Map<String, dynamic> json) => PrinterConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        port: json['port'] as String,
        baudRate: json['baudRate'] as int,
        extruderCount: json['extruderCount'] as int? ?? 1,
      );

  PrinterConfig copyWith({
    String? id,
    String? name,
    String? port,
    int? baudRate,
    int? extruderCount,
  }) =>
      PrinterConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        port: port ?? this.port,
        baudRate: baudRate ?? this.baudRate,
        extruderCount: extruderCount ?? this.extruderCount,
      );
}
