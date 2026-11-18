import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";

/// The app's one spinner. Its stroke follows its size, so a small one on a
/// button and a large one on a page look the same.
class Spinner extends StatelessWidget {
  /// The spinner's side; null fills the box it is given, 36 when unbounded.
  final double? size;

  /// The theme's progress colour unless given.
  final Color? color;

  /// A faint ring behind the arc, for a spinner that stands alone.
  final bool track;

  const Spinner({super.key, this.size, this.color, this.track = false});

  /// White, for on a filled pill button.
  const Spinner.onButton({super.key, this.size = 18})
    : color = const Color(0xFFFFFFFF),
      track = false;

  /// The stroke for a spinner [size] wide.
  static double strokeFor(double size) => size < 16
      ? 2
      : size < 24
      ? 3
      : 3.5;

  @override
  Widget build(BuildContext context) {
    final spinner = CircularProgressIndicator(
      strokeWidth: strokeFor(size ?? 36),
      color: color,
      backgroundColor: track ? YiviPalette.of(context).outline : null,
    );
    final side = size;
    return side == null
        ? spinner
        : SizedBox.square(dimension: side, child: spinner);
  }
}
