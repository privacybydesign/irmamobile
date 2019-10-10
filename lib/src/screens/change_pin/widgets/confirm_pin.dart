import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_event.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'change_pin/confirm_pin';

  @override
  Widget build(BuildContext context) {
    final ChangePinBloc changePinBloc = BlocProvider.of<ChangePinBloc>(context);

    return Scaffold(
        appBar: AppBar(
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
                  onSubmit: (String pin) {
                    changePinBloc.dispatch(NewPinConfirmed(pin: pin));
                  },
                )
              ])),
        ));
  }
}
