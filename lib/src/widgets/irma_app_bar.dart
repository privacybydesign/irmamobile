import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';

class IrmaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Text title;
  final Icon icon;
  final void Function() iconAction;
  final void Function() cancel;
  final String iconTooltip;

  const IrmaAppBar(
      {this.title,
      this.icon = const Icon(IrmaIcons.arrowBack, size: 18.0),
      this.iconAction,
      this.iconTooltip,
      this.cancel});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      leading: IconButton(
          icon: icon,
          tooltip: iconTooltip,
          onPressed: () {
            if (cancel != null) {
              cancel();
            }
            if (iconAction == null) {
              Navigator.of(context).pop();
            } else {
              iconAction();
            }
          }),
      title: title,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
