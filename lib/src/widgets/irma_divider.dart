import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_card.dart';

class IrmaDivider extends StatelessWidget {
  final IrmaCardStyle style;

  const IrmaDivider({
    this.style = IrmaCardStyle.normal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
      child: Container(
        height: 1,
        decoration: DottedDecoration(
          dash: style == IrmaCardStyle.template
              //Dotted line
              ? [5, 5]
              //Solid line
              : [1, 0],
          color: style == IrmaCardStyle.highlighted || style == IrmaCardStyle.outlined
              ? theme.themeData.colorScheme.primary
              : Colors.grey.shade300,
        ),
      ),
    );
  }
}
