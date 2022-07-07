// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

import '../../pin/bloc/yivi_pin_bloc.dart';
import '../../pin/secure_pin_bottom_sheet.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'change_pin/confirm_pin';

  final void Function(String) confirmNewPin;
  final void Function() cancel;

  const ConfirmPin({@required this.confirmNewPin, @required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(context, 'change_pin.confirm_pin.title'),
          style: IrmaTheme.of(context).textTheme.headline3,
        ),
        leadingAction: () async {
          if (cancel != null) {
            cancel();
          }
          if (!await Navigator.of(context).maybePop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
        leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      ),
      body: BlocBuilder<ChangePinBloc, ChangePinState>(builder: (context, state) {
        final pinBloc = PinStateBloc(state.longPin ? 16 : 5);
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: IrmaTheme.of(context).hugeSpacing),
              Text(
                FlutterI18n.translate(context, 'change_pin.confirm_pin.instruction'),
                style: IrmaTheme.of(context).textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: IrmaTheme.of(context).mediumSpacing),
              PinField(
                longPin: state.longPin,
                onChange: pinStringToListConverter(pinBloc),
                onSubmit: (String pin) => confirmNewPin(pin),
              ),
              UnsecurePinWarningTextButton(
                bloc: pinBloc,
              ),
            ],
          ),
        );
      }),
    );
  }
}
