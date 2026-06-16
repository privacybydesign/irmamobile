import "package:flutter/material.dart";

import "../theme/theme.dart";
import "translated_text.dart";

class BulletList extends StatelessWidget {
  final List<String> translationKeys;
  final Widget? leading;

  const BulletList({required this.translationKeys, this.leading});

  @override
  Widget build(BuildContext context) {
    final textStyle = context.text.bodyLarge;

    return Column(
      children: translationKeys
          .map(
            (translationKey) => Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.yivi.spacing.small,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading != null ? leading! : Text("•  ", style: textStyle),
                  SizedBox(width: context.yivi.spacing.small),
                  Expanded(
                    child: TranslatedText(translationKey, style: textStyle),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
