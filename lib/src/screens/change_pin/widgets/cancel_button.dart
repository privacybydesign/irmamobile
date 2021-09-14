// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';

class CancelButton extends StatelessWidget {
  final void Function() cancel;

  const CancelButton({this.cancel});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(IrmaIcons.arrowBack, semanticLabel: FlutterI18n.translate(context, "accessibility.back")),
      iconSize: 20.0,
      onPressed: () async {
        if (cancel != null) {
          cancel();
        }
        if (!await Navigator.of(context).maybePop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }
}
