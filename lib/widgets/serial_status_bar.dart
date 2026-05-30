import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/printer_data.dart';
import '../providers/serial_provider.dart';

class SerialStatusBar extends ConsumerWidget {
  const SerialStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(serialConnectionProvider);
    final theme = Theme.of(context);

    final Color bgColor;
    final String label;
    final IconData icon;

    switch (data.connectionState) {
      case PrinterConnectionState.connected:
        bgColor = Colors.green.shade800;
        label = 'Connected: ${data.connectedPort ?? ""} @ ${data.connectedBaudRate ?? 0}';
        icon = Icons.link;
      case PrinterConnectionState.connecting:
        bgColor = Colors.orange.shade800;
        label = 'Connecting...';
        icon = Icons.sync;
      case PrinterConnectionState.disconnected:
        bgColor = Colors.grey.shade700;
        label = 'Disconnected';
        icon = Icons.link_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
