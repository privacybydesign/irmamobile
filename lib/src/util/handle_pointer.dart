import 'package:flutter/material.dart';

import '../models/issue_wizard.dart';
import '../models/session.dart';
import '../models/session_events.dart';
import '../providers/irma_repository_provider.dart';
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

Future<void> _startIssueWizard(
  BuildContext context,
  IssueWizardPointer wizardPointer,
  int? sessionID,
  bool pushReplacement,
) async {
  final repo = IrmaRepositoryProvider.of(context);
  repo.bridgedDispatch(GetIssueWizardContentsEvent(id: wizardPointer.wizard));

  // Push wizard on top of session screen (if any). If the user cancels the wizard by going back
  // to the wallet, then the session screen is automatically dismissed, which cancels the session.
  final params = IssueWizardRouteParams(wizardID: wizardPointer.wizard, sessionID: sessionID);

  if (pushReplacement) {
    context.pushReplacementIssueWizardScreen(params);
  } else {
    await context.pushIssueWizardScreen(params);
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

  final params = SessionRouteParams(
    sessionID: event.sessionID,
    sessionType: event.request.irmaqr,
    hasUnderlyingSession: hasActiveSessions,
    wizardActive: wizardActive,
    wizardCred: wizardActive ? (await repo.getIssueWizard().first)?.activeItem?.credential : null,
  );

  if (!context.mounted) {
    return event.sessionID;
  }

  if (const {'issuing', 'disclosing', 'signing', 'redirect'}.contains(params.sessionType)) {
    if (pushReplacement) {
      context.pushReplacementSessionScreen(params);
    } else {
      context.pushSessionScreen(params);
    }
  } else {
    if (pushReplacement) {
      context.pushReplacementUnknownSessionScreen(params);
    } else {
      context.pushUnknownSessionScreen(params);
    }
  }

  return event.sessionID;
}
