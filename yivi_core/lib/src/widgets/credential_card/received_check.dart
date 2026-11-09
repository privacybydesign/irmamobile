import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../corner_badge.dart";

/// The green check on a received or shared card or pile, ringed in the page
/// colour: on the success screens and the done screen.
class ReceivedCheck extends StatelessWidget {
  final double size;

  const ReceivedCheck({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) => CornerBadge(
    icon: Icons.check,
    fill: YiviPalette.successMark,
    size: size,
    iconSize: size * 0.54,
    ring: YiviPalette.of(context).background,
    ringWidth: 4,
  );
}
