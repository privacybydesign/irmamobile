import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "glass/round_icon_button.dart";

/// The round close button ([RoundIconButton]).
class IrmaCloseButton extends StatelessWidget {
  final Function()? onTap;

  /// Fades the button with its page.
  final double opacity;

  /// The cross's colour without a disc (white over a photo's dark band).
  final Color? color;

  const IrmaCloseButton({super.key, this.onTap, this.opacity = 1, this.color});

  @override
  Widget build(BuildContext context) {
    return RoundIconButton(
      label: FlutterI18n.translate(context, "accessibility.close"),
      onTap: onTap ?? Navigator.of(context).pop,
      opacity: opacity,
      iconColor: color,
      icon: CupertinoIcons.xmark,
    );
  }
}
