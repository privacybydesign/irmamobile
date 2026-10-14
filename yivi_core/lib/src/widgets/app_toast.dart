import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "two_pane.dart";

/// Shows [message] as a glass pill above the tab bar for 2.6 seconds, like
/// "You have been logged out". Uses the nearest [ScaffoldMessenger], so it
/// queues with other toasts and is announced by screen readers.
void showAppToast(BuildContext context, String message, {Key? key}) =>
    appToastFor(context)(message, key: key);

/// Looks up what a toast needs from [context] now, for showing one later when
/// [context] may be gone (e.g. after the screen closed itself).
void Function(String message, {Key? key}) appToastFor(BuildContext context) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final palette = YiviPalette.of(context);
  final bottom = bottomBarSpace(context);
  return (message, {key}) => messenger?.showSnackBar(
    SnackBar(
      key: key,
      duration: const Duration(milliseconds: 2600),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.fromLTRB(24, 0, 24, bottom),
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: palette.glassStrongFill,
              shape: StadiumBorder(
                side: BorderSide(color: palette.glassBorder),
              ),
              shadows: [
                BoxShadow(
                  color: palette.glassShadow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: palette
                    .body(14, weight: FontWeight.w600)
                    .copyWith(height: 20 / 14),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
