import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/glass/glass_dialog.dart";
import "../../widgets/contact_widgets.dart";
import "../../widgets/embedded_issuance_error_screen.dart";
import "phone_number_entry.dart";

class EnterPhoneScreen extends ConsumerStatefulWidget {
  const EnterPhoneScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _EnterPhoneScreenState();
  }
}

class _EnterPhoneScreenState extends ConsumerState<EnterPhoneScreen> {
  final _entryKey = GlobalKey<PhoneNumberEntryState>();
  final _focusNode = FocusNode();

  var _validPhoneNumber = false;

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
    final phone = _entryKey.currentState?.submittable();
    if (phone != null) {
      ref
          .read(smsIssuanceProvider.notifier)
          .sendSms(phoneNumber: phone, language: context.lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsIssuanceProvider);

    if (state.error is! SmsIssuanceNoError) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: "sms_issuance.verify_code.title",
        contentTranslationKey: "sms_issuance.enter_phone.error",
        errorMessage: state.error.toString(),
        onTryAgain: () {
          ref
              .read(smsIssuanceProvider.notifier)
              .sendSms(phoneNumber: state.phoneNumber, language: context.lang);
        },
      );
    }

    return ContactEnterPage(
      titleKey: "sms_issuance.enter_phone.title",
      focusNode: _focusNode,
      fieldAlignment: 0.1,
      icon: Icons.smartphone_rounded,
      tone: DialogTone.success,
      headerKey: "sms_issuance.enter_phone.header",
      bodyKey: "sms_issuance.enter_phone.body",
      labelKey: "sms_issuance.enter_phone.label",
      field: PhoneNumberEntry(
        key: _entryKey,
        focusNode: _focusNode,
        onValidChanged: (valid) {
          if (mounted) {
            setState(() => _validPhoneNumber = valid);
          }
        },
      ),
      nextKey: "sms_issuance.enter_phone.next_button",
      backKey: "sms_issuance.enter_phone.back_button",
      onNext: _validPhoneNumber ? _submit : null,
    );
  }
}
