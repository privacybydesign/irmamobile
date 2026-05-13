import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/radio_indicator.dart";
import "../../../widgets/translated_text.dart";
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
  late Set<String> _previousOwnedHashes;

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
    _previousOwnedHashes = {
      for (final owned in widget.pickOne.ownedOptions ?? []) owned.hash,
    };
  }

  bool get _isOwnedSelected => _selection is _OwnedSelection;

  bool _selectedObtainableIsObtainable(List<CredentialDescriptor> obtainable) {
    if (_selection is! _ObtainableSelection) return false;
    final index = (_selection as _ObtainableSelection).index;
    if (index >= obtainable.length) return false;
    return obtainable[index].issueURL != null;
  }

  void _onObtainData(List<CredentialDescriptor> obtainable) {
    if (_selection is! _ObtainableSelection) return;
    final index = (_selection as _ObtainableSelection).index;
    if (index >= obtainable.length) return;

    final cred = obtainable[index];
    context.pushSchemalessDataDetailsScreen(
      AddDataDetailsRouteParams(credential: cred),
    );
  }

  void _onDone() {
    widget.onChoiceMade((_selection as _OwnedSelection).index);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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

    // Detect newly obtained credentials and auto-select them.
    if (livePickOne != null) {
      for (var i = 0; i < owned.length; i++) {
        if (!_previousOwnedHashes.contains(owned[i].hash)) {
          // A new credential appeared — update provider and select it.
          _previousOwnedHashes = {for (final o in owned) o.hash};

          final cred = owned[i];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final notifier = ref.read(
              sessionUserChoicesProvider(widget.sessionId).notifier,
            );
            if (widget.addOptional) {
              notifier.addOptional(widget.disconIndex);
            }
            notifier.setChoice(
              widget.disconIndex,
              SelectedCredential(
                credentialId: cred.credentialId,
                credentialHash: cred.hash,
                attributePaths: cred.attributes
                    .map((attr) => attr.claimPath)
                    .toList(),
              ),
            );
            setState(() => _selection = _OwnedSelection(i));
          });
          break;
        }
      }
    }

    final theme = IrmaTheme.of(context);

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
                DisclosurePermissionChoice.fromInstances(
                  options: owned,
                  selectedIndex: _selection is _OwnedSelection
                      ? (_selection as _OwnedSelection).index
                      : -1,
                  onChoiceUpdated: (i) =>
                      setState(() => _selection = _OwnedSelection(i)),
                ),

              // Obtainable options section
              if (obtainable.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.only(
                    bottom: theme.smallSpacing,
                    left: theme.smallSpacing,
                    top: theme.mediumSpacing,
                  ),
                  child: TranslatedText(
                    "disclosure_permission.obtain_new",
                    style: theme.themeData.textTheme.headlineMedium,
                    isHeader: true,
                  ),
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
                          style:
                              _selection is _ObtainableSelection &&
                                  (_selection as _ObtainableSelection).index ==
                                      i
                              ? IrmaCardStyle.highlighted
                              : IrmaCardStyle.normal,
                          headerTrailing: RadioIndicator(
                            isSelected:
                                _selection is _ObtainableSelection &&
                                (_selection as _ObtainableSelection).index == i,
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
