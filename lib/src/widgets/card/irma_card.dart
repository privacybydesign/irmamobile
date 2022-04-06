import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class IrmaCard extends StatelessWidget {
  final Function()? onTap;
  final Widget? child;

  const IrmaCard({Key? key, this.onTap, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: theme.smallSpacing,
              horizontal: theme.smallSpacing + theme.tinySpacing,
            ),
            child: child,
          ),
        ));
  }
}
