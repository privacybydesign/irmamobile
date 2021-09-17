// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'confirm_pin';

  final Function(String) submitConfirmationPin;
  final void Function(BuildContext) cancelAndNavigate;

  const ConfirmPin({@required this.submitConfirmationPin, @required this.cancelAndNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(context, 'enrollment.choose_pin.title'),
        ),
        leadingAction: () => cancelAndNavigate(context),
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: IrmaTheme.of(context).hugeSpacing),
            Text(
              FlutterI18n.translate(context, 'enrollment.choose_pin.confirm_instruction'),
              style: IrmaTheme.of(context).textTheme.body1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: IrmaTheme.of(context).mediumSpacing),
            PinField(
              longPin: false,
              onSubmit: submitConfirmationPin,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
          ],
        ),
      ),
    );
  }
}
