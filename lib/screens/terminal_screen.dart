import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../models/printer_data.dart';
import '../providers/serial_provider.dart';
import '../services/storage_service.dart';
import '../widgets/gcode_capitalizer.dart';
import '../widgets/macro_panel.dart';
import '../widgets/terminal_output.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _storageService = StorageService();

  static const _maxHistory = 50;
  List<String> _commandHistory = [];
  int _historyIndex = -1;
  bool _hideSystem = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _focusNode.onKeyEvent = _handleKeyEvent;
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _storageService.loadCommandHistory();
    setState(() => _commandHistory = history);
  }

  Future<void> _saveHistory() async {
    await _storageService.saveCommandHistory(_commandHistory);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _navigateHistory(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _navigateHistory(1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _navigateHistory(int direction) {
    if (_commandHistory.isEmpty) return;

    int newIndex;
    if (direction < 0) {
      newIndex = _historyIndex <= -1
          ? _commandHistory.length - 1
          : (_historyIndex - 1).clamp(0, _commandHistory.length - 1);
    } else {
      newIndex = (_historyIndex >= _commandHistory.length - 1 || _historyIndex == -1)
          ? -1
          : _historyIndex + 1;
    }

    if (newIndex == _historyIndex) return;

    setState(() {
      _historyIndex = newIndex;
      if (_historyIndex == -1) {
        _inputController.clear();
      } else {
        _inputController.text = _commandHistory[_historyIndex];
        _inputController.selection = TextSelection.collapsed(
          offset: _inputController.text.length,
        );
      }
    });
  }

  void _sendCommand() {
    final cmd = _inputController.text.trim();
    if (cmd.isEmpty) return;

    ref.read(serialConnectionProvider.notifier).sendGcode(cmd);
    _inputController.clear();
    _focusNode.requestFocus();

    _commandHistory.remove(cmd);
    _commandHistory.add(cmd);
    if (_commandHistory.length > _maxHistory) {
      _commandHistory.removeAt(0);
    }
    _historyIndex = -1;
    _saveHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(serialConnectionProvider);
    final isConnected = data.connectionState == PrinterConnectionState.connected;
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
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
                isConnected ? 'Connected' : 'Disconnected',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              if (isConnected) ...[
                const Spacer(),
                Text(
                  '${data.connectedPort} @ ${data.connectedBaudRate}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                TerminalOutput(
                  lines: data.terminalLog,
                  scrollController: _scrollController,
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _hideSystem = !_hideSystem);
                      ref.read(serialConnectionProvider.notifier).setHideSystemCommands(_hideSystem);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _hideSystem ? 'silent mode is ON' : 'silent mode is OFF',
                        style: TextStyle(
                          fontSize: 10,
                          color: _hideSystem
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              _hideSystem ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  inputFormatters: [GcodeCapitalizer()],
                  decoration: InputDecoration(
                    hintText: isConnected ? 'Enter G-code...' : 'Not connected',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  onSubmitted: (_) => _sendCommand(),
                  enabled: isConnected,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: isConnected ? _sendCommand : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('SEND'),
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: const MacroPanel(),
        ),
      ],
    );
  }
}
