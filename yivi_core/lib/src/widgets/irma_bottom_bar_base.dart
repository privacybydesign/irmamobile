import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";

class IrmaBottomBarBase extends StatelessWidget {
  final Widget child;

  const IrmaBottomBarBase({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return SizedBox(
      width: mediaQuery.size.width,
      child: Padding(
        padding: .only(
          left: theme.defaultSpacing + mediaQuery.padding.left,
          right: theme.defaultSpacing + mediaQuery.padding.right,
          top: theme.defaultSpacing,
          bottom: theme.defaultSpacing + mediaQuery.padding.bottom,
        ),
        child: child,
      ),
    );
  }
}
