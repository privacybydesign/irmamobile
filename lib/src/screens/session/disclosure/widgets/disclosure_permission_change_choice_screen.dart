import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_issue_wizard_choice.dart';

class DisclosurePermissionChangeChoiceScreen extends StatelessWidget {
  final DisclosurePermissionChangeChoice state;
  final Function(DisclosurePermissionBlocEvent) onEvent;

  const DisclosurePermissionChangeChoiceScreen({
    required this.state,
    required this.onEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SessionScaffold(
      appBarTitle: 'disclosure_permission.issue_wizard.title',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: DisclosureIssueWizardChoice(
          choice: state.discon,
          selectedConIndex: state.selectedConIndex,
          onChoiceUpdatedEvent: (int conIndex) => onEvent(DisclosurePermissionChoiceUpdated(conIndex: conIndex)),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'ui.done', //TODO Add if fetch data
        onPrimaryPressed: () => onEvent(DisclosurePermissionNextPressed()),
      ),
    );
  }
}
