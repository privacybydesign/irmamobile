import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/enrollment/provide_email/widgets/skip_email_confirmation_dialog.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/translated_text.dart';
import 'widgets/email_input_field.dart';

class ProvideEmailScreen extends StatefulWidget {
  final Function(String) onEmailProvided;
  final VoidCallback onEmailSkipped;
  final VoidCallback onPrevious;

  const ProvideEmailScreen({
    required this.onEmailProvided,
    required this.onEmailSkipped,
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

  void _onSkipPressed() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => SkipEmailConfirmationDialog(),
        ) ??
        false;
    if (confirmed) widget.onEmailSkipped();
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
        alignment: IrmaBottomBarAlignment.horizontal,
        primaryButtonLabel: 'ui.next',
        onPrimaryPressed: _onContinuePressed,
        secondaryButtonLabel: 'ui.skip',
        onSecondaryPressed: _onSkipPressed,
      ),
      body: Form(
        key: _emailFormKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
