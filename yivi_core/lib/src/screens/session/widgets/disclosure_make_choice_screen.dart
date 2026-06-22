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
import "disclosure_selection.dart";
import "session_scaffold.dart";

/// Selection type: either an owned credential or an obtainable one.
///
/// An owned selection is keyed on the *stable identity* (credential hashes) of
/// the chosen bundle rather than its list index, so it keeps pointing at the
/// same credential when the owned-options list changes underneath us — e.g.
/// after a credential is deleted mid-session (issue #520). Obtainable options
/// are never disclosed, so a transient index is fine for them.
sealed class _Selection {
  const _Selection();
}

class _OwnedSelection extends _Selection {
  final Set<String> hashes;
  const _OwnedSelection(this.hashes);
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
  final ValueChanged<DisclosureBundle> onChoiceMade;
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
    final owned = widget.pickOne.ownedOptions ?? [];
    if (owned.isNotEmpty) {
      final initial =
          widget.initialSelectedIndex >= 0 &&
              widget.initialSelectedIndex < owned.length
          ? widget.initialSelectedIndex
          : 0;
      _selection = _OwnedSelection(owned[initial].credentialHashes);
    } else if ((widget.pickOne.obtainableOptions ?? []).isNotEmpty) {
      _selection = const _ObtainableSelection(0);
    } else {
      _selection = const _OwnedSelection(<String>{});
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

    // Resolve the selected bundle against the *live* owned list by its stable
    // identity, so we hand back the bundle the user actually picked even if the
    // list shifted (e.g. a credential was deleted mid-session). Index-based
    // resolution against a re-read list would map the stale index onto the
    // wrong credential — see issue #520.
    final owned = _liveOwnedOptions();
    final bundle = resolveSelectedBundle(owned, sel.hashes);
    if (bundle == null) return;

    widget.onChoiceMade(bundle);
    Navigator.of(context).pop();
  }

  /// The owned options for this discon from live session state, falling back to
  /// the initial snapshot. Mirrors the resolution used in [build].
  List<DisclosureBundle> _liveOwnedOptions() {
    final overview = ref
        .read(sessionStateProvider(widget.sessionId))
        .value
        ?.disclosurePlan
        ?.disclosureChoicesOverview;
    final livePickOne =
        (overview != null && widget.disconIndex < overview.length)
        ? overview[widget.disconIndex]
        : null;
    return (livePickOne ?? widget.pickOne).ownedOptions ?? [];
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

    final owned = _liveOwnedOptions();
    if (selectedBundleIndex(owned, nextHashes) == null) return;

    if (widget.addOptional) {
      ref
          .read(sessionUserChoicesProvider(widget.sessionId).notifier)
          .addOptional(widget.disconIndex);
    }
    setState(() => _selection = _OwnedSelection(nextHashes));
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

    final theme = IrmaTheme.of(context);
    final selection = _selection;
    // Re-resolve the owned radio index from the selected identity against the
    // current list, so the highlighted card follows the chosen credential even
    // if the list shifted (-1 selects nothing, e.g. after a deletion).
    final ownedSelectedIndex = switch (selection) {
      _OwnedSelection(:final hashes) =>
        selectedBundleIndex(owned, hashes) ?? -1,
      _ObtainableSelection() => -1,
    };
    bool isObtainableSelectedAt(int i) =>
        selection is _ObtainableSelection && selection.index == i;

    return SessionScaffold(
      appBarTitle: "disclosure_permission.change_choice",
      onPrevious: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owned options — selectable
              if (owned.isNotEmpty)
                DisclosurePermissionChoice.fromBundles(
                  options: owned,
                  selectedIndex: ownedSelectedIndex,
                  onChoiceUpdated: (i) => setState(
                    () =>
                        _selection = _OwnedSelection(owned[i].credentialHashes),
                  ),
                ),

              // Obtainable options section
              if (obtainable.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.only(
                    bottom: theme.smallSpacing,
                    top: theme.mediumSpacing,
                  ),
                  child: SectionHeader("disclosure_permission.obtain_new"),
                ),
                for (var i = 0; i < obtainable.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: theme.smallSpacing),
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
