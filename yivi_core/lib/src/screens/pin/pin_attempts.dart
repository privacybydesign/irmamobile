import "package:material_ui/material_ui.dart";

import "../../util/i18n.dart";
import "yivi_pin_screen.dart";

/// "Try again in 4:58": how long a block still lasts, as a clock under an
/// hour and in words above.
String pinTryAgainIn(BuildContext context, Duration left) {
  final String time;
  if (left.inHours >= 1) {
    time = left.inDays >= 1
        ? context.plural("pin_common.day.time", left.inDays)
        : context.plural("pin_common.hour.time", left.inHours);
  } else {
    final seconds = left.inSeconds.remainder(60).toString().padLeft(2, "0");
    time = "${left.inMinutes}:$seconds";
  }
  return context.tr("pin.try_again_in", {"time": time});
}

/// What the line under the title says after a wrong PIN or during a block:
/// how long until the next try, or the tries [left] after a [wrong] PIN.
/// Null when neither.
String? pinAttemptLine(
  BuildContext context, {
  Duration blockedFor = Duration.zero,
  required bool wrong,
  int? left,
}) {
  if (blockedFor.inSeconds > 0) return pinTryAgainIn(context, blockedFor);
  if (wrong && left != null && left > 0) {
    return context.plural("pin.wrong.attempts", left);
  }
  return null;
}

/// What the PIN screen shows about the attempts: the line under the title
/// ([pinAttemptLine]) as an error, with a clock while [blocked], and the
/// dots red after a wrong PIN.
class PinAttempts {
  final String? line;
  final bool blocked;

  PinAttempts.of(
    BuildContext context, {
    required Duration blockedFor,
    required this.blocked,
    required bool wrong,
    int? left,
  }) : line = pinAttemptLine(
         context,
         blockedFor: blockedFor,
         wrong: wrong,
         left: left,
       );

  PinDetailKind get detailKind =>
      line == null ? PinDetailKind.info : PinDetailKind.error;

  bool get pinError => line != null && !blocked;
}

/// A [YiviPinScreen.listener] that submits a short PIN as soon as all its
/// digits are in (a long one has a button), while [enabled].
void Function(BuildContext, EnterPinState) submitWhenFull(
  int maxPinSize,
  void Function(String pin) submit, {
  bool enabled = true,
}) => (context, state) {
  if (maxPinSize == shortPinSize && state.pin.length == maxPinSize && enabled) {
    submit(state.toString());
  }
};
