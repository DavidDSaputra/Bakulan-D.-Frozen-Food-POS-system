import 'package:intl/intl.dart';

class AppFormatters {
  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _date = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _monthYear = DateFormat('MMMM yyyy', 'id_ID');

  static String rupiah(num value) => _rupiah.format(value);

  static String date(DateTime date) => _date.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);
}
