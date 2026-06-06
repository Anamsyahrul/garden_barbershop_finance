import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String format(num value) => _formatter.format(value);

  static int parse(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(digits) ?? 0;
  }
}
