import "package:flutter/material.dart";

import "../theme/theme.dart";

class ActiveIndicator extends StatelessWidget {
  final bool isActive;

  const ActiveIndicator(this.isActive);

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? context.yivi.brand.success
        : context.colors.primary;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
