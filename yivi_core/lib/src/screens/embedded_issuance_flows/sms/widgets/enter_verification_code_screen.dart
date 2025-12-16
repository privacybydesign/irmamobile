import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:pinput/pinput.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../util/handle_pointer.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/translated_text.dart";

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
        body: Padding(
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
              TranslatedText("sms_issuance.verify_code.body"),
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
            ],
          ),
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: "sms_issuance.verify_code.next_button",
          secondaryButtonLabel: "sms_issuance.verify_code.back_button",
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
}
