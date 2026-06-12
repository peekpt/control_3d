import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/serial_service.dart';
import '../services/storage_service.dart';
import '../models/printer_config.dart';
import '../providers/printer_config_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/printer_config_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    final printers = ref.watch(printerConfigsProvider);
    final activeId = ref.watch(activePrinterIdProvider);
    final configNotifier = ref.read(printerConfigsProvider.notifier);
    final themeNotifier = ref.read(themeProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<AppTheme>(
          segments: const [
            ButtonSegment(
              value: AppTheme.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: AppTheme.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode),
            ),
            ButtonSegment(
              value: AppTheme.system,
              label: Text('System'),
              icon: Icon(Icons.settings_brightness),
            ),
          ],
          selected: {currentTheme},
          onSelectionChanged: (selected) {
            themeNotifier.setTheme(selected.first);
          },
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Text('Printers', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showPrinterDialog(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Printer'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (printers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No printers configured.\nTap "Add Printer" to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
          )
        else if (isDesktop(context))
          _printerGrid(printers, activeId, configNotifier)
        else
          ...printers.map((printer) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PrinterConfigCard(
                  printer: printer,
                  isActive: printer.id == activeId,
                  onSelect: () {
                    configNotifier.setActivePrinter(
                      printer.id == activeId ? null : printer.id,
                    );
                  },
                  onEdit: () => _showPrinterDialog(context, printer),
                  onDelete: () => _confirmDelete(context, printer),
                ),
              )),

        const SizedBox(height: 24),

        Text('Data', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Clear Command History'),
            subtitle: const Text('Removes all saved G-code history'),
            onTap: () => _clearCommandHistory(context),
          ),
        ),

        const SizedBox(height: 24),

        Text('About', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Control 3D', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Version $_appVersion'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'A cross-platform 3D printer control app. '
                  'Connect to your printer via USB serial, send G-code commands, '
                  'monitor temperatures, and control movements.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://github.com/peekpt/control_3d'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'github.com/peekpt/control_3d',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _printerGrid(List<PrinterConfig> printers, String? activeId, dynamic configNotifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: printers.map((printer) => SizedBox(
            width: cardWidth,
            child: PrinterConfigCard(
              printer: printer,
              isActive: printer.id == activeId,
              onSelect: () {
                configNotifier.setActivePrinter(
                  printer.id == activeId ? null : printer.id,
                );
              },
              onEdit: () => _showPrinterDialog(context, printer),
              onDelete: () => _confirmDelete(context, printer),
            ),
          )).toList(),
        );
      },
    );
  }

  void _showPrinterDialog(BuildContext context, PrinterConfig? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final portController = TextEditingController(text: existing?.port ?? '');
    final baudController =
        TextEditingController(text: existing?.baudRate.toString() ?? '115200');
    int extruderCount = existing?.extruderCount ?? 1;
    final ports = SerialService.getAvailablePorts();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing != null ? 'Edit Printer' : 'Add Printer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Printer Name',
                        hintText: 'e.g. Ender 3 v2',
                      ),
                    ),
                    const SizedBox(height: 12),

                    Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return ports;
                        return ports.where((p) =>
                            p.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      initialValue: TextEditingValue(text: portController.text),
                      onSelected: (value) => portController.text = value,
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '/dev/cu.usbserial-xxx',
                          ),
                          onSubmitted: (_) => onSubmitted(),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: int.tryParse(baudController.text) ?? 115200,
                      decoration: const InputDecoration(labelText: 'Baud Rate'),
                      items: [
                        9600, 14400, 19200, 38400, 57600,
                        115200, 250000, 500000,
                      ].map<DropdownMenuItem<int>>((b) => DropdownMenuItem(
                            value: b,
                            child: Text(b.toString()),
                          )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          baudController.text = value.toString();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Text('Extruders: '),
                        const SizedBox(width: 8),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('1')),
                            ButtonSegment(value: 2, label: Text('2')),
                            ButtonSegment(value: 3, label: Text('3')),
                            ButtonSegment(value: 4, label: Text('4')),
                          ],
                          selected: {extruderCount},
                          onSelectionChanged: (selected) {
                            setDialogState(() => extruderCount = selected.first);
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final port = portController.text.trim();
                    final baud = int.tryParse(baudController.text) ?? 115200;
                    if (name.isEmpty || port.isEmpty) return;

                    final config = PrinterConfig(
                      id: existing?.id ?? '',
                      name: name,
                      port: port,
                      baudRate: baud,
                      extruderCount: extruderCount,
                    );

                    final notifier = ref.read(printerConfigsProvider.notifier);
                    if (existing != null) {
                      notifier.updatePrinter(config);
                    } else {
                      notifier.addPrinter(config);
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(existing != null ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, PrinterConfig printer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Printer'),
        content: Text('Are you sure you want to delete "${printer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(printerConfigsProvider.notifier).removePrinter(printer.id);
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCommandHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Clear all saved G-code command history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await StorageService().clearCommandHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Command history cleared')),
        );
      }
    }
  }
}
