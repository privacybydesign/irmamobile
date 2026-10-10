import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "credential_card/yivi_credential_card_header.dart";
import "irma_markdown.dart";
import "yivi_bottom_sheet.dart";

Future<void> showRequestorVerificationSheet(BuildContext context) {
  final theme = IrmaTheme.of(context);
  return showYiviBottomSheet(
    context: context,
    titleKey:
        "disclosure_permission.overview.requestor_verification.bottom_sheet.title",
    titleStyle: credentialNameStyle(
      theme,
      18,
    ).copyWith(fontWeight: FontWeight.w500),
    child: RequestorVerificationExplanationBottomSheet(),
  );
}

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
