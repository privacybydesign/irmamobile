import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaAvatar extends StatelessWidget {
  final double? size;
  final Image? logoImage;
  final String? logoPath;
  final String? initials;

  const IrmaAvatar({
    this.size = 48,
    this.logoImage,
    this.logoPath,
    this.initials,
  })  : assert(
          (logoImage != null || logoPath != null) || initials != null,
          'Provide initials or a logo',
        ),
        assert(
          logoImage == null || logoPath == null,
          'Provide a logoImage or a logoPath, not both',
        );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    Image? image = logoImage;
    if (logoPath != null) {
      final logoFile = File(logoPath!);
      image = Image.file(logoFile);
    }

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
      child: SizedBox(
        height: size! / 2,
        child: image ??
            FittedBox(
              fit: BoxFit.fitHeight,
              child: Text(
                initials!.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.neutral,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      ),
    );
  }
}
