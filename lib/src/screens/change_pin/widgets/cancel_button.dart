import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/choose_pin.dart';
import 'package:irmamobile/src/theme/irma-icons.dart';

class CancelButton extends StatelessWidget {
  final void Function() cancel;

  CancelButton({this.cancel});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(IrmaIcons.arrowBack),
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
