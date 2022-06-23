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
      children: candidates.entries
          .map(
            (candidateEntry) =>
                // If this item is a choice, render choice widget.
                currentCandidateIndex != null &&
                        currentCandidateIndex! <= candidateEntry.key &&
                        candidateEntry.value.length > 1
                    ? DisclosureIssueWizardChoice(
                        isActive: candidateEntry.key == currentCandidateIndex,
                        choice: candidateEntry.value,
                        selectedConIndex: selectedConIndices[candidateEntry.key]!,
                        onChoiceUpdated: onChoiceUpdated,
                      )
                    // If not, render credential card.
                    : DisclosureIssueWizardCredentialCards(
                        isActive: candidateEntry.key == currentCandidateIndex,
                        credentials: candidateEntry.value[selectedConIndices[candidateEntry.key]!]),
          )
          .toList(),
    );
  }
}
