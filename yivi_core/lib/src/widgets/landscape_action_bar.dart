import "package:material_ui/material_ui.dart";

import "glass/floating_bar_placement.dart";

/// The button at the bottom of a result screen on a phone held sideways:
/// at the right, [width] wide, as low as on every other screen, without the
/// fade across the screen (nothing scrolls under it there).
class LandscapeActionBar extends StatelessWidget {
  final Widget child;
  final double width;

  const LandscapeActionBar({super.key, required this.child, this.width = 320});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16 + padding.left,
        12,
        16 + padding.right,
        FloatingBarPlacement.buttonBottom(context),
      ),
      // Only as high as the button: the bar slot would let it take the page.
      child: Align(
        heightFactor: 1,
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(width: width, child: child),
      ),
    );
  }
}
