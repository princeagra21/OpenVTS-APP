import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static String dateTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd MMM yyyy, hh:mm a').format(value.toLocal());
  }

  static String number(num? value) {
    if (value == null) return '-';
    return NumberFormat.decimalPattern().format(value);
  }
}
