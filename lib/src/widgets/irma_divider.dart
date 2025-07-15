import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaDivider extends StatelessWidget {
  final Color? color;

  const IrmaDivider({this.color});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(height: 1, color: color ?? theme.neutralExtraLight);
  }
}
