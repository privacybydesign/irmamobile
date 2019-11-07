import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/add_card_email/model/request_email_bloc.dart';
import 'package:irmamobile/src/screens/add_card_email/model/request_email_events.dart';
import 'package:irmamobile/src/theme/irma-icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/primary_button.dart';
import 'package:irmamobile/src/widgets/success_alert.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailAttributeConfirmation extends StatelessWidget {
  EmailAttributeConfirmation() : super(key: myKey);

  static const String routeName = 'store/email/success';
  static Key myKey = const Key(routeName);

  @override
  Widget build(BuildContext context) {
    final RequestEmailBloc _bloc = BlocProvider.of<RequestEmailBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          FlutterI18n.translate(
            context,
            'card_store.email.title',
          ),
        ),
        leading: IconButton(
            icon: Icon(IrmaIcons.arrowBack),
            onPressed: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop()),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).spacing),
        child: BlocBuilder(
            bloc: _bloc,
            builder: (context, state) {
              return SingleChildScrollView(
                  child: Stack(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: IrmaTheme.of(context).spacing,
                      ),
                      Text(
                        FlutterI18n.translate(
                          context,
                          'card_store.email.success.description',
                        ),
                        style: IrmaTheme.of(context).textTheme.body1,
                      ),
                      SizedBox(
                        height: IrmaTheme.of(context).spacing,
                      ),
                      Text(
                        FlutterI18n.translate(
                          context,
                          'card_store.email.success.no_email_received_title',
                        ),
                        style: IrmaTheme.of(context).textTheme.title,
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 0.5 * IrmaTheme.of(context).spacing,
                        ),
                        child: Text.rich(
                          TextSpan(
                            text:
                                FlutterI18n.translate(context, "card_store.email.success.no_email_received_body_step1"),
                            style: IrmaTheme.of(context).textTheme.body1,
                            children: <TextSpan>[
                              TextSpan(
                                text: FlutterI18n.translate(
                                    context, "card_store.email.success.no_email_received_body_step2_1"),
                                style: IrmaTheme.of(context)
                                    .textTheme
                                    .body1
                                    .copyWith(decoration: TextDecoration.underline),
                                recognizer: new TapGestureRecognizer()
                                  ..onTap = () {
                                    _bloc.dispatch(RequestAgain());
                                  },
                              ),
                              TextSpan(
                                text: FlutterI18n.translate(
                                    context, "card_store.email.success.no_email_received_body_step2_2", {
                                  "e-mail": state.enteredEmail,
                                }),
                                style: IrmaTheme.of(context).textTheme.body1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: IrmaTheme.of(context).spacing,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: PrimaryButton(
                            label: FlutterI18n.translate(
                              context,
                              "card_store.email.success.open_email_button",
                            ),
                            onPressed: () {
                              if (Platform.isIOS) {
                                launch("message://");
                              } else {
                                // TODO: find out how to just open a mail client on android.
                                // mailto: will open a mail client and with the intention to write a new mail.
                                launch("mailto:");
                              }
                            }),
                      ),
                      if (state.inProgress)
                        Center(
                            child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        )),
                    ],
                  ),
                  if (state.showSuccessConfirmation)
                    SuccessAlert(
                      title: FlutterI18n.translate(context, "card_store.email.success.alert_title"),
                      body: FlutterI18n.translate(
                          context, "card_store.email.success.alert_body", {"e-mail": state.enteredEmail}),
                    ),
                ],
              ));
            }),
      ),
    );
  }
}
