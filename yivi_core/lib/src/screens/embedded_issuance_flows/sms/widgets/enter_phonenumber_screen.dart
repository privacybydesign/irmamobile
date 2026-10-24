import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../widgets/glass/glass_dialog.dart";
import "../../../../widgets/glass/pill_buttons.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
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
          .sendSms(
            phoneNumber: phone,
            language: FlutterI18n.currentLocale(context)?.languageCode ?? "en",
          );
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
              .sendSms(
                phoneNumber: state.phoneNumber,
                language:
                    FlutterI18n.currentLocale(context)?.languageCode ?? "en",
              );
        },
      );
    }

    return ContactScrollPage(
      appBar: IrmaAppBar(titleTranslationKey: "sms_issuance.enter_phone.title"),
      focusNode: _focusNode,
      fieldAlignment: 0.1,
      before: const [
        ContactIntro(
          icon: Icons.smartphone_rounded,
          tone: DialogTone.success,
          headerKey: "sms_issuance.enter_phone.header",
          bodyKey: "sms_issuance.enter_phone.body",
        ),
        ContactFieldLabel("sms_issuance.enter_phone.label"),
      ],
      field: PhoneNumberEntry(
        key: _entryKey,
        focusNode: _focusNode,
        onValidChanged: (valid) {
          if (mounted) {
            setState(() => _validPhoneNumber = valid);
          }
        },
      ),
      // With the keyboard up only the "send sms" button, right above it;
      // otherwise both the send and the cancel button.
      keyboardButton: FancyPillButton(
        label: FlutterI18n.translate(
          context,
          "sms_issuance.enter_phone.next_button",
        ),
        onPressed: _validPhoneNumber ? _submit : null,
      ),
      bottomBar: IrmaBottomBar(
        primaryButtonLabel: "sms_issuance.enter_phone.next_button",
        secondaryButtonLabel: "sms_issuance.enter_phone.back_button",
        onPrimaryPressed: _validPhoneNumber ? _submit : null,
        onSecondaryPressed: context.pop,
      ),
    );
  }
}
