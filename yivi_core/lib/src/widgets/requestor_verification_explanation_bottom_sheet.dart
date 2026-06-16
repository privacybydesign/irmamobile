import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../theme/theme.dart";
import "irma_markdown.dart";

class RequestorVerificationExplanationBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: context.yivi.spacing.base,
        right: context.yivi.spacing.base,
        top: context.yivi.spacing.base,
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
