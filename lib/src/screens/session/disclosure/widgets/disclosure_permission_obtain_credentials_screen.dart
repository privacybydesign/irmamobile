import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/irma_repository_provider.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_template_stepper.dart';

class DisclosurePermissionObtainCredentialsScreen extends StatelessWidget {
  final DisclosurePermissionObtainCredentials state;
  final Function(DisclosurePermissionBlocEvent) onEvent;

  const DisclosurePermissionObtainCredentialsScreen({
    required this.state,
    required this.onEvent,
  });

  void _onButtonPressed(BuildContext context) {
    if (!state.allObtainedCredentialsMatch) {
      IrmaRepositoryProvider.of(context).openIssueURL(
        context,
        state.currentIssueWizardItem!.credentialType.fullId,
      );
    } else {
      onEvent(DisclosurePermissionNextPressed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SessionScaffold(
      appBarTitle: 'disclosure_permission.issue_wizard.title',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclosureTemplateStepper(
              templates: state.templates,
              currentItem: state.currentIssueWizardItem,
            )
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: state.hasObtainedCredentials ? 'ui.done' : 'disclosure_permission.obtain_data',
        onPrimaryPressed: () => _onButtonPressed(context),
      ),
    );
  }
}
