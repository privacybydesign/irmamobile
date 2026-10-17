import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/email_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../widgets/glass/glass_dialog.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/keyboard_animation_listener.dart";
import "../../../../widgets/yivi_themed_button.dart";
import "../../widgets/contact_widgets.dart";
import "../../widgets/embedded_issuance_error_screen.dart";
import "email_address_entry.dart";

class EnterEmailScreen extends ConsumerStatefulWidget {
  final EmailIssuancePurpose purpose;

  const EnterEmailScreen({this.purpose = EmailIssuancePurpose.addCredential});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _EnterEmailScreenState();
  }
}

class _EnterEmailScreenState extends ConsumerState<EnterEmailScreen> {
  final _entryKey = GlobalKey<EmailAddressEntryState>();
  final _focusNode = FocusNode();
  final _scrollableKey = GlobalKey();
  final _scrollController = ScrollController();
  final _emailFieldPositionKey = GlobalKey();

  var _validEmail = false;

  @override
  void dispose() {
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
    final email = _entryKey.currentState?.submittable();
    if (email != null) {
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
    final palette = YiviPalette.of(context);
    final media = MediaQuery.of(context);
    final onScreenKeyboardShown = media.viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        key: Key("$onScreenKeyboardShown"),
        backgroundColor: palette.background,
        appBar: IrmaAppBar(
          titleTranslationKey: titleKey,
          hasBorder: false,
        ),
        body: KeyboardAnimationListener(
          onKeyboardSettled: (context, inset, visible) {
            _handleFocusChange();
          },
          key: _scrollableKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SafeArea(
              child: Padding(
                padding: .all(theme.defaultSpacing),
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    SizedBox(height: theme.defaultSpacing),
                    ContactIntro(
                      icon: Icons.mail_rounded,
                      tone: DialogTone.warning,
                      headerKey: linking
                          ? "email_linking.enter_email.header"
                          : "email_issuance.enter_email.header",
                      bodyKey: linking
                          ? "email_linking.enter_email.body"
                          : "email_issuance.enter_email.body",
                    ),
                    ContactFieldLabel(
                      linking
                          ? "email_linking.enter_email.label"
                          : "email_issuance.enter_email.label",
                    ),
                    Container(
                      key: _emailFieldPositionKey,
                      child: EmailAddressEntry(
                        key: _entryKey,
                        focusNode: _focusNode,
                        onValidChanged: (valid) =>
                            setState(() => _validEmail = valid),
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
