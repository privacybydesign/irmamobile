import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/translated_text.dart';
import '../bloc/enrollment_bloc.dart';
import '../bloc/enrollment_state.dart';
import 'widgets/provide_email_actions.dart';

class ProvideEmailScreen extends StatefulWidget {
  static const String routeName = 'provide_email';

  final void Function(String) submitEmail;
  final void Function() skipEmail;
  final void Function(BuildContext) cancelAndNavigate;

  const ProvideEmailScreen({
    required this.submitEmail,
    required this.skipEmail,
    required this.cancelAndNavigate,
  });

  @override
  _ProvideEmailScreenState createState() => _ProvideEmailScreenState();
}

class _ProvideEmailScreenState extends State<ProvideEmailScreen> {
  String email = '';
  FocusNode inputFocusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'enrollment.email.provide.title',
        leadingAction: () => widget.cancelAndNavigate(context),
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        builder: (context, state) {
          String? error;

          if (state.emailValid == false && state.showEmailValidation == true) {
            error = FlutterI18n.translate(context, 'enrollment.email.provide.input.invalid');
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
                      key: const Key('enrollment_provide_email'),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(theme.defaultSpacing),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TranslatedText(
                                'enrollment.email.provide.header',
                                style: theme.textTheme.headline3,
                              ),
                              SizedBox(
                                height: theme.defaultSpacing,
                              ),
                              const TranslatedText('enrollment.email.provide.explanation'),
                              SizedBox(height: theme.defaultSpacing),
                              TextField(
                                key: const Key('enrollment_provide_email_textfield'),
                                controller: _textEditingController,
                                autofocus: true,
                                autofillHints: const [AutofillHints.email],
                                focusNode: inputFocusNode,
                                cursorColor: theme.themeData.colorScheme.secondary,
                                decoration: InputDecoration(
                                  errorText: error,
                                  label: const TranslatedText(
                                    'enrollment.email.provide.input.label',
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onEditingComplete: () => widget.submitEmail(email),
                                onChanged: (value) => (email = value),
                              ),
                            ],
                          ),
                        ),
                        ProvideEmailActions(
                          submitEmail: () => widget.submitEmail(email),
                          skipEmail: widget.skipEmail,
                          enterEmail: () => FocusScope.of(context).requestFocus(inputFocusNode),
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

void _hideKeyboard(BuildContext context) => FocusScope.of(context).requestFocus(FocusNode());
