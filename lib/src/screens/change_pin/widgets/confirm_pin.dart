import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/cancel_button.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'change_pin/confirm_pin';

  final void Function(String) confirmNewPin;
  final void Function() cancel;

  const ConfirmPin({@required this.confirmNewPin, @required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: IrmaTheme.of(context).grayscale85,
        leading: CancelButton(cancel: cancel),
        title: Text(
          FlutterI18n.translate(context, 'change_pin.confirm_pin.title'),
          style: IrmaTheme.of(context).textTheme.display2,
        ),
      ),
      body: BlocBuilder<ChangePinBloc, ChangePinState>(builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: IrmaTheme.of(context).hugeSpacing),
              Text(
                FlutterI18n.translate(context, 'change_pin.confirm_pin.instruction'),
                style: IrmaTheme.of(context).textTheme.body1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: IrmaTheme.of(context).mediumSpacing),
              PinField(
                maxLength: state.longPin ? 16 : 5,
                onSubmit: (String pin) => confirmNewPin(pin),
              )
            ],
          ),
        );
      }),
    );
  }
}
