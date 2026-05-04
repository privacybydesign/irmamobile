import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../theme/theme.dart";
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

    final theme = IrmaTheme.of(context);
    final effectiveOnTap = onTap ?? Navigator.of(context).pop;
    const size = 44.0;

    return Semantics(
      button: true,
      label: FlutterI18n.translate(context, "accessibility.close"),
      child: Material(
        color: theme.neutralExtraLight,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: effectiveOnTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              Icons.close,
              size: 24,
              color: theme.neutralExtraDark,
            ),
          ),
        ),
      ),
    );
  }
}
