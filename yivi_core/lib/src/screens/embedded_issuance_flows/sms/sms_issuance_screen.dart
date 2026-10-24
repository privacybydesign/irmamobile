import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/sms_issuance_provider.dart";
import "../widgets/contact_widgets.dart";
import "widgets/enter_phonenumber_screen.dart";
import "widgets/verify_phonenumber_screen.dart";

// ==========================================================

class SmsIssuanceScreen extends ConsumerWidget {
  const SmsIssuanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smsIssuanceProvider);

    return switch (state.stage) {
      .enteringPhoneNumber => EnterPhoneScreen(),
      .enteringVerificationCode => VerifyPhoneScreen(),
      .waiting => const ContactWaitingScreen(
        titleKey: "sms_issuance.enter_phone.title",
        backKey: "sms_issuance.enter_phone.back_button",
      ),
    };
  }
}
