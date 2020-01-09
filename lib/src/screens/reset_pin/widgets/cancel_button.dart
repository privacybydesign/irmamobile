import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';

class CancelButton extends StatelessWidget {
  final void Function(BuildContext) cancel;

  CancelButton({@required this.cancel});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(IrmaIcons.arrowBack),
      onPressed: () {
        cancel(context);
      },
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
