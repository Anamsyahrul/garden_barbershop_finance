import 'package:flutter/services.dart';

import 'currency_formatter.dart';

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    bool isNegative = newValue.text.startsWith('-');
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digits.isEmpty) {
      if (isNegative) {
        return const TextEditingValue(
          text: '-',
          selection: TextSelection.collapsed(offset: 1),
        );
      }
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final value = int.parse(digits) * (isNegative ? -1 : 1);
    final formatted = CurrencyFormatter.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
