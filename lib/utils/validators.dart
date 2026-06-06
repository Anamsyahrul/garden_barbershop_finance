class Validators {
  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  static String? number(String? value, String label, {bool required = true}) {
    if (!required && (value == null || value.trim().isEmpty)) return null;
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    if (int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) == null) {
      return '$label harus berupa angka';
    }
    return null;
  }
}
