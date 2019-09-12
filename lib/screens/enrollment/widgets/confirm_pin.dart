import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/screens/enrollment/models/enrollment_event.dart';
import 'package:irmamobile/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/widgets/pin_field.dart';
import 'cancel_button.dart';

class ConfirmPin extends StatelessWidget {
  static const String routeName = 'enrollment/confirm_pin';

  @override
  Widget build(BuildContext context) {
    final EnrollmentBloc enrollmentBloc =
        BlocProvider.of<EnrollmentBloc>(context);

    return Scaffold(
        appBar: AppBar(
          leading: CancelButton(routeName: ChoosePin.routeName),
          title: Text(FlutterI18n.translate(
              context, 'enrollment.choose_pin.confirm_title')),
        ),
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(children: [
                Text(
                  FlutterI18n.translate(
                      context, 'enrollment.choose_pin.confirm_instruction'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                PinField(
                  maxLength: 5,
                  onSubmit: (String pin) {
                    enrollmentBloc.dispatch(PinConfirmed(pin: pin));
                  },
                )
              ])),
        ));
  }
}
