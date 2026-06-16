import "package:flutter/material.dart";

import "../theme/theme.dart";

class RadioIndicator extends StatelessWidget {
  final bool isSelected;
  final double size;

  const RadioIndicator({this.isSelected = false, this.size = 28});

  Widget _buildInnerCircle({required Color color, required double size}) =>
      Container(
        height: size,
        width: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onSurfaceVariant;

    return Container(
      height: size,
      width: size,
      decoration: isSelected
          // Filled
          ? BoxDecoration(color: color, shape: BoxShape.circle)
          // Outlined
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
      child: Center(
        child: isSelected
            ? _buildInnerCircle(color: Colors.white, size: size * 0.45)
            : null,
      ),
    );
  }
}
