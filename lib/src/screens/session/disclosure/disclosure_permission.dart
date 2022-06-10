import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/irma_repository.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/session.dart';
import '../../../widgets/loading_indicator.dart';
import 'bloc/disclosure_permission_bloc.dart';
import 'bloc/disclosure_permission_event.dart';
import 'bloc/disclosure_permission_state.dart';
import 'widgets/disclosure_permission_issue_wizard_screen.dart';

class DisclosurePermission extends StatelessWidget {
  final int sessionId;
  final IrmaRepository repo;
  final RequestorInfo requestor;

  const DisclosurePermission({
    required this.sessionId,
    required this.repo,
    required this.requestor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DisclosurePermissionBloc(
        sessionID: sessionId,
        repo: repo,
        onObtainCredential: (CredentialType credType) {
          //TODO Implement
        },
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
    void addEvent(DisclosurePermissionBlocEvent event) => bloc.add(event);

    return BlocBuilder<DisclosurePermissionBloc, DisclosurePermissionBlocState>(
      builder: (context, state) {
        if (state is DisclosurePermissionIssueWizard) {
          return DisclosurePermissionIssueWizardScreen(
            requestor: requestor,
            state: state,
            onEvent: addEvent,
          );
        } else if (state is DisclosurePermissionChangeChoice) {
          throw UnimplementedError();
        } else if (state is DisclosurePermissionChoices) {
          throw UnimplementedError();
        }

        // If state is loading/initial show centered loading indicator
        return Scaffold(
          body: Center(
            child: LoadingIndicator(),
          ),
        );
      },
    );
  }
}
