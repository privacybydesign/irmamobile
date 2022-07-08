import 'package:intl/intl.dart';

String printableDate(DateTime date, String lang) {
  return DateFormat.yMMMMd(lang).format(date);
}
