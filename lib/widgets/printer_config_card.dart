import 'package:flutter/material.dart';

import '../models/printer_config.dart';

class PrinterConfigCard extends StatelessWidget {
  final PrinterConfig printer;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PrinterConfigCard({
    super.key,
    required this.printer,
    required this.isActive,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isActive
          ? theme.colorScheme.primaryContainer
          : null,
      child: ListTile(
        leading: Icon(
          isActive ? Icons.usb : Icons.usb_off,
          color: isActive ? theme.colorScheme.primary : null,
        ),
        title: Text(
          printer.name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${printer.port} · ${printer.baudRate} baud · ${printer.extruderCount} extruder${printer.extruderCount > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onSelect,
      ),
    );
  }
}
