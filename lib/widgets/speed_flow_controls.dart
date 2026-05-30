import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/serial_provider.dart';

class SpeedFlowControls extends ConsumerStatefulWidget {
  const SpeedFlowControls({super.key});

  @override
  ConsumerState<SpeedFlowControls> createState() => _SpeedFlowControlsState();
}

class _SpeedFlowControlsState extends ConsumerState<SpeedFlowControls> {
  Timer? _debounceTimer;
  int _pendingSpeed = 100;
  int _pendingFlow = 100;

  @override
  void initState() {
    super.initState();
    final data = ref.read(serialConnectionProvider);
    _pendingSpeed = data.speed;
    _pendingFlow = data.flow;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSpeedChanged(int v) {
    _pendingSpeed = v;
    ref.read(serialConnectionProvider.notifier).setSpeedRaw(v);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      ref.read(serialConnectionProvider.notifier).setSpeed(_pendingSpeed);
    });
  }

  void _onFlowChanged(int v) {
    _pendingFlow = v;
    ref.read(serialConnectionProvider.notifier).setFlowRaw(v);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      ref.read(serialConnectionProvider.notifier).setFlow(_pendingFlow);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(serialConnectionProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Speed & Flow', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            _sliderRow(
              label: 'Speed',
              value: data.speed.toDouble(),
              onChanged: (v) => _onSpeedChanged(v.round()),
            ),
            const SizedBox(height: 8),
            _sliderRow(
              label: 'Flow',
              value: data.flow.toDouble(),
              onChanged: (v) => _onFlowChanged(v.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: 500,
            divisions: 499,
            label: '${value.round()}%',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '${value.round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
