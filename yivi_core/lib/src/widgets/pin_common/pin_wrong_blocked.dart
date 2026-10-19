import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../glass/glass_dialog.dart";
import "../glass/pill_buttons.dart";
import "../irma_dialog.dart";
import "format_blocked_for.dart";

class PinWrongBlockedDialog extends StatelessWidget {
  final void Function()? onClose;
  final int blocked;

  const PinWrongBlockedDialog({required this.blocked, this.onClose})
    : assert(blocked > 0);

  @override
  Widget build(BuildContext context) {
    final blockedForStr = formatBlockedFor(context, Duration(seconds: blocked));

    return IrmaDialog(
      icon: const ToneDisc(icon: Icons.lock_clock, tone: DialogTone.danger),
      title: FlutterI18n.translate(context, "pin_common.blocked_title"),
      content: FlutterI18n.translate(
        context,
        "pin_common.blocked_pin",
        translationParams: {"blocked": blockedForStr},
      ),
      child: FancyPillButton(
        label: FlutterI18n.translate(context, "pin_common.blocked_close"),
        size: PillSize.regular,
        onPressed: onClose ?? () => Navigator.of(context).pop(),
      ),
    );
  }
}
