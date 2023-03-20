import 'package:flutter/material.dart';

import 'irma_icon_button.dart';

class IrmaCloseButton extends StatelessWidget {
  final Function()? onTap;

  const IrmaCloseButton({
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => IrmaIconButton(
        icon: Icons.close,
        semanticsLabelKey: 'accessibility.close',
        onTap: onTap ?? Navigator.of(context).pop,
      );
}
