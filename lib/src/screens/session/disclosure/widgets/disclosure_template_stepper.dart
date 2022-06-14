import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../../widgets/irma_stepper.dart';
import '../models/template_disclosure_credential.dart';
import 'disclosure_issue_wizard_credential_card.dart';

class DisclosureTemplateStepper extends StatelessWidget {
  final UnmodifiableListView<TemplateDisclosureCredential> templates;

  final TemplateDisclosureCredential currentItem;

  const DisclosureTemplateStepper({
    required this.templates,
    required this.currentItem,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaStepper(
      currentIndex: templates.indexWhere((cred) => cred == currentItem),
      children: templates
          .map(
            (cred) => DisclosureIssueWizardCredentialCard(
              credential: cred,
              isActive: cred == currentItem,
            ),
          )
          .toList(),
    );
  }
}
