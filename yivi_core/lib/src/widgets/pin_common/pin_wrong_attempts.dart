import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../glass/glass_dialog.dart";
import "../glass/pill_buttons.dart";
import "../irma_dialog.dart";

class PinWrongAttemptsDialog extends StatelessWidget {
  final void Function() onClose;
  final int attemptsRemaining;

  const PinWrongAttemptsDialog({
    required this.attemptsRemaining,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaDialog(
      icon: const ToneDisc(
        icon: Icons.password_rounded,
        tone: DialogTone.warning,
      ),
      title: FlutterI18n.translate(context, "pin_common.invalid_title"),
      content: FlutterI18n.plural(
        context,
        "pin_common.invalid_pin.attempts",
        attemptsRemaining,
      ),
      child: FancyPillButton(
        label: FlutterI18n.translate(context, "pin_common.invalid_close"),
        size: PillSize.regular,
        onPressed: onClose,
      ),
    );
  }
}
