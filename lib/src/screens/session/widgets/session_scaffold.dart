import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_close_button.dart';

class SessionScaffold extends StatelessWidget {
  final Widget? body, bottomNavigationBar;
  final String appBarTitle;
  final VoidCallback? onDismiss;
  final VoidCallback? onPrevious;

  const SessionScaffold({
    Key? key,
    this.onDismiss,
    this.onPrevious,
    this.bottomNavigationBar,
    this.body,
    required this.appBarTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
      appBar: IrmaAppBar(
        titleTranslationKey: appBarTitle,
        noLeading: onPrevious == null,
        leadingAction: onPrevious,
        actions: [
          if (onDismiss != null)
            Padding(
              padding: EdgeInsets.only(
                right: theme.defaultSpacing,
              ),
              child: IrmaCloseButton(
                onTap: onDismiss,
              ),
            ),
        ],
      ),
    );
  }
}
