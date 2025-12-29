import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:go_router/go_router.dart";

import "../../../../../package_name.dart";
import "../../../../providers/email_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";
import "../../../error/error_screen.dart";

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

  var _validEmail = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final email = _textController.text;
      ref.read(emailIssuanceProvider.notifier).sendEmail(email: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final state = ref.watch(emailIssuanceProvider);
    final onScreenKeyboardShown = MediaQuery.of(context).viewInsets.bottom > 0;

    if (state.error.isNotEmpty) {
      return Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: "sms_issuance.verify_code.title",
        ),
        body: Padding(
          padding: .all(theme.defaultSpacing),
          child: Column(
            mainAxisSize: .max,
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            children: [
              SizedBox(height: theme.largeSpacing),
              SvgPicture.asset(
                yiviAsset("error/general_error_illustration.svg"),
              ),
              SizedBox(height: theme.largeSpacing),
              TranslatedText(
                "email_issuance.enter_email.error",
                textAlign: .center,
              ),
              SizedBox(height: theme.largeSpacing),
              YiviLinkButton(
                textAlign: .center,
                labelTranslationKey: "error.button_show_error",
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ErrorScreen(
                        onTapClose: context.pop,
                        type: .general,
                        details: state.error,
                        reportable: false,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: "error.button_retry",
          secondaryButtonLabel: "email_issuance.enter_email.back_button",
          onPrimaryPressed: () {
            ref
                .read(emailIssuanceProvider.notifier)
                .sendEmail(email: state.email);
          },
          onSecondaryPressed: context.pop,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        key: Key("$onScreenKeyboardShown"),
        appBar: IrmaAppBar(
          titleTranslationKey: "email_issuance.enter_email.title",
        ),
        body: SingleChildScrollView(
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
                  onChanged: () {
                    final valid = _formKey.currentState?.validate() ?? false;
                    if (valid != _validEmail) {
                      setState(() {
                        _validEmail = valid;
                      });
                    }
                  },
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      TextFormField(
                        controller: _textController,
                        focusNode: _focusNode,
                        key: const Key("email_input_field"),
                        keyboardType: .emailAddress,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: .none,
                        autovalidateMode: .onUserInteraction,
                        validator: (v) {
                          final value = (v ?? "").trim();
                          if (value.isEmpty) return "Enter your email";
                          if (!RegExp(
                            r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
                          ).hasMatch(value)) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // When the on-screen keyboard is shown we want to show the "send email" button above it
        // without the cancel button. When the keyboard is not showing we want to show both the send
        // and cancel button.
        floatingActionButtonAnimator: .noAnimation,
        floatingActionButton: onScreenKeyboardShown
            ? Padding(
                padding: .symmetric(horizontal: theme.defaultSpacing),
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
