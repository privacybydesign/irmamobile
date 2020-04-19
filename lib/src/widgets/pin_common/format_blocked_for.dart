import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

String formatBlockedFor(BuildContext context, Duration blockedFor) {
  var seconds = blockedFor.inSeconds;
  final days = seconds ~/ Duration.secondsPerDay;
  seconds -= days * Duration.secondsPerDay;
  final hours = seconds ~/ Duration.secondsPerHour;
  seconds -= hours * Duration.secondsPerHour;
  final minutes = seconds ~/ Duration.secondsPerMinute;
  seconds -= minutes * Duration.secondsPerMinute;

  String remainingStr;
  if (days != 0) {
    remainingStr = FlutterI18n.plural(context, 'pin_common.day.time', days);
  }
  if (hours != 0 && remainingStr == null) {
    remainingStr = FlutterI18n.plural(context, 'pin_common.hour.time', hours);
  }
  if (minutes != 0 && remainingStr == null) {
    remainingStr = FlutterI18n.plural(context, 'pin_common.minute.time', minutes);
  }
  if (seconds != 0 && remainingStr == null) {
    remainingStr = FlutterI18n.plural(context, 'pin_common.second.time', seconds);
  }

  return remainingStr;
}
