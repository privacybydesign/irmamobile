import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../widgets/glass/glass_dialog.dart";
import "../../../../widgets/glass/pill_buttons.dart";

/// Says that the two PINs differ. Its one button runs [onPressed] with the
/// dialog's context; there is no other way out.
Future<void> showPinConfirmationFailedDialog(
  BuildContext context, {
  required void Function(BuildContext dialogContext) onPressed,
}) => showDialog(
  barrierDismissible: false,
  context: context,
  builder: (context) => GlassDialog(
    icon: const ToneDisc(icon: Icons.pin_outlined, tone: DialogTone.danger),
    title: FlutterI18n.translate(context, "confirm_pin.error.title"),
    message: FlutterI18n.translate(context, "confirm_pin.error.body"),
    actions: [
      FancyPillButton(
        label: FlutterI18n.translate(context, "confirm_pin.error.action"),
        size: PillSize.regular,
        onPressed: () => onPressed(context),
      ),
    ],
  ),
);
