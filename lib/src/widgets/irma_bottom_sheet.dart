import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_close_button.dart';

class IrmaBottomSheet extends StatelessWidget {
  final Widget child;
  final Widget? title;

  const IrmaBottomSheet({
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: CustomScrollView(
        slivers: [
          PinnedHeaderSliver(
            child: Container(
              decoration: BoxDecoration(
                color: theme.backgroundPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
                    child: title ?? Container(),
                  ),
                  IrmaCloseButton(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: child),
        ],
      ),
    );
  }
}
