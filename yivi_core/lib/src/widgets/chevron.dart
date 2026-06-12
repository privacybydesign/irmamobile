import "package:flutter/material.dart";

import "../theme/theme.dart";

/// Right-pointing chevron with the app's standard size and color.
class Chevron extends StatelessWidget {
  final Color? color;
  final double size;

  const Chevron({super.key, this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Icon(
      Icons.chevron_right,
      size: size,
      color: color ?? theme.neutralDark,
    );
  }
}
