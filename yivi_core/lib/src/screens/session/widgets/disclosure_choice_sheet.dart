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

/// Opens the sheet in which the user picks what to share for the
/// [DisclosurePickOne] at [disconIndex]. A tap on an owned option calls
/// [onChoiceMade] with its index in `ownedOptions` and closes the sheet.
///
/// The sheet stays open while an option is obtained through [onObtain].
/// [onSelected] is called whenever a bundle becomes selected for this choice,
/// including the one the app selects after the credential was obtained.
Future<void> showDisclosureChoiceSheet({
  required BuildContext context,
  required DisclosurePickOne pickOne,
  required int sessionId,
  required int disconIndex,
  required String requestorName,
  required ValueChanged<int> onChoiceMade,
  required ValueChanged<CredentialDescriptor> onObtain,
  VoidCallback? onSelected,
}) {
  return showYiviBottomSheet(
    context: context,
    titleKey: "disclosure_permission.choice.sheet_title",
    child: DisclosureChoiceSheet(
      pickOne: pickOne,
      sessionId: sessionId,
      disconIndex: disconIndex,
      requestorName: requestorName,
      onChoiceMade: onChoiceMade,
      onObtain: onObtain,
      onSelected: onSelected,
    ),
  );
}

/// Content of the sheet from [showDisclosureChoiceSheet]: the owned options as
/// cards with the current one highlighted, then the options that are not in
/// the app yet as rows with an "Obtain" hint. There is no confirm button.
class DisclosureChoiceSheet extends ConsumerWidget {
  final DisclosurePickOne pickOne;
  final int sessionId;
  final int disconIndex;
  final String requestorName;
  final ValueChanged<int> onChoiceMade;
  final ValueChanged<CredentialDescriptor> onObtain;
  final VoidCallback? onSelected;

  const DisclosureChoiceSheet({
    super.key,
    required this.pickOne,
    required this.sessionId,
    required this.disconIndex,
    required this.requestorName,
    required this.onChoiceMade,
    required this.onObtain,
    this.onSelected,
  });

  /// The index in [owned] of the bundle the user has selected, matched by
  /// credential hashes like the share screen does. Defaults to 0.
  static int _currentIndex(
    List<DisclosureBundle> owned,
    DisclosureBundle? selected,
  ) {
    if (selected == null) return 0;

    final hashes = selected.credentialHashes;
    final index = owned.indexWhere(
      (b) =>
          b.credentialHashes.length == hashes.length &&
          b.credentialHashes.containsAll(hashes),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final selectedBundle = sessionUserChoicesProvider(
      sessionId,
    ).select((choices) => choices.disclosureChoices[disconIndex]);

    ref.listen(selectedBundle, (previous, next) {
      if (next != null && next != previous) onSelected?.call();
    });

    // The session gets new owned options while the sheet is open once a
    // credential has been obtained, so prefer its live state.
    final choices = ref
        .watch(sessionStateProvider(sessionId))
        .value
        ?.disclosurePlan
        ?.disclosureChoicesOverview;
    final live = choices != null && disconIndex < choices.length
        ? choices[disconIndex]
        : pickOne;
    final owned = live.ownedOptions ?? [];
    final obtainable = live.obtainableOptions ?? [];

    final currentIndex = _currentIndex(owned, ref.watch(selectedBundle));

    void pick(int index) {
      onChoiceMade(index);
      Navigator.of(context).pop();
    }

    return Padding(
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            "disclosure_permission.choice.sheet_explanation",
            translationParams: {
              "requestor": requestorName,
              "options": joinChoiceNames(context, pickOneNames(live)),
            },
            style: theme.themeData.textTheme.bodyMedium,
          ),
          SizedBox(height: theme.defaultSpacing),
          for (var i = 0; i < owned.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: theme.smallSpacing),
              child: _OwnedOption(
                bundle: owned[i],
                style: i == currentIndex
                    ? IrmaCardStyle.highlighted
                    : IrmaCardStyle.normal,
                onTap: () => pick(i),
              ),
            ),
          for (final descriptor in obtainable)
            Padding(
              padding: EdgeInsets.only(bottom: theme.smallSpacing),
              child: ChoiceOptionRow(
                name: descriptor.name,
                logo: descriptor.image,
                onTap: descriptor.issueURL != null
                    ? () => onObtain(descriptor)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// An owned option: one card per credential in the bundle, all tappable.
class _OwnedOption extends StatelessWidget {
  final DisclosureBundle bundle;
  final IrmaCardStyle style;
  final VoidCallback onTap;

  const _OwnedOption({
    required this.bundle,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final credentials = bundle.credentials;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < credentials.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i < credentials.length - 1 ? theme.smallSpacing : 0,
            ),
            child: Semantics(
              container: true,
              button: true,
              selected: style == IrmaCardStyle.highlighted,
              child: YiviCredentialCard.fromSelectableInstance(
                instance: credentials[i],
                compact: true,
                hideFooter: true,
                style: style,
                onTap: onTap,
              ),
            ),
          ),
      ],
    );
  }
}
