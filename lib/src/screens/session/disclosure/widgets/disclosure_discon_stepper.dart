import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../models/attributes.dart';
import '../../../../widgets/irma_stepper.dart';
import '../models/disclosure_credential.dart';
import 'disclosure_issue_wizard_choice.dart';
import 'disclosure_issue_wizard_credential_card.dart';

class DisclosureDisconStepper extends StatelessWidget {
  final MapEntry<int, DisCon<DisclosureCredential>>? currentCandidate;
  final UnmodifiableMapView<int, DisCon<DisclosureCredential>> candidates;
  final UnmodifiableMapView<int, int> selectedConIndices;
  final Function(int conIndex) onChoiceUpdatedEvent;

  const DisclosureDisconStepper({
    this.currentCandidate,
    required this.candidates,
    required this.selectedConIndices,
    required this.onChoiceUpdatedEvent,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaStepper(
      currentIndex: currentCandidate?.key,
      children: candidates.values
          .mapIndexed(
            (i, candidate) =>
                // If this item is a choice render choice widget.
                currentCandidate != null && currentCandidate!.key <= i && candidate.length > 1
                    ? DisclosureIssueWizardChoice(
                        choice: candidate,
                        selectedConIndex: selectedConIndices[currentCandidate!.key]!,
                        isActive: currentCandidate!.key == i,
                        onChoiceUpdatedEvent: onChoiceUpdatedEvent,
                      )
                    // If not render Template credential card
                    : DisclosureIssueWizardCredentialCard(
                        credential: candidate.first.first,
                        isActive: currentCandidate?.key == i,
                        highlightAttributes: true,
                      ),
          )
          .toList(),
    );
  }
}
