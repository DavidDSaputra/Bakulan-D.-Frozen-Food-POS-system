import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'formatters.dart';

class ThousandSeparatorInputFormatter extends TextInputFormatter {
  ThousandSeparatorInputFormatter()
    : _numberFormat = NumberFormat.decimalPattern('id_ID');

  final NumberFormat _numberFormat;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = AppFormatters.digitsOnly(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final parsed = int.tryParse(digits);
    if (parsed == null) return oldValue;

    final formatted = _numberFormat.format(parsed);
    final digitsBeforeCursor = AppFormatters.digitsOnly(
      newValue.selection.textBefore(newValue.text),
    ).length;
    final selectionIndex = _selectionIndexAfterDigits(
      formatted,
      digitsBeforeCursor,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  int _selectionIndexAfterDigits(String text, int digitCount) {
    if (digitCount <= 0) return 0;

    var seenDigits = 0;
    for (var i = 0; i < text.length; i++) {
      if (_isDigit(text[i])) {
        seenDigits++;
        if (seenDigits == digitCount) {
          return i + 1;
        }
      }
    }

    return text.length;
  }

  bool _isDigit(String char) => RegExp(r'[0-9]').hasMatch(char);
}
