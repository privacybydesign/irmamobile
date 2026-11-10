import "dart:io";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";

class IrmaAvatar extends StatelessWidget {
  final double size;
  final Widget? logoImage;
  final String? logoPath;
  final String? logoSemanticsLabel;
  final String? initials;

  /// How a logo at [logoPath] fills the room inside [logoPadding].
  final BoxFit? logoFit;

  /// Room around a logo, inside the circle.
  final double logoPadding;

  /// Behind a logo (else the light neutral of the initials).
  final Color? logoBackground;

  const IrmaAvatar({
    this.size = 48,
    this.logoImage,
    this.logoPath,
    this.initials,
    this.logoSemanticsLabel,
    this.logoFit,
    this.logoPadding = 0,
    this.logoBackground,
  }) : assert(
         (logoImage != null || logoPath != null) || initials != null,
         "Provide initials or a logo",
       ),
       assert(
         logoImage == null || logoPath == null,
         "Provide a logoImage or a logoPath, not both",
       );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    Widget? image = logoImage;
    if (logoPath != null) {
      final logoFile = File(logoPath!);

      if (logoFile.existsSync()) {
        image = Image.file(logoFile, fit: logoFit);
      }
    }

    return Semantics(
      excludeSemantics: image == null,
      label: image != null && logoSemanticsLabel != null
          ? FlutterI18n.translate(
              context,
              "disclosure.logo_semantic",
              translationParams: {"otherParty": logoSemanticsLabel!},
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          color: image == null
              ? theme.neutralExtraLight
              : logoBackground ?? theme.neutralExtraLight,
          height: size,
          width: size,
          padding: image == null ? null : EdgeInsets.all(logoPadding),
          child:
              image ??
              Container(
                height: size / 2,
                padding: EdgeInsets.all(theme.smallSpacing),
                child: FittedBox(
                  fit: BoxFit.fitHeight,
                  child: Text(
                    initials!.toUpperCase(),
                    textAlign: TextAlign.center,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                    ),
                    style: TextStyle(
                      color: theme.neutral,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
