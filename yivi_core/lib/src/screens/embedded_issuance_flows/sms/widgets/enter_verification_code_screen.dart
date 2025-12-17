import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:pinput/pinput.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../util/handle_pointer.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/irma_confirmation_dialog.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";

class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _VerifyCodeScreenState();
  }
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
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
                if (state.error != null)
                  Text(state.error!, style: TextStyle(color: theme.error)),

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

    if (!resend) {
      return;
    }

    ref.read(smsIssuanceProvider.notifier).sendSms(phoneNumber: phoneNumber);
  }
}
