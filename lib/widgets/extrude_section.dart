import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../providers/serial_provider.dart';

class ExtrudeSection extends ConsumerStatefulWidget {
  const ExtrudeSection({super.key});

  @override
  ConsumerState<ExtrudeSection> createState() => _ExtrudeSectionState();
}

class _ExtrudeSectionState extends ConsumerState<ExtrudeSection> {
  double _feedRate = 300;
  double _amount = 10;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(serialConnectionProvider);
    final notifier = ref.read(serialConnectionProvider.notifier);
    final theme = Theme.of(context);
    final canExtrude = data.nozzleTemp >= 180;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Extrude', style: theme.textTheme.titleSmall),
                if (!canExtrude) ...[
                  const SizedBox(width: 8),
                  Text('(heat nozzle first)', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
                const Spacer(),
                Text('Feed: ${_feedRate.toInt()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text('Amt: ${_amount.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _sliderRow(
                        label: 'Feed Rate',
                        value: _feedRate,
                        min: 50,
                        max: 1000,
                        divisions: 19,
                        suffix: ' mm/min',
                        onChanged: (v) => setState(() => _feedRate = v),
                      ),
                      const SizedBox(height: 4),
                      _sliderRow(
                        label: 'Amount',
                        value: _amount,
                        min: 1,
                        max: 100,
                        divisions: 99,
                        suffix: ' mm',
                        onChanged: (v) => setState(() => _amount = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    _ExtrudeBtn(
                      icon: FontAwesomeIcons.chevronUp,
                      label: 'E\u2011',
                      color: Colors.grey,
                      enabled: canExtrude,
                      onPressed: canExtrude ? () => notifier.extrude(-_amount) : null,
                    ),
                    const SizedBox(height: 8),
                    _ExtrudeBtn(
                      icon: FontAwesomeIcons.chevronDown,
                      label: 'E+',
                      color: Colors.grey,
                      enabled: canExtrude,
                      onPressed: canExtrude ? () => notifier.extrude(_amount) : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${value.toStringAsFixed(value >= 10 ? 0 : 1)}$suffix',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            '${value.toStringAsFixed(value >= 10 ? 0 : 1)}$suffix',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _ExtrudeBtn extends StatefulWidget {
  final FaIconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ExtrudeBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    this.onPressed,
  });

  @override
  State<_ExtrudeBtn> createState() => _ExtrudeBtnState();
}

class _ExtrudeBtnState extends State<_ExtrudeBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bgColor = enabled
        ? (_pressed ? widget.color.withAlpha(180) : widget.color)
        : widget.color.withAlpha(80);
    final fgColor = enabled
        ? (_pressed ? Colors.black54 : Colors.black87)
        : Colors.black38;

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_pressed ? 30 : 50),
                blurRadius: _pressed ? 2 : 4,
                offset: Offset(0, _pressed ? 1 : 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(widget.icon, size: 16, color: fgColor),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
