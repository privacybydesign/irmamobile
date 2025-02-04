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
      title: TranslatedText(
        'disclosure_permission.overview.requestor_verification.bottom_sheet.title',
        style: theme.textTheme.displaySmall,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
        child: IrmaMarkdown(
          FlutterI18n.translate(
              context, 'disclosure_permission.overview.requestor_verification.bottom_sheet.content_markdown'),
        ),
      ),
    );
  }
}
