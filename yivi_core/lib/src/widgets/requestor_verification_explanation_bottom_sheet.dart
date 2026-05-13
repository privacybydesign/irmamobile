import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../theme/theme.dart";
import "irma_markdown.dart";

class RequestorVerificationExplanationBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: theme.defaultSpacing,
        right: theme.defaultSpacing,
        top: theme.defaultSpacing,
        bottom: 100,
      ),
      child: IrmaMarkdown(
        FlutterI18n.translate(
          context,
          "disclosure_permission.overview.requestor_verification.bottom_sheet.content_markdown",
        ),
      ),
    );
  }
}
