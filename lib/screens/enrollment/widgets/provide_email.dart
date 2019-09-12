import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/screens/enrollment/models/enrollment_event.dart';
import 'package:irmamobile/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/screens/enrollment/widgets/cancel_button.dart';
import 'package:irmamobile/widgets/error_message.dart';

import 'choose_pin.dart';

class ProvideEmail extends StatelessWidget {
  static const String routeName = 'enrollment/provide_email';

  @override
  Widget build(BuildContext context) {
    final EnrollmentBloc enrollmentBloc =
        BlocProvider.of<EnrollmentBloc>(context);

    return Scaffold(
        appBar: AppBar(
          leading: CancelButton(routeName: ChoosePin.routeName),
          title: Text(
              FlutterI18n.translate(context, 'enrollment.provide_email.title')),
        ),
        body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
            builder: (context, state) {
          return SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(children: [
                    if (state.emailValidated == false) ...[
                      ErrorMessage(message: 'enrollment.provide_email.error'),
                      const SizedBox(height: 20)
                    ],
                    Text(
                      FlutterI18n.translate(
                          context, 'enrollment.provide_email.instruction'),
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                          hintText: FlutterI18n.translate(
                              context, 'enrollment.provide_email.placeholder')),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (String email) {
                        enrollmentBloc.dispatch(EmailChanged(email: email));
                      },
                      onEditingComplete: () {
                        enrollmentBloc.dispatch(EmailSubmitted());
                      },
                    ),
                    const SizedBox(height: 20),
                    RaisedButton(
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      onPressed: () {
                        enrollmentBloc.dispatch(EmailSubmitted());
                      },
                      child: Text(
                          FlutterI18n.translate(
                              context, 'enrollment.provide_email.next'),
                          style: TextStyle(fontSize: 20)),
                    ),
                  ])));
        }));
  }
}
