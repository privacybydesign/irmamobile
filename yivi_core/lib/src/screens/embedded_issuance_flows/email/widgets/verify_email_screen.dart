import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:pinput/pinput.dart";

import "../../../../../routing.dart";
import "../../../../models/email_code_pointer.dart";
import "../../../../providers/email_issuance_provider.dart";
import "../../../../providers/email_linking_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../util/handle_pointer.dart";
import "../../../../util/missing_data_flow.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/irma_confirmation_dialog.dart";
import "../../../../widgets/keyboard_animation_listener.dart";
import "../../../../widgets/missing_data_bottom_bar.dart";
import "../../../../widgets/missing_data_style.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";
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
  final _scrollController = ScrollController();
  final _codeFieldPositionKey = GlobalKey();
  final _textController = TextEditingController();

  var _codeComplete = false;
  var _codeFromLink = false;

  bool get _linking => widget.purpose == EmailIssuancePurpose.linkKeyshare;

  /// Whether the user is adding the address for a request, from the missing
  /// data checklist.
  bool get _collecting => !_linking && context.isCollectingMissingData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.addListener(_handleFocusChange);
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

    final theme = IrmaTheme.of(context);
    final codeInvalid = state.error is EmailIssuanceInvalidCodeError;
    // The code is sent with a button, as when linking.
    final explicitSubmit = _linking || _collecting;

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
          backgroundColor: _collecting ? theme.backgroundTertiary : null,
          appBar: context.issuanceAppBar(
            titleKey: titleKey,
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
                      SizedBox(
                        height: _collecting
                            ? theme.smallSpacing
                            : theme.defaultSpacing,
                      ),
                      TranslatedText(
                        _collecting
                            ? "missing_data.email.code_header"
                            : _linking
                            ? "email_linking.verify_code.header"
                            : "email_issuance.verify_code.header",
                        style: _collecting
                            ? missingDataHeadingStyle(theme)
                            : theme.textTheme.bodyLarge!.copyWith(
                                color: theme.neutralExtraDark,
                              ),
                      ),
                      SizedBox(height: theme.defaultSpacing),
                      if (_collecting)
                        _CodeSentText(email: state.email)
                      else
                        TranslatedText(
                          _linking
                              ? "email_linking.verify_code.body"
                              : "email_issuance.verify_code.body",
                          translationParams: {"email": state.email},
                        ),
                      SizedBox(
                        height: _collecting
                            ? theme.mediumSpacing
                            : theme.largeSpacing,
                      ),
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
                          length: emailCodeLength,
                          onChanged: explicitSubmit ? _codeChanged : null,
                          onCompleted: explicitSubmit ? null : _handleCode,
                          pinAnimationType: .scale,
                          hapticFeedbackType: .lightImpact,
                        ),
                      ),
                      if (state.error is EmailIssuanceInvalidCodeError)
                        TranslatedText(
                          "email_issuance.verify_code.invalid_code_error",
                          style: TextStyle(color: theme.error),
                        ),
                      if (_codeFromLink)
                        Semantics(
                          liveRegion: true,
                          child: TranslatedText(
                            "email_linking.verify_code.filled_from_link",
                            key: const Key("code_filled_from_link"),
                            style: TextStyle(color: theme.neutralExtraDark),
                          ),
                        ),
                      SizedBox(height: theme.largeSpacing),
                      if (!explicitSubmit)
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
          bottomNavigationBar: _collecting
              ? MissingDataBottomBar.buttons(
                  primaryButtonLabel: "missing_data.email.check_code",
                  onPrimaryPressed: _codeComplete
                      ? () => _handleCode(_textController.text)
                      : null,
                  secondaryButtonLabel: "missing_data.email.resend",
                  onSecondaryPressed: () => showResendSmsDialog(state.email),
                )
              : _linking
              ? IrmaBottomBar(
                  primaryButtonLabel: "email_linking.verify_code.next_button",
                  onPrimaryPressed: _codeComplete
                      ? () => _handleCode(_textController.text)
                      : null,
                  secondaryButtonLabel:
                      "email_linking.verify_code.resend_button",
                  onSecondaryPressed: () => showResendSmsDialog(state.email),
                )
              : IrmaBottomBar(
                  secondaryButtonLabel:
                      "email_issuance.verify_code.back_button",
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

    if (session == null || !mounted) return;

    final sessionId = await handlePointer(context, session);
    if (_linking && sessionId != null && mounted) {
      ref.read(emailLinkingProvider.notifier).trackIssuance(sessionId);
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

/// "We have sent an e-mail to {address}", with the address in bold.
class _CodeSentText extends StatelessWidget {
  final String email;

  const _CodeSentText({required this.email});

  @override
  Widget build(BuildContext context) {
    final style = IrmaTheme.of(context).textTheme.bodyMedium!;
    // The address goes in the middle of the sentence, in a different weight,
    // so translate around a marker and put it back as its own span.
    const marker = "\u0000";
    final parts = FlutterI18n.translate(
      context,
      "missing_data.email.code_body",
      translationParams: {"email": marker},
    ).split(marker);
    if (parts.length < 2) return Text(parts.first, style: style);

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: parts.first),
          TextSpan(
            text: email,
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: parts.last),
        ],
      ),
    );
  }
}
