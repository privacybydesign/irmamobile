import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_event.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/error_message.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

import 'cancel_button.dart';
import 'confirm_pin.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'enrollment/choose_pin';

  @override
  Widget build(BuildContext context) {
    final EnrollmentBloc enrollmentBloc = BlocProvider.of<EnrollmentBloc>(context);

    return Scaffold(
        appBar: AppBar(
          leading: CancelButton(routeName: Welcome.routeName),
          title: Text(FlutterI18n.translate(context, 'enrollment.choose_pin.title')),
        ),
        body: BlocBuilder<EnrollmentBloc, EnrollmentState>(builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.only(top: IrmaTheme.spacing * 2),
                child: Column(children: [
                  if (state.pinConfirmed == false) ...[
                    ErrorMessage(message: 'enrollment.choose_pin.error'),
                    SizedBox(height: IrmaTheme.spacing)
                  ],
                  Text(
                    FlutterI18n.translate(context, 'enrollment.choose_pin.instruction'),
                    style: Theme.of(context).textTheme.body1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: IrmaTheme.spacing),
                  PinField(
                      maxLength: 5,
                      onSubmit: (String pin) {
                        enrollmentBloc.dispatch(PinChosen(pin: pin));
                        Navigator.of(context).pushReplacementNamed(ConfirmPin.routeName);
                      })
                ])),
          );
        }));
  }
}
