import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/session_state.dart";
import "../../../models/session_user_interaction.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/i18n.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/credential_card/card_attribute_list.dart";
import "../layout/session_scaffold.dart";
import "../models/disclosure_plan_view.dart";
import "signed_message.dart";

/// The disclosure (and signature) request of [session]: what is shared, and
/// one button. For now the cards in use by default, one after the other;
/// the add step, the overview and the change page replace this.
class DisclosureFlow extends ConsumerWidget {
  final SessionState session;
  final VoidCallback onDismiss;

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
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final plan = session.disclosurePlan ?? DisclosurePlan(choices: const []);
    final selection = ref.watch(disclosureSelectionProvider(session.id));
    final signing = session.type == SessionType.signature;
    final cards = sharedCards(plan, selection);
    final missing = missingDescriptors(plan);
    final ready = canShare(plan);

    return SessionScaffold(
      appBarTitle: signing ? "share.bar.sign" : "share.bar.share",
      onDismiss: onDismiss,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PrimaryPillButton(
            key: const Key("share_button"),
            label: context.tr(
              signing ? "share.button.sign_and_share" : "share.button.share",
            ),
            onPressed: ready
                ? () => onShare(answerFor(plan, selection), cards)
                : null,
          ),
        ),
      ),
      body: ListView(
        key: const Key("share_overview"),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(session.requestor.name, style: palette.titleSmall),
          if (signing && session.messageToSign != null) ...[
            const SizedBox(height: 16),
            Text(
              context.tr("share.message_label"),
              style: palette.sectionHeader,
            ),
            const SizedBox(height: 8),
            SignedMessage(
              key: const Key("share_message"),
              message: session.messageToSign!,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            context.tr("share.section.you_share"),
            style: palette.sectionHeader,
          ),
          for (final card in cards) ...[
            const SizedBox(height: 16),
            Text(card.name, style: palette.rowTitle),
            CardAttributeList(
              card.attributes,
              credentialId: card.credentialId,
              disclosure: true,
            ),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              context.tr("share.not_in_app_yet"),
              style: palette.sectionHeader,
            ),
            for (final d in missing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(d.name, style: palette.rowTitle),
              ),
          ],
        ],
      ),
    );
  }
}
