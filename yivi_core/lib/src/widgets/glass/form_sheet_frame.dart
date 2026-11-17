import "dart:math" as math;

import "package:material_ui/material_ui.dart";

import "../../theme/yivi_motion.dart";

/// Where a form sheet sits on a tablet: the most it may take ([size]), and
/// how much of it the keyboard still covers ([covered]).
typedef FormSheetPlace = ({Size size, double covered});

/// Where a form sheet sits on a tablet, and how it comes and goes: in the
/// middle of the safe area, as wide as an iOS form sheet. With
/// [followKeyboard] it rises above the keyboard, as a native form sheet.
/// The sheet itself (its surface and shadow) is [builder]'s.
class FormSheetFrame extends StatelessWidget {
  const FormSheetFrame({
    super.key,
    required this.builder,
    this.followKeyboard = false,
  });

  final Widget Function(BuildContext context, FormSheetPlace place) builder;
  final bool followKeyboard;

  /// The width of a sheet on a tablet: 540, as an iOS form sheet, or less in
  /// a narrow window. One column: under sheetColumnsWidth.
  static double width(double window) => math.min(540.0, window - 48);

  /// The height of a sheet on a tablet: at most 85% of the window, and no
  /// taller than 720 (a native form sheet's proportions; the QR scanner's).
  static double height(double window) => math.min(window * 0.85, 720.0);

  /// How long a form sheet takes to come in, and to go.
  static const duration = Duration(milliseconds: 260);
  static const reverseDuration = Duration(milliseconds: 240);

  /// The easing of [transition].
  static CurvedAnimation curve(Animation<double> animation) => CurvedAnimation(
    parent: animation,
    curve: YiviMotion.ease,
    reverseCurve: Curves.easeIn,
  );

  /// How a form sheet comes in (and goes) on [curved]: it rises a little
  /// and settles while it fades in. The dim fades on its own.
  static Widget transition(Animation<double> curved, Widget child) =>
      FadeTransition(
        opacity: curved,
        child: AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, 48 * (1 - curved.value)),
            child: Transform.scale(
              scale: 0.97 + 0.03 * curved.value,
              child: child,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size.height;
    // In the safe area: clear of a side panel (an unfolded phone held
    // sideways), a notch or the Dynamic Island.
    final safeWidth =
        media.size.width - media.padding.left - media.padding.right;
    final w = width(safeWidth).clamp(0.0, safeWidth);
    final h = height(screen);
    final lowest = (screen - h) / 2;
    var top = lowest;
    var covered = 0.0;
    if (followKeyboard) {
      // With the keyboard up it moves up, centred in the room above the
      // keyboard but no higher than 12 below the safe area. What still
      // falls behind the keyboard, the content ends above.
      final keyboard = media.viewInsets.bottom;
      top = ((screen - keyboard - h) / 2)
          .clamp(math.min(media.padding.top + 12, lowest), lowest)
          .toDouble();
      covered = math.max(0.0, top + h - (screen - keyboard));
    }
    return Padding(
      padding: EdgeInsets.only(
        top: top,
        left: media.padding.left,
        right: media.padding.right,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: w, maxHeight: h),
          child: builder(context, (size: Size(w, h), covered: covered)),
        ),
      ),
    );
  }
}
