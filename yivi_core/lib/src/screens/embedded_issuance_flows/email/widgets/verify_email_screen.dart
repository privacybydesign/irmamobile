import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../../models/email_code_pointer.dart";
import "../../../../providers/contact_issuance_provider.dart";
import "../../../../providers/email_linking_provider.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../theme/yivi_space.dart";
import "../../../../theme/yivi_tone.dart";
import "../../../../util/after_frame.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/resend_countdown.dart";
import "../../../../widgets/translated_text.dart";
import "../../widgets/contact_widgets.dart";
import "../../widgets/embedded_issuance_error_screen.dart";

/// The code for the address to link: typed, or filled in from the link in
/// the e-mail.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _VerifyEmailScreenState();
  }
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with VerifyCodeScreen {
  var _codeComplete = false;
  var _codeFromLink = false;

  static final _flow = contactIssuanceProvider(ContactFlow.linkEmail);

  @override
  void initState() {
    super.initState();
    afterFrame(_applyLink);
  }

  @override
  void resetFlow() => ref.read(_flow.notifier).reset();

  void _codeChanged(String code) {
    final complete = code.length == emailCodeLength;
    if (complete != _codeComplete) {
      setState(() => _codeComplete = complete);
    }
  }

  /// Fills in the code from the link in the e-mail and continues with it.
  void _applyLink() {
    if (!mounted) return;

    final handling = ref.read(emailLinkingProvider).linkHandling;
    final link = ref.read(emailLinkingProvider.notifier).takeLink();
    if (link == null) return;

    // Without an address the code is for the address of this screen.
    if (link.email case final email?) {
      ref.read(_flow.notifier).codeOnItsWay(email);
    }
    codeController.text = link.code;
    setState(() {
      _codeComplete = true;
      _codeFromLink = true;
    });
    if (handling == EmailLinkHandling.submit) _handleCode(link.code);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(emailLinkingProvider.select((state) => state.link), (_, link) {
      if (link != null) _applyLink();
    });

    // When the state changes to an invalid code error we clear the textfield and regain focus
    ref.listen(_flow, (prev, next) {
      if (next.error is ContactWrongCode && (prev?.error != next.error)) {
        clearWrongCode(
          () => setState(() {
            _codeComplete = false;
            _codeFromLink = false;
          }),
        );
      }
    });

    final state = ref.watch(_flow);

    const titleKey = "email_linking.verify_code.title";

    // Handle the more generic errors
    if (state.error != null && state.error is! ContactWrongCode) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: titleKey,
        contentTranslationKey: "email_issuance.verify_code.error",
        errorMessage: state.error.toString(),
        onTryAgain: () {
          ref.read(_flow.notifier).clearError();
        },
      );
    }

    final codeInvalid = state.error is ContactWrongCode;

    final palette = YiviPalette.of(context);

    return backAsks(
      _goBack,
      ContactScrollPage(
        appBar: IrmaAppBar(
          titleTranslationKey: titleKey,
          leading: YiviBackButton(onTap: _goBack),
        ),
        focusNode: codeFocus,
        fieldAlignment: 0.2,
        before: [
          ContactIntro(
            icon: Icons.mail_rounded,
            tone: YiviTone.warning,
            headerKey: "email_linking.verify_code.header",
            bodyKey: "email_linking.verify_code.body",
            bodyParams: {"email": state.target},
          ),
        ],
        field: ContactCodeField(
          fieldKey: const Key("email_verification_code_input_field"),
          controller: codeController,
          focusNode: codeFocus,
          length: emailCodeLength,
          invalid: codeInvalid,
          onChanged: _codeChanged,
        ),
        after: [
          if (codeInvalid)
            const ContactCodeError(
              "email_issuance.verify_code.invalid_code_error",
            ),
          if (_codeFromLink)
            Padding(
              padding: const EdgeInsets.only(top: YiviSpace.x12),
              child: Semantics(
                liveRegion: true,
                child: TranslatedText(
                  "email_linking.verify_code.filled_from_link",
                  key: const Key("code_filled_from_link"),
                  textAlign: .center,
                  style: palette
                      .body(14)
                      .copyWith(color: palette.secondaryText),
                ),
              ),
            ),
        ],
        bottomBar: ResendCountdown(
          until: ref.read(_flow.notifier).resendAt(state.target),
          builder: (context, left) => IrmaBottomBar(
            primaryButtonLabel: "email_linking.verify_code.next_button",
            onPrimaryPressed: _codeComplete
                ? () => _handleCode(codeController.text)
                : null,
            secondaryButtonLabel: left == null
                ? "email_linking.verify_code.resend_button"
                : "email_linking.verify_code.resend_button_in",
            secondaryButtonParams: left == null ? null : {"time": left},
            onSecondaryPressed: left == null
                ? () => _showResendDialog(state.target)
                : null,
          ),
        ),
      ),
    );
  }

  /// Once at a time: a second code (the button, the code completing again,
  /// the link) would start a second issuance.
  Future<void> _handleCode(String code) async {
    final sessionId = await handleCode(
      code,
      (code) => ref.read(_flow.notifier).verify(code),
    );
    if (sessionId != null && mounted) {
      ref.read(emailLinkingProvider.notifier).trackIssuance(sessionId);
    }
  }

  Future<void> _goBack() => confirmThen(
    "email_issuance.verify_code.back_dialog",
    ref.read(_flow.notifier).backToAddress,
  );

  Future<void> _showResendDialog(String email) => confirmThen(
    "email_issuance.verify_code.resend_dialog",
    () => ref.read(_flow.notifier).send(email, language: context.lang),
  );
}
