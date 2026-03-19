import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/schemaless/session_state.dart";
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

  const DisclosureMakeChoiceScreen({
    super.key,
    required this.pickOne,
    required this.initialSelectedIndex,
    required this.onChoiceMade,
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
    _selection = _OwnedSelection(widget.initialSelectedIndex);
  }

  bool get _isOwnedSelected => _selection is _OwnedSelection;

  void _onObtainData() {
    if (_selection is! _ObtainableSelection) return;
    final obtainable = widget.pickOne.obtainableOptions ?? [];
    final index = (_selection as _ObtainableSelection).index;
    if (index >= obtainable.length) return;

    final cred = obtainable[index];
    context.pushSchemalessDataDetailsScreen(
      AddDataDetailsRouteParams(credential: cred),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final owned = widget.pickOne.ownedOptions ?? [];
    final obtainable = widget.pickOne.obtainableOptions ?? [];

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
                      onTap: () =>
                          setState(() => _selection = _ObtainableSelection(i)),
                      child: YiviCredentialCard.fromDescriptor(
                        descriptor: obtainable[i],
                        compact: true,
                        style:
                            _selection is _ObtainableSelection &&
                                (_selection as _ObtainableSelection).index == i
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
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: _isOwnedSelected
            ? "ui.done"
            : "disclosure_permission.obtain_data",
        onPrimaryPressed: _isOwnedSelected
            ? () {
                widget.onChoiceMade((_selection as _OwnedSelection).index);
                Navigator.of(context).pop();
              }
            : _onObtainData,
      ),
    );
  }
}
