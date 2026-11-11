import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/email_issuance_provider.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/glass/glass_dialog.dart";
import "../../widgets/contact_widgets.dart";
import "../../widgets/embedded_issuance_error_screen.dart";
import "email_address_entry.dart";

class EnterEmailScreen extends ConsumerStatefulWidget {
  final EmailIssuancePurpose purpose;

  const EnterEmailScreen({required this.purpose});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _submit() {
    final email = _entryKey.currentState?.submittable();
    if (email != null) {
      ref
          .read(emailIssuanceProvider.notifier)
          .sendEmail(email: email, language: context.lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailIssuanceProvider);
    final linking = widget.purpose == EmailIssuancePurpose.linkKeyshare;
    final titleKey = linking
        ? "email_linking.enter_email.title"
        : "email_issuance.enter_email.title";

    if (state.error is! EmailIssuanceNoError) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: titleKey,
        contentTranslationKey: "email_issuance.enter_email.error",
        errorMessage: state.error.toString(),
        onTryAgain: () {
          ref
              .read(emailIssuanceProvider.notifier)
              .sendEmail(email: state.email, language: context.lang);
        },
      );
    }

    return ContactEnterPage(
      titleKey: titleKey,
      focusNode: _focusNode,
      fieldAlignment: 0.0,
      icon: Icons.mail_rounded,
      tone: DialogTone.warning,
      headerKey: linking
          ? "email_linking.enter_email.header"
          : "email_issuance.enter_email.header",
      bodyKey: linking
          ? "email_linking.enter_email.body"
          : "email_issuance.enter_email.body",
      labelKey: linking
          ? "email_linking.enter_email.label"
          : "email_issuance.enter_email.label",
      field: EmailAddressEntry(
        key: _entryKey,
        focusNode: _focusNode,
        onValidChanged: (valid) => setState(() => _validEmail = valid),
      ),
      nextKey: "email_issuance.enter_email.next_button",
      backKey: "email_issuance.enter_email.back_button",
      onNext: _validEmail ? _submit : null,
    );
  }
}
