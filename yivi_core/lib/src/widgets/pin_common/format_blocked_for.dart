import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

String formatBlockedFor(BuildContext context, Duration blockedFor) {
  if (blockedFor.isNegative) throw UnsupportedError('User cannot be blocked for a negative duration');

  var seconds = blockedFor.inSeconds;
  final days = seconds ~/ Duration.secondsPerDay;
  seconds -= days * Duration.secondsPerDay;
  final hours = seconds ~/ Duration.secondsPerHour;
  seconds -= hours * Duration.secondsPerHour;
  final minutes = seconds ~/ Duration.secondsPerMinute;
  seconds -= minutes * Duration.secondsPerMinute;

  if (days != 0) {
    return FlutterI18n.plural(context, 'pin_common.day.time', days);
  }
  if (hours != 0) {
    return FlutterI18n.plural(context, 'pin_common.hour.time', hours);
  }
  if (minutes != 0) {
    return FlutterI18n.plural(context, 'pin_common.minute.time', minutes);
  }
  return FlutterI18n.plural(context, 'pin_common.second.time', seconds);
}
