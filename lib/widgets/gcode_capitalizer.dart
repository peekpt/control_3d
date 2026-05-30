import 'package:flutter/services.dart';

class GcodeCapitalizer extends TextInputFormatter {
  static const _preservedCommands = ['M117', 'M118', 'M23', 'M32', 'M928'];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final commentIdx = text.indexOf(';');
    final commandPart = commentIdx >= 0 ? text.substring(0, commentIdx) : text;
    final commentPart = commentIdx >= 0 ? text.substring(commentIdx) : null;

    if (commandPart.isEmpty) return newValue;

    final result = _processCommandPart(commandPart) + (commentPart ?? '');
    if (result == text) return newValue;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset,
      ),
    );
  }

  String _processCommandPart(String part) {
    final trimmed = part.trimLeft();
    if (trimmed.isEmpty) return part;

    final leadingSpaces = part.length - trimmed.length;
    final prefix = ' ' * leadingSpaces;

    final firstSpace = trimmed.indexOf(' ');
    final firstWordLen = firstSpace >= 0 ? firstSpace : trimmed.length;
    final firstWord = trimmed.substring(0, firstWordLen);
    final firstWordUpper = firstWord.toUpperCase();
    final rest = firstSpace >= 0 ? trimmed.substring(firstSpace) : '';

    for (final cmd in _preservedCommands) {
      if (firstWordUpper == cmd) {
        return prefix + cmd + rest;
      }
    }

    return prefix + firstWordUpper + rest.toUpperCase();
  }
}
