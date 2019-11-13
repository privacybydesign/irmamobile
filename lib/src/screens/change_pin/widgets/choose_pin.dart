import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/cancel_button.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/error_message.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'change_pin/choose_pin';

  final void Function(BuildContext, String) chooseNewPin;
  final void Function() cancel;

  const ChoosePin({@required this.chooseNewPin, @required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CancelButton(cancel: cancel),
        title: Text(FlutterI18n.translate(context, 'change_pin.choose_pin.title')),
      ),
      body: BlocBuilder<ChangePinBloc, ChangePinState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                if (state.newPinConfirmed == ValidationState.invalid) ...[
                  SizedBox(height: IrmaTheme.of(context).spacing),
                  const ErrorMessage(message: 'change_pin.choose_pin.error')
                ],
                SizedBox(height: IrmaTheme.of(context).spacing),
                Text(
                  FlutterI18n.translate(context, 'change_pin.choose_pin.instruction'),
                  style: Theme.of(context).textTheme.body1,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: IrmaTheme.of(context).spacing),
                PinField(
                  maxLength: 5,
                  onSubmit: (String pin) => chooseNewPin(context, pin),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
