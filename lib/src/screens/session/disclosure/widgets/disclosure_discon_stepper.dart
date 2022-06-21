import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../models/attributes.dart';
import '../../../../widgets/irma_stepper.dart';
import '../models/disclosure_credential.dart';
import 'disclosure_issue_wizard_choice.dart';
import 'disclosure_issue_wizard_credential_card.dart';

class DisclosureDisconStepper extends StatelessWidget {
  final int? currentCandidateIndex;
  final UnmodifiableMapView<int, DisCon<DisclosureCredential>> candidates;
  final UnmodifiableMapView<int, int> selectedConIndices;
  final Function(int conIndex) onChoiceUpdated;

  const DisclosureDisconStepper({
    this.currentCandidateIndex,
    required this.candidates,
    required this.selectedConIndices,
    required this.onChoiceUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaStepper(
      currentIndex: currentCandidateIndex,
      children: candidates.values
          .mapIndexed(
            (i, disCon) =>
                // If this item is a choice, render choice widget.
                currentCandidateIndex != null && currentCandidateIndex! <= i && candidates[i]!.length > 1
                    ? DisclosureIssueWizardChoice(
                        isActive: i == currentCandidateIndex,
                        choice: candidates[i]!,
                        selectedConIndex: selectedConIndices[i]!,
                        onChoiceUpdated: onChoiceUpdated,
                      )
                    // If not, render credential card.
                    : DisclosureIssueWizardCredentialCard(
                        isActive: i == currentCandidateIndex,
                        credentials: candidates[i]![selectedConIndices[i]!],
                      ),
          )
          .toList(),
    );
  }
}
