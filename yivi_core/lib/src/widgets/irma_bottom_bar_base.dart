import "package:flutter/material.dart";

import "../theme/theme.dart";

class IrmaBottomBarBase extends StatelessWidget {
  final Widget child;

  const IrmaBottomBarBase({required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      width: mediaQuery.size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Colors.white, width: 2.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade600.withAlpha(128),
            blurRadius: 10.0,
            spreadRadius: 1.0,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: .only(
          left: context.yivi.defaultSpacing + mediaQuery.padding.left,
          right: context.yivi.defaultSpacing + mediaQuery.padding.right,
          top: context.yivi.smallSpacing,
          bottom: context.yivi.smallSpacing + mediaQuery.padding.bottom,
        ),
        child: child,
      ),
    );
  }
}
