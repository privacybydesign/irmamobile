import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../../data/feature_flags.dart";
import "../../../../providers/email_issuance_provider.dart";
import "../../../../providers/feature_flag_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../util/missing_data_flow.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/keyboard_animation_listener.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_text_field.dart";
import "../../../../widgets/yivi_themed_button.dart";
import "../../widgets/embedded_issuance_error_screen.dart";

bool isValidEmail(String value) {
  if (value.isEmpty) return false;
  return RegExp(
    r"^(?:[a-zA-Z0-9_+-])+(?:[\.+](?:[a-zA-Z0-9_-])+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$",
  ).hasMatch(value);
}

class EnterEmailScreen extends ConsumerStatefulWidget {
  final EmailIssuancePurpose purpose;

  const EnterEmailScreen({this.purpose = EmailIssuancePurpose.addCredential});

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

  bool get _formFieldsV2 =>
      ref.read(featureFlagProvider(FeatureFlag.formFieldsV2)).value ?? false;

  // Translated with form fields V2 on; the old English text is kept without it.
  String _message(String key, String legacy) => _formFieldsV2
      ? FlutterI18n.translate(context, "email_issuance.enter_email.$key")
      : legacy;

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
      if (isValidEmail(email)) {
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

  Widget _buildEmailField(
    InputDecoration decoration,
    FormFieldErrorBuilder? errorBuilder,
    TextStyle? style,
  ) {
    return TextFormField(
      decoration: decoration,
      errorBuilder: errorBuilder,
      style: style,
      controller: _textController,
      focusNode: _focusNode,
      key: const Key("email_input_field"),
      keyboardType: .emailAddress,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: .none,
      autovalidateMode: _showErrors ? .onUserInteraction : .disabled,
      onChanged: (v) {
        final lower = v.toLowerCase();
        if (v != lower) {
          _textController.value = _textController.value.copyWith(
            text: lower,
            selection: TextSelection.collapsed(
              offset: _textController.selection.baseOffset,
            ),
          );
        }
        final ok = isValidEmail(lower);
        if (ok != _validEmail) {
          setState(() => _validEmail = ok);
        }
      },
      validator: (v) {
        final value = (v ?? "").trim();
        if (value.isEmpty) {
          return _message("email_required", "Enter your email");
        }
        if (!isValidEmail(value)) {
          return _message("email_invalid", "Enter a valid email");
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailIssuanceProvider);
    final linking = widget.purpose == EmailIssuancePurpose.linkKeyshare;
    final titleKey = linking
        ? "email_linking.enter_email.title"
        : "email_issuance.enter_email.title";

    if (state.error is! EmailIssuanceNoError) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: titleKey,
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
    final formFieldsV2 =
        ref.watch(featureFlagProvider(FeatureFlag.formFieldsV2)).value ?? false;
    final media = MediaQuery.of(context);
    final onScreenKeyboardShown = media.viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        key: Key("$onScreenKeyboardShown"),
        backgroundColor: formFieldsV2 ? theme.fieldPageBackground : null,
        appBar: IrmaAppBar(
          bottom: context.missingDataBand,
          titleTranslationKey: titleKey,
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
                    SizedBox(
                      height: formFieldsV2
                          ? theme.smallSpacing
                          : theme.defaultSpacing,
                    ),
                    TranslatedText(
                      linking
                          ? "email_linking.enter_email.header"
                          : "email_issuance.enter_email.header",
                      style: formFieldsV2
                          ? theme.fieldScreenHeading
                          : theme.textTheme.bodyLarge!.copyWith(
                              color: theme.neutralExtraDark,
                            ),
                    ),
                    SizedBox(height: theme.defaultSpacing),
                    TranslatedText(
                      linking
                          ? "email_linking.enter_email.body"
                          : formFieldsV2
                          ? "email_issuance.enter_email.body_v2"
                          : "email_issuance.enter_email.body",
                    ),
                    SizedBox(
                      height: formFieldsV2
                          ? theme.mediumSpacing
                          : theme.largeSpacing,
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: .stretch,
                        children: [
                          Container(
                            key: _emailFieldPositionKey,
                            child: YiviTextField(
                              label: FlutterI18n.translate(
                                context,
                                linking
                                    ? "email_linking.enter_email.label"
                                    : "email_issuance.enter_email.email_label",
                              ),
                              hint: FlutterI18n.translate(
                                context,
                                "email_issuance.enter_email.email_placeholder",
                              ),
                              legacyDecoration: linking
                                  ? InputDecoration(
                                      labelText: FlutterI18n.translate(
                                        context,
                                        "email_linking.enter_email.label",
                                      ),
                                    )
                                  : InputDecoration(
                                      hint: TranslatedText(
                                        "email_issuance.enter_email.email_hint",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                              builder: _buildEmailField,
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
                secondaryButtonLabel: context.missingDataBackLabel(
                  "email_issuance.enter_email.back_button",
                ),
                onPrimaryPressed: _validEmail ? _submit : null,
                onSecondaryPressed: context.missingDataBack(context.pop),
              ),
      ),
    );
  }
}
