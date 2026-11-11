import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/glass/glass_dialog.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../widgets/contact_widgets.dart";
import "../../widgets/embedded_issuance_error_screen.dart";

class VerifyPhoneScreen extends ConsumerStatefulWidget {
  const VerifyPhoneScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _VerifyPhoneScreenState();
  }
}

class _VerifyPhoneScreenState extends ConsumerState<VerifyPhoneScreen>
    with VerifyCodeScreen {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      codeFocus.requestFocus();
    });
  }

  @override
  void resetFlow() =>
      ref.read(smsIssuanceProvider.notifier).goBackToEnterPhone();

  @override
  Widget build(BuildContext context) {
    // When the state changes to an invalid code error we clear the textfield and regain focus
    ref.listen(smsIssuanceProvider, (prev, next) {
      if (next.error is SmsIssuanceInvalidCodeError &&
          (prev?.error != next.error)) {
        clearWrongCode();
      }
    });

    final state = ref.watch(smsIssuanceProvider);

    if (state.error is! SmsIssuanceNoError &&
        state.error is! SmsIssuanceInvalidCodeError) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: "sms_issuance.verify_code.title",
        contentTranslationKey: "sms_issuance.verify_code.error",
        errorMessage: state.error.toString(),
        onTryAgain: () {
          ref.read(smsIssuanceProvider.notifier).resetError();
        },
      );
    }

    final codeInvalid = state.error is SmsIssuanceInvalidCodeError;

    final smsRetriever = ref.watch(smsRetrieverProvider);

    return backAsks(
      _goBack,
      ContactScrollPage(
        appBar: IrmaAppBar(
          titleTranslationKey: "sms_issuance.verify_code.title",
          leading: YiviBackButton(onTap: _goBack),
        ),
        focusNode: codeFocus,
        fieldAlignment: 0.2,
        before: [
          ContactIntro(
            icon: Icons.smartphone_rounded,
            tone: DialogTone.success,
            headerKey: "sms_issuance.verify_code.header",
            bodyKey: "sms_issuance.verify_code.body",
            bodyParams: {"phone": state.phoneNumber},
          ),
        ],
        field: ContactCodeField(
          fieldKey: const Key("sms_verification_code_input_field"),
          controller: codeController,
          focusNode: codeFocus,
          smsRetriever: smsRetriever,
          length: smsCodeLength,
          invalid: codeInvalid,
          onCompleted: _handleCode,
        ),
        after: [
          if (codeInvalid)
            const ContactCodeError(
              "sms_issuance.verify_code.invalid_code_error",
            ),
          // The dialog to send it again only after the minute.
          ContactResend.link(
            until: ref
                .read(smsIssuanceProvider.notifier)
                .resendAt(state.phoneNumber),
            linkKey: "sms_issuance.verify_code.no_sms_received",
            onResend: () => _showResendDialog(state.phoneNumber),
          ),
        ],
        bottomBar: IrmaBottomBar(
          secondaryButtonLabel: "sms_issuance.verify_code.back_button",
          onSecondaryPressed: context.pop,
        ),
      ),
    );
  }

  /// Once at a time: a second code would start a second issuance.
  Future<void> _handleCode(String code) => handleCode(
    code,
    (code) => ref.read(smsIssuanceProvider.notifier).verifyCode(code: code),
  );

  Future<void> _goBack() => confirmThen(
    "sms_issuance.verify_code.back_dialog",
    ref.read(smsIssuanceProvider.notifier).goBackToEnterPhone,
  );

  Future<void> _showResendDialog(String phoneNumber) => confirmThen(
    "sms_issuance.verify_code.resend_dialog",
    () => ref
        .read(smsIssuanceProvider.notifier)
        .sendSms(phoneNumber: phoneNumber, language: context.lang),
  );
}
