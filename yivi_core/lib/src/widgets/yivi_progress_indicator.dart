import "package:flutter/material.dart";

import "../theme/theme.dart";

class _YiviProgressIndicatorElement extends StatelessWidget {
  final bool isActive;

  const _YiviProgressIndicatorElement({required this.isActive});

  @override
  Widget build(BuildContext context) {
    const double size = 8;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? context.colors.primary : context.colors.tertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      height: size,
      width: isActive ? size * 3 : size,
    );
  }
}

class YiviProgressIndicator extends StatelessWidget {
  final int stepIndex;
  final int stepCount;

  const YiviProgressIndicator({
    required this.stepIndex,
    required this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        stepCount,
        (int index) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _YiviProgressIndicatorElement(isActive: index == stepIndex),
        ),
        growable: false,
      ),
    );
  }
}
