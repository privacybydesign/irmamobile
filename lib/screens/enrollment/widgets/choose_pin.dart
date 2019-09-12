import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/screens/enrollment/models/enrollment_event.dart';
import 'package:irmamobile/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/screens/enrollment/widgets/welcome.dart';
import 'package:irmamobile/widgets/error_message.dart';
import 'package:irmamobile/widgets/pin_field.dart';

import 'cancel_button.dart';
import 'confirm_pin.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'enrollment/choose_pin';

  @override
  Widget build(BuildContext context) {
    final EnrollmentBloc enrollmentBloc =
        BlocProvider.of<EnrollmentBloc>(context);

    return Scaffold(
        appBar: AppBar(
          leading: CancelButton(routeName: Welcome.routeName),
          title: Text(
              FlutterI18n.translate(context, 'enrollment.choose_pin.title')),
        ),
        body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
            builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(children: [
                  if (state.pinConfirmed == false) ...[
                    ErrorMessage(message: 'enrollment.choose_pin.error'),
                    const SizedBox(height: 20)
                  ],
                  Text(
                    FlutterI18n.translate(
                        context, 'enrollment.choose_pin.instruction'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  PinField(
                      maxLength: 5,
                      autosubmit: false,
                      autoclear: false,
                      onSubmit: (String pin) {
                        Navigator.of(context)
                            .pushReplacementNamed(ConfirmPin.routeName);
                      },
                      onFull: (String pin) {
                        enrollmentBloc.dispatch(PinChosen(pin: pin));
                      }),
                  const SizedBox(height: 20),
                  if (state.pin != null)
                    RaisedButton(
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed(ConfirmPin.routeName);
                      },
                      child: Text(
                          FlutterI18n.translate(
                              context, 'enrollment.choose_pin.next'),
                          style: TextStyle(fontSize: 20)),
                    )
                ])),
          );
        }));
  }
}
