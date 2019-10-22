import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';

class CancelButton extends StatelessWidget {
  final String routeName;
  final void Function() cancel;

  CancelButton({@required this.routeName, this.cancel});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (cancel != null) {
          cancel();
        }
        Navigator.of(context)
            .popUntil((route) => route.settings.name == routeName || route.settings.name == Welcome.routeName);
      },
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }
}
