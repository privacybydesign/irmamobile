import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({@required this.headerText});

  final String headerText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Text(
        headerText,
        style: IrmaTheme.of(context).textTheme.display1,
      ),
    );
  }
}
