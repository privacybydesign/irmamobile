import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

void startDevExperiment4(BuildContext context) {
  // Start this experiment in locked state
  IrmaRepository.get().lock();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        return Stack(children: <Widget>[
          Scaffold(
            appBar: IrmaAppBar(
              title: const Text('App unlocked'),
            ),
            body: Center(
              child: Container(
                color: IrmaTheme.of(context).interactionInformation,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("The app is now unlocked"),
                ),
              ),
            ),
          ),
          PinScreen(
            isEnrolled: true,
          )
        ]);
      },
    ),
  );
}
