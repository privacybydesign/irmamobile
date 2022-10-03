import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'translated_text.dart';

class BulletList extends StatelessWidget {
  final List<String> translationKeys;

  const BulletList({
    required this.translationKeys,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final textStyle = theme.textTheme.bodyText1;

    return Column(
      children: translationKeys
          .map(
            (translationKey) => Padding(
              padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: textStyle,
                  ),
                  Expanded(
                    child: TranslatedText(
                      translationKey,
                      style: textStyle,
                    ),
                  )
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
