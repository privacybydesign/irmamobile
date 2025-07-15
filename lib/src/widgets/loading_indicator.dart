import 'package:flutter/material.dart';

import '../theme/theme.dart';

class LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      CircularProgressIndicator(color: IrmaTheme.of(context).secondary, strokeWidth: 3.5);
}
