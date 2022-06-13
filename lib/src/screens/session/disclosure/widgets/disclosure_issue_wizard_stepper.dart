import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../../../models/attributes.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/irma_step_indicator.dart';
import '../models/disclosure_credential.dart';
import 'disclosure_issue_wizard_choice.dart';

class DisclosureIssueWizardStepper extends StatelessWidget {
  final UnmodifiableMapView<int, DisCon<DisclosureCredential>> candidates;
  final MapEntry<int, DisCon<DisclosureCredential>> currentCandidate;
  final UnmodifiableMapView<int, int> selectedConIndices;
  final Function(int conIndex) onChoiceUpdatedEvent;

  const DisclosureIssueWizardStepper({
    required this.candidates,
    required this.currentCandidate,
    required this.selectedConIndices,
    required this.onChoiceUpdatedEvent,
  });

  Widget _buildStepperItem(IrmaThemeData theme, int index) {
    // Build the indicator widget
    final Widget indicator = IrmaStepIndicator(
      step: index + 1,
      //If item is current show filled indicator
      style: currentCandidate.key == index
          ? IrmaStepIndicatorStyle.filled
          //If item has already been completed show success indicator
          : currentCandidate.key > index
              ? IrmaStepIndicatorStyle.success
              //Else show outlined indicator
              : IrmaStepIndicatorStyle.outlined,
    );

    Widget child = candidates[index]!.length > 1 && currentCandidate.key <= index
        // If this item is a choice render choice widget.
        ? DisclosureIssueWizardChoice(
            choice: candidates[index]!,
            selectedConIndex: selectedConIndices[index]!,
            isActive: currentCandidate.key == index,
            onChoiceUpdatedEvent: onChoiceUpdatedEvent,
          )
        // If not render regular card
        : IrmaCredentialsCard(
            style: currentCandidate.key == index ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
            attributesByCredential: {
              for (var cred in candidates[index]!.first) cred: cred.attributes,
            },
            // Compare to self to highlight the required attribute values
            compareToCredentials: candidates[index]!.first,
          );

    // If this candidate comes after current candidate,
    // wrap the child widget in a color filter to make it look greyed out.
    if (currentCandidate.key < index) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white.withOpacity(0.5),
          BlendMode.modulate,
        ),
        child: child,
      );
    }

    // Compose a TimelineTile with the indicator and child
    return TimelineTile(
      indicatorStyle: IndicatorStyle(
        indicator: indicator,
        padding: EdgeInsets.all(theme.smallSpacing),
      ),
      endChild: child,
      beforeLineStyle: LineStyle(
        thickness: 1,
        color: theme.themeData.colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ScrollablePositionedList.builder(
      shrinkWrap: true,
      itemCount: candidates.length,
      itemBuilder: (_, index) => _buildStepperItem(theme, index),
    );
  }
}
