import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaLinearProgressIndicator extends StatelessWidget {
  final double filledPercentage;

  const IrmaLinearProgressIndicator({
    this.filledPercentage = 0,
  }) : assert(filledPercentage <= 100);

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: filledPercentage / 100,
                color: IrmaTheme.of(context).success,
                backgroundColor: Colors.grey.shade300,
              ),
            )
          ],
        ),
      );
}
