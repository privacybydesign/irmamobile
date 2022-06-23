import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import '../models/template_disclosure_credential.dart';
import 'disclosure_permission_choice.dart';

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
      appBarTitle: 'disclosure_permission.overview.title',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: DisclosurePermissionChoice(
          choice: state.discon,
          selectedConIndex: state.selectedConIndex,
          onChoiceUpdated: (int conIndex) => onEvent(DisclosurePermissionChoiceUpdated(conIndex: conIndex)),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: state.selectedCon.whereType<TemplateDisclosureCredential>().isNotEmpty
            ? 'disclosure_permission.obtain_data'
            : 'ui.done',
        onPrimaryPressed: () => onEvent(DisclosurePermissionNextPressed()),
      ),
    );
  }
}
