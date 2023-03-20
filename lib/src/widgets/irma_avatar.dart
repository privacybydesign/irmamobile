import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';

class IrmaAvatar extends StatelessWidget {
  final double? size;
  final Image? logoImage;
  final String? logoPath;
  final String? logoSemanticsLabel;
  final String? initials;

  const IrmaAvatar({
    this.size = 48,
    this.logoImage,
    this.logoPath,
    this.initials,
    this.logoSemanticsLabel,
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

      if (logoFile.existsSync()) {
        image = Image.file(logoFile);
      }
    }

    return Semantics(
      excludeSemantics: image == null,
      label: image != null && logoSemanticsLabel != null
          ? FlutterI18n.translate(context, 'disclosure.logo_semantic',
              translationParams: {'otherParty': logoSemanticsLabel!})
          : null,
      child: Container(
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
      ),
    );
  }
}
