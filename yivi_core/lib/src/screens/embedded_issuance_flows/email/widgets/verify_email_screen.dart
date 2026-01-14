import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:pinput/pinput.dart";

import "../../../../../routing.dart";
import "../../../../providers/email_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../util/handle_pointer.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/irma_confirmation_dialog.dart";
import "../../../../widgets/keyboard_animation_listener.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";
import "../../widgets/embedded_issuance_error_screen.dart";

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _VerifyCodeScreenState();
  }
}

class _VerifyCodeScreenState extends ConsumerState<VerifyEmailScreen>
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
    _scrollController.dispose();
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
    ref.listen(emailIssuanceProvider, (prev, next) {
      if (next.error is EmailIssuanceInvalidCodeError &&
          (prev?.error != next.error)) {
        _textController.text = "";
        _focusNode.requestFocus();
      }
    });

    final state = ref.watch(emailIssuanceProvider);

    // Handle the more generic errors
    if (state.error is! EmailIssuanceNoError &&
        state.error is! EmailIssuanceInvalidCodeError) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: "email_issuance.verify_code.title",
        contentTranslationKey: "email_issuance.verify_code.error",
        errorMessage: state.error.toString(),
        onTryAgain: () {
          ref.read(emailIssuanceProvider.notifier).resetError();
        },
      );
    }

    final theme = IrmaTheme.of(context);
    final codeInvalid = state.error is EmailIssuanceInvalidCodeError;

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goBack();
        }
      },
      child: GestureDetector(
        onTap: () {
          _focusNode.unfocus();
        },
        child: Scaffold(
          appBar: IrmaAppBar(
            titleTranslationKey: "email_issuance.verify_code.title",
            leading: YiviBackButton(onTap: _goBack),
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
                        "email_issuance.verify_code.header",
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: theme.neutralExtraDark,
                        ),
                      ),
                      SizedBox(height: theme.defaultSpacing),
                      TranslatedText(
                        "email_issuance.verify_code.body",
                        translationParams: {"email": state.email},
                      ),
                      SizedBox(height: theme.largeSpacing),
                      Container(
                        key: _codeFieldPositionKey,
                        child: Pinput(
                          key: const Key("email_verification_code_input_field"),
                          controller: _textController,
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
                      if (state.error is EmailIssuanceInvalidCodeError)
                        TranslatedText(
                          "email_issuance.verify_code.invalid_code_error",
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
                                "email_issuance.verify_code.no_email_received",
                            onTap: () {
                              showResendSmsDialog(state.email);
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
            secondaryButtonLabel: "email_issuance.verify_code.back_button",
            onSecondaryPressed: context.pop,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCode(String code) async {
    final session = await ref
        .read(emailIssuanceProvider.notifier)
        .verifyCode(code: code.toUpperCase());

    if (session != null && mounted) {
      handlePointer(context, session);
    }
  }

  Future<void> _goBack() async {
    final result = await showDialog(
      context: context,
      builder: (context) => IrmaConfirmationDialog(
        titleTranslationKey: "email_issuance.verify_code.back_dialog.title",
        contentTranslationKey: "email_issuance.verify_code.back_dialog.body",
        confirmTranslationKey: "email_issuance.verify_code.back_dialog.confirm",
        cancelTranslationKey: "email_issuance.verify_code.back_dialog.cancel",
        onCancelPressed: () => context.pop(false),
        onConfirmPressed: () => context.pop(true),
      ),
    );
    if (result ?? false) {
      ref.read(emailIssuanceProvider.notifier).goBackToEnteringEmail();
    }
  }

  Future<void> showResendSmsDialog(String email) async {
    final bool resend =
        await showDialog(
          context: context,
          builder: (context) {
            return IrmaConfirmationDialog(
              titleTranslationKey:
                  "email_issuance.verify_code.resend_dialog.title",
              contentTranslationKey:
                  "email_issuance.verify_code.resend_dialog.body",
              confirmTranslationKey:
                  "email_issuance.verify_code.resend_dialog.confirm",
              cancelTranslationKey:
                  "email_issuance.verify_code.resend_dialog.cancel",
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
        .read(emailIssuanceProvider.notifier)
        .sendEmail(
          email: email,
          language: FlutterI18n.currentLocale(context)?.languageCode ?? "en",
        );
  }
}
