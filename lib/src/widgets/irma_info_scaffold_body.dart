import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'translated_text.dart';

class IrmaInfoScaffoldBody extends StatelessWidget {
  final String? titleKey;
  final String? bodyKey;
  final TranslatedText? title;
  final TranslatedText? body;
  final IconData? icon;
  final Color? iconColor;

  const IrmaInfoScaffoldBody({
    Key? key,
    this.titleKey,
    this.bodyKey,
    this.icon,
    this.iconColor,
    this.title,
    this.body,
  })  : assert(
          iconColor == null || icon != null,
          'Icon color can only be used when an icon is provided',
        ),
        assert(titleKey != null || title != null, 'The title must be set either with the key or the translation'),
        assert(bodyKey != null || body != null, 'The body must be set either with the key or the translation'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    TranslatedText? actualTitle;
    TranslatedText? actualBody;

    if (titleKey != null) {
      actualTitle = TranslatedText(
        titleKey!,
        style: theme.textTheme.headline1,
        textAlign: TextAlign.center,
      );
    }

    if (title != null) {
      actualTitle = title;
    }

    if (bodyKey != null) {
      actualBody = TranslatedText(
        bodyKey!,
        style: theme.textTheme.bodyText2,
        textAlign: TextAlign.center,
      );
    }

    if (body != null) {
      actualBody = body;
    }

    return Center(
        child: SingleChildScrollView(
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
          actualTitle!,
          SizedBox(height: theme.mediumSpacing),
          actualBody!
        ],
      ),
    ));
  }
}
