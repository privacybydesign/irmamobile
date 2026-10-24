import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/email_code_pointer.dart";
import "../../../providers/email_issuance_provider.dart";
import "../../../providers/email_linking_provider.dart";
import "../widgets/contact_widgets.dart";
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
  ///
  /// A link without an address needs the address the user typed. Before one
  /// is typed, the code cannot be checked, so the link is dropped and the flow
  /// starts at the address.
  void _showCodeScreenFor(EmailCodePointer? link) {
    if (link == null || widget.purpose != EmailIssuancePurpose.linkKeyshare) {
      return;
    }
    final email = link.email;
    if (email == null) {
      final stage = ref.read(emailIssuanceProvider).stage;
      if (stage == .enteringEmail) {
        ref.read(emailLinkingProvider.notifier).takeLink();
      }
      return;
    }
    ref.read(emailIssuanceProvider.notifier).startVerification(email: email);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(emailLinkingProvider.select((state) => state.link), (_, link) {
      _showCodeScreenFor(link);
    });

    if (widget.purpose == EmailIssuancePurpose.linkKeyshare) {
      ref.watch(linkingFlowOpenProvider);
    }

    final state = ref.watch(emailIssuanceProvider);

    return switch (state.stage) {
      .enteringEmail => EnterEmailScreen(purpose: widget.purpose),
      .enteringVerificationCode => VerifyEmailScreen(purpose: widget.purpose),
      .waiting => const ContactWaitingScreen(
        titleKey: "email_issuance.enter_email.title",
        backKey: "email_issuance.enter_email.back_button",
      ),
    };
  }
}
