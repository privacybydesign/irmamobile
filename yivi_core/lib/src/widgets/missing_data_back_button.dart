import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "missing_data_icon.dart";

const _buttonSize = 48.0;
const _arrowSize = 24.0;

/// The back arrow of the issuance screens while the user collects data for a
/// request, drawn as in the design.
class MissingDataBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const MissingDataBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final goBack = onTap ?? Navigator.of(context).pop;

    return Semantics(
      button: true,
      label: FlutterI18n.translate(context, "ui.go_back"),
      excludeSemantics: true,
      onTap: goBack,
      child: SizedBox.square(
        dimension: _buttonSize,
        child: InkWell(
          key: const Key("irma_app_bar_leading"),
          customBorder: const CircleBorder(),
          onTap: goBack,
          child: Center(
            child: MissingDataIcon(
              size: _arrowSize,
              lines: const [
                [Offset(20, 12), Offset(5, 12)],
                [Offset(11, 5), Offset(4, 12), Offset(11, 19)],
              ],
              strokeWidth: 2,
              color: theme.dark,
            ),
          ),
        ),
      ),
    );
  }
}
