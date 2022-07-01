import 'package:flutter/material.dart';

import '../../../widgets/irma_app_bar.dart';

class SessionScaffold extends Scaffold {
  SessionScaffold({
    Key? key,
    Function()? onDismiss,
    Widget? bottomNavigationBar,
    Widget? body,
    required String appBarTitle,
  }) : super(
          key: key,
          appBar: IrmaAppBar(
            titleTranslationKey: appBarTitle,
            leadingAction: onDismiss,
          ),
          bottomNavigationBar: bottomNavigationBar,
          body: body,
        );
}
