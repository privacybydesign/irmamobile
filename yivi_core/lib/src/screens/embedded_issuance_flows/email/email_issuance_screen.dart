import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../providers/email_issuance_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "widgets/enter_email_screen.dart";
import "widgets/verify_email_screen.dart";

// ==========================================================

class EmailIssuanceScreen extends ConsumerWidget {
  const EmailIssuanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emailIssuanceProvider);

    return switch (state.stage) {
      .enteringEmail => EnterEmailScreen(),
      .enteringVerificationCode => VerifyEmailScreen(),
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
      appBar: IrmaAppBar(
        titleTranslationKey: "email_issuance.enter_email.title",
      ),
      body: Padding(
        padding: .all(theme.defaultSpacing),
        child: Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: IrmaBottomBar(
        secondaryButtonLabel: "email_issuance.enter_email.back_button",
        onSecondaryPressed: context.pop,
      ),
    );
  }
}
