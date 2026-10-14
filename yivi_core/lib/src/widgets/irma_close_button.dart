import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "glass/glass_surface.dart";
import "irma_icon_button.dart";

class IrmaCloseButton extends StatelessWidget {
  final Function()? onTap;
  final bool _filled;

  const IrmaCloseButton({this.onTap}) : _filled = false;

  const IrmaCloseButton.filled({this.onTap}) : _filled = true;

  @override
  Widget build(BuildContext context) {
    if (!_filled) {
      return IrmaIconButton(
        icon: Icons.close,
        semanticsLabelKey: "accessibility.close",
        onTap: onTap ?? Navigator.of(context).pop,
      );
    }

    return GlassIconButton(
      semanticsLabel: FlutterI18n.translate(context, "accessibility.close"),
      onTap: onTap ?? Navigator.of(context).pop,
      icon: Icon(Icons.close, size: 22, color: YiviPalette.of(context).text),
    );
  }
}
