import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card_header.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";

/// Footer of a share-screen card that is part of a choice: who certified the
/// data, and the "Switch" button that opens the options.
class ChoiceCardFooter extends StatelessWidget {
  final String issuerName;
  final VoidCallback? onSwitch;

  const ChoiceCardFooter({super.key, required this.issuerName, this.onSwitch});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Row(
      children: [
        Expanded(
          child: TranslatedText(
            "disclosure_permission.choice.certified_by",
            translationParams: {"issuer": issuerName},
            style: issuerLabelStyle(theme),
          ),
        ),
        if (onSwitch != null) ...[
          SizedBox(width: theme.smallSpacing),
          YiviThemedButton(
            key: const Key("choice_switch_button"),
            label: "disclosure_permission.choice.switch",
            style: YiviButtonStyle.outlined,
            size: YiviButtonSize.small,
            isTransparent: true,
            onPressed: onSwitch,
          ),
        ],
      ],
    );
  }
}
