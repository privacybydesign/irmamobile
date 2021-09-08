// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class EnterPin extends StatelessWidget {
  static const String routeName = 'change_pin/enter_pin';

  final void Function(String) submitOldPin;
  final void Function() cancel;
  final FocusNode pinFocusNode;

  const EnterPin({@required this.pinFocusNode, @required this.submitOldPin, @required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(context, 'change_pin.enter_pin.title'),
        ),
        leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        leadingAction: () async {
          if (cancel != null) {
            cancel();
          }
          if (!await Navigator.of(context).maybePop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).defaultSpacing),
          child: Column(
            children: [
              SizedBox(height: IrmaTheme.of(context).hugeSpacing),
              Text(
                FlutterI18n.translate(context, 'change_pin.enter_pin.instruction'),
                style: IrmaTheme.of(context).textTheme.body1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: IrmaTheme.of(context).mediumSpacing),
              StreamBuilder(
                stream: IrmaPreferences.get().getLongPin(),
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  return PinField(
                    focusNode: pinFocusNode,
                    longPin: snapshot.hasData && snapshot.data,
                    onSubmit: (String pin) {
                      submitOldPin(pin);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
