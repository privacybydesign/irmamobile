import 'package:flutter/material.dart';

import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/translated_text.dart';

class SessionScaffold extends Scaffold {
  SessionScaffold({
    Key? key,
    Function()? onDismiss,
    Widget? bottomNavigationBar,
    Widget? body,
    String? appBarTitle,
    TextStyle? appBarTitleStyle,
  }) : super(
          key: key,
          appBar: IrmaAppBar(
            title: TranslatedText(
              appBarTitle,
              style: appBarTitleStyle,
            ),
            leadingAction: onDismiss,
          ),
          bottomNavigationBar: bottomNavigationBar,
          body: body,
        );
}
