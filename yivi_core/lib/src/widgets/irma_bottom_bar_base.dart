import "dart:math";

import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";

/// [flat] is the bar of the e-mail linking screens (`FeatureFlag.emailLinking`):
/// a hairline shadow on top and more room around the buttons.
enum IrmaBottomBarStyle { standard, flat }

// The bottom padding of the flat bar also has to clear the system gesture
// area, so it takes the larger of the two.
const _flatBottomPadding = 32.0;

class IrmaBottomBarBase extends StatelessWidget {
  final Widget child;
  final IrmaBottomBarStyle style;

  const IrmaBottomBarBase({
    required this.child,
    this.style = IrmaBottomBarStyle.standard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mediaQuery = MediaQuery.of(context);

    if (style == IrmaBottomBarStyle.flat) {
      return Container(
        width: mediaQuery.size.width,
        decoration: BoxDecoration(
          color: theme.surfacePrimary,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(0.0, -1.0),
              blurRadius: 6.0,
            ),
          ],
        ),
        padding: .only(
          left: theme.defaultSpacing + mediaQuery.padding.left,
          right: theme.defaultSpacing + mediaQuery.padding.right,
          top: theme.defaultSpacing,
          bottom: max(_flatBottomPadding, mediaQuery.padding.bottom),
        ),
        child: child,
      );
    }

    return Container(
      width: mediaQuery.size.width,
      decoration: BoxDecoration(
        color: theme.surfacePrimary,
        border: const Border(top: BorderSide(color: Colors.white, width: 2.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade600.withAlpha(128),
            blurRadius: 10.0,
            spreadRadius: 1.0,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: .only(
          left: theme.defaultSpacing + mediaQuery.padding.left,
          right: theme.defaultSpacing + mediaQuery.padding.right,
          top: theme.smallSpacing,
          bottom: theme.smallSpacing + mediaQuery.padding.bottom,
        ),
        child: child,
      ),
    );
  }
}
