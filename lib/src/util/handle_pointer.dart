import 'package:flutter/material.dart';

import '../models/issue_wizard.dart';
import '../models/session.dart';
import '../models/session_events.dart';
import '../screens/error/error_screen.dart';
import '../screens/issue_wizard/issue_wizard.dart';
import '../screens/session/session.dart';
import '../screens/session/session_screen.dart';
import '../screens/session/unknown_session_screen.dart';
import '../widgets/irma_repository_provider.dart';

/// First handles the issue wizard if one is present, and subsequently the session is handled.
/// If no wizard is specified, only the session will be performed.
/// If no session is specified, the user will be returned to the HomeScreen after completing the wizard.
/// If pushReplacement is true, then the current screen is being replaced with the handler screen.
Future<void> handlePointer(NavigatorState navigator, Pointer pointer, {bool pushReplacement = false}) async {
  try {
    await pointer.validate(irmaRepository: IrmaRepositoryProvider.of(navigator.context));
  } catch (e) {
    final pageRoute = MaterialPageRoute(
      builder: (context) => ErrorScreen(
        details: 'error starting session or wizard: ${e.toString()}',
        onTapClose: () => navigator.pop(),
      ),
    );
    if (pushReplacement) {
      await navigator.pushReplacement(pageRoute);
    } else {
      await navigator.push(pageRoute);
    }
    return;
  }

  int? sessionID;
  if (pointer is SessionPointer) {
    sessionID = await _startSessionAndNavigate(navigator, pointer, pushReplacement);
  }

  if (pointer is IssueWizardPointer) {
    await _startIssueWizard(navigator, pointer, sessionID, pushReplacement);
  }
}

Future<void> _startIssueWizard(
  NavigatorState navigator,
  IssueWizardPointer wizardPointer,
  int? sessionID,
  bool pushReplacement,
) async {
  final repo = IrmaRepositoryProvider.of(navigator.context);
  repo.dispatch(
    GetIssueWizardContentsEvent(id: wizardPointer.wizard),
    isBridgedEvent: true,
  );

  // Push wizard on top of session screen (if any). If the user cancels the wizard by going back
  // to the wallet, then the session screen is automatically dismissed, which cancels the session.
  final args = IssueWizardScreenArguments(wizardID: wizardPointer.wizard, sessionID: sessionID);
  if (pushReplacement) {
    await navigator.pushReplacementNamed(
      IssueWizardScreen.routeName,
      arguments: args,
    );
  } else {
    await navigator.pushNamed(
      IssueWizardScreen.routeName,
      arguments: args,
    );
  }
}

Future<int> _startSessionAndNavigate(
  NavigatorState navigator,
  SessionPointer sessionPointer,
  bool pushReplacement,
) async {
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

  final routeName = () {
    switch (args.sessionType) {
      case 'issuing':
      case 'disclosing':
      case 'signing':
      case 'redirect':
        return SessionScreen.routeName;
      default:
        return UnknownSessionScreen.routeName;
    }
  }();
  if (pushReplacement) {
    await navigator.pushReplacementNamed(routeName, arguments: args);
  } else {
    await navigator.pushNamed(routeName, arguments: args);
  }

  return event.sessionID;
}
