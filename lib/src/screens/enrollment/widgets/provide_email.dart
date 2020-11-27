import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/provide_email_actions.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class ProvideEmail extends StatefulWidget {
  static const String routeName = 'provide_email';

  final void Function(String) submitEmail;
  final void Function() skipEmail;
  final void Function(BuildContext) cancelAndNavigate;

  const ProvideEmail({
    @required this.submitEmail,
    @required this.skipEmail,
    @required this.cancelAndNavigate,
  });

  @override
  _ProvideEmailState createState() => _ProvideEmailState();
}

class _ProvideEmailState extends State<ProvideEmail> {
  String email = "";
  FocusNode inputFocusNode;
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    inputFocusNode = FocusNode();
    _textEditingController.text = email;
  }

  @override
  void dispose() {
    inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(context, 'enrollment.provide_email.title'),
        ),
        leadingAction: () => widget.cancelAndNavigate(context),
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        builder: (context, state) {
          String error;

          if (state.emailValid == false && state.showEmailValidation == true) {
            error = FlutterI18n.translate(context, 'enrollment.provide_email.error');
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
                          child: Column(
                            children: <Widget>[
                              Text(
                                FlutterI18n.translate(context, 'enrollment.provide_email.instruction'),
                                style: IrmaTheme.of(context).textTheme.body1,
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                              TextField(
                                controller: _textEditingController,
                                autofocus: true,
                                autofillHints: const [AutofillHints.email],
                                focusNode: inputFocusNode,
                                decoration: InputDecoration(
                                  labelStyle: IrmaTheme.of(context).textTheme.overline,
                                  errorText: error,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onEditingComplete: () {
                                  widget.submitEmail(email);
                                },
                                onChanged: (value) {
                                  email = value;
                                },
                              ),
                            ],
                          ),
                        ),
                        ProvideEmailActions(
                          submitEmail: () {
                            widget.submitEmail(email);
                          },
                          skipEmail: widget.skipEmail,
                          enterEmail: () {
                            FocusScope.of(context).requestFocus(inputFocusNode);
                          },
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

void _hideKeyboard(BuildContext context) {
  FocusScope.of(context).requestFocus(FocusNode());
}
