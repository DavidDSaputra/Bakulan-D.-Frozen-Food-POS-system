class Validators {
  static String? requiredText(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi';
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'Angka'}) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null) return '$field harus berupa angka';
    if (number <= 0) return '$field harus lebih dari 0';
    return null;
  }

  static String? nonNegativeNumber(String? value, {String field = 'Angka'}) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null) return '$field harus berupa angka';
    if (number < 0) return '$field tidak boleh kurang dari 0';
    return null;
  }
}
