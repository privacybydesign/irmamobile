import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class _EnrollmentProgressIndicatorElement extends StatelessWidget {
  final bool isActive;

  const _EnrollmentProgressIndicatorElement({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    const double size = 8;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? theme.primary : theme.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      height: size,
      width: isActive ? size * 3 : size,
    );
  }
}

class EnrollmentProgressIndicator extends StatelessWidget {
  final int stepIndex;
  final int stepCount;

  const EnrollmentProgressIndicator({
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
          child: _EnrollmentProgressIndicatorElement(
            isActive: index == stepIndex,
          ),
        ),
        growable: false,
      ),
    );
  }
}
