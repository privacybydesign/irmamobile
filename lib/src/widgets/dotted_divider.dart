import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

class DottedDivider extends StatelessWidget {
  final Color? color;

  const DottedDivider({this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
      child: Container(
        height: 1,
        decoration: DottedDecoration(color: color ?? Colors.grey.shade300),
      ),
    );
  }
}
