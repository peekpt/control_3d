import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/serial_provider.dart';

class HomingButtons extends ConsumerWidget {
  const HomingButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(serialConnectionProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Homing', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _homeButton(context, 'Home X', () => notifier.home(PrinterAxis.x)),
            _homeButton(context, 'Home Y', () => notifier.home(PrinterAxis.y)),
            _homeButton(context, 'Home Z', () => notifier.home(PrinterAxis.z)),
            _homeButton(context, 'Home All', () => notifier.home(PrinterAxis.all)),
          ],
        ),
      ],
    );
  }

  Widget _homeButton(BuildContext context, String label, VoidCallback onPressed) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 11),
        ),
        child: Text(label),
      ),
    );
  }
}
