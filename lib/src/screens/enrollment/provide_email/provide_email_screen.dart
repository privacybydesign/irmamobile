import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/translated_text.dart';
import 'widgets/email_input_field.dart';

class ProvideEmailScreen extends StatefulWidget {
  final Function(String) onEmailProvided;
  final VoidCallback onPrevious;

  const ProvideEmailScreen({
    required this.onEmailProvided,
    required this.onPrevious,
  });

  @override
  _ProvideEmailScreenState createState() => _ProvideEmailScreenState();
}

class _ProvideEmailScreenState extends State<ProvideEmailScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onContinuePressed() {
    final emailForm = _emailFormKey.currentState;
    if (emailForm!.validate()) {
      final email = _emailController.text;
      widget.onEmailProvided(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'enrollment.email.provide.title',
        leadingAction: widget.onPrevious,
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'ui.next',
        onPrimaryPressed: _onContinuePressed,
        secondaryButtonLabel: 'ui.previous',
        onSecondaryPressed: widget.onPrevious,
      ),
      body: Form(
        key: _emailFormKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            mainAxisSize: MainAxisSize.max,
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
              EmailInputField(controller: _emailController)
            ],
          ),
        ),
      ),
    );
  }
}
