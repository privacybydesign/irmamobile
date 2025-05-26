import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/irma_repository.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/return_url.dart';
import '../../../models/session.dart';
import '../../../providers/irma_repository_provider.dart';
import '../../../widgets/loading_indicator.dart';
import '../../add_data/add_data_details_screen.dart';
import 'bloc/disclosure_permission_bloc.dart';
import 'bloc/disclosure_permission_event.dart';
import 'bloc/disclosure_permission_state.dart';
import 'widgets/disclosure_permission_choices_screen.dart';
import 'widgets/disclosure_permission_close_dialog.dart';
import 'widgets/disclosure_permission_introduction_screen.dart';
import 'widgets/disclosure_permission_issue_wizard_screen.dart';
import 'widgets/disclosure_permission_make_choice_screen.dart';
import 'widgets/disclosure_permission_obtain_credentials_screen.dart';
import 'widgets/disclosure_permission_wrong_credentials_obtained_dialog.dart';

class DisclosurePermission extends StatelessWidget {
  final int sessionId;
  final IrmaRepository repo;
  final RequestorInfo requestor;
  final ReturnURL? returnURL;

  const DisclosurePermission({
    required this.sessionId,
    required this.repo,
    required this.requestor,
    this.returnURL,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DisclosurePermissionBloc(
        sessionID: sessionId,
        repo: repo,
        onObtainCredential: (CredentialType credType) =>
            IrmaRepositoryProvider.of(context).openIssueURL(context, credType.fullId),
      ),
      child: ProvidedDisclosurePermission(
        requestor,
        returnURL,
      ),
    );
  }
}

class ProvidedDisclosurePermission extends StatelessWidget {
  final RequestorInfo requestor;
  final ReturnURL? returnURL;

  const ProvidedDisclosurePermission(
    this.requestor,
    this.returnURL,
  );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DisclosurePermissionBloc>();
    void addEvent(DisclosurePermissionBlocEvent event) => bloc.add(event);
    void onConfirmedDismiss() => addEvent(DisclosurePermissionDismissed());
    void onDismiss({bool skipConfirmation = false}) => skipConfirmation
        ? onConfirmedDismiss()
        : DisclosurePermissionCloseDialog.show(context, onConfirm: onConfirmedDismiss);

    // Wrapped with PopScope to gain control over the behavior of the "go back" gesture
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, popResult) async {
        if (bloc.state is DisclosurePermissionMakeChoice) {
          addEvent(DisclosurePermissionPreviousPressed());
        } else {
          onDismiss();
        }
      },
      // Wrap our widget in a custom navigator, such that popping this widget from the root navigator will include
      // popping the DisclosurePermissionWrongCredentialsAddedDialog.
      child: Navigator(
        onDidRemovePage: (_) {
          Navigator.of(context).pop();
        },
        pages: [
          MaterialPage(
            child: BlocConsumer<DisclosurePermissionBloc, DisclosurePermissionBlocState>(
              listener: (context, state) async {
                final navigator = Navigator.of(context);

                // Prevent dialogs to be stacked when a state refreshes.
                if (navigator.canPop()) return;

                if (state is DisclosurePermissionWrongCredentialsObtained) {
                  await showDialog(
                    context: context,
                    useRootNavigator: false,
                    builder: (context) => DisclosurePermissionWrongCredentialsAddedDialog(state: state),
                  );
                  addEvent(DisclosurePermissionDialogDismissed());
                }
              },
              builder: (context, blocState) {
                var state = blocState;
                if (state is DisclosurePermissionWrongCredentialsObtained) {
                  state = state.parentState;
                }

                if (state is DisclosurePermissionIntroduction) {
                  return DisclosurePermissionIntroductionScreen(
                    onEvent: addEvent,
                    onDismiss: onDismiss,
                  );
                } else if (state is DisclosurePermissionIssueWizard) {
                  return DisclosurePermissionIssueWizardScreen(
                    requestor: requestor,
                    state: state,
                    onEvent: addEvent,
                    onDismiss: onDismiss,
                  );
                } else if (state is DisclosurePermissionMakeChoice) {
                  return DisclosurePermissionMakeChoiceScreen(
                    state: state,
                    onEvent: addEvent,
                  );
                } else if (state is DisclosurePermissionObtainCredentials) {
                  return DisclosurePermissionObtainCredentialsScreen(
                    state: state,
                    onEvent: addEvent,
                    onDismiss: onDismiss,
                  );
                } else if (state is DisclosurePermissionChoices) {
                  return DisclosurePermissionChoicesScreen(
                    requestor: requestor,
                    state: state,
                    onEvent: addEvent,
                    onDismiss: onDismiss,
                  );
                } else if (state is DisclosurePermissionCredentialInformation) {
                  return AddDataDetailsScreen(
                    inDisclosure: true,
                    credentialType: state.credentialType,
                    onDismiss: onDismiss,
                    onAdd: () => addEvent(DisclosurePermissionNextPressed()),
                    onCancel: () => addEvent(DisclosurePermissionPreviousPressed()),
                  );
                }

                // If state is loading/initial show centered loading indicator
                return Scaffold(
                  body: Center(
                    child: LoadingIndicator(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
