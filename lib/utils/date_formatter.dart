import 'package:intl/intl.dart';

class DateFormatter {
  static final date = DateFormat('yyyy-MM-dd');
  static final month = DateFormat('yyyy-MM');

  static String formatDate(DateTime value) => date.format(value);

  static String formatMonth(DateTime value) => month.format(value);
}
