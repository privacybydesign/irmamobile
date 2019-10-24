import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

class RequiredUpdateScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: IrmaTheme.of(context).interactionInvalid,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Update required (UI TODO)"),
          ),
        ),
      ),
    );
  }
}
