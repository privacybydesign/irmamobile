import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/cancel_button.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'confirm_pin';

  final Function(String) submitConfirmationPin;
  final void Function() cancel;

  const ConfirmPin({@required this.submitConfirmationPin, @required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: IrmaTheme.of(context).grayscale85,
        leading: CancelButton(routeName: ChoosePin.routeName, cancel: cancel),
        title: Text(
          FlutterI18n.translate(context, 'enrollment.choose_pin.title'),
          style: IrmaTheme.of(context).textTheme.subhead,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: IrmaTheme.of(context).spacing * 2),
          child: Column(
            children: [
              Text(
                FlutterI18n.translate(context, 'enrollment.choose_pin.confirm_instruction'),
                style: Theme.of(context).textTheme.body1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: IrmaTheme.of(context).spacing),
              PinField(
                maxLength: 5,
                onSubmit: submitConfirmationPin,
              ),
              SizedBox(height: IrmaTheme.of(context).spacing),
              Text(
                FlutterI18n.translate(context, 'enrollment.choose_pin.instruction'),
                style: Theme.of(context).textTheme.body1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
