import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_bottom_sheet.dart";
import "choice_option_row.dart";

/// Opens the sheet in which the user picks what to share for a
/// [DisclosurePickOne]. Tapping an owned option calls [onChoiceMade] with its
/// index in `ownedOptions` and closes the sheet.
///
/// [onObtained] is called when a credential obtained from the sheet has been
/// selected for this choice.
Future<void> showDisclosureChoiceSheet({
  required BuildContext context,
  required DisclosurePickOne pickOne,
  required int sessionId,
  required int disconIndex,
  required int initialSelectedIndex,
  required String requestorName,
  required ValueChanged<int> onChoiceMade,
  required ValueChanged<CredentialDescriptor> onObtain,
  VoidCallback? onObtained,
}) {
  return showYiviBottomSheet(
    context: context,
    titleKey: "disclosure_permission.choice.sheet_title",
    child: DisclosureChoiceSheet(
      pickOne: pickOne,
      sessionId: sessionId,
      disconIndex: disconIndex,
      initialSelectedIndex: initialSelectedIndex,
      requestorName: requestorName,
      onChoiceMade: onChoiceMade,
      onObtain: onObtain,
      onObtained: onObtained,
    ),
  );
}

/// Content of the sheet from [showDisclosureChoiceSheet]: the owned options as
/// cards, the current one highlighted, and the options that are not in the app
/// yet as rows with an "Obtain" hint. There is no confirm button, a tap picks.
class DisclosureChoiceSheet extends ConsumerStatefulWidget {
  final DisclosurePickOne pickOne;
  final int sessionId;
  final int disconIndex;
  final int initialSelectedIndex;
  final String requestorName;
  final ValueChanged<int> onChoiceMade;
  final ValueChanged<CredentialDescriptor> onObtain;
  final VoidCallback? onObtained;

  const DisclosureChoiceSheet({
    super.key,
    required this.pickOne,
    required this.sessionId,
    required this.disconIndex,
    required this.initialSelectedIndex,
    required this.requestorName,
    required this.onChoiceMade,
    required this.onObtain,
    this.onObtained,
  });

  @override
  ConsumerState<DisclosureChoiceSheet> createState() =>
      _DisclosureChoiceSheetState();
}

class _DisclosureChoiceSheetState extends ConsumerState<DisclosureChoiceSheet> {
  late int _selectedIndex = widget.initialSelectedIndex;

  /// The choice as it is now in the session, which has new options once a
  /// credential has been obtained. Falls back to the one the sheet opened with.
  DisclosurePickOne _livePickOne(SessionState? session) {
    final choices = session?.disclosurePlan?.disclosureChoicesOverview;
    if (choices == null || widget.disconIndex >= choices.length) {
      return widget.pickOne;
    }
    return choices[widget.disconIndex];
  }

  void _onPick(int index) {
    widget.onChoiceMade(index);
    Navigator.of(context).pop();
  }

  /// Highlights the bundle that the provider selected after a credential was
  /// obtained from this sheet.
  void _syncFromProvider(
    DisclosureBundle? previousBundle,
    DisclosureBundle? nextBundle,
  ) {
    if (!mounted || nextBundle == null) return;

    final nextHashes = nextBundle.credentialHashes;
    final prevHashes = previousBundle?.credentialHashes;
    if (prevHashes != null &&
        prevHashes.length == nextHashes.length &&
        prevHashes.containsAll(nextHashes)) {
      return;
    }

    final session = ref.read(sessionStateProvider(widget.sessionId)).value;
    final owned = _livePickOne(session).ownedOptions ?? [];
    final index = owned.indexWhere(
      (b) =>
          b.credentialHashes.length == nextHashes.length &&
          b.credentialHashes.containsAll(nextHashes),
    );
    if (index < 0) return;

    widget.onObtained?.call();
    setState(() => _selectedIndex = index);
  }

  Widget _buildOwnedOption(DisclosureBundle bundle, int index) {
    final theme = IrmaTheme.of(context);
    final isCurrent = index == _selectedIndex;
    final credentials = bundle.credentials;

    return Semantics(
      selected: isCurrent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < credentials.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < credentials.length - 1 ? theme.smallSpacing : 0,
              ),
              child: YiviCredentialCard.fromSelectableInstance(
                instance: credentials[i],
                compact: true,
                hideFooter: true,
                style: isCurrent
                    ? IrmaCardStyle.highlighted
                    : IrmaCardStyle.normal,
                onTap: () => _onPick(index),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionUserChoices>(
      sessionUserChoicesProvider(widget.sessionId),
      (previous, next) => _syncFromProvider(
        previous?.disclosureChoices[widget.disconIndex],
        next.disclosureChoices[widget.disconIndex],
      ),
    );

    final session = ref.watch(sessionStateProvider(widget.sessionId)).value;
    final theme = IrmaTheme.of(context);
    final pickOne = _livePickOne(session);
    final owned = pickOne.ownedOptions ?? [];
    final obtainable = pickOne.obtainableOptions ?? [];

    return Padding(
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            "disclosure_permission.choice.sheet_explanation",
            translationParams: {
              "requestor": widget.requestorName,
              "options": joinChoiceLabels(context, pickOneLabels(pickOne)),
            },
            style: theme.themeData.textTheme.bodyMedium,
          ),
          SizedBox(height: theme.defaultSpacing),
          for (var i = 0; i < owned.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: theme.smallSpacing),
              child: _buildOwnedOption(owned[i], i),
            ),
          for (final descriptor in obtainable)
            Padding(
              padding: EdgeInsets.only(bottom: theme.smallSpacing),
              child: ChoiceOptionRow(
                name: descriptor.name,
                logo: descriptor.image,
                onTap: descriptor.issueURL != null
                    ? () => widget.onObtain(descriptor)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
