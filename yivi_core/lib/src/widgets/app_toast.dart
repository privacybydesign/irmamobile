import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "centred_max_width.dart";
import "glass/glass_surface.dart";
import "two_pane.dart";

/// Shows [message] as a glass pill for 2.6 seconds, like "You have been
/// logged out": just above the bottom of the screen, or above the tab bar
/// when it lands on a tab ([overTabBar]). Uses the nearest
/// [ScaffoldMessenger], so it queues with other toasts and is announced by
/// screen readers.
///
/// [atTop]: under the status bar instead, for a screen whose bottom is full
/// (the PIN screen, with its keypad and link).
///
/// [action]: a link at its end, such as "Undo"; the toast then stays longer.
void showAppToast(
  BuildContext context,
  String message, {
  Key? key,
  bool overTabBar = false,
  bool atTop = false,
  ToastAction? action,
}) => appToastFor(context, overTabBar: overTabBar, atTop: atTop)(
  message,
  key: key,
  action: action,
);

/// A link at the end of a toast: its [label], and what a tap does.
typedef ToastAction = ({String label, VoidCallback onTap});

/// Looks up what a toast needs from [context] now, for showing one later when
/// [context] may be gone (e.g. after the screen closed itself).
void Function(String message, {Key? key, ToastAction? action}) appToastFor(
  BuildContext context, {
  bool overTabBar = false,
  bool atTop = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final palette = YiviPalette.of(context);
  // Clear of the floating tab bar where there is one; otherwise just above
  // the bottom of the safe area (a floating snack bar already keeps out of
  // it).
  // At the top: a floating snack bar is placed from the bottom, so from
  // there it is the screen less the status bar, a gap and its own height.
  final media = MediaQuery.of(context);
  final bottom = atTop
      ? media.size.height -
            media.padding.top -
            media.padding.bottom -
            8 -
            _toastHeight
      : overTabBar
      ? bottomBarSpace(context)
      : 16.0;
  return (message, {key, action}) => messenger?.showSnackBar(
    SnackBar(
      key: key,
      duration: Duration(milliseconds: action == null ? 2600 : 5000),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.fromLTRB(24, 0, 24, bottom),
      content: CentredMaxWidth(
        maxWidth: 440,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: palette.glassStrongFill,
            // Dark: lit from above like the glass, no rim.
            shape: StadiumBorder(
              side: palette.isDark
                  ? BorderSide.none
                  : BorderSide(color: palette.glassBorder),
            ),
            shadows: [
              BoxShadow(
                color: palette.glassShadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipPath(
            clipper: const ShapeBorderClipper(shape: StadiumBorder()),
            child: CustomPaint(
              foregroundPainter: palette.isDark
                  ? GlassLitEdge(shape: const StadiumBorder())
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: _Message(
                  message: message,
                  action: action,
                  messenger: messenger,
                  palette: palette,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A one-line toast: 20 pt of text and 12 above and below it.
const _toastHeight = 44.0;

/// The toast's text, and its [action] after it when it has one.
class _Message extends StatelessWidget {
  final String message;
  final ToastAction? action;
  final ScaffoldMessengerState? messenger;
  final YiviPalette palette;

  const _Message({
    required this.message,
    required this.action,
    required this.messenger,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final style = palette
        .body(14, weight: FontWeight.w600)
        .copyWith(height: 20 / 14);
    final text = Text(message, textAlign: TextAlign.center, style: style);
    final action = this.action;
    if (action == null) return text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 16,
      children: [
        Flexible(child: text),
        Semantics(
          button: true,
          child: GestureDetector(
            key: const Key("toast_action"),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              messenger?.hideCurrentSnackBar();
              action.onTap();
            },
            child: PressScale(
              child: Text(
                action.label,
                style: style.copyWith(color: palette.link),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
