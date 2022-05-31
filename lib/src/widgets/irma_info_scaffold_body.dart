import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'translated_text.dart';

class IrmaInfoScaffoldBody extends StatelessWidget {
  final String titleKey;
  final String bodyKey;
  final IconData? icon;
  final Color? iconColor;

  const IrmaInfoScaffoldBody({
    Key? key,
    required this.titleKey,
    required this.bodyKey,
    this.icon,
    this.iconColor,
  })  : assert(
          iconColor == null || icon != null,
          'Icon color can only be used when an icon is provided',
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Center(
        child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(theme.largeSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? theme.themeData.colorScheme.primary,
                size: 125,
              ),
              SizedBox(height: theme.mediumSpacing),
            ],
            TranslatedText(
              titleKey,
              style: theme.textTheme.headline1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: theme.mediumSpacing),
            TranslatedText(
              bodyKey,
              style: theme.textTheme.bodyText2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ));
  }
}
