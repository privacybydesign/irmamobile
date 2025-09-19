import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaBottomBarBase extends StatelessWidget {
  final Widget child;

  const IrmaBottomBarBase({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      width: mediaQuery.size.width,
      decoration: BoxDecoration(
        color: theme.surfacePrimary,
        border: const Border(
          top: BorderSide(
            color: Colors.white,
            width: 2.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade600.withAlpha(128),
            blurRadius: 10.0,
            spreadRadius: 1.0,
            offset: const Offset(0, 7),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: theme.smallSpacing,
            horizontal: theme.defaultSpacing,
          ),
          child: child,
        ),
      ),
    );
  }
}
