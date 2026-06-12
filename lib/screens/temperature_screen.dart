import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/printer_data.dart';
import '../models/temperature_record.dart';
import '../providers/serial_provider.dart';
import '../widgets/macro_panel.dart';

class TemperatureScreen extends ConsumerStatefulWidget {
  const TemperatureScreen({super.key});

  @override
  ConsumerState<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends ConsumerState<TemperatureScreen> {
  Duration _timeWindow = const Duration(minutes: 5);

  final _windows = [
    const Duration(seconds: 30),
    const Duration(minutes: 1),
    const Duration(minutes: 5),
    const Duration(minutes: 15),
  ];

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(serialConnectionProvider);
    final records = ref.watch(temperatureHistoryProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        _SerialStatusBarInline(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _windows.map((w) {
                    String label;
    if (w.inSeconds < 60) {
      label = '${w.inSeconds}s';
    } else if (w.inMinutes < 60) {
      label = '${w.inMinutes}m';
    } else {
      label = '${w.inHours}h';
    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(label, style: const TextStyle(fontSize: 11)),
                        selected: _timeWindow == w,
                        onSelected: (_) => setState(() => _timeWindow = w),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                Flexible(
                  flex: 1,
                  child: _buildChart('Nozzle', records, theme,
                    spotGetter: (r) => r.nozzleTemp,
                    targetGetter: (r) => r.nozzleTarget,
                    color: Colors.orange,
                    maxY: 300,
                  ),
                ),
                const SizedBox(height: 8),

                Flexible(
                  flex: 1,
                  child: _buildChart('Bed', records, theme,
                    spotGetter: (r) => r.bedTemp,
                    targetGetter: (r) => r.bedTarget,
                    color: Colors.blue,
                    maxY: 120,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _tempReadout(
                          'Nozzle',
                          data.nozzleTemp,
                          data.nozzleTarget,
                          Colors.orange,
                          theme,
                        ),
                        _tempReadout(
                          'Bed',
                          data.bedTemp,
                          data.bedTarget,
                          Colors.blue,
                          theme,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: MacroPanel(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(
    String label,
    List<TemperatureRecord> records,
    ThemeData theme, {
    required double Function(TemperatureRecord) spotGetter,
    required double Function(TemperatureRecord) targetGetter,
    required Color color,
    required double maxY,
  }) {
    if (records.isEmpty) {
      return Center(
        child: Text('Waiting for $label data...'),
      );
    }

    final now = DateTime.now();
    final cutoff = now.subtract(_timeWindow);
    final filtered = records.where((r) => r.timestamp.isAfter(cutoff)).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No data in selected window'));
    }

    final minTime = filtered.first.timestamp.millisecondsSinceEpoch.toDouble();
    final maxTime = now.millisecondsSinceEpoch.toDouble();
    final timeRange = maxTime - minTime;

    double maxTemp = 0;
    for (final r in filtered) {
      maxTemp = max(maxTemp, spotGetter(r));
      maxTemp = max(maxTemp, targetGetter(r));
    }
    maxTemp = max(maxTemp + 20, maxY);

    final spots = filtered.map((r) {
      final x = (r.timestamp.millisecondsSinceEpoch.toDouble() - minTime) / timeRange;
      return FlSpot(x, spotGetter(r));
    }).toList();

    final currentTarget = targetGetter(filtered.last);

    return LineChart(
      LineChartData(
        extraLinesData: ExtraLinesData(
          horizontalLines: currentTarget > 0
              ? [
                  HorizontalLine(
                    y: currentTarget,
                    color: Colors.lightBlue.shade100.withAlpha(120),
                    strokeWidth: 1,
                    dashArray: [6, 4],
                  ),
                ]
              : [],
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withAlpha(80),
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: theme.dividerColor.withAlpha(40),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}°C',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: theme.dividerColor),
        ),
        minY: 0,
        maxY: maxTemp,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.6,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withAlpha(30),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '$label: ${spot.y.toStringAsFixed(1)}°C',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _tempReadout(String label, double current, double target, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          '${current.toStringAsFixed(1)}°C',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'Target: ${target.toStringAsFixed(0)}°C',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _SerialStatusBarInline extends ConsumerWidget {
  const _SerialStatusBarInline();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(serialConnectionProvider);
    final isConnected = data.connectionState == PrinterConnectionState.connected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: isConnected ? Colors.green.shade800 : Colors.grey.shade700,
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.link : Icons.link_off,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isConnected
                ? '${data.connectedPort} @ ${data.connectedBaudRate}'
                : 'Disconnected',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          const Spacer(),
          Text(
            'Nozzle ${data.nozzleTemp.toStringAsFixed(1)}°C | Bed ${data.bedTemp.toStringAsFixed(1)}°C',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
