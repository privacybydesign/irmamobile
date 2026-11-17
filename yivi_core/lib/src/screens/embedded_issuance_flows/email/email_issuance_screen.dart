import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/email_code_pointer.dart";
import "../../../providers/contact_issuance_provider.dart";
import "../../../providers/email_linking_provider.dart";
import "../../../util/after_frame.dart";
import "../widgets/contact_widgets.dart";
import "widgets/enter_email_screen.dart";
import "widgets/verify_email_screen.dart";

/// Linking an e-mail address to the keyshare server, full-screen: the
/// address, then the code.
class EmailIssuanceScreen extends ConsumerStatefulWidget {
  const EmailIssuanceScreen({super.key});

  @override
  ConsumerState<EmailIssuanceScreen> createState() =>
      _EmailIssuanceScreenState();
}

class _EmailIssuanceScreenState extends ConsumerState<EmailIssuanceScreen> {
  static final _flow = contactIssuanceProvider(ContactFlow.linkEmail);

  @override
  void initState() {
    super.initState();
    afterFrame(() {
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
    if (link == null) return;
    final email = link.email;
    if (email == null) {
      final stage = ref.read(_flow).stage;
      if (stage == ContactStage.address) {
        ref.read(emailLinkingProvider.notifier).takeLink();
      }
      return;
    }
    ref.read(_flow.notifier).codeOnItsWay(email);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(emailLinkingProvider.select((state) => state.link), (_, link) {
      _showCodeScreenFor(link);
    });

    final state = ref.watch(_flow);

    return switch (state.stage) {
      ContactStage.address => const EnterEmailScreen(),
      ContactStage.code => const VerifyEmailScreen(),
      ContactStage.sending => const ContactWaitingScreen(
        titleKey: "email_issuance.enter_email.title",
        backKey: "email_issuance.enter_email.back_button",
      ),
    };
  }
}
