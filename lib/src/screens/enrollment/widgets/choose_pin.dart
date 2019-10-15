import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/error_message.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

import 'cancel_button.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'enrollment/choose_pin';

  final void Function(BuildContext, String) submitPin;

  ChoosePin({this.submitPin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: CancelButton(routeName: Welcome.routeName),
          title: Text(FlutterI18n.translate(context, 'enrollment.choose_pin.title')),
        ),
        body: BlocBuilder<EnrollmentBloc, EnrollmentState>(builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.only(top: IrmaTheme.of(context).spacing * 2),
                child: Column(children: [
                  if (state.showPinValidation && !state.pinConfirmed) ...[
                    ErrorMessage(message: 'enrollment.choose_pin.error'),
                    SizedBox(height: IrmaTheme.of(context).spacing)
                  ],
                  Text(
                    FlutterI18n.translate(context, 'enrollment.choose_pin.instruction'),
                    style: Theme.of(context).textTheme.body1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: IrmaTheme.of(context).spacing),
                  PinField(maxLength: 5, onSubmit: (pin) => submitPin(context, pin))
                ])),
          );
        }));
  }
}
