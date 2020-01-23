import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/add_card_email/model/request_email_bloc.dart';
import 'package:irmamobile/src/screens/add_card_email/model/request_email_events.dart';
import 'package:irmamobile/src/screens/add_card_email/model/request_email_state.dart';
import 'package:irmamobile/src/screens/add_cards/customs/future_card.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/error_alert.dart';
import 'package:irmamobile/src/widgets/info_alert.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

class RequestEmailAttribute extends StatefulWidget {
  RequestEmailAttribute(this.name, this.issuer, this.logoPath) : super(key: myKey);

  static const String routeName = 'store/email/request';
  static Key myKey = const Key(routeName);
  final String name;
  final String issuer;
  final String logoPath;

  @override
  State<StatefulWidget> createState() {
    return RequestEmailAttributeState();
  }
}

class RequestEmailAttributeState extends State<RequestEmailAttribute> {
  final _emailTextController = TextEditingController();
  final _scrollController = ScrollController();
  final _scrollViewKey = GlobalKey();
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final RequestEmailBloc bloc = BlocProvider.of<RequestEmailBloc>(context);

    return Scaffold(
      appBar: IrmaAppBar(
          title: Text(
            FlutterI18n.translate(
              context,
              'card_store.app_bar',
              {
                "card_type": widget.name,
              },
            ),
          ),
          leadingAction: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pop()),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).spacing),
        child: BlocBuilder<RequestEmailBloc, RequestEmailState>(
            bloc: bloc,
            builder: (context, state) {
              return SingleChildScrollView(
                  controller: _scrollController,
                  key: _scrollViewKey,
                  child: Column(
                    children: <Widget>[
                      FutureCard(widget.name, widget.issuer, widget.logoPath),
                      SizedBox(
                        height: IrmaTheme.of(context).spacing,
                      ),
                      Text(
                        FlutterI18n.translate(context, 'card_store.email.description'),
                      ),
                      if (state.enteredEmail == null && state.irmaEmail != null)
                        Container(
                          padding: EdgeInsets.only(top: IrmaTheme.of(context).spacing),
                          child: InfoAlert(
                            title: FlutterI18n.translate(context, 'card_store.email.info_alert_title'),
                            body: FlutterI18n.translate(
                              context,
                              'card_store.email.info_alert_body',
                              {
                                "e-mail": state.irmaEmail,
                              },
                            ),
                          ),
                        ),
                      if (state.emailCouldNotBeSend)
                        Container(
                          padding: EdgeInsets.only(top: IrmaTheme.of(context).spacing),
                          child: ErrorAlert(
                            title: FlutterI18n.translate(context, 'card_store.email.fail.alert_title'),
                            body: FlutterI18n.translate(context, 'card_store.email.fail.alert_body', {
                              "e-mail": state.enteredEmail,
                            }),
                          ),
                        ),
                      SizedBox(
                        height: IrmaTheme.of(context).spacing,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Form(
                              key: _formKey,
                              child: TextFormField(
                                controller: _emailTextController,
                                validator: _validateEmail,
                                decoration: InputDecoration(
                                  labelText: FlutterI18n.translate(
                                    context,
                                    "card_store.email.hint_email",
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            color: Colors.grey,
                            icon:
                                Icon(Icons.close, semanticLabel: FlutterI18n.translate(context, "accessibility.close")),
                            onPressed: () {
                              _emailTextController.clear();
                              bloc.dispatch(ClearEmail());
                            },
                          )
                        ],
                      ),
                      SizedBox(
                        height: IrmaTheme.of(context).spacing,
                      ),
                      if (state.inProgress) ...[
                        const CircularProgressIndicator(),
                      ] else ...[
                        IrmaButton(
                          label: FlutterI18n.translate(
                            context,
                            "card_store.email.get_button",
                          ),
                          onPressed: () {
                            if (!_formKey.currentState.validate()) {
                              return;
                            }
                            bloc.dispatch(
                              RequestAttribute(
                                email: _emailTextController.value.text,
                                language: Localizations.localeOf(context).languageCode,
                              ),
                            );
                          },
                        ),
                      ],
                      SizedBox(
                        height: IrmaTheme.of(context).spacing,
                      ),
                      SizedBox(
                        height: IrmaTheme.of(context).spacing,
                      ),
                    ],
                  ));
            }),
      ),
    );
  }

  String _validateEmail(String value) {
    if (value.isEmpty) {
      return FlutterI18n.translate(context, "card_store.email.empty_email_address");
    }

    if (!EmailValidator.validate(value)) {
      return FlutterI18n.translate(context, "card_store.email.invalid_email_address");
    }

    return null;
  }
}
