import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/email_code_pointer.dart";
import "../../../providers/email_issuance_provider.dart";
import "../../../providers/email_linking_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "widgets/enter_email_screen.dart";
import "widgets/verify_email_screen.dart";

// ==========================================================

class EmailIssuanceScreen extends ConsumerStatefulWidget {
  final EmailIssuancePurpose purpose;

  const EmailIssuanceScreen({
    super.key,
    this.purpose = EmailIssuancePurpose.addCredential,
  });

  @override
  ConsumerState<EmailIssuanceScreen> createState() =>
      _EmailIssuanceScreenState();
}

class _EmailIssuanceScreenState extends ConsumerState<EmailIssuanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCodeScreenFor(ref.read(emailLinkingProvider).link);
    });
  }

  /// The link in the e-mail skips sending, so go straight to the code screen,
  /// which then picks the link up and fills in the code.
  void _showCodeScreenFor(EmailCodePointer? link) {
    if (link == null || widget.purpose != EmailIssuancePurpose.linkKeyshare) {
      return;
    }
    ref
        .read(emailIssuanceProvider.notifier)
        .startVerification(email: link.email);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(emailLinkingProvider.select((state) => state.link), (_, link) {
      _showCodeScreenFor(link);
    });

    final state = ref.watch(emailIssuanceProvider);

    return switch (state.stage) {
      .enteringEmail => EnterEmailScreen(purpose: widget.purpose),
      .enteringVerificationCode => VerifyEmailScreen(purpose: widget.purpose),
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
