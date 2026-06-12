import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/serial_provider.dart';

class TemperatureDisplay extends ConsumerStatefulWidget {
  const TemperatureDisplay({super.key});

  @override
  ConsumerState<TemperatureDisplay> createState() => _TemperatureDisplayState();
}

class _TemperatureDisplayState extends ConsumerState<TemperatureDisplay> {
  final _nozzleController = TextEditingController();
  final _bedController = TextEditingController();

  @override
  void dispose() {
    _nozzleController.dispose();
    _bedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(serialConnectionProvider);
    final records = ref.watch(temperatureHistoryProvider);
    final notifier = ref.read(serialConnectionProvider.notifier);
    final theme = Theme.of(context);

    final nozzleTemps = records.map((r) => r.nozzleTemp).toList();
    final bedTemps = records.map((r) => r.bedTemp).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temperatures', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            _tempRow(
              label: 'Nozzle',
              current: data.nozzleTemp,
              target: data.nozzleTarget,
              sparkData: nozzleTemps,
              controller: _nozzleController,
              onSet: () {
                final value = double.tryParse(_nozzleController.text);
                if (value != null) notifier.setNozzleTemp(value);
              },
              onOff: () {
                _nozzleController.clear();
                notifier.setNozzleTemp(0);
              },
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _tempRow(
              label: 'Bed',
              current: data.bedTemp,
              target: data.bedTarget,
              sparkData: bedTemps,
              controller: _bedController,
              onSet: () {
                final value = double.tryParse(_bedController.text);
                if (value != null) notifier.setBedTemp(value);
              },
              onOff: () {
                _bedController.clear();
                notifier.setBedTemp(0);
              },
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tempRow({
    required String label,
    required double current,
    required double target,
    required List<double> sparkData,
    required TextEditingController controller,
    required VoidCallback onSet,
    required VoidCallback onOff,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Text(
          '${current.toStringAsFixed(1)}°C',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 32,
            child: _Sparkline(data: sparkData, color: color),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          height: 32,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Target',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: onSet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('SET'),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: onOff,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('Off'),
          ),
        ),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _Sparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(data: data, color: color),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2 || size.width <= 0 || size.height <= 0) return;

    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    final actualRange = range < 1 ? 1.0 : range;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final margin = 1.5;
    final drawH = size.height - margin * 2;
    final stepX = size.width / (data.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = margin + drawH - ((data[i] - min) / actualRange) * drawH;
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      if (i < points.length - 1) {
        final midX = (points[i].dx + points[i + 1].dx) / 2;
        final midY = (points[i].dy + points[i + 1].dy) / 2;
        path.quadraticBezierTo(points[i].dx, points[i].dy, midX, midY);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) => data != oldDelegate.data;
}
