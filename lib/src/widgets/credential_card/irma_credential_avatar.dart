import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class IrmaCredentialAvatar extends StatelessWidget {
  final double? size;
  final String? logo;

  const IrmaCredentialAvatar({
    this.size = 40,
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final logoFile = File(logo ?? '');

    return Container(
      height: size,
      width: size,
      padding: EdgeInsets.all(theme.smallSpacing),
      decoration: BoxDecoration(
        color: theme.dark.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.neutralExtraLight,
        ),
      ),
      child: logoFile.existsSync()
          ? SizedBox(
              height: size! / 2,
              child: Image.file(
                logoFile,
                excludeFromSemantics: true,
              ),
            )
          : null,
    );
  }
}
