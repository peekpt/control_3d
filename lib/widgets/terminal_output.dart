import 'package:flutter/material.dart';

class TerminalOutput extends StatelessWidget {
  final List<String> lines;
  final ScrollController scrollController;

  const TerminalOutput({
    super.key,
    required this.lines,
    required this.scrollController,
  });

  static const _bg = Color(0xFF1A1B26);
  static const _bgLight = Color(0xFFCBCCD1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? _bg : _bgLight,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: SelectionArea(
        child: ListView.builder(
        controller: scrollController,
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = lines[index];
          final isSent = line.startsWith('>>>');
          final isError = line.startsWith('Error:') || line.contains('error');
          final isOk = line == 'ok';

          Color textColor;
          if (isError) {
            textColor = cs.error;
          } else if (isOk) {
            textColor = cs.tertiary;
          } else if (isSent) {
            textColor = cs.primary;
          } else {
            textColor = cs.onSurface;
          }

          final commentIdx = line.indexOf(';');
          final commandPart = commentIdx >= 0 ? line.substring(0, commentIdx) : line;
          final commentPart = commentIdx >= 0 ? line.substring(commentIdx + 1) : null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: commandPart,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (commentPart != null)
                    TextSpan(
                      text: ' $commentPart',
                      style: TextStyle(
                        color: cs.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}
