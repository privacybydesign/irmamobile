import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaCloseButton extends StatelessWidget {
  final Function()? onTap;

  const IrmaCloseButton({
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        right: theme.defaultSpacing,
        top: theme.defaultSpacing,
      ),
      child: GestureDetector(
        onTap: onTap ?? () => Navigator.of(context).pop(),
        child: CircleAvatar(
          backgroundColor: theme.neutralExtraLight,
          radius: 18,
          child: Icon(
            Icons.close,
            size: 20,
            color: theme.neutral,
          ),
        ),
      ),
    );
  }
}
