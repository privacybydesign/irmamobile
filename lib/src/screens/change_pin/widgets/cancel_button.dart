import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';

class CancelButton extends StatelessWidget {
  final void Function() cancel;

  CancelButton({this.cancel});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (cancel != null) {
          cancel();
        }
        Navigator.of(context, rootNavigator: true).pushReplacementNamed(SettingsScreen.routeName);
      },
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }
}
