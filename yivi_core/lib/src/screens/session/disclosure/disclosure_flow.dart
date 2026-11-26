import "package:material_ui/material_ui.dart";

import "../../../models/session_state.dart";
import "../../../models/session_user_interaction.dart";
import "disclosure_overview_page.dart";

/// The disclosure (and signature) request of [session]. For now the
/// overview; the add step (before it) and "Kies wat je deelt" (from its
/// pile row) join it.
class DisclosureFlow extends StatelessWidget {
  final SessionState session;
  final VoidCallback onDismiss;

  /// Ends the session without asking.
  final VoidCallback onClose;

  /// Shares [choices]; [shared] are the cards that go, for the done screen.
  final void Function(
    List<ChoiceSelection> choices,
    List<SelectableCredentialInstance> shared,
  )
  onShare;

  const DisclosureFlow({
    super.key,
    required this.session,
    required this.onDismiss,
    required this.onClose,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) => DisclosureOverviewPage(
    session: session,
    onDismiss: onDismiss,
    onClose: onClose,
    onShare: onShare,
  );
}
