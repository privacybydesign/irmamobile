// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';

class CancelButton extends StatelessWidget {
  final void Function(BuildContext) cancel;

  const CancelButton({@required this.cancel});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        IrmaIcons.arrowBack,
        semanticLabel: FlutterI18n.translate(context, "accessibility.back"),
      ),
      onPressed: () {
        cancel(context);
      },
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
