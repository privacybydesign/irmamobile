import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/translated_text.dart';

class EmailInputField extends StatelessWidget {
  final TextEditingController controller;

  const EmailInputField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final baseTextStyle = theme.textTheme.bodyMedium;

    return TextFormField(
      key: const Key('email_input_field'),
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      cursorColor: theme.themeData.colorScheme.secondary,
      style: baseTextStyle,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(top: -10.0),
        label: TranslatedText('enrollment.email.provide.input.label', style: baseTextStyle),
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: FlutterI18n.translate(context, 'enrollment.email.provide.input.hint'),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (email) => email != null && !EmailValidator.validate(email)
          ? FlutterI18n.translate(context, 'enrollment.email.provide.input.invalid')
          : null,
    );
  }
}
