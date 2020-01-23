import 'package:intl/intl.dart';

final _dateFormat = DateFormat.yMMMMd().addPattern(" - ").add_jm();

String formatDate(DateTime date) {
  return _dateFormat.format(date);
}
