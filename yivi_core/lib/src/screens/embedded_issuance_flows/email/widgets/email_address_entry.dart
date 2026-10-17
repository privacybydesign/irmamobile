import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/email_issuance_provider.dart";
import "../../../../widgets/pill_text_field.dart";

bool isValidEmail(String value) {
  if (value.isEmpty) return false;
  return RegExp(
    r"^(?:[a-zA-Z0-9_+-])+(?:[\.+](?:[a-zA-Z0-9_-])+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$",
  ).hasMatch(value);
}

/// The e-mail address field of adding an e-mail address, with its
/// validation: kept in lower case, filled in with the address typed before
/// (when coming back from the code), and [onValidChanged] whenever it turns
/// valid or invalid. The full screen and the Change sheet both show it.
///
/// [EmailAddressEntryState.submittable] validates (showing what is wrong)
/// and returns the address to send to, or null.
class EmailAddressEntry extends ConsumerStatefulWidget {
  final FocusNode focusNode;
  final ValueChanged<bool> onValidChanged;

  const EmailAddressEntry({
    super.key,
    required this.focusNode,
    required this.onValidChanged,
  });

  @override
  ConsumerState<EmailAddressEntry> createState() => EmailAddressEntryState();
}

class EmailAddressEntryState extends ConsumerState<EmailAddressEntry> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  var _valid = false;
  var _showErrors = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The address typed before, when coming back from the code.
      final email = ref.read(emailIssuanceProvider).email;
      _textController.text = email;
      _setValid(isValidEmail(email));
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _setValid(bool valid) {
    if (valid == _valid) return;
    setState(() => _valid = valid);
    widget.onValidChanged(valid);
  }

  /// The address to send the code to, once it is valid; shows what is wrong
  /// otherwise.
  String? submittable() {
    setState(() => _showErrors = true);
    return _formKey.currentState!.validate() ? _textController.text : null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: TextFormField(
        decoration: pillInputDecoration(
          context,
          hint: FlutterI18n.translate(
            context,
            "email_issuance.enter_email.email_hint",
          ),
        ),
        controller: _textController,
        focusNode: widget.focusNode,
        key: const Key("email_input_field"),
        keyboardType: .emailAddress,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: .none,
        autovalidateMode: _showErrors ? .onUserInteraction : .disabled,
        onChanged: (v) {
          final lower = v.toLowerCase();
          if (v != lower) {
            _textController.value = _textController.value.copyWith(
              text: lower,
              selection: TextSelection.collapsed(
                offset: _textController.selection.baseOffset,
              ),
            );
          }
          _setValid(isValidEmail(lower));
        },
        validator: (v) {
          final value = (v ?? "").trim();
          if (value.isEmpty) return "Enter your email";
          if (!isValidEmail(value)) return "Enter a valid email";
          return null;
        },
      ),
    );
  }
}
