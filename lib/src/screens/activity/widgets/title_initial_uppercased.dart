import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class TitleInitialUpperCased extends StatelessWidget {
  final String title;
  const TitleInitialUpperCased(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return FittedBox(
      fit: BoxFit.fitHeight,
      child: Text(
        title[0].toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.neutralLight,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
