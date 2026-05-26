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
  final Widget Function(BuildContext context, int index, bool isSelected)
  _cardBuilder;

  const DisclosurePermissionChoice({
    super.key,
    required this.optionCount,
    required this.selectedIndex,
    required this.onChoiceUpdated,
    required Widget Function(BuildContext context, int index, bool isSelected)
    cardBuilder,
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
      onChoiceUpdated: onChoiceUpdated != null
          ? (index) {
              // Only allow selecting obtainable options.
              if (options[index].issueURL != null) {
                onChoiceUpdated(index);
              }
            }
          : null,
      cardBuilder: (context, index, isSelected) {
        final isObtainable = options[index].issueURL != null;
        return Opacity(
          opacity: isObtainable ? 1.0 : 0.5,
          child: YiviCredentialCard.fromDescriptor(
            descriptor: options[index],
            compact: true,
            style: IrmaCardStyle.highlighted,
            headerTrailing: RadioIndicator(isSelected: isSelected),
          ),
        );
      },
    );
  }

  /// Creates a choice widget for [IssuanceBundle] options. A single-credential
  /// bundle renders as one card; a multi-credential bundle renders as a column
  /// of cards (separated by `theme.smallSpacing`) with a single radio on the
  /// first card and a shared highlight style. Mirrors the disclosure-side
  /// bundle layout for visual consistency.
  factory DisclosurePermissionChoice.fromIssuanceBundles({
    Key? key,
    required List<IssuanceBundle> options,
    required int selectedIndex,
    required ValueChanged<int>? onChoiceUpdated,
  }) {
    bool isObtainable(IssuanceBundle bundle) =>
        bundle.credentials.every((c) => c.issueURL != null);

    return DisclosurePermissionChoice(
      key: key,
      optionCount: options.length,
      selectedIndex: selectedIndex,
      onChoiceUpdated: onChoiceUpdated != null
          ? (index) {
              if (isObtainable(options[index])) {
                onChoiceUpdated(index);
              }
            }
          : null,
      cardBuilder: (context, index, isSelected) {
        final theme = IrmaTheme.of(context);
        final credentials = options[index].credentials;
        final style = isSelected
            ? IrmaCardStyle.highlighted
            : IrmaCardStyle.normal;
        final opacity = isObtainable(options[index]) ? 1.0 : 0.5;

        Widget card(int i) => YiviCredentialCard.fromDescriptor(
          descriptor: credentials[i],
          compact: true,
          style: style,
          headerTrailing: i == 0
              ? RadioIndicator(isSelected: isSelected)
              : null,
        );

        if (credentials.length == 1) {
          return Opacity(opacity: opacity, child: card(0));
        }

        return Opacity(
          opacity: opacity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < credentials.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i < credentials.length - 1 ? theme.smallSpacing : 0,
                  ),
                  child: card(i),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Creates a choice widget for [DisclosureBundle] options. A bundle with a
  /// single credential renders as one card; a bundle with multiple credentials
  /// renders as a column of cards (separated by `theme.smallSpacing`) with a
  /// single radio on the first card and a shared highlight style.
  factory DisclosurePermissionChoice.fromBundles({
    Key? key,
    required List<DisclosureBundle> options,
    required int selectedIndex,
    required ValueChanged<int>? onChoiceUpdated,
  }) {
    return DisclosurePermissionChoice(
      key: key,
      optionCount: options.length,
      selectedIndex: selectedIndex,
      onChoiceUpdated: onChoiceUpdated,
      cardBuilder: (context, index, isSelected) {
        final theme = IrmaTheme.of(context);
        final credentials = options[index].credentials;
        final style = isSelected
            ? IrmaCardStyle.highlighted
            : IrmaCardStyle.normal;

        if (credentials.length == 1) {
          return YiviCredentialCard.fromSelectableInstance(
            instance: credentials[0],
            compact: true,
            hideFooter: true,
            style: style,
            headerTrailing: RadioIndicator(isSelected: isSelected),
          );
        }

        return Column(
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
                  style: style,
                  headerTrailing: i == 0
                      ? RadioIndicator(isSelected: isSelected)
                      : null,
                ),
              ),
          ],
        );
      },
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
                child: _cardBuilder(context, i, i == selectedIndex),
              ),
            ),
        ],
      ),
    );
  }
}
