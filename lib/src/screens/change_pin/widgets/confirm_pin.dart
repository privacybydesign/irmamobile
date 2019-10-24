import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/cancel_button.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'change_pin/confirm_pin';

  final void Function(String) confirmNewPin;
  final void Function() cancel;

  ConfirmPin({@required this.confirmNewPin, @required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: CancelButton(cancel: cancel),
          title: Text(FlutterI18n.translate(context, 'change_pin.confirm_pin.title')),
        ),
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.only(top: IrmaTheme.of(context).spacing * 2),
              child: Column(children: [
                Text(
                  FlutterI18n.translate(context, 'change_pin.confirm_pin.instruction'),
                  style: Theme.of(context).textTheme.body1,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: IrmaTheme.of(context).spacing),
                PinField(
                  maxLength: 5,
                  onSubmit: (String pin) => confirmNewPin(pin),
                )
              ])),
        ));
  }
}
