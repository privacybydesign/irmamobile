import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../providers/sms_issuance_provider.dart";
import "widgets/enter_phonenumber_screen.dart";
import "widgets/enter_verification_code_screen.dart";

// ==========================================================

class SmsIssuanceScreen extends ConsumerWidget {
  const SmsIssuanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smsIssuanceProvider);

    return switch (state.stage) {
      .enteringPhoneNumber => EnterPhoneScreen(),
      .enteringVerificationCode => VerifyCodeScreen(),
      .waiting => CircularProgressIndicator(),
    };
  }
}
