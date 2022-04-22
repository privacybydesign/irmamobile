import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/irma_repository.dart';
import '../../../models/session.dart';
import '../../../theme/theme.dart';
import '../../../widgets/loading_indicator.dart';
import '../widgets/session_scaffold.dart';
import 'bloc/disclosure_permission_bloc.dart';
import 'bloc/disclosure_permission_state.dart';
import 'widgets/disclosure_issue_wizard.dart';
import 'widgets/disclosure_issue_wizard_choices.dart';

class DisclosurePermission extends StatelessWidget {
  final int sessionId;
  final IrmaRepository repo;
  final RequestorInfo requestor;

  const DisclosurePermission({required this.sessionId, required this.repo, required this.requestor});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DisclosurePermissionBloc(
        sessionID: sessionId,
        repo: repo,
      ),
      child: ProvidedDisclosurePermission(requestor),
    );
  }
}

class ProvidedDisclosurePermission extends StatelessWidget {
  final RequestorInfo requestor;

  const ProvidedDisclosurePermission(this.requestor);

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DisclosurePermissionBloc>();

    return SessionScaffold(
      appBarTitle: 'disclosure_permission.title',
      appBarTitleStyle: IrmaTheme.of(context).textTheme.headline3,
      body: BlocBuilder<DisclosurePermissionBloc, DisclosurePermissionBlocState>(
        builder: (context, state) {
          switch (state.runtimeType) {
            case DisclosurePermissionIssueWizardChoices:
              return DisclosureIssueWizardChoices(bloc);
            case DisclosurePermissionIssueWizard:
              return DisclosureIssueWizard(
                bloc: bloc,
                requestor: requestor,
              );
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
    );
  }
}
