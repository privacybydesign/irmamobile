import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../providers/email_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/keyboard_animation_listener.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";
import "../../widgets/embedded_issuance_error_screen.dart";

class EnterEmailScreen extends ConsumerStatefulWidget {
  const EnterEmailScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _EnterEmailScreenState();
  }
}

class _EnterEmailScreenState extends ConsumerState<EnterEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollableKey = GlobalKey();
  final _scrollController = ScrollController();
  final _emailFieldPositionKey = GlobalKey();

  var _validEmail = false;
  var _showErrors = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.addListener(_handleFocusChange);
      _focusNode.requestFocus();

      // set text to previously entered email (for when coming back from verification screen)
      final email = ref.read(emailIssuanceProvider).email;
      _textController.text = email;
      if (_isValidEmail(email)) {
        setState(() {
          _validEmail = true;
        });
      }
    });
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final emailFieldContext = _emailFieldPositionKey.currentContext;
        if (emailFieldContext == null) {
          return;
        }

        Scrollable.ensureVisible(
          emailFieldContext,
          alignment: 0.0,
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _submit() {
    setState(() {
      _showErrors = true;
    });
    if (_formKey.currentState!.validate()) {
      final email = _textController.text;
      ref
          .read(emailIssuanceProvider.notifier)
          .sendEmail(
            email: email,
            language: FlutterI18n.currentLocale(context)?.languageCode ?? "en",
          );
    }
  }

  bool _isValidEmail(String value) {
    if (value.isEmpty) return false;
    return RegExp(
      r"^(?:[a-zA-Z0-9_+-])+(?:[\.+](?:[a-zA-Z0-9_-])+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$",
    ).hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailIssuanceProvider);

    if (state.error is! EmailIssuanceNoError) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: "email_issuance.enter_email.title",
        contentTranslationKey: "email_issuance.enter_email.error",
        errorMessage: state.error.toString(),
        onTryAgain: () {
          ref
              .read(emailIssuanceProvider.notifier)
              .sendEmail(
                email: state.email,
                language:
                    FlutterI18n.currentLocale(context)?.languageCode ?? "en",
              );
        },
      );
    }

    final theme = IrmaTheme.of(context);
    final media = MediaQuery.of(context);
    final onScreenKeyboardShown = media.viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        key: Key("$onScreenKeyboardShown"),
        appBar: IrmaAppBar(
          titleTranslationKey: "email_issuance.enter_email.title",
        ),
        body: SafeArea(
          child: KeyboardAnimationListener(
            onKeyboardSettled: (context, inset, visible) {
              _handleFocusChange();
            },
            key: _scrollableKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: .all(theme.defaultSpacing),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    SizedBox(height: theme.defaultSpacing),
                    TranslatedText(
                      "email_issuance.enter_email.header",
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: theme.neutralExtraDark,
                      ),
                    ),
                    SizedBox(height: theme.defaultSpacing),
                    TranslatedText("email_issuance.enter_email.body"),
                    SizedBox(height: theme.largeSpacing),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: .stretch,
                        children: [
                          Container(
                            key: _emailFieldPositionKey,
                            child: TextFormField(
                              decoration: InputDecoration(
                                hint: TranslatedText(
                                  "email_issuance.enter_email.email_hint",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              controller: _textController,
                              focusNode: _focusNode,
                              key: const Key("email_input_field"),
                              keyboardType: .emailAddress,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              enableSuggestions: false,
                              textCapitalization: .none,
                              autovalidateMode: _showErrors
                                  ? .onUserInteraction
                                  : .disabled,
                              onChanged: (v) {
                                final ok = _isValidEmail(v);
                                if (ok != _validEmail) {
                                  setState(() => _validEmail = ok);
                                }
                              },
                              validator: (v) {
                                final value = (v ?? "").trim();
                                if (value.isEmpty) return "Enter your email";
                                if (!_isValidEmail(value)) {
                                  return "Enter a valid email";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),

        // When the on-screen keyboard is shown we want to show the "send email" button above it
        // without the cancel button. When the keyboard is not showing we want to show both the send
        // and cancel button.
        floatingActionButtonAnimator: .noAnimation,
        floatingActionButton: onScreenKeyboardShown
            ? Padding(
                padding: .only(
                  left: theme.defaultSpacing + media.padding.left,
                  right: theme.defaultSpacing + media.padding.right,
                ),
                child: YiviThemedButton(
                  label: "email_issuance.enter_email.next_button",
                  onPressed: _validEmail ? _submit : null,
                ),
              )
            : null,
        floatingActionButtonLocation: .centerFloat,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: onScreenKeyboardShown
            ? null
            : IrmaBottomBar(
                primaryButtonLabel: "email_issuance.enter_email.next_button",
                secondaryButtonLabel: "email_issuance.enter_email.back_button",
                onPrimaryPressed: _validEmail ? _submit : null,
                onSecondaryPressed: context.pop,
              ),
      ),
    );
  }
}
