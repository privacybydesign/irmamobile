import 'package:flutter/material.dart';

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
        Navigator.of(context, rootNavigator: true).pushReplacementNamed('/');
      },
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }
}
