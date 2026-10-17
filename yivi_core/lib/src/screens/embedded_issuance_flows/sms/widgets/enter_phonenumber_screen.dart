import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../widgets/glass/glass_dialog.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/keyboard_animation_listener.dart";
import "../../../../widgets/yivi_themed_button.dart";
import "../../widgets/contact_widgets.dart";
import "../../widgets/embedded_issuance_error_screen.dart";
import "phone_number_entry.dart";

class EnterPhoneScreen extends ConsumerStatefulWidget {
  const EnterPhoneScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _EnterPhoneScreenState();
  }
}

class _EnterPhoneScreenState extends ConsumerState<EnterPhoneScreen> {
  final _entryKey = GlobalKey<PhoneNumberEntryState>();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _phoneFieldPositionKey = GlobalKey();

  // key used to maintain the scrollable's state when the scaffold key updates
  // and thus voids its own state
  final _scrollableKey = GlobalKey();

  var _validPhoneNumber = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
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

  void _submit() {
    final phone = _entryKey.currentState?.submittable();
    if (phone != null) {
      ref
          .read(smsIssuanceProvider.notifier)
          .sendSms(
            phoneNumber: phone,
            language: FlutterI18n.currentLocale(context)?.languageCode ?? "en",
          );
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final phoneFieldContext = _phoneFieldPositionKey.currentContext;
        if (phoneFieldContext == null) {
          return;
        }

        Scrollable.ensureVisible(
          phoneFieldContext,
          alignment: 0.1,
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsIssuanceProvider);

    if (state.error is! SmsIssuanceNoError) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: "sms_issuance.verify_code.title",
        contentTranslationKey: "sms_issuance.enter_phone.error",
        errorMessage: state.error.toString(),
        onTryAgain: () {
          ref
              .read(smsIssuanceProvider.notifier)
              .sendSms(
                phoneNumber: state.phoneNumber,
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
          titleTranslationKey: "sms_issuance.enter_phone.title",
          hasBorder: false,
        ),
        body: KeyboardAnimationListener(
          key: _scrollableKey,
          onKeyboardSettled: (context, inset, visible) {
            _handleFocusChange();
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SafeArea(
              child: Padding(
                padding: .all(theme.defaultSpacing),
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    SizedBox(height: theme.defaultSpacing),
                    const ContactIntro(
                      icon: Icons.smartphone_rounded,
                      tone: DialogTone.success,
                      headerKey: "sms_issuance.enter_phone.header",
                      bodyKey: "sms_issuance.enter_phone.body",
                    ),
                    const ContactFieldLabel("sms_issuance.enter_phone.label"),
                    Container(
                      key: _phoneFieldPositionKey,
                      child: PhoneNumberEntry(
                        key: _entryKey,
                        focusNode: _focusNode,
                        onValidChanged: (valid) {
                          if (mounted) {
                            setState(() => _validPhoneNumber = valid);
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),

        // When the on-screen keyboard is shown we want to show the "send sms" button above it
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
                  label: "sms_issuance.enter_phone.next_button",
                  onPressed: _validPhoneNumber ? _submit : null,
                ),
              )
            : null,
        floatingActionButtonLocation: .centerFloat,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: onScreenKeyboardShown
            ? null
            : IrmaBottomBar(
                primaryButtonLabel: "sms_issuance.enter_phone.next_button",
                secondaryButtonLabel: "sms_issuance.enter_phone.back_button",
                onPrimaryPressed: _validPhoneNumber ? _submit : null,
                onSecondaryPressed: context.pop,
              ),
      ),
    );
  }
}
