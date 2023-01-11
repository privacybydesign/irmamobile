import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/translated_text.dart';
import 'widgets/email_input_field.dart';
import 'widgets/skip_email_confirmation_dialog.dart';

class ProvideEmailScreen extends StatefulWidget {
  final String? email;
  final Function(String) onEmailProvided;
  final VoidCallback onEmailSkipped;
  final VoidCallback onPrevious;

  const ProvideEmailScreen({
    this.email,
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

  bool emailFormIsValid = false;

  @override
  void initState() {
    _emailController.text = widget.email ?? '';
    super.initState();
  }

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
    final mediaQuery = MediaQuery.of(context);
    final keyboardIsActive = mediaQuery.viewInsets.bottom > 0;
    final isLandscape = mediaQuery.size.width > 450;

    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'enrollment.email.provide.title',
        leadingAction: widget.onPrevious,
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Form(
                key: _emailFormKey,
                onChanged: () => setState(
                  () => emailFormIsValid = _emailFormKey.currentState!.validate(),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(theme.defaultSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          TranslatedText(
                            'enrollment.email.provide.header',
                            style: theme.textTheme.headline3,
                          ),
                          SizedBox(height: theme.defaultSpacing),
                          const TranslatedText('enrollment.email.provide.explanation'),
                          SizedBox(height: theme.mediumSpacing),
                          EmailInputField(controller: _emailController),
                        ],
                      ),
                    ),
                    if (!keyboardIsActive || !isLandscape) ...[
                      const Spacer(),
                      IrmaBottomBar(
                        alignment: isLandscape ? IrmaBottomBarAlignment.horizontal : IrmaBottomBarAlignment.vertical,
                        primaryButtonLabel: 'ui.next',
                        onPrimaryPressed: emailFormIsValid ? _onContinuePressed : null,
                        secondaryButtonLabel: 'ui.skip',
                        onSecondaryPressed: _onSkipPressed,
                      )
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
