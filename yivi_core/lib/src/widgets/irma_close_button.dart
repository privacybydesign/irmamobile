import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "glass/glass_surface.dart";

/// The round glass close button. [IrmaCloseButton.filled] is the same button;
/// it stays for the call sites that asked for the filled look before every
/// close button became glass.
class IrmaCloseButton extends StatelessWidget {
  final Function()? onTap;

  /// Fades the button with its page; see [GlassSurface.opacity].
  final double opacity;

  const IrmaCloseButton({super.key, this.onTap, this.opacity = 1});

  const IrmaCloseButton.filled({super.key, this.onTap, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      semanticsLabel: FlutterI18n.translate(context, "accessibility.close"),
      onTap: onTap ?? Navigator.of(context).pop,
      opacity: opacity,
      icon: Icon(Icons.close, size: 22, color: YiviPalette.of(context).text),
    );
  }
}
