import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

class CancelButton extends StatelessWidget {
  final String routeName;
  final void Function() cancel;

  const CancelButton({@required this.routeName, this.cancel});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(IrmaIcons.arrowBack),
      iconSize: IrmaTheme.of(context).defaultSpacing * 1.25,
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
