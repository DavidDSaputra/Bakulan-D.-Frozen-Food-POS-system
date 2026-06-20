import 'package:intl/intl.dart';

class AppFormatters {
  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _number = NumberFormat.decimalPattern('id_ID');
  static final _compactNumber = NumberFormat.compact(locale: 'id_ID');
  static final _date = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _fullDate = DateFormat('dd MMMM yyyy', 'id_ID');
  static final _monthYear = DateFormat('MMMM yyyy', 'id_ID');

  static String rupiah(num value) => _rupiah.format(value);

  static String number(num value) => _number.format(value);

  static String compactNumber(num value) => _compactNumber.format(value);

  static int? parseNumberInput(String? value) {
    final digits = digitsOnly(value);
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  static String digitsOnly(String? value) {
    return (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String date(DateTime date) => _date.format(date);

  static String fullDate(DateTime date) => _fullDate.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);
}
