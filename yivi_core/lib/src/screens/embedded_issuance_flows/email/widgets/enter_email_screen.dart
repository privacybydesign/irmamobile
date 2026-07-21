import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../providers/email_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/irma_card.dart";
import "../../../../widgets/keyboard_animation_listener.dart";
import "../../../../widgets/radio_indicator.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";
import "../../widgets/embedded_issuance_error_screen.dart";

bool isValidEmail(String value) {
  if (value.isEmpty) return false;
  return RegExp(
    r"^(?:[a-zA-Z0-9_+-])+(?:[\.+](?:[a-zA-Z0-9_-])+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$",
  ).hasMatch(value);
}

class EnterEmailScreen extends ConsumerStatefulWidget {
  /// When the verifier requested specific email addresses, they are passed
  /// here. The screen then locks its input to a choice between these
  /// addresses instead of showing a free-text field: any other address would
  /// not satisfy the disclosure request, so editing is not allowed.
  ///
  /// Values that are not email addresses are ignored: a verifier may
  /// constrain other attributes of this credential too (e.g. `domain`), and
  /// those values must not end up in the email input.
  final List<String> requestedEmails;

  const EnterEmailScreen({this.requestedEmails = const []});

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
  String? _selectedEmail;

  late final List<String> _requestedEmails = widget.requestedEmails
      .where(isValidEmail)
      .toList();

  bool get _lockedToRequestedEmails => _requestedEmails.isNotEmpty;

  bool get _canSubmit =>
      _lockedToRequestedEmails ? _selectedEmail != null : _validEmail;

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
    if (_lockedToRequestedEmails) {
      // Restore the earlier choice (when coming back from the verification
      // screen). A single requested address is the only possible choice, so
      // it is preselected; multiple addresses require an explicit choice.
      final enteredEmail = ref.read(emailIssuanceProvider).email;
      if (_requestedEmails.contains(enteredEmail)) {
        _selectedEmail = enteredEmail;
      } else if (_requestedEmails.length == 1) {
        _selectedEmail = _requestedEmails.single;
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.addListener(_handleFocusChange);
      _focusNode.requestFocus();

      // Use the previously entered email when coming back from the
      // verification screen.
      final enteredEmail = ref.read(emailIssuanceProvider).email;
      _textController.text = enteredEmail;
      if (isValidEmail(enteredEmail)) {
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
    if (_lockedToRequestedEmails) {
      final email = _selectedEmail;
      if (email == null) return;
      ref
          .read(emailIssuanceProvider.notifier)
          .sendEmail(
            email: email,
            language: FlutterI18n.currentLocale(context)?.languageCode ?? "en",
          );
      return;
    }
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
                      !_lockedToRequestedEmails
                          ? "email_issuance.enter_email.header"
                          : _requestedEmails.length == 1
                          ? "email_issuance.enter_email.header_requested"
                          : "email_issuance.enter_email.header_requested_multiple",
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: theme.neutralExtraDark,
                      ),
                    ),
                    SizedBox(height: theme.defaultSpacing),
                    TranslatedText(
                      !_lockedToRequestedEmails
                          ? "email_issuance.enter_email.body"
                          : _requestedEmails.length == 1
                          ? "email_issuance.enter_email.body_requested"
                          : "email_issuance.enter_email.body_requested_multiple",
                    ),
                    SizedBox(height: theme.largeSpacing),
                    if (_lockedToRequestedEmails)
                      Column(
                        crossAxisAlignment: .stretch,
                        children: [
                          // A single requested address leaves nothing to
                          // choose, so it renders as a plain fixed value
                          // without radio controls.
                          if (_requestedEmails.length == 1)
                            _RequestedEmailOption(
                              key: const Key("requested_email_option_0"),
                              email: _requestedEmails.single,
                            )
                          else
                            for (final (i, email)
                                in _requestedEmails.indexed) ...[
                              if (i > 0) SizedBox(height: theme.smallSpacing),
                              _RequestedEmailOption(
                                key: Key("requested_email_option_$i"),
                                email: email,
                                isSelected: email == _selectedEmail,
                                onTap: () =>
                                    setState(() => _selectedEmail = email),
                              ),
                            ],
                        ],
                      )
                    else
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
                                  final lower = v.toLowerCase();
                                  if (v != lower) {
                                    _textController.value = _textController
                                        .value
                                        .copyWith(
                                          text: lower,
                                          selection: TextSelection.collapsed(
                                            offset: _textController
                                                .selection
                                                .baseOffset,
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
                                  if (value.isEmpty) return "Enter your email";
                                  if (!isValidEmail(value)) {
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
                  onPressed: _canSubmit ? _submit : null,
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
                onPrimaryPressed: _canSubmit ? _submit : null,
                onSecondaryPressed: context.pop,
              ),
      ),
    );
  }
}

/// One of the addresses the verifier accepts. The address itself is always
/// fixed; the user can at most select it, never edit it. With [isSelected]
/// and [onTap] set it renders as a radio-style choice between multiple
/// addresses; without them it is a non-interactive display of the single
/// accepted address.
class _RequestedEmailOption extends StatelessWidget {
  final String email;
  final bool? isSelected;
  final VoidCallback? onTap;

  const _RequestedEmailOption({
    super.key,
    required this.email,
    this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final selected = isSelected;
    return IrmaCard(
      style: (selected ?? true)
          ? IrmaCardStyle.highlighted
          : IrmaCardStyle.outlined,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: Text(email, style: theme.textTheme.bodyLarge)),
          if (selected != null) ...[
            SizedBox(width: theme.smallSpacing),
            RadioIndicator(isSelected: selected),
          ],
        ],
      ),
    );
  }
}
