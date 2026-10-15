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
    // behind the buttons, as in the design (with `extendBody`).
    final palette = YiviPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.background.withValues(alpha: 0), palette.background],
          stops: const [0, 0.45],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: .only(
            left: theme.defaultSpacing + mediaQuery.padding.left,
            right: theme.defaultSpacing + mediaQuery.padding.right,
            // Room for the fade above the buttons.
            top: theme.defaultSpacing * 2,
            bottom: theme.defaultSpacing + mediaQuery.padding.bottom,
          ),
          child: child,
        ),
      ),
    );
  }
}
