import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/irma_repository.dart';
import '../../../theme/theme.dart';
import '../../../widgets/loading_indicator.dart';
import '../widgets/session_scaffold.dart';
import 'bloc/disclosure_permission_bloc.dart';
import 'bloc/disclosure_permission_state.dart';
import 'widgets/issue_wizard.dart';
import 'widgets/issue_wizard_choices.dart';

class DisclosurePermission extends StatelessWidget {
  final int sessionId;
  final IrmaRepository repo;

  const DisclosurePermission({required this.sessionId, required this.repo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (_) => DisclosurePermissionBloc(
              sessionID: sessionId,
              repo: repo,
            ),
        child: ProvidedDisclosurePermission());
  }
}

class ProvidedDisclosurePermission extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DisclosurePermissionBloc>();

    return SessionScaffold(
      appBarTitle: 'disclosure.title',
      appBarTitleStyle: IrmaTheme.of(context).textTheme.headline3,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
        child: BlocBuilder<DisclosurePermissionBloc, DisclosurePermissionBlocState>(
          builder: (context, state) {
            switch (state.runtimeType) {
              case DisclosurePermissionIssueWizardChoices:
                return IssueWizardChoices(bloc);
              case DisclosurePermissionIssueWizard:
                return IssueWizard(bloc);
              case DisclosurePermissionChoices:
                throw UnimplementedError;
              case DisclosurePermissionConfirmChoices:
                throw UnimplementedError;
              case DisclosurePermissionFinished:
                throw UnimplementedError;
              case DisclosurePermissionInitial:
              default:
                return Center(
                  child: LoadingIndicator(),
                );
            }
          },
        ),
      ),
    );
  }
}
