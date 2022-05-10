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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
      child: Container(
        height: 1,
        decoration: DottedDecoration(
          strokeWidth: 0.5,
          dash: style == IrmaCardStyle.template
              //Dotted line
              ? [5, 5]
              //Solid line
              : [1, 0],
          color: style == IrmaCardStyle.selected
              ? IrmaTheme.of(context).themeData.colorScheme.primary.withOpacity(0.8)
              : Colors.grey.shade300,
        ),
      ),
    );
  }
}
