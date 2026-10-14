import "package:email_validator/email_validator.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../widgets/pill_text_field.dart";

/// The e-mail field of enrollment. It says an address is invalid once the
/// user has typed something that is not one.
class EmailInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  const EmailInputField({required this.controller, this.onSubmitted});

  static bool isValid(String email) => EmailValidator.validate(email);

  @override
  State<EmailInputField> createState() => _EmailInputFieldState();
}

class _EmailInputFieldState extends State<EmailInputField> {
  var _touched = false;

  @override
  Widget build(BuildContext context) {
    final email = widget.controller.text;
    final invalid =
        _touched && email.isNotEmpty && !EmailInputField.isValid(email);
    return PillTextField(
      fieldKey: const Key("email_input_field"),
      controller: widget.controller,
      label: FlutterI18n.translate(
        context,
        "enrollment.email.provide.input.label",
      ),
      hint: FlutterI18n.translate(
        context,
        "enrollment.email.provide.input.hint",
      ),
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.done,
      onChanged: (_) => setState(() => _touched = true),
      onSubmitted: (_) => widget.onSubmitted?.call(),
      errorText: invalid
          ? FlutterI18n.translate(
              context,
              "enrollment.email.provide.input.invalid",
            )
          : null,
    );
  }
}
