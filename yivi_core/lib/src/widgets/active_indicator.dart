import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

class ActiveIndicator extends StatelessWidget {
  final bool isActive;

  const ActiveIndicator(this.isActive);

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? YiviPalette.successMark
        : YiviPalette.of(context).primary;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
