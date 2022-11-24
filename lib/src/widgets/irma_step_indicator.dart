import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum IrmaStepIndicatorStyle {
  filled,
  outlined,
  success,
}

class IrmaStepIndicator extends StatelessWidget {
  final int step;
  final IrmaStepIndicatorStyle style;

  const IrmaStepIndicator({
    Key? key,
    required this.step,
    this.style = IrmaStepIndicatorStyle.filled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // If style is success background is green.
        color: style == IrmaStepIndicatorStyle.success
            ? theme.success
            // If style is outlined background is secondary.
            : style == IrmaStepIndicatorStyle.filled
                ? theme.themeData.colorScheme.secondary
                // Else background is white.
                : Colors.white,
        border: Border.all(
          color: style == IrmaStepIndicatorStyle.success ? theme.success : theme.themeData.colorScheme.secondary,
          width: 2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.fitHeight,
        child: style == IrmaStepIndicatorStyle.success
            ? const Icon(
                Icons.check,
                color: Colors.white,
              )
            : Text(
                step.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.caption!.copyWith(
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                  color:
                      style == IrmaStepIndicatorStyle.outlined ? theme.themeData.colorScheme.secondary : Colors.white,
                ),
              ),
      ),
    );
  }
}
