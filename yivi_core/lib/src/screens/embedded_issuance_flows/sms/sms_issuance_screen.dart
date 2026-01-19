import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../providers/sms_issuance_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
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
      .waiting => _WaitingScreen(),
    };
  }
}

class _WaitingScreen extends StatelessWidget {
  const _WaitingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      appBar: IrmaAppBar(titleTranslationKey: "sms_issuance.enter_phone.title"),
      body: Padding(
        padding: .all(theme.defaultSpacing),
        child: Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: IrmaBottomBar(
        secondaryButtonLabel: "sms_issuance.enter_phone.back_button",
        onSecondaryPressed: context.pop,
      ),
    );
  }
}
