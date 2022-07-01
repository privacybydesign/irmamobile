import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaDivider extends StatelessWidget {
  const IrmaDivider();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          color: theme.neutralLight,
        ),
      ),
    );
  }
}
