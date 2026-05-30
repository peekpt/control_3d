class Macro {
  final String id;
  final String name;
  final String gcodeCommand;
  final int sortOrder;

  const Macro({
    required this.id,
    required this.name,
    required this.gcodeCommand,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gcodeCommand': gcodeCommand,
        'sortOrder': sortOrder,
      };

  factory Macro.fromJson(Map<String, dynamic> json) => Macro(
        id: json['id'] as String,
        name: json['name'] as String,
        gcodeCommand: json['gcodeCommand'] as String,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  Macro copyWith({
    String? id,
    String? name,
    String? gcodeCommand,
    int? sortOrder,
  }) =>
      Macro(
        id: id ?? this.id,
        name: name ?? this.name,
        gcodeCommand: gcodeCommand ?? this.gcodeCommand,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
