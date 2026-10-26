import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../../../routing.dart";
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
    return _VerifyCodeScreenState();
  }
}

class _VerifyCodeScreenState extends ConsumerState<VerifyPhoneScreen>
    with RouteAware {
  final _focusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didPopNext() {
    Future.microtask(() {
      ref.read(smsIssuanceProvider.notifier).reset();
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

  @override
  Widget build(BuildContext context) {
    // When the state changes to an invalid code error we clear the textfield and regain focus
    ref.listen(smsIssuanceProvider, (prev, next) {
      if (next.error is SmsIssuanceInvalidCodeError &&
          (prev?.error != next.error)) {
        _textController.text = "";
        _focusNode.requestFocus();
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
        focusNode: _focusNode,
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
          controller: _textController,
          focusNode: _focusNode,
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
                  ? () => showResendSmsDialog(state.phoneNumber)
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

  Future<void> _handleCode(String code) async {
    final session = await ref
        .read(smsIssuanceProvider.notifier)
        .verifyCode(code: code.toUpperCase());

    if (session != null && mounted) {
      handlePointer(context, session);
    }
  }

  Future<void> _goBack() async {
    final result = await confirmContactStep(
      context,
      "sms_issuance.verify_code.back_dialog",
    );
    if (result) {
      ref.read(smsIssuanceProvider.notifier).goBackToEnterPhone();
    }
  }

  Future<void> showResendSmsDialog(String phoneNumber) async {
    final resend = await confirmContactStep(
      context,
      "sms_issuance.verify_code.resend_dialog",
    );

    if (!resend || !mounted) {
      return;
    }

    ref
        .read(smsIssuanceProvider.notifier)
        .sendSms(phoneNumber: phoneNumber, language: context.lang);
  }
}
