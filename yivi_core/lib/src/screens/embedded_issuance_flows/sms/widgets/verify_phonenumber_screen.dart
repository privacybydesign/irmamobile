import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:pinput/pinput.dart";

import "../../../../../routing.dart";
import "../../../../providers/sms_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../util/handle_pointer.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/irma_confirmation_dialog.dart";
import "../../../../widgets/keyboard_animation_listener.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";
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
  final _scrollController = ScrollController();
  final _codeFieldPositionKey = GlobalKey();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.addListener(_handleFocusChange);
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
    _scrollController.dispose();
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

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final codeFieldContext = _codeFieldPositionKey.currentContext;
        if (codeFieldContext == null) {
          return;
        }

        Scrollable.ensureVisible(
          codeFieldContext,
          alignment: 0.2,
          duration: Duration(milliseconds: 300),
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
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

    final theme = IrmaTheme.of(context);
    final codeInvalid = state.error is SmsIssuanceInvalidCodeError;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: TextStyle(
        fontSize: 25,
        color: Color.fromRGBO(30, 60, 87, 1),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: codeInvalid ? theme.error.withAlpha(40) : theme.surfaceSecondary,
        borderRadius: .circular(10),
      ),
    );

    final focussedPinTheme = defaultPinTheme.copyWith(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: codeInvalid ? theme.error.withAlpha(40) : theme.surfaceSecondary,
        border: .all(color: codeInvalid ? theme.error : theme.link),
        borderRadius: .circular(10),
      ),
    );

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: "sms_issuance.verify_code.title",
          leading: YiviBackButton(
            onTap: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => IrmaConfirmationDialog(
                  titleTranslationKey:
                      "sms_issuance.verify_code.back_dialog.title",
                  contentTranslationKey:
                      "sms_issuance.verify_code.back_dialog.body",
                  confirmTranslationKey:
                      "sms_issuance.verify_code.back_dialog.confirm",
                  cancelTranslationKey:
                      "sms_issuance.verify_code.back_dialog.cancel",
                  onCancelPressed: () => context.pop(false),
                  onConfirmPressed: () => context.pop(true),
                ),
              );
              if (result ?? false) {
                ref.read(smsIssuanceProvider.notifier).goBackToEnterPhone();
              }
            },
          ),
        ),
        body: SafeArea(
          child: KeyboardAnimationListener(
            onKeyboardSettled: (context, inset, visible) {
              _handleFocusChange();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: .all(theme.defaultSpacing),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    SizedBox(height: theme.defaultSpacing),
                    TranslatedText(
                      "sms_issuance.verify_code.header",
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: theme.neutralExtraDark,
                      ),
                    ),
                    SizedBox(height: theme.defaultSpacing),
                    TranslatedText(
                      "sms_issuance.verify_code.body",
                      translationParams: {"phone": state.phoneNumber},
                    ),
                    SizedBox(height: theme.largeSpacing),
                    Container(
                      key: _codeFieldPositionKey,
                      child: Pinput(
                        controller: _textController,
                        key: const Key("sms_verification_code_input_field"),
                        keyboardType: .text,
                        textCapitalization: .characters,
                        focusNode: _focusNode,
                        autofocus: true,
                        mainAxisAlignment: .start,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focussedPinTheme,
                        length: 6,
                        onCompleted: _handleCode,
                        pinAnimationType: .scale,
                        hapticFeedbackType: .lightImpact,
                      ),
                    ),
                    if (state.error is SmsIssuanceInvalidCodeError)
                      TranslatedText(
                        "sms_issuance.verify_code.invalid_code_error",
                        style: TextStyle(color: theme.error),
                      ),
                    SizedBox(height: theme.largeSpacing),
                    Row(
                      mainAxisAlignment: .start,
                      mainAxisSize: .max,
                      children: [
                        YiviLinkButton(
                          textAlign: .center,
                          labelTranslationKey:
                              "sms_issuance.verify_code.no_sms_received",
                          onTap: () {
                            showResendSmsDialog(state.phoneNumber);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: IrmaBottomBar(
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

  Future<void> showResendSmsDialog(String phoneNumber) async {
    final bool resend =
        await showDialog(
          context: context,
          builder: (context) {
            return IrmaConfirmationDialog(
              titleTranslationKey:
                  "sms_issuance.verify_code.resend_dialog.title",
              contentTranslationKey:
                  "sms_issuance.verify_code.resend_dialog.body",
              confirmTranslationKey:
                  "sms_issuance.verify_code.resend_dialog.confirm",
              cancelTranslationKey:
                  "sms_issuance.verify_code.resend_dialog.cancel",
              onCancelPressed: () => context.pop(false),
              onConfirmPressed: () => context.pop(true),
            );
          },
        ) ??
        false;

    if (!resend || !mounted) {
      return;
    }

    ref
        .read(smsIssuanceProvider.notifier)
        .sendSms(
          phoneNumber: phoneNumber,
          language: FlutterI18n.currentLocale(context)?.languageCode ?? "en",
        );
  }
}
