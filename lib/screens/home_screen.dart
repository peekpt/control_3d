import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/printer_data.dart';
import '../providers/printer_config_provider.dart';
import '../providers/serial_provider.dart';
import '../theme/responsive.dart';
import 'control_screen.dart';
import 'temperature_screen.dart';
import 'terminal_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _showedDisconnectDialog = false;

  final _screens = const [
    ControlScreen(),
    TemperatureScreen(),
    TerminalScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final activePrinter = ref.watch(activePrinterConfigProvider);
    final printerData = ref.watch(serialConnectionProvider);
    final isConnected = printerData.connectionState == PrinterConnectionState.connected;
    final isConnecting = printerData.connectionState == PrinterConnectionState.connecting;
    final notifier = ref.read(serialConnectionProvider.notifier);

    final reason = printerData.autoDisconnectReason;
    if (reason != null && !_showedDisconnectDialog) {
      _showedDisconnectDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Printer Disconnected'),
            content: Text(reason),
            actions: [
              TextButton(
                onPressed: () {
                  notifier.clearAutoDisconnectReason();
                  _showedDisconnectDialog = false;
                  Navigator.of(ctx).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }

    final desktop = isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control 3D'),
        centerTitle: true,
        actions: [
          if (activePrinter != null && !isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                onPressed: isConnecting
                    ? null
                    : () => notifier.connect(
                          activePrinter.port,
                          activePrinter.baudRate,
                        ),
                icon: isConnecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                tooltip: isConnecting
                    ? 'Connecting...'
                    : 'Connect to ${activePrinter.name}',
              ),
            ),
          if (isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                onPressed: () => notifier.disconnect(),
                icon: const Icon(Icons.link_off, color: Colors.red),
                tooltip: 'Disconnect',
              ),
            ),
        ],
      ),
      body: desktop ? _desktopBody() : _mobileBody(),
      bottomNavigationBar: desktop ? null : _mobileNav(),
    );
  }

  Widget _desktopBody() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.settings_remote_outlined),
              selectedIcon: Icon(Icons.settings_remote),
              label: Text('Control'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.thermostat_outlined),
              selectedIcon: Icon(Icons.thermostat),
              label: Text('Temperature'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.terminal_outlined),
              selectedIcon: Icon(Icons.terminal),
              label: Text('Terminal'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Text('Settings'),
            ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
      ],
    );
  }

  Widget _mobileBody() {
    return IndexedStack(
      index: _currentIndex,
      children: _screens,
    );
  }

  Widget _mobileNav() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.settings_remote_outlined),
          selectedIcon: Icon(Icons.settings_remote),
          label: 'Control',
        ),
        NavigationDestination(
          icon: Icon(Icons.thermostat_outlined),
          selectedIcon: Icon(Icons.thermostat),
          label: 'Temperature',
        ),
        NavigationDestination(
          icon: Icon(Icons.terminal_outlined),
          selectedIcon: Icon(Icons.terminal),
          label: 'Terminal',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
