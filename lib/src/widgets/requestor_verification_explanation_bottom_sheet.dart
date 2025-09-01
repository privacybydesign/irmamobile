import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'irma_bottom_sheet.dart';
import 'irma_markdown.dart';
import 'translated_text.dart';

class RequestorVerificationExplanationBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaBottomSheet(
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TranslatedText(
          'disclosure_permission.overview.requestor_verification.bottom_sheet.title',
          style: theme.textTheme.displaySmall!.copyWith(overflow: TextOverflow.visible, height: 1.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: theme.defaultSpacing, right: theme.defaultSpacing, bottom: 100),
        child: IrmaMarkdown(
          FlutterI18n.translate(
            context,
            'disclosure_permission.overview.requestor_verification.bottom_sheet.content_markdown',
          ),
        ),
      ),
    );
  }
}
