import "package:material_ui/material_ui.dart";

import "../../../widgets/glass/glass_group.dart";

/// A rounded group of [Tile]s with dividers between them; the dividers start
/// after the tiles' icon squares.
class TilesCard extends StatelessWidget {
  final List<Widget> children;

  const TilesCard({required this.children});

  @override
  Widget build(BuildContext context) =>
      GlassGroup(dividerIndent: 68, children: children);
}
