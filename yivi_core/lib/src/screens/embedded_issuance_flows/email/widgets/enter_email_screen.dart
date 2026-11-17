import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/contact_issuance_provider.dart";
import "../../../../theme/yivi_tone.dart";
import "../../../../util/after_frame.dart";
import "../../../../util/i18n.dart";
import "../../widgets/contact_widgets.dart";
import "../../widgets/embedded_issuance_error_screen.dart";
import "email_address_entry.dart";

/// The address to link.
class EnterEmailScreen extends ConsumerStatefulWidget {
  const EnterEmailScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _EnterEmailScreenState();
  }
}

class _EnterEmailScreenState extends ConsumerState<EnterEmailScreen> {
  final _entryKey = GlobalKey<EmailAddressEntryState>();
  final _focusNode = FocusNode();

  var _validEmail = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    afterFrame(_focusNode.requestFocus);
  }

  void _submit() {
    final email = _entryKey.currentState?.submittable();
    if (email != null) {
      ref
          .read(contactIssuanceProvider(ContactFlow.linkEmail).notifier)
          .send(email, language: context.lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactIssuanceProvider(ContactFlow.linkEmail));
    const titleKey = "email_linking.enter_email.title";

    if (state.error != null) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: titleKey,
        contentTranslationKey: "email_issuance.enter_email.error",
        errorMessage: state.error.toString(),
        onTryAgain: () {
          ref
              .read(contactIssuanceProvider(ContactFlow.linkEmail).notifier)
              .send(state.target, language: context.lang);
        },
      );
    }

    return ContactEnterPage(
      titleKey: titleKey,
      focusNode: _focusNode,
      fieldAlignment: 0.0,
      icon: Icons.mail_rounded,
      tone: YiviTone.warning,
      headerKey: "email_linking.enter_email.header",
      bodyKey: "email_linking.enter_email.body",
      labelKey: "email_linking.enter_email.label",
      field: EmailAddressEntry(
        key: _entryKey,
        initial: state.target,
        focusNode: _focusNode,
        onValidChanged: (valid) => setState(() => _validEmail = valid),
      ),
      nextKey: "email_issuance.enter_email.next_button",
      backKey: "email_issuance.enter_email.back_button",
      onNext: _validEmail ? _submit : null,
    );
  }
}
