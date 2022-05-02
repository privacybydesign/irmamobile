import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/irma_repository.dart';
import '../../../models/session.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/loading_indicator.dart';
import '../widgets/session_scaffold.dart';
import 'bloc/disclosure_permission_bloc.dart';
import 'bloc/disclosure_permission_event.dart';
import 'bloc/disclosure_permission_state.dart';
import 'widgets/disclosure_choices.dart';
import 'widgets/disclosure_choices_confirm.dart';
import 'widgets/disclosure_issue_wizard.dart';
import 'widgets/disclosure_issue_wizard_choices.dart';

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
    final theme = IrmaTheme.of(context);
    final bloc = context.read<DisclosurePermissionBloc>();
    void addEvent(DisclosurePermissionBlocEvent event) => bloc.add(event);

    return BlocBuilder<DisclosurePermissionBloc, DisclosurePermissionBlocState>(
      builder: (context, state) {
        //Build scaffold components according to state
        late Widget body;
        IrmaBottomBar? bottomBar;

        // If state is loading/initial show centered loading indicator
        if (state is DisclosurePermissionInitial) {
          body = Center(
            child: LoadingIndicator(),
          );
        } else {
          //Else build body with actual state
          if (state is DisclosurePermissionIssueWizardChoices) {
            body = DisclosureIssueWizardChoices(
              state: state,
              onEvent: addEvent,
            );
            bottomBar = _buildBottomBar(addEvent);
          } else if (state is DisclosurePermissionIssueWizard) {
            body = DisclosureIssueWizard(
              state: state,
              requestor: requestor,
            );
            bottomBar = _buildBottomBar(
              addEvent,
              primaryIsDisabled: !state.completed,
            );
          } else if (state is DisclosurePermissionChoices) {
            body = DisclosureChoices(
              state: state,
              onEvent: addEvent,
              requestor: requestor,
            );
            bottomBar = _buildBottomBar(addEvent);
          } else if (state is DisclosurePermissionConfirmChoices) {
            body = DisclosureChoicesConfirm(
              state: state,
              requestor: requestor,
              onEvent: addEvent,
            );
            bottomBar = _buildBottomBar(addEvent, showChangeChoice: true);
          } else if (state is DisclosurePermissionFinished) {
            throw UnimplementedError;
          }
          // Wrap body with scrollview to make body scrollable
          body = SingleChildScrollView(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: body,
          );
        }

        //Return composed scaffold
        return SessionScaffold(
          appBarTitle: 'disclosure_permission.title',
          appBarTitleStyle: theme.textTheme.headline3,
          bottomNavigationBar: bottomBar,
          body: body,
        );
      },
    );
  }
}

IrmaBottomBar _buildBottomBar(
  addEvent, {
  primaryIsDisabled = false,
  showChangeChoice = false,
}) =>
    IrmaBottomBar(
      primaryButtonLabel: 'disclosure_permission.next',
      onPrimaryPressed: primaryIsDisabled == true
          ? null
          : () => addEvent(
                DisclosurePermissionNextPressed(),
              ),
      secondaryButtonLabel: showChangeChoice == true ? 'disclosure_permission.choices.change_choice' : null,
      onSecondaryPressed: showChangeChoice == true
          ? () => addEvent(
                DisclosurePermissionEditCurrentSelectionPressed(),
              )
          : null,
    );
