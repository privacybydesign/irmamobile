import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "../theme/yivi_palette.dart";

class IrmaBottomBarBase extends StatelessWidget {
  final Widget child;

  const IrmaBottomBarBase({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Floats over the page: the content scrolls underneath and fades out
    // above the bar, as in the design (with `extendBody`). The fade is a
    // fixed band above the content, so a taller bar (a reason above the
    // button) is solid behind everything it shows.
    final palette = YiviPalette.of(context);
    final fade = theme.defaultSpacing * 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.background.withValues(alpha: 0),
                palette.background,
              ],
            ),
          ),
          child: SizedBox(height: fade),
        ),
        ColoredBox(
          color: palette.background,
          child: Padding(
            padding: .only(
              left: theme.defaultSpacing + mediaQuery.padding.left,
              right: theme.defaultSpacing + mediaQuery.padding.right,
              bottom: theme.defaultSpacing + mediaQuery.padding.bottom,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}
