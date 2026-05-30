import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/macro.dart';
import '../providers/macro_provider.dart';
import '../providers/serial_provider.dart';

class MacroPanel extends ConsumerStatefulWidget {
  const MacroPanel({super.key});

  @override
  ConsumerState<MacroPanel> createState() => _MacroPanelState();
}

class _MacroPanelState extends ConsumerState<MacroPanel> {
  bool _expanded = false;
  bool _editMode = false;
  final _nameController = TextEditingController();
  final _gcodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _gcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final macros = ref.watch(macrosProvider);
    final notifier = ref.read(serialConnectionProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() {
            _expanded = !_expanded;
            if (!_expanded) _editMode = false;
          }),
          child: Row(
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text('Macros (${macros.length})',
                  style: theme.textTheme.titleSmall),
              const Spacer(),
              if (_expanded)
                GestureDetector(
                  onTap: () => setState(() => _editMode = !_editMode),
                  child: Text(
                    _editMode ? 'Done' : 'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          if (macros.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No macros yet. Add one below.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  )),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: macros.map((macro) {
                if (_editMode) {
                  return _buildEditModeChip(macro, theme);
                }
                return _buildViewModeChip(macro, notifier);
              }).toList(),
            ),
          const Divider(height: 16),
          _buildAddMacroForm(),
        ],
      ],
    );
  }

  Widget _buildViewModeChip(Macro macro, SerialConnectionNotifier notifier) {
    return ActionChip(
      label: Text(macro.name, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        final commands = macro.gcodeCommand.split('\\n');
        for (final cmd in commands) {
          notifier.sendGcode(cmd.trim());
        }
      },
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEditModeChip(Macro macro, ThemeData theme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActionChip(
          label: Text(macro.name, style: const TextStyle(fontSize: 11)),
          onPressed: () => _editMacro(context, macro),
          visualDensity: VisualDensity.compact,
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Material(
            color: Colors.red,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _deleteMacro(context, macro),
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(Icons.close, size: 11, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _editMacro(BuildContext context, Macro macro) {
    final nameCtrl = TextEditingController(text: macro.name);
    final gcodeCtrl = TextEditingController(text: macro.gcodeCommand);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Macro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gcodeCtrl,
              decoration: const InputDecoration(
                labelText: 'G-code',
                helperText: 'Use \\n for multi-line',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveEdit(ctx, macro, nameCtrl.text.trim(), gcodeCtrl.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveEdit(BuildContext context, Macro macro, String name, String gcode) {
    if (name.isEmpty || gcode.isEmpty) return;
    if (name == macro.name && gcode == macro.gcodeCommand) {
      Navigator.pop(context);
      return;
    }
    ref.read(macrosProvider.notifier).updateMacro(
          macro.copyWith(name: name, gcodeCommand: gcode),
        );
    Navigator.pop(context);
  }

  Widget _buildAddMacroForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Macro', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _gcodeController,
                decoration: const InputDecoration(
                  hintText: 'G-code (use \\n for multi-line)',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: _addMacro,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('ADD'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addMacro() {
    final name = _nameController.text.trim();
    final gcode = _gcodeController.text.trim();
    if (name.isEmpty || gcode.isEmpty) return;

    ref.read(macrosProvider.notifier).addMacro(
          Macro(id: '', name: name, gcodeCommand: gcode),
        );

    _nameController.clear();
    _gcodeController.clear();
  }

  void _deleteMacro(BuildContext context, Macro macro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Macro'),
        content: Text('Delete "${macro.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(macrosProvider.notifier).removeMacro(macro.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
