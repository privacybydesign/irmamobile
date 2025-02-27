import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/issue_wizard.dart';
import '../models/session.dart';
import '../models/session_events.dart';
import '../screens/issue_wizard/issue_wizard.dart';
import '../screens/session/session.dart';
import '../widgets/irma_repository_provider.dart';
import 'navigation.dart';

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
      context.pushReplacementErrorScreen(message: message);
    } else {
      context.pushErrorScreen(message: message);
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
  final uri = Uri(path: '/issue_wizard', queryParameters: args.toQueryParams()).toString();

  if (pushReplacement) {
    context.pushReplacement(uri);
  } else {
    await context.push(uri);
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

  if (!context.mounted) {
    return event.sessionID;
  }

  if (const {'issuing', 'disclosing', 'signing', 'redirect'}.contains(args.sessionType)) {
    if (pushReplacement) {
      context.pushReplacementSessionScreen(args);
    } else {
      context.pushSessionScreen(args);
    }
  } else {
    if (pushReplacement) {
      context.pushReplacementUnknownSessionScreen(args);
    } else {
      context.pushUnknownSessionScreen(args);
    }
  }

  return event.sessionID;
}
