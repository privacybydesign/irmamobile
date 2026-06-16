import "package:flutter/material.dart";

import "../theme/theme.dart";

enum IrmaStepIndicatorStyle { filled, outlined, success }

class IrmaStepIndicator extends StatelessWidget {
  final int step;
  final IrmaStepIndicatorStyle style;

  const IrmaStepIndicator({
    super.key,
    required this.step,
    this.style = IrmaStepIndicatorStyle.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // If style is success background is green.
        color: style == IrmaStepIndicatorStyle.success
            ? context.yivi.brand.success
            // If style is outlined background is secondary.
            : style == IrmaStepIndicatorStyle.filled
            ? context.colors.secondary
            // Else background is white.
            : Colors.white,
        border: Border.all(
          color: style == IrmaStepIndicatorStyle.success
              ? context.yivi.brand.success
              : context.colors.secondary,
          width: 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.fitHeight,
        child: style == IrmaStepIndicatorStyle.success
            ? const Icon(Icons.check, color: Colors.white)
            : Text(
                step.toString(),
                textAlign: TextAlign.center,
                style: context.yivi.indicator.circularStep(
                  style == IrmaStepIndicatorStyle.outlined,
                ),
              ),
      ),
    );
  }
}
