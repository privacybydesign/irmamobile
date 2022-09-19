import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_close_button.dart';

class IrmaBottomSheet extends StatelessWidget {
  final Widget child;

  const IrmaBottomSheet({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Stack(
          children: [
            //Close button
            const Align(
              alignment: Alignment.topRight,
              child: IrmaCloseButton(),
            ),
            // Actual content
            Padding(
              padding: EdgeInsets.all(theme.mediumSpacing),
              child: child,
            )
          ],
        ),
      ),
    );
  }
}