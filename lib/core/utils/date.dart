import 'package:intl/intl.dart';

String formatDate(DateTime value, {String pattern = 'yyyy-MM-dd'}) {
  return DateFormat(pattern).format(value);
}

String formatDateTime(DateTime value, {String pattern = 'dd MMM yyyy, hh:mm a'}) {
  return DateFormat(pattern).format(value);
}
