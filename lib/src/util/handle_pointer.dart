import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/issue_wizard.dart';
import '../models/session.dart';
import '../models/session_events.dart';
import '../screens/issue_wizard/issue_wizard.dart';
import '../screens/session/session.dart';
import '../screens/session/session_screen.dart';
import '../screens/session/unknown_session_screen.dart';
import '../widgets/irma_repository_provider.dart';

/// First handles the issue wizard if one is present, and subsequently the session is handled.
/// If no wizard is specified, only the session will be performed.
/// If no session is specified, the user will be returned to the HomeScreen after completing the wizard.
/// If pushReplacement is true, then the current screen is being replaced with the handler screen.
Future<void> handlePointer(BuildContext context, Pointer pointer, {bool pushReplacement = false}) async {
  try {
    await pointer.validate(irmaRepository: IrmaRepositoryProvider.of(context));
  } catch (e) {
    if (!context.mounted) {
      return;
    }
    final message = 'error starting session or wizard: $e';
    if (pushReplacement) {
      context.pushReplacement('/error', extra: message);
    } else {
      context.push('/error', extra: message);
    }
    return;
  }

  int? sessionID;
  if (pointer is SessionPointer && context.mounted) {
    sessionID = await _startSessionAndNavigate(context, pointer, pushReplacement);
  }

  if (pointer is IssueWizardPointer && context.mounted) {
    await _startIssueWizard(context, pointer, sessionID, pushReplacement);
  }
}

_startIssueWizard(
  BuildContext context,
  IssueWizardPointer wizardPointer,
  int? sessionID,
  bool pushReplacement,
) async {
  final repo = IrmaRepositoryProvider.of(context);
  repo.bridgedDispatch(GetIssueWizardContentsEvent(id: wizardPointer.wizard));

  // Push wizard on top of session screen (if any). If the user cancels the wizard by going back
  // to the wallet, then the session screen is automatically dismissed, which cancels the session.
  final args = IssueWizardScreenArguments(wizardID: wizardPointer.wizard, sessionID: sessionID);
  if (pushReplacement) {
    context.pushReplacement(IssueWizardScreen.routeName, extra: args);
  } else {
    await context.push(IssueWizardScreen.routeName, extra: args);
  }
}

Future<int> _startSessionAndNavigate(
  BuildContext context,
  SessionPointer sessionPointer,
  bool pushReplacement,
) async {
  final repo = IrmaRepositoryProvider.of(context);
  final event = NewSessionEvent(
    request: sessionPointer,
    previouslyLaunchedCredentials: await repo.getPreviouslyLaunchedCredentials(),
  );

  final hasActiveSessions = await repo.hasActiveSessions();
  final wizardActive = await repo.getIssueWizardActive().first;
  repo.bridgedDispatch(event);

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
  if (!context.mounted) {
    return event.sessionID;
  }
  if (pushReplacement) {
    context.pushReplacement(routeName, extra: args);
  } else {
    await context.push(routeName, extra: args);
  }

  return event.sessionID;
}
