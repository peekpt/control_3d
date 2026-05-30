class TemperatureRecord {
  final DateTime timestamp;
  final double nozzleTemp;
  final double nozzleTarget;
  final double bedTemp;
  final double bedTarget;

  const TemperatureRecord({
    required this.timestamp,
    required this.nozzleTemp,
    required this.nozzleTarget,
    required this.bedTemp,
    required this.bedTarget,
  });
}
