class DateFormatter {
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String formatDate(DateTime value) {
    return '${value.day} ${_months[value.month - 1]} ${value.year}';
  }

  static String formatMonth(DateTime value) {
    return '${_months[value.month - 1]} ${value.year}';
  }

  static String formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${formatDate(value)}, $hour.$minute WIB';
  }

  static String formatDateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String formatMonthKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    return '${value.year}-$month';
  }

  static String toStorageDate(String value) {
    final trimmed = value.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) return trimmed;

    final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(trimmed);
    if (slash != null) {
      final day = int.parse(slash.group(1)!);
      final month = int.parse(slash.group(2)!);
      final year = int.parse(slash.group(3)!);
      return formatDateKey(DateTime(year, month, day));
    }

    final text =
        RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$').firstMatch(trimmed);
    if (text != null) {
      final day = int.parse(text.group(1)!);
      final month = _monthIndex(text.group(2)!);
      final year = int.parse(text.group(3)!);
      if (month != null) return formatDateKey(DateTime(year, month, day));
    }

    return trimmed;
  }

  static String toStorageMonth(String value) {
    final trimmed = value.trim();
    if (RegExp(r'^\d{4}-\d{2}$').hasMatch(trimmed)) return trimmed;

    final text = RegExp(r'^([A-Za-z]+)\s+(\d{4})$').firstMatch(trimmed);
    if (text != null) {
      final month = _monthIndex(text.group(1)!);
      final year = int.parse(text.group(2)!);
      if (month != null) {
        return '$year-${month.toString().padLeft(2, '0')}';
      }
    }

    return trimmed;
  }

  static String displayDate(String value) {
    final key = toStorageDate(value);
    final date = _parseDateKey(key);
    return date == null ? value : formatDate(date);
  }

  static String displayMonth(String value) {
    final key = toStorageMonth(value);
    final parts = key.split('-');
    if (parts.length != 2) return value;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return value;
    }
    return formatMonth(DateTime(year, month));
  }

  static int? _monthIndex(String value) {
    final normalized = value.toLowerCase();
    for (var i = 0; i < _months.length; i++) {
      if (_months[i].toLowerCase() == normalized) return i + 1;
    }
    return null;
  }

  static DateTime? _parseDateKey(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
}
