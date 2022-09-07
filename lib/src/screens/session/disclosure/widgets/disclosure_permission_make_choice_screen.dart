import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/translated_text.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import '../models/template_disclosure_credential.dart';
import 'disclosure_permission_choice.dart';

class DisclosurePermissionMakeChoiceScreen extends StatelessWidget {
  final DisclosurePermissionMakeChoice state;
  final Function(DisclosurePermissionBlocEvent) onEvent;
  final Function() onDismiss;

  const DisclosurePermissionMakeChoiceScreen({
    required this.state,
    required this.onEvent,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SessionScaffold(
      appBarTitle: state is DisclosurePermissionChangeChoice
          ? 'disclosure_permission.change_choice'
          : 'disclosure_permission.choose',
      onDismiss: onDismiss,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclosurePermissionChoice(
              choice: state.choosableCons,
              selectedConIndex: state.selectedConIndex,
              onChoiceUpdated: (int conIndex) => onEvent(DisclosurePermissionChoiceUpdated(conIndex: conIndex)),
            ),
            if (state.templateCons.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.all(theme.smallSpacing),
                child: TranslatedText(
                  'disclosure_permission.obtain_new',
                  style: theme.themeData.textTheme.headline5,
                ),
              ),
              DisclosurePermissionChoice(
                choice: state.templateCons,
                selectedConIndex: state.selectedConIndex,
                onChoiceUpdated: (int conIndex) => onEvent(DisclosurePermissionChoiceUpdated(conIndex: conIndex)),
              ),
            ],
          ],
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
