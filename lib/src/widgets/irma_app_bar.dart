import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';

class IrmaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Text title;
  final Icon leadingIcon;
  final void Function() leadingAction;
  final void Function() leadingCancel;
  final String leadingTooltip;
  final List<Widget> actions;

  const IrmaAppBar(
      {this.title,
      this.leadingIcon = const Icon(IrmaIcons.arrowBack, size: 18.0),
      this.leadingAction,
      this.leadingTooltip,
      this.leadingCancel,
      this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      leading: IconButton(
          icon: leadingIcon,
          tooltip: leadingTooltip,
          onPressed: () {
            if (leadingCancel != null) {
              leadingCancel();
            }
            if (leadingAction == null) {
              Navigator.of(context).pop();
            } else {
              leadingAction();
            }
          }),
      title: title,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
