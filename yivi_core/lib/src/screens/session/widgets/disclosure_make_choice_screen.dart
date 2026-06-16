import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/radio_indicator.dart";
import "../../../widgets/section_header.dart";
import "disclosure_permission_choice.dart";
import "session_scaffold.dart";

/// Selection type: either an owned credential (by index) or an obtainable one.
sealed class _Selection {
  const _Selection();
}

class _OwnedSelection extends _Selection {
  final int index;
  const _OwnedSelection(this.index);
}

class _ObtainableSelection extends _Selection {
  final int index;
  const _ObtainableSelection(this.index);
}

/// Submenu screen for choosing between the available options in a [DisclosurePickOne].
///
/// Shows owned credentials first (selectable with radio buttons), then
/// obtainable credentials below. When an owned option is selected, the bottom
/// bar shows a "Done" button. When an obtainable option is selected, it shows
/// an "Obtain data" button that opens the issue URL.
class DisclosureMakeChoiceScreen extends ConsumerStatefulWidget {
  final DisclosurePickOne pickOne;
  final int initialSelectedIndex;
  final ValueChanged<int> onChoiceMade;
  final int sessionId;
  final int disconIndex;
  final bool addOptional;

  const DisclosureMakeChoiceScreen({
    super.key,
    required this.pickOne,
    required this.initialSelectedIndex,
    required this.onChoiceMade,
    required this.sessionId,
    required this.disconIndex,
    this.addOptional = false,
  });

  @override
  ConsumerState<DisclosureMakeChoiceScreen> createState() =>
      _DisclosureMakeChoiceScreenState();
}

class _DisclosureMakeChoiceScreenState
    extends ConsumerState<DisclosureMakeChoiceScreen> {
  late _Selection _selection;

  @override
  void initState() {
    super.initState();
    final hasOwned = (widget.pickOne.ownedOptions ?? []).isNotEmpty;
    if (hasOwned) {
      _selection = _OwnedSelection(widget.initialSelectedIndex);
    } else if ((widget.pickOne.obtainableOptions ?? []).isNotEmpty) {
      _selection = const _ObtainableSelection(0);
    } else {
      _selection = const _OwnedSelection(0);
    }
  }

  bool get _isOwnedSelected => _selection is _OwnedSelection;

  bool _selectedObtainableIsObtainable(List<CredentialDescriptor> obtainable) {
    final sel = _selection;
    if (sel is! _ObtainableSelection) return false;
    if (sel.index >= obtainable.length) return false;
    return obtainable[sel.index].issueURL != null;
  }

  void _onObtainData(List<CredentialDescriptor> obtainable) {
    final sel = _selection;
    if (sel is! _ObtainableSelection) return;
    if (sel.index >= obtainable.length) return;

    final cred = obtainable[sel.index];
    context.pushSchemalessDataDetailsScreen(
      AddDataDetailsRouteParams(credential: cred),
    );
  }

  void _onDone() {
    final sel = _selection;
    if (sel is! _OwnedSelection) return;
    widget.onChoiceMade(sel.index);
    Navigator.of(context).pop();
  }

  /// Mirrors a provider-driven bundle change into the local radio selection.
  /// The provider's auto-select (in [SessionUserChoicesNotifier]) is the sole
  /// writer of `setBundle` on issuance; here we just sync the UI and honour
  /// `addOptional`, which the provider does not handle.
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

    final overview = ref
        .read(sessionStateProvider(widget.sessionId))
        .value
        ?.disclosurePlan
        ?.disclosureChoicesOverview;
    if (overview == null || widget.disconIndex >= overview.length) return;
    final owned = overview[widget.disconIndex].ownedOptions ?? [];

    for (var i = 0; i < owned.length; i++) {
      final bundleHashes = owned[i].credentialHashes;
      if (bundleHashes.length != nextHashes.length ||
          !bundleHashes.containsAll(nextHashes)) {
        continue;
      }
      if (widget.addOptional) {
        ref
            .read(sessionUserChoicesProvider(widget.sessionId).notifier)
            .addOptional(widget.disconIndex);
      }
      setState(() => _selection = _OwnedSelection(i));
      return;
    }
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

    // Watch session state to use live data for this discon.
    final sessionAsync = ref.watch(sessionStateProvider(widget.sessionId));
    final livePickOne = sessionAsync.whenOrNull(
      data: (session) {
        final choices = session.disclosurePlan?.disclosureChoicesOverview;
        if (choices != null && widget.disconIndex < choices.length) {
          return choices[widget.disconIndex];
        }
        return null;
      },
    );

    // Use live data when available, falling back to the initial snapshot.
    final pickOne = livePickOne ?? widget.pickOne;
    final owned = pickOne.ownedOptions ?? [];
    final obtainable = pickOne.obtainableOptions ?? [];

    final selection = _selection;
    final ownedSelectedIndex = switch (selection) {
      _OwnedSelection(:final index) => index,
      _ObtainableSelection() => -1,
    };
    bool isObtainableSelectedAt(int i) =>
        selection is _ObtainableSelection && selection.index == i;

    return SessionScaffold(
      appBarTitle: "disclosure_permission.change_choice",
      onPrevious: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.yivi.spacing.base),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owned options — selectable
              if (owned.isNotEmpty)
                DisclosurePermissionChoice.fromBundles(
                  options: owned,
                  selectedIndex: ownedSelectedIndex,
                  onChoiceUpdated: (i) =>
                      setState(() => _selection = _OwnedSelection(i)),
                ),

              // Obtainable options section
              if (obtainable.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.only(
                    bottom: context.yivi.spacing.small,
                    top: context.yivi.spacing.medium,
                  ),
                  child: SectionHeader("disclosure_permission.obtain_new"),
                ),
                for (var i = 0; i < obtainable.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: context.yivi.spacing.small),
                    child: GestureDetector(
                      onTap: obtainable[i].issueURL != null
                          ? () => setState(
                              () => _selection = _ObtainableSelection(i),
                            )
                          : null,
                      child: Opacity(
                        opacity: obtainable[i].issueURL != null ? 1.0 : 0.5,
                        child: YiviCredentialCard.fromDescriptor(
                          descriptor: obtainable[i],
                          compact: true,
                          style: isObtainableSelectedAt(i)
                              ? IrmaCardStyle.highlighted
                              : IrmaCardStyle.normal,
                          headerTrailing: RadioIndicator(
                            isSelected: isObtainableSelectedAt(i),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: _isOwnedSelected
            ? "ui.done"
            : _selectedObtainableIsObtainable(obtainable)
            ? "disclosure_permission.obtain_data"
            : "disclosure_permission.close",
        onPrimaryPressed: _isOwnedSelected
            ? _onDone
            : _selectedObtainableIsObtainable(obtainable)
            ? () => _onObtainData(obtainable)
            : () => Navigator.of(context).pop(),
      ),
    );
  }
}
