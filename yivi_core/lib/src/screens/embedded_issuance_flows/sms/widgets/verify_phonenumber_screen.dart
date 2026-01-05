import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:go_router/go_router.dart";
import "package:pinput/pinput.dart";

import "../../../../../package_name.dart";
import "../../../../providers/sms_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../util/handle_pointer.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/irma_confirmation_dialog.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";
import "../../../error/error_screen.dart";

class VerifyPhoneScreen extends ConsumerStatefulWidget {
  const VerifyPhoneScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _VerifyCodeScreenState();
  }
}

class _VerifyCodeScreenState extends ConsumerState<VerifyPhoneScreen> {
  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final state = ref.watch(smsIssuanceProvider);

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: TextStyle(
        fontSize: 25,
        color: Color.fromRGBO(30, 60, 87, 1),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceSecondary,
        borderRadius: .circular(10),
      ),
    );

    final focussedPinTheme = defaultPinTheme.copyWith(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: theme.surfaceSecondary,
        border: .all(color: theme.link),
        borderRadius: .circular(10),
      ),
    );

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
                "sms_issuance.verify_code.error",
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
          secondaryButtonLabel: "sms_issuance.verify_code.back_button",
          onPrimaryPressed: () {
            ref.read(smsIssuanceProvider.notifier).resetError();
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
        appBar: IrmaAppBar(
          titleTranslationKey: "sms_issuance.verify_code.title",
        ),
        body: SingleChildScrollView(
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
                Pinput(
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
              ],
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
        .verifyCode(code: code);

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
