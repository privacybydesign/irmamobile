import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../util/handle_pointer.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/glass/glass_dialog.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/resend_countdown.dart";
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
  void resetFlow() => ref.read(smsIssuanceProvider.notifier).reset();

  @override
  Widget build(BuildContext context) {
    // When the state changes to an invalid code error we clear the textfield and regain focus
    ref.listen(smsIssuanceProvider, (prev, next) {
      if (next.error is SmsIssuanceInvalidCodeError &&
          (prev?.error != next.error)) {
        codeController.text = "";
        codeFocus.requestFocus();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goBack();
        }
      },
      child: ContactScrollPage(
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
          ResendCountdown(
            until: ref
                .read(smsIssuanceProvider.notifier)
                .resendAt(state.phoneNumber),
            builder: (context, left) => ContactTextLink(
              labelKey: "sms_issuance.verify_code.no_sms_received",
              label: left == null
                  ? null
                  : context.tr("contact_sheet.send_again_in", {"time": left}),
              onTap: left == null
                  ? () => _showResendDialog(state.phoneNumber)
                  : null,
            ),
          ),
        ],
        bottomBar: IrmaBottomBar(
          secondaryButtonLabel: "sms_issuance.verify_code.back_button",
          onSecondaryPressed: context.pop,
        ),
      ),
    );
  }

  /// A code being checked or its issuance starting: a second one would
  /// start a second issuance.
  var _handling = false;

  Future<void> _handleCode(String code) async {
    if (_handling) return;
    _handling = true;
    try {
      final session = await ref
          .read(smsIssuanceProvider.notifier)
          .verifyCode(code: code.toUpperCase());

      if (session != null && mounted) {
        await handlePointer(context, session);
      }
    } finally {
      _handling = false;
    }
  }

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
