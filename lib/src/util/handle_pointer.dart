import 'package:flutter/material.dart';

import '../models/issue_wizard.dart';
import '../models/session.dart';
import '../models/session_events.dart';
import '../screens/error/error_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/issue_wizard/issue_wizard.dart';
import '../screens/session/session.dart';
import '../screens/session/session_screen.dart';
import '../screens/session/unknown_session_screen.dart';
import '../widgets/irma_repository_provider.dart';

/// First handles the issue wizard if one is present, and subsequently the session is handled.
/// If no wizard is specified, only the session will be performed.
/// If no session is specified, the user will be returned to the HomeScreen after completing the wizard.
Future<void> handlePointer(NavigatorState navigator, Pointer pointer) async {
  try {
    await pointer.validate(irmaRepository: IrmaRepositoryProvider.of(navigator.context));
  } catch (e) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ErrorScreen(
          details: 'error starting session or wizard: ${e.toString()}',
          onTapClose: () => navigator.pop(),
        ),
      ),
      ModalRoute.withName(HomeScreen.routeName),
    );
    return;
  }

  int? sessionID;
  if (pointer is SessionPointer) {
    sessionID = await _startSessionAndNavigate(navigator, pointer);
  }

  if (pointer is IssueWizardPointer) {
    _startIssueWizard(navigator, pointer, sessionID);
  }
}

Future<void> _startIssueWizard(NavigatorState navigator, IssueWizardPointer wizardPointer, int? sessionID) async {
  final repo = IrmaRepositoryProvider.of(navigator.context);
  repo.dispatch(
    GetIssueWizardContentsEvent(id: wizardPointer.wizard),
    isBridgedEvent: true,
  );

  // Push wizard on top of session screen (if any). If the user cancels the wizard by going back
  // to the wallet, then the session screen is automatically dismissed, which cancels the session.
  navigator.pushNamed(
    IssueWizardScreen.routeName,
    arguments: IssueWizardScreenArguments(wizardID: wizardPointer.wizard, sessionID: sessionID),
  );
}

Future<int> _startSessionAndNavigate(NavigatorState navigator, SessionPointer sessionPointer) async {
  final repo = IrmaRepositoryProvider.of(navigator.context);
  final event = NewSessionEvent(
    request: sessionPointer,
    inAppCredential: await repo.getInAppCredential(),
  );

  final hasActiveSessions = await repo.hasActiveSessions();
  final wizardActive = await repo.getIssueWizardActive().first;
  repo.dispatch(event, isBridgedEvent: true);

  final args = SessionScreenArguments(
    sessionID: event.sessionID,
    sessionType: event.request.irmaqr,
    hasUnderlyingSession: hasActiveSessions,
    wizardActive: wizardActive,
    wizardCred: wizardActive ? (await repo.getIssueWizard().first)?.activeItem?.credential : null,
  );
  if (hasActiveSessions || wizardActive) {
    switch (args.sessionType) {
      case 'issuing':
      case 'disclosing':
      case 'signing':
      case 'redirect':
        navigator.pushNamed(SessionScreen.routeName, arguments: args);
        break;
      default:
        navigator.pushNamed(UnknownSessionScreen.routeName, arguments: args);
    }
  } else {
    navigator.pushNamedAndRemoveUntil(
      SessionScreen.routeName,
      ModalRoute.withName(HomeScreen.routeName),
      arguments: args,
    );
  }

  return event.sessionID;
}
