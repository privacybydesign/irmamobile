import 'package:flutter/material.dart';

import '../theme/theme.dart';

void showYiviBottomSheet({required BuildContext context, required Widget child}) {
  final theme = IrmaTheme.of(context);
  showModalBottomSheet(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: child),
    ),
  );
}
