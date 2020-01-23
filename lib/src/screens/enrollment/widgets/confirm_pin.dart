import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'confirm_pin';

  final Function(String) submitConfirmationPin;
  final void Function() cancel;

  const ConfirmPin({@required this.submitConfirmationPin, @required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(context, 'enrollment.choose_pin.title'),
        ),
        leadingCancel: cancel,
        leadingAction: () {
          Navigator.of(context).popUntil(
              (route) => route.settings.name == ChoosePin.routeName || route.settings.name == Welcome.routeName);
        },
        leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
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
            Text(
              FlutterI18n.translate(context, 'enrollment.choose_pin.instruction'),
              style: IrmaTheme.of(context).textTheme.body1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
