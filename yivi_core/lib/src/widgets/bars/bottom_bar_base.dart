import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "floating_bar_placement.dart";

class BottomBarBase extends StatelessWidget {
  final Widget child;

  /// The lowest button is a plain text one, which sits lower (see
  /// [FloatingBarPlacement.buttonBottom]).
  final bool endsWithTextButton;

  const BottomBarBase({required this.child, this.endsWithTextButton = false});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    // Floats over the page: the content scrolls underneath and fades out
    // above the bar, as in the design (with `extendBody`). The fade is a
    // fixed band above the content, so a taller bar (a reason above the
    // button) is solid behind everything it shows.
    final palette = YiviPalette.of(context);
    const fade = YiviSpace.x16 * 2;
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
          child: const SizedBox(height: fade),
        ),
        ColoredBox(
          color: palette.background,
          child: Padding(
            padding: .only(
              left: YiviSpace.x16 + padding.left,
              right: YiviSpace.x16 + padding.right,
              // The same place on every screen (see buttonBottom).
              bottom: FloatingBarPlacement.buttonPadding(
                context,
                text: endsWithTextButton,
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}
