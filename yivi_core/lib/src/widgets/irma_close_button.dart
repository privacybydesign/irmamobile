import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "glass/round_icon_button.dart";

/// The round close button ([RoundIconButton]). [IrmaCloseButton.filled] is
/// the same button; it stays for the call sites that asked for the filled
/// look before every close button became one.
class IrmaCloseButton extends StatelessWidget {
  final Function()? onTap;

  /// Fades the button with its page.
  final double opacity;

  /// Dark with a white cross, over a photo or a camera picture.
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
    return RoundIconButton(
      label: FlutterI18n.translate(context, "accessibility.close"),
      onTap: onTap ?? Navigator.of(context).pop,
      opacity: opacity,
      dark: dark,
      icon: CupertinoIcons.xmark,
    );
  }
}
