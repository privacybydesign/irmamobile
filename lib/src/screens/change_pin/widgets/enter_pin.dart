import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/cancel_button.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/error_message.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class EnterPin extends StatelessWidget {
  static const String routeName = 'change_pin/enter_pin';

  final void Function(String) submitOldPin;
  final void Function() cancel;

  EnterPin({@required this.submitOldPin, @required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: CancelButton(cancel: cancel),
          title: Text(FlutterI18n.translate(context, 'change_pin.enter_pin.title')),
        ),
        body: BlocBuilder<ChangePinBloc, ChangePinState>(builder: (context, state) {
          return SingleChildScrollView(
            child: Column(children: [
              SizedBox(height: IrmaTheme.of(context).spacing),
              if (state.oldPinVerified == ValidationState.invalid) ...[
                ErrorMessage(message: 'change_pin.enter_pin.error'),
                SizedBox(height: IrmaTheme.of(context).spacing)
              ],
              Text(
                FlutterI18n.translate(context, 'change_pin.enter_pin.instruction'),
                style: Theme.of(context).textTheme.body1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: IrmaTheme.of(context).spacing),
              PinField(
                maxLength: 5,
                onSubmit: (String pin) => submitOldPin(pin),
              ),
            ]),
          );
        }));
  }
}
