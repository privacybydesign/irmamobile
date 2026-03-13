import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../../../package_name.dart";
import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";
import "dynamic_layout.dart";
import "session_scaffold.dart";

class DisclosurePermissionIntroductionScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  const DisclosurePermissionIntroductionScreen({
    super.key,
    required this.onContinue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SessionScaffold(
      appBarTitle: "disclosure_permission.introduction.title",
      onDismiss: onDismiss,
      body: DynamicLayout(
        hero: SvgPicture.asset(yiviAsset("disclosure/disclosure_intro.svg")),
        content: Column(
          children: [
            TranslatedText(
              "disclosure_permission.introduction.header",
              style: theme.themeData.textTheme.displaySmall!.copyWith(
                color: theme.dark,
              ),
            ),
            SizedBox(height: theme.tinySpacing),
            TranslatedText(
              "disclosure_permission.introduction.explanation",
              style: theme.themeData.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          YiviThemedButton(
            label: "disclosure_permission.introduction.continue",
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
