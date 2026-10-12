import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "irma_app_bar.dart";

/// Back arrow of the e-mail linking screens (`FeatureFlag.emailLinking`): black,
/// and read as "Terug".
class LinkingBackButton extends StatelessWidget {
  final Function()? onTap;

  const LinkingBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return YiviBackButton(
      onTap: onTap,
      color: IrmaTheme.of(context).dark,
      semanticsLabelKey: "email_linking.go_back",
    );
  }
}
