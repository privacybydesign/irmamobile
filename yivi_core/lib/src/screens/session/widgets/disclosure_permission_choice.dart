import "package:flutter/material.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/radio_indicator.dart";

/// Displays a list of credential options with radio buttons, allowing
/// the user to select one.
class DisclosurePermissionChoice extends StatelessWidget {
  final int optionCount;
  final int selectedIndex;
  final ValueChanged<int>? onChoiceUpdated;
  final Widget Function(int index, bool isSelected) _cardBuilder;

  const DisclosurePermissionChoice({
    super.key,
    required this.optionCount,
    required this.selectedIndex,
    required this.onChoiceUpdated,
    required Widget Function(int index, bool isSelected) cardBuilder,
  }) : _cardBuilder = cardBuilder;

  /// Creates a choice widget for [CredentialDescriptor] options,
  /// typically used in the issue-during-disclosure stepper.
  factory DisclosurePermissionChoice.fromDescriptors({
    Key? key,
    required List<CredentialDescriptor> options,
    required int selectedIndex,
    required ValueChanged<int>? onChoiceUpdated,
  }) {
    return DisclosurePermissionChoice(
      key: key,
      optionCount: options.length,
      selectedIndex: selectedIndex,
      onChoiceUpdated: onChoiceUpdated,
      cardBuilder: (index, isSelected) => YiviCredentialCard.fromDescriptor(
        descriptor: options[index],
        compact: true,
        style: IrmaCardStyle.highlighted,
        headerTrailing: RadioIndicator(isSelected: isSelected),
      ),
    );
  }

  /// Creates a choice widget for [SelectableCredentialInstance] options,
  /// typically used in the disclosure choices overview.
  factory DisclosurePermissionChoice.fromInstances({
    Key? key,
    required List<SelectableCredentialInstance> options,
    required int selectedIndex,
    required ValueChanged<int>? onChoiceUpdated,
  }) {
    return DisclosurePermissionChoice(
      key: key,
      optionCount: options.length,
      selectedIndex: selectedIndex,
      onChoiceUpdated: onChoiceUpdated,
      cardBuilder: (index, isSelected) =>
          YiviCredentialCard.fromSelectableInstance(
            instance: options[index],
            compact: true,
            hideFooter: true,
            style: isSelected
                ? IrmaCardStyle.highlighted
                : IrmaCardStyle.normal,
            headerTrailing: RadioIndicator(isSelected: isSelected),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Semantics(
      button: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < optionCount; i++)
            Padding(
              padding: EdgeInsets.only(bottom: theme.smallSpacing),
              child: GestureDetector(
                onTap: onChoiceUpdated != null
                    ? () => onChoiceUpdated!(i)
                    : null,
                child: _cardBuilder(i, i == selectedIndex),
              ),
            ),
        ],
      ),
    );
  }
}
