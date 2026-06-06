import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';

class CurrencyText extends StatelessWidget {
  const CurrencyText(
    this.value, {
    super.key,
    this.style,
  });

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(CurrencyFormatter.format(value), style: style);
  }
}
