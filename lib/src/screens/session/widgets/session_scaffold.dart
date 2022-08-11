import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';

class SessionScaffold extends StatelessWidget {
  final Widget? body, bottomNavigationBar;
  final String appBarTitle;

  const SessionScaffold({
    Key? key,
    Function()? onDismiss,
    this.bottomNavigationBar,
    this.body,
    required this.appBarTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return _Scaffold(
      backgroundColor: theme.background,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
      appBarTitle: appBarTitle,
    );
  }
}

class _Scaffold extends Scaffold {
  _Scaffold({
    Function()? onDismiss,
    Widget? bottomNavigationBar,
    Widget? body,
    Color? backgroundColor,
    required String appBarTitle,
  }) : super(
          // Material's ThemeData.primary should take care of this?
          backgroundColor: backgroundColor,
          appBar: IrmaAppBar(
            titleTranslationKey: appBarTitle,
            leadingAction: onDismiss,
          ),
          bottomNavigationBar: bottomNavigationBar,
          body: body,
        );
}
