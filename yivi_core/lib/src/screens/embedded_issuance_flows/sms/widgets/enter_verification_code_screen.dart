import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:pinput/pinput.dart";

import "../../../../providers/sms_issuance_provider.dart";
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: TranslatedText("sms_issuance.verify_code.title"),
      ),
      body: Column(
        children: [
          TranslatedText("sms_issuance.verify_code.header"),
          TranslatedText("sms_issuance.verify_code.body"),
          Pinput(length: 6, onCompleted: _handleCode),
        ],
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "sms_issuance.verify_code.next_button",
        secondaryButtonLabel: "sms_issuance.verify_code.back_button",
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
