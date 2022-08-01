import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/translated_text.dart';

class EmailInputField extends StatelessWidget {
  final TextEditingController controller;

  const EmailInputField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        cursorColor: IrmaTheme.of(context).themeData.colorScheme.secondary,
        decoration: const InputDecoration(
          //errorText: error,
          label: TranslatedText(
            'enrollment.email.provide.input.label',
          ),
        ),
        validator: (email) => email != null && !EmailValidator.validate(email)
            ? FlutterI18n.translate(
                context,
                'enrollment.email.provide.input.invalid',
              )
            : null,
      );
}
