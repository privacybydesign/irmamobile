import 'package:flutter/material.dart';

import '../../../../providers/irma_repository_provider.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_template_stepper.dart';

class DisclosurePermissionObtainCredentialsScreen extends StatelessWidget {
  final DisclosurePermissionObtainCredentials state;
  final Function(DisclosurePermissionBlocEvent) onEvent;
  final Function() onDismiss;

  const DisclosurePermissionObtainCredentialsScreen({
    required this.state,
    required this.onEvent,
    required this.onDismiss,
  });

  void _onButtonPressed(BuildContext context) {
    if (state.allObtained) {
      onEvent(DisclosurePermissionNextPressed());
    } else {
      IrmaRepositoryProvider.of(context).openIssueURL(context, state.currentIssueWizardItem!.credentialType.fullId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SessionScaffold(
      appBarTitle: 'disclosure_permission.issue_wizard.title',
      onDismiss: onDismiss,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [DisclosureTemplateStepper(templates: state.templates, currentItem: state.currentIssueWizardItem)],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: state.allObtained ? 'ui.done' : 'disclosure_permission.obtain_data',
        onPrimaryPressed: () => _onButtonPressed(context),
      ),
    );
  }
}
