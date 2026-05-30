import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/printer_data.dart';
import '../providers/printer_config_provider.dart';
import '../providers/serial_provider.dart';
import '../theme/responsive.dart';
import '../widgets/directional_pad.dart';
import '../widgets/extrude_section.dart';
import '../widgets/macro_panel.dart';
import '../widgets/serial_status_bar.dart';
import '../widgets/speed_flow_controls.dart';
import '../widgets/temperature_display.dart';

class ControlScreen extends ConsumerWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePrinter = ref.watch(activePrinterConfigProvider);
    final printerData = ref.watch(serialConnectionProvider);
    final isConnected = printerData.connectionState == PrinterConnectionState.connected;
    final isConnecting = printerData.connectionState == PrinterConnectionState.connecting;
    final notifier = ref.read(serialConnectionProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      children: [
        const SerialStatusBar(),
        Expanded(
          child: isConnected
              ? _connectedBody(context, printerData, theme, notifier)
              : _disconnectedBody(context, activePrinter, isConnecting, notifier, theme),
        ),
      ],
    );
  }

  Widget _connectedBody(BuildContext context, PrinterData data, ThemeData theme, dynamic notifier) {
    if (isDesktop(context)) {
      return _desktopConnectedBody(data, theme);
    }
    return _mobileConnectedBody(data, theme);
  }

  Widget _mobileConnectedBody(PrinterData data, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: const DirectionalPad()),
          const SizedBox(height: 12),
          _buildCoords(data, theme),
          const SizedBox(height: 16),
          const ExtrudeSection(),
          const SizedBox(height: 16),
          const TemperatureDisplay(),
          const SizedBox(height: 12),
          const SpeedFlowControls(),
          const SizedBox(height: 16),
          _macrosCard(),
        ],
      ),
    );
  }

  Widget _desktopConnectedBody(PrinterData data, ThemeData theme) {
    const gap = 12.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                const Center(child: DirectionalPad()),
                const SizedBox(height: gap),
                _buildCoords(data, theme),
                const SizedBox(height: gap),
                const TemperatureDisplay(),
              ],
            ),
          ),
          const SizedBox(width: gap),
          Expanded(
            child: Column(
              children: [
                const ExtrudeSection(),
                const SizedBox(height: gap),
                const SpeedFlowControls(),
                const SizedBox(height: gap),
                _macrosCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macrosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: MacroPanel(),
      ),
    );
  }

  Widget _disconnectedBody(BuildContext context, activePrinter, bool isConnecting, dynamic notifier, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activePrinter != null
                  ? Icons.usb
                  : Icons.settings_remote_outlined,
              size: 72,
              color: theme.colorScheme.primary.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Text(
              activePrinter != null
                  ? 'Printer Disconnected'
                  : 'No Printer Configured',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              activePrinter != null
                  ? '${activePrinter.name} is ready to connect'
                  : 'Add a printer in Settings to get started',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: isConnecting
                  ? null
                  : activePrinter != null
                      ? () => notifier.connect(
                            activePrinter.port,
                            activePrinter.baudRate,
                          )
                      : () => ScaffoldMessenger.of(context)
                            .showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Go to Settings to add a printer'),
                              ),
                            ),
              icon: Icon(
                isConnecting
                    ? Icons.hourglass_top
                    : activePrinter != null
                        ? Icons.link
                        : Icons.add_circle_outline,
              ),
              label: Text(
                isConnecting
                    ? 'Connecting...'
                    : activePrinter != null
                        ? 'Connect to Printer'
                        : 'Add Printer',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoords(PrinterData data, ThemeData theme) {
    final isHomed = data.x != 0 || data.y != 0 || data.z != 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isHomed
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _coord('X', data.x, Colors.orange),
                  _coord('Y', data.y, Colors.blue),
                  _coord('Z', data.z, theme.colorScheme.tertiary),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Home printer first',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _coord(String axis, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$axis: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
