import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/cancel_button.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/error_message.dart';
import 'package:irmamobile/src/widgets/primary_button.dart';

import 'choose_pin.dart';

class ProvideEmail extends StatelessWidget {
  static const String routeName = 'enrollment/provide_email';

  final void Function() submitEmail;
  final void Function(String) changeEmail;
  final void Function() cancel;

  ProvideEmail({@required this.submitEmail, @required this.changeEmail, @required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: CancelButton(routeName: ChoosePin.routeName, cancel: cancel),
          title: Text(FlutterI18n.translate(context, 'enrollment.provide_email.title')),
        ),
        body: BlocBuilder<EnrollmentBloc, EnrollmentState>(builder: (context, state) {
          return SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.all(IrmaTheme.of(context).spacing * 2),
                  child: Column(children: [
                    if (state.emailValid == false && state.showEmailValidation) ...[
                      ErrorMessage(message: 'enrollment.provide_email.error'),
                      SizedBox(height: IrmaTheme.of(context).spacing)
                    ],
                    Text(
                      FlutterI18n.translate(context, 'enrollment.provide_email.instruction'),
                      style: Theme.of(context).textTheme.body1,
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: IrmaTheme.of(context).spacing),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                          hintText: FlutterI18n.translate(context, 'enrollment.provide_email.placeholder')),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: changeEmail,
                      onEditingComplete: submitEmail,
                    ),
                    SizedBox(height: IrmaTheme.of(context).spacing),
                    PrimaryButton(
                      onPressed: submitEmail,
                      label: 'enrollment.provide_email.next',
                    ),
                  ])));
        }));
  }
}
