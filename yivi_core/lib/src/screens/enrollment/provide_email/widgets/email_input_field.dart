import "package:email_validator/email_validator.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../../widgets/translated_text.dart";

class EmailInputField extends StatelessWidget {
  final TextEditingController controller;

  /// An address the keyshare server refused. The field reports it as
  /// invalid until the user changes it.
  final String? rejectedEmail;

  const EmailInputField({required this.controller, this.rejectedEmail});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final baseTextStyle = theme.textTheme.bodyMedium;

    return TextFormField(
      key: const Key("email_input_field"),
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      cursorColor: theme.themeData.colorScheme.secondary,
      style: baseTextStyle,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(top: -10.0),
        label: TranslatedText(
          "enrollment.email.provide.input.label",
          style: baseTextStyle,
        ),
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: FlutterI18n.translate(
          context,
          "enrollment.email.provide.input.hint",
        ),
      ),
      // The rejection must show right away, without waiting for an edit.
      autovalidateMode: rejectedEmail != null
          ? AutovalidateMode.always
          : AutovalidateMode.onUserInteraction,
      validator: (email) {
        if (email == null) return null;
        if (!EmailValidator.validate(email)) {
          return FlutterI18n.translate(
            context,
            "enrollment.email.provide.input.invalid",
          );
        }
        if (email == rejectedEmail) {
          return FlutterI18n.translate(
            context,
            "enrollment.email.provide.input.rejected",
          );
        }
        return null;
      },
    );
  }
}
