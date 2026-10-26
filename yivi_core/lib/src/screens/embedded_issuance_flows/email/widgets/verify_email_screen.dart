import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../../../routing.dart";
import "../../../../models/email_code_pointer.dart";
import "../../../../providers/email_issuance_provider.dart";
import "../../../../providers/email_linking_provider.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../util/handle_pointer.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/glass/glass_dialog.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/resend_countdown.dart";
import "../../../../widgets/translated_text.dart";
import "../../widgets/contact_widgets.dart";
import "../../widgets/embedded_issuance_error_screen.dart";

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final EmailIssuancePurpose purpose;

  const VerifyEmailScreen({this.purpose = EmailIssuancePurpose.addCredential});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _VerifyCodeScreenState();
  }
}

class _VerifyCodeScreenState extends ConsumerState<VerifyEmailScreen>
    with RouteAware {
  final _focusNode = FocusNode();
  final _textController = TextEditingController();

  var _codeComplete = false;
  var _codeFromLink = false;

  bool get _linking => widget.purpose == EmailIssuancePurpose.linkKeyshare;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyLink();
    });
  }

  @override
  void didPopNext() {
    Future.microtask(() {
      ref.read(emailIssuanceProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
    _focusNode.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  void _codeChanged(String code) {
    final complete = code.length == emailCodeLength;
    if (complete != _codeComplete) {
      setState(() => _codeComplete = complete);
    }
  }

  /// Fills in the code from the link in the e-mail and continues with it.
  void _applyLink() {
    if (!_linking || !mounted) return;

    final handling = ref.read(emailLinkingProvider).linkHandling;
    final link = ref.read(emailLinkingProvider.notifier).takeLink();
    if (link == null) return;

    // Without an address the code is for the address of this screen.
    if (link.email case final email?) {
      ref.read(emailIssuanceProvider.notifier).startVerification(email: email);
    }
    _textController.text = link.code;
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
    ref.listen(emailIssuanceProvider, (prev, next) {
      if (next.error is EmailIssuanceInvalidCodeError &&
          (prev?.error != next.error)) {
        _textController.text = "";
        setState(() {
          _codeComplete = false;
          _codeFromLink = false;
        });
        _focusNode.requestFocus();
      }
    });

    final state = ref.watch(emailIssuanceProvider);

    final titleKey = _linking
        ? "email_linking.verify_code.title"
        : "email_issuance.verify_code.title";

    // Handle the more generic errors
    if (state.error is! EmailIssuanceNoError &&
        state.error is! EmailIssuanceInvalidCodeError) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: titleKey,
        contentTranslationKey: "email_issuance.verify_code.error",
        errorMessage: state.error.toString(),
        onTryAgain: () {
          ref.read(emailIssuanceProvider.notifier).resetError();
        },
      );
    }

    final codeInvalid = state.error is EmailIssuanceInvalidCodeError;

    final palette = YiviPalette.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goBack();
        }
      },
      child: ContactScrollPage(
        appBar: IrmaAppBar(
          titleTranslationKey: titleKey,
          leading: YiviBackButton(onTap: _goBack),
        ),
        focusNode: _focusNode,
        fieldAlignment: 0.2,
        before: [
          ContactIntro(
            icon: Icons.mail_rounded,
            tone: DialogTone.warning,
            headerKey: _linking
                ? "email_linking.verify_code.header"
                : "email_issuance.verify_code.header",
            bodyKey: _linking
                ? "email_linking.verify_code.body"
                : "email_issuance.verify_code.body",
            bodyParams: {"email": state.email},
          ),
        ],
        field: ContactCodeField(
          fieldKey: const Key("email_verification_code_input_field"),
          controller: _textController,
          focusNode: _focusNode,
          length: emailCodeLength,
          invalid: codeInvalid,
          onChanged: _linking ? _codeChanged : null,
          onCompleted: _linking ? null : _handleCode,
        ),
        after: [
          if (codeInvalid)
            const ContactCodeError(
              "email_issuance.verify_code.invalid_code_error",
            ),
          if (_codeFromLink)
            Padding(
              padding: const EdgeInsets.only(top: 12),
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
          // The dialog to send it again only after the minute.
          if (!_linking)
            ResendCountdown(
              until: ref
                  .read(emailIssuanceProvider.notifier)
                  .resendAt(state.email),
              builder: (context, left) => ContactTextLink(
                labelKey: "email_issuance.verify_code.no_email_received",
                label: left == null
                    ? null
                    : context.tr("contact_sheet.send_again_in", {"time": left}),
                onTap: left == null
                    ? () => showResendSmsDialog(state.email)
                    : null,
              ),
            ),
        ],
        bottomBar: _linking
            ? ResendCountdown(
                until: ref
                    .read(emailIssuanceProvider.notifier)
                    .resendAt(state.email),
                builder: (context, left) => IrmaBottomBar(
                  primaryButtonLabel: "email_linking.verify_code.next_button",
                  onPrimaryPressed: _codeComplete
                      ? () => _handleCode(_textController.text)
                      : null,
                  secondaryButtonLabel: left == null
                      ? "email_linking.verify_code.resend_button"
                      : "email_linking.verify_code.resend_button_in",
                  secondaryButtonParams: left == null ? null : {"time": left},
                  onSecondaryPressed: left == null
                      ? () => showResendSmsDialog(state.email)
                      : null,
                ),
              )
            : IrmaBottomBar(
                secondaryButtonLabel: "email_issuance.verify_code.back_button",
                onSecondaryPressed: context.pop,
              ),
      ),
    );
  }

  Future<void> _handleCode(String code) async {
    final session = await ref
        .read(emailIssuanceProvider.notifier)
        .verifyCode(code: code.toUpperCase());

    if (session == null || !mounted) return;

    final sessionId = await handlePointer(context, session);
    if (_linking && sessionId != null && mounted) {
      ref.read(emailLinkingProvider.notifier).trackIssuance(sessionId);
    }
  }

  Future<void> _goBack() async {
    final result = await confirmContactStep(
      context,
      "email_issuance.verify_code.back_dialog",
    );
    if (result) {
      ref.read(emailIssuanceProvider.notifier).goBackToEnteringEmail();
    }
  }

  Future<void> showResendSmsDialog(String email) async {
    final resend = await confirmContactStep(
      context,
      "email_issuance.verify_code.resend_dialog",
    );

    if (!resend || !mounted) {
      return;
    }

    ref
        .read(emailIssuanceProvider.notifier)
        .sendEmail(email: email, language: context.lang);
  }
}
