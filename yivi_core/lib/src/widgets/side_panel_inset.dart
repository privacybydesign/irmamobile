import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

/// Lays the whole app out beside a panel down the side of the screen, as the
/// control bar of an iPhone Duo held upright (84 pt at the right).
///
/// The app's upright layouts keep 16 from the screen's sides and nothing
/// more, as an upright phone has no inset there; beside such a panel their
/// buttons and rows (the + at the search field, the rows of a list) would sit
/// under it, where they can't be pressed. So when the window is upright and
/// has an inset at a side, everything below gets the room beside it, as if
/// the screen ended there, and the strip under the panel shows the page's
/// background. On a phone without one (every upright iPhone) this does
/// nothing.
///
/// Held sideways, the layouts place themselves in the safe area (an iPhone's
/// Dynamic Island is in the side inset then), so it leaves those alone.
class SidePanelInset extends StatelessWidget {
  final Widget child;

  const SidePanelInset({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final padding = media.padding;
    final upright = media.size.width < media.size.height;
    if (!upright || (padding.left == 0 && padding.right == 0)) return child;

    final sides = EdgeInsets.only(left: padding.left, right: padding.right);
    return ColoredBox(
      color: YiviPalette.of(context).background,
      child: Padding(
        padding: sides,
        child: MediaQuery(
          data: media.copyWith(
            size: Size(media.size.width - sides.horizontal, media.size.height),
            padding: padding.copyWith(left: 0, right: 0),
            viewPadding: media.viewPadding.copyWith(left: 0, right: 0),
            viewInsets: media.viewInsets.copyWith(left: 0, right: 0),
          ),
          child: child,
        ),
      ),
    );
  }
}
