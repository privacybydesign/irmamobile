// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/heading.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({@required this.headerText});

  final String headerText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Heading(
        headerText,
        style: IrmaTheme.of(context).textTheme.display1,
      ),
    );
  }
}
