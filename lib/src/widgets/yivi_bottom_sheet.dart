import 'package:flutter/material.dart';

import '../theme/theme.dart';

void showYiviBottomSheet({required BuildContext context, required Widget child}) {
  final theme = IrmaTheme.of(context);
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    ),
  );
}
