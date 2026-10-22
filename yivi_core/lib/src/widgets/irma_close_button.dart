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

  /// Dark glass with a white cross, over a photo or a camera picture.
  final bool dark;

  const IrmaCloseButton({
    super.key,
    this.onTap,
    this.opacity = 1,
    this.dark = false,
  });

  const IrmaCloseButton.filled({
    super.key,
    this.onTap,
    this.opacity = 1,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      semanticsLabel: FlutterI18n.translate(context, "accessibility.close"),
      onTap: onTap ?? Navigator.of(context).pop,
      opacity: opacity,
      dark: dark,
      icon: Icon(
        Icons.close,
        size: 22,
        color: dark ? Colors.white : YiviPalette.of(context).text,
      ),
    );
  }
}
