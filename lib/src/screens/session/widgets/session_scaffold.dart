// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class SessionScaffold extends Scaffold {
  SessionScaffold({
    Key key,
    @required Function() onDismiss,
    Widget bottomNavigationBar,
    Widget body,
    @required String appBarTitle,
  }) : super(
          key: key,
          appBar: IrmaAppBar(
            title: TranslatedText(appBarTitle),
            leadingAction: onDismiss,
          ),
          bottomNavigationBar: bottomNavigationBar,
          body: body,
        );
}
