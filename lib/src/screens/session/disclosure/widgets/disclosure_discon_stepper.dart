import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../util/con_dis_con.dart';
import '../../../../widgets/irma_stepper.dart';
import '../../../../widgets/translated_text.dart';
import '../models/disclosure_credential.dart';
import 'disclosure_issue_wizard_credential_card.dart';
import 'disclosure_permission_choice.dart';

class DisclosureDisconStepper extends StatelessWidget {
  final int? currentCandidateKey;
  final List<MapEntry<int, DisCon<DisclosureCredential>>> candidatesList;
  final Map<int, int> selectedConIndices;
  final Function(int conIndex) onChoiceUpdated;

  const DisclosureDisconStepper({
    this.currentCandidateKey,
    required this.candidatesList,
    required this.selectedConIndices,
    required this.onChoiceUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final currentCandidateIndex = currentCandidateKey != null
        ? candidatesList.indexWhere((candidateEntry) => candidateEntry.key == currentCandidateKey)
        : null;
    return IrmaStepper(
      currentIndex: currentCandidateIndex,
      children: candidatesList
          .mapIndexed(
            (candidateIndex, candidateEntry) =>
                // If this item is a choice, render choice widget.
                currentCandidateKey != null &&
                    currentCandidateKey! <= candidateEntry.key &&
                    candidateEntry.value.length > 1
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(theme.smallSpacing),
                        child: TranslatedText(
                          'disclosure_permission.choose',
                          style: theme.themeData.textTheme.headlineMedium,
                        ),
                      ),
                      DisclosurePermissionChoice(
                        isActive: candidateEntry.key == currentCandidateKey,
                        choice: {for (int i = 0; i < candidateEntry.value.length; i++) i: candidateEntry.value[i]},
                        selectedConIndex: selectedConIndices[candidateEntry.key]!,
                        onChoiceUpdated: onChoiceUpdated,
                      ),
                    ],
                  )
                // If not, render credential card.
                : DisclosureIssueWizardCredentialCards(
                    isActive: candidateEntry.key == currentCandidateKey,
                    // Only show the attribute values when the candidate has yet to be completed
                    hideAttributes: currentCandidateIndex == null || candidateIndex < currentCandidateIndex,
                    credentials: candidateEntry.value[selectedConIndices[candidateEntry.key]!],
                  ),
          )
          .toList(),
    );
  }
}
