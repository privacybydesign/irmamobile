import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../data/irma_repository.dart';
import '../../../../models/attributes.dart';
import '../../../../models/credentials.dart';
import '../../../../models/irma_configuration.dart';
import '../../../../models/session_events.dart';
import '../../../../models/session_state.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import '../models/choosable_disclosure_credential.dart';
import '../models/disclosure_dis_con.dart';
import '../models/template_disclosure_credential.dart';

/**
 * This bloc enforces the following state machine:
 *
 *    --------
 *  | Initial |
 *   ---------
 *    | on requestDisclosurePermission status
 *    |
 *    | (a)  -------------------------------------                   NextPressed (i)
 *    |--> |            IssueWizard              |  <---------------------------
 *    |     -------------------------------------                               |
 *    |      | NextPressed       |__^ ChoiceUpdated                (c)  -------------------           NextPressed (h)
 *    |      |------------------------------------------------------>  | ObtainCredentials | <------------
 *    |      |                                                          -------------------               |
 *    |      |                                          NextPressed (f)           |                       |
 *    |      | (d) ------------------------------------   <-------------          | NextPressed (j)       |
 *    |      |--> | PreviouslyAddedCredentialsOverview |---------       |         v                       |
 *    |      |     ------------------------------------         |       ----------------                  |
 *    |      |             | NextPressed                        |----> |  ChangeChoice  | ----------------
 *    |      v (e)         v                ChangeChoicePressed |       ----------------
 *    | (b) -------------------------------------               |         |      |__^ ChoiceUpdated
 *     --> |           ChoicesOverview           |--------------          |
 *          -------------------------------------  <----------------------  NextPressed (g)
 *           |__^ NextPressed (k)      |
 *                                     v  NextPressed (l)
 *                                ----------
 *                               | Finished |
 *                                ----------
 *
 * Notes:
 * a). if the candidates contain discons without any choosable option.
 * b). if all discons contain a choosable option (the empty option in optional disjunctions is also choosable).
 * c). if the issue wizard is not completed yet. Credentials are obtained for the first incomplete discon.
 * d). if the candidates contain more credential instances than the onces that we added during the issue wizard.
 * e). if all choosable options are populated using credential instances that were added during the issue wizard.
 * f). if the previous state was PreviouslyAddedCredentialsOverview.
 * g). if the previous state was ChoicesOverview.
 * h). if the chosen option still contains template credentials that must be obtained first.
 * i). if the previous state was IssueWizard. This action is triggered automatically if the sub issue wizard only
 *     contains one credential and the attempt to obtain it succeeds at once.
 * j). if the previous state was ChangeChoice.
 * k). if showConfirmationPopup is false.
 * l). if showConfirmationPopup is true.
 */

/// Bloc that specifies the flow during DisclosurePermission. Check the bloc source code for a state machine drawing.
class DisclosurePermissionBloc extends Bloc<DisclosurePermissionBlocEvent, DisclosurePermissionBlocState> {
  final int sessionID;
  final Function(CredentialType) onObtainCredential;

  final IrmaRepository _repo; // Repository is hidden by design, because behaviour should be triggered via bloc events.

  late final StreamSubscription _sessionStateSubscription;
  late final StreamSubscription _sessionEventSubscription;

  final List<String> _newlyAddedCredentialHashes;

  DisclosurePermissionBloc({
    required this.sessionID,
    required this.onObtainCredential,
    required IrmaRepository repo,
  })  : _repo = repo,
        _newlyAddedCredentialHashes = [],
        super(DisclosurePermissionInitial()) {
    _sessionStateSubscription = repo.getSessionState(sessionID).asyncExpand(_mapSessionStateToBlocState).listen(emit);
    _sessionEventSubscription = repo
        .getEvents()
        .whereType<RequestIssuancePermissionSessionEvent>()
        .expand((event) => event.issuedCredentials.map((cred) => cred.hash))
        .listen(_newlyAddedCredentialHashes.add);
  }

  @override
  Future<void> close() async {
    await _sessionStateSubscription.cancel();
    await _sessionEventSubscription.cancel();
    super.close();
  }

  @override
  Stream<DisclosurePermissionBlocState> mapEventToState(DisclosurePermissionBlocEvent event) async* {
    final state = this.state; // To prevent the need for type casting.
    final session = _repo.getCurrentSessionState(sessionID)!;
    if (state is DisclosurePermissionIssueWizard && event is DisclosurePermissionChoiceUpdated) {
      if (state.currentDiscon == null) throw Exception('No DisCon found that expects an update');
      final updatedCandidates = state.candidates.map(
        (i, discon) => MapEntry(
            i,
            discon.disconIndex == state.currentDiscon!.disconIndex
                ? discon.copyWith(selectedConIndex: event.conIndex)
                : discon),
      );
      // When an option is changed, the list of previous added credentials that are involved in this session
      // may have changed too. Therefore, we have to recalculate the planned steps.
      yield DisclosurePermissionIssueWizard(
        plannedSteps: state.plannedSteps, // TODO: This might have been changed.
        candidates: updatedCandidates,
      );
    } else if (state is DisclosurePermissionIssueWizard && event is DisclosurePermissionNextPressed) {
      if (state.isCompleted) {
        // Wizard is completed, so now we show the previously added credentials that are involved in this session.
        final candidates = _parseDisclosureCandidates(session.disclosuresCandidates!, prevCandidates: state.candidates);
        final prevAddedDiscons = {
          for (final entry in candidates.entries)
            if (entry.value.choosableCons.values.any((con) => con.any((cred) => cred.previouslyAdded)))
              entry.key: DisclosureDisCon(
                disconIndex: entry.key,
                selectedConIndex: entry.value.selectedConIndex,
                discon: DisCon(
                    entry.value.choosableCons.values.map((con) => Con(con.where((cred) => cred.previouslyAdded)))),
              )
        };
        if (prevAddedDiscons.isEmpty) {
          // No previously added credentials are involved in this session, so we immediately continue to the overview.
          yield DisclosurePermissionChoicesOverview(
            plannedSteps: state.plannedSteps,
            candidates: candidates,
            signedMessage: session.isSignatureSession ?? false ? session.signedMessage : null,
          );
        } else {
          yield DisclosurePermissionPreviouslyAddedCredentialsOverview(
            plannedSteps: state.plannedSteps,
            candidates: prevAddedDiscons,
          );
        }
      } else {
        // If only one credential is involved, we can open the issue url immediately.
        if (state.currentDiscon!.selectedCon.length == 1) {
          onObtainCredential(state.currentDiscon!.selectedCon.first.credentialType);
        }
        yield DisclosurePermissionObtainCredentials(
          parentState: state,
          templates: state.currentDiscon!.selectedCon.whereType<TemplateDisclosureCredential>().toList(),
        );
      }
    } else if (state is DisclosurePermissionObtainCredentials && event is DisclosurePermissionNextPressed) {
      if (state.allObtainedCredentialsMatch) {
        yield state.parentState;
      } else {
        onObtainCredential(state.currentIssueWizardItem!.credentialType);
      }
    } else if (state is DisclosurePermissionPreviouslyAddedCredentialsOverview &&
        event is DisclosurePermissionNextPressed) {
      yield DisclosurePermissionChoicesOverview(
        plannedSteps: state.plannedSteps,
        candidates: _parseDisclosureCandidates(session.disclosuresCandidates!, prevCandidates: state.candidates),
      );
    } else if (state is DisclosurePermissionStep && event is DisclosurePermissionChangeChoicePressed) {
      if (state is DisclosurePermissionIssueWizard) {
        throw UnsupportedError('No separate state exists for changing choices during issue wizards');
      }
      final discon = state.candidates[event.disconIndex];
      if (discon == null) {
        throw Exception('DisclosureDisCon with index ${event.disconIndex} does not exist');
      }
      yield DisclosurePermissionChangeChoice(parentState: state, discon: discon);
    } else if (state is DisclosurePermissionChangeChoice && event is DisclosurePermissionChoiceUpdated) {
      if (!state.discon.choosableCons.containsKey(event.conIndex) &&
          !state.discon.templateCons.containsKey(event.conIndex)) {
        throw Exception('Con with index ${event.conIndex} does not exist');
      }

      final parentState = state.parentState; // To prevent the need for type casting.
      final updatedCandidates = parentState.candidates.map(
        (i, discon) => MapEntry(
            i,
            discon.disconIndex == state.discon.disconIndex
                ? state.discon.copyWith(selectedConIndex: event.conIndex)
                : discon),
      );
      late final DisclosurePermissionStep updatedParentState;
      if (parentState is DisclosurePermissionPreviouslyAddedCredentialsOverview) {
        updatedParentState = DisclosurePermissionPreviouslyAddedCredentialsOverview(
          plannedSteps: parentState.plannedSteps,
          candidates: updatedCandidates,
        );
      } else if (parentState is DisclosurePermissionChoicesOverview) {
        updatedParentState = DisclosurePermissionChoicesOverview(
          plannedSteps: parentState.plannedSteps,
          candidates: updatedCandidates,
        );
      } else {
        throw UnsupportedError('Transition from DisclosurePermissionChangeChoice to ${state.parentState.runtimeType}');
      }

      yield DisclosurePermissionChangeChoice(
        parentState: updatedParentState,
        discon: updatedParentState.candidates[state.discon.disconIndex]!,
      );
    } else if (state is DisclosurePermissionChangeChoice && event is DisclosurePermissionNextPressed) {
      if (state.discon.selectedCon.any((cred) => cred is TemplateDisclosureCredential)) {
        // If only one credential is involved, we can open the issue url immediately.
        if (state.discon.selectedCon.length == 1) {
          onObtainCredential(state.discon.selectedCon.first.credentialType);
        }
        yield DisclosurePermissionObtainCredentials(
          parentState: state,
          templates: state.discon.selectedCon.whereType<TemplateDisclosureCredential>().toList(),
        );
      } else {
        yield state.parentState;
      }
    } else if (state is DisclosurePermissionChoicesOverview && event is DisclosurePermissionNextPressed) {
      if (!state.showConfirmationPopup) {
        yield DisclosurePermissionChoicesOverview(
          plannedSteps: state.plannedSteps,
          candidates: state.candidates,
          showConfirmationPopup: true,
        );
      } else if (session.isIssuanceSession) {
        // TODO: We have to store the RespondPermissionEvent with disclosure choices somewhere.
        _repo.dispatch(
          ContinueToIssuanceEvent(sessionID: sessionID),
          isBridgedEvent: true,
        );
      } else {
        _repo.dispatch(
          RespondPermissionEvent(
            sessionID: sessionID,
            proceed: true,
            disclosureChoices: [
              for (int i = 0; i < state.candidates.length; i++)
                state.candidates[i]!.selectedCon
                    .expand((cred) => cred.attributes.map((attr) => AttributeIdentifier.fromAttribute(attr)))
                    .toList()
            ],
          ),
          isBridgedEvent: true,
        );
      }
    } else if (state is DisclosurePermissionChoicesOverview && event is DisclosurePermissionConfirmationDismissed) {
      yield DisclosurePermissionChoicesOverview(
        plannedSteps: state.plannedSteps,
        candidates: state.candidates,
      );
    } else {
      throw UnsupportedError(
          'Event ${event.runtimeType.toString()} not supported in state ${state.runtimeType.toString()}');
    }
  }

  Stream<DisclosurePermissionBlocState> _mapSessionStateToBlocState(SessionState session) async* {
    final state = this.state;
    if (session.status != SessionStatus.requestDisclosurePermission) {
      if (state is! DisclosurePermissionInitial && state is! DisclosurePermissionFinished) {
        yield DisclosurePermissionFinished();
      }
      return;
    } else if (state is DisclosurePermissionStep) {
      yield _refreshDisclosurePermissionStep(session, state);
    } else if (state is DisclosurePermissionObtainCredentials) {
      final refreshedWizard = _refreshObtainedCredentials(session, state);
      // In case the sub wizard only contains one item, we immediately go back to the parent step.
      if (refreshedWizard.templates.length == 1 && refreshedWizard.allObtainedCredentialsMatch) {
        yield refreshedWizard.parentState;
      } else {
        yield refreshedWizard;
      }
    } else if (state is DisclosurePermissionChangeChoice) {
      final refreshedStep = _refreshDisclosurePermissionStep(session, state.parentState);
      yield DisclosurePermissionChangeChoice(
        parentState: refreshedStep,
        discon: refreshedStep.candidates[state.discon.disconIndex]!,
      );
    } else {
      // Check whether an issue wizard is needed to bootstrap the session.
      final candidates = _parseDisclosureCandidates(session.disclosuresCandidates!);
      if (candidates.values.every((discon) => discon.choosableCons.isNotEmpty)) {
        yield DisclosurePermissionChoicesOverview(
          plannedSteps: [DisclosurePermissionStepName.choicesOverview],
          candidates: candidates,
          signedMessage: session.isSignatureSession ?? false ? session.signedMessage : null,
        );
      } else {
        // In an issue wizard, only the credential templates are relevant. If an issue wizard is needed,
        // we also include the optional discons where no non-empty con is fully obtained yet. If no issue wizard
        // is needed, then the optional discons are presented in DisclosurePermissionChoicesOverview.
        yield DisclosurePermissionIssueWizard(plannedSteps: [], //_calculatePlannedSteps(condiscon), TODO: fix
            candidates: {
              for (final entry in candidates.entries)
                if (entry.value.choosableCons.isEmpty)
                  entry.key: DisclosureDisCon(
                    discon: DisCon(entry.value.templateCons.values
                        .map((con) => Con(con.whereType<TemplateDisclosureCredential>()))),
                    disconIndex: entry.key,
                  )
            });
      }
    }
  }

  DisclosurePermissionStep _refreshDisclosurePermissionStep(SessionState session, DisclosurePermissionStep state) {
    final updatedCandidates = _parseDisclosureCandidates(
      session.disclosuresCandidates!,
      prevCandidates: state.candidates,
    );
    if (state is DisclosurePermissionIssueWizard) {
      // We assume that in the initial disclosure candidates all credential types involved in this session are
      // being mentioned. This allows us to build upon the previously generated issue wizard.
      return DisclosurePermissionIssueWizard(plannedSteps: state.plannedSteps, candidates: updatedCandidates);
    } else if (state is DisclosurePermissionPreviouslyAddedCredentialsOverview) {
      return DisclosurePermissionPreviouslyAddedCredentialsOverview(
          plannedSteps: state.plannedSteps, candidates: updatedCandidates);
    } else if (state is DisclosurePermissionChoicesOverview) {
      return DisclosurePermissionChoicesOverview(
        plannedSteps: state.plannedSteps,
        candidates: updatedCandidates,
        signedMessage: state.signedMessage,
        showConfirmationPopup: state.showConfirmationPopup,
      );
    } else {
      throw UnsupportedError('unknown step ${state.runtimeType}');
    }
  }

  DisclosurePermissionObtainCredentials _refreshObtainedCredentials(
    SessionState session,
    DisclosurePermissionObtainCredentials state,
  ) {
    // Reverse list to make sure newest credentials are considered first.
    final newlyAddedCredentials = _newlyAddedCredentialHashes.reversed
        .expand((hash) => _repo.credentials.containsKey(hash) ? [_repo.credentials[hash]!] : <Credential>[]);

    final parentState = state.parentState; // To prevent the need for type casting.
    late final DisclosurePermissionStep condiscon;
    if (parentState is DisclosurePermissionStep) {
      condiscon = parentState;
    } else if (parentState is DisclosurePermissionChangeChoice) {
      condiscon = parentState.parentState;
    } else {
      throw Exception('DisclosurePermissionObtainCredentials has unexpected parent: ${parentState.runtimeType}');
    }

    return DisclosurePermissionObtainCredentials(
      parentState: _refreshDisclosurePermissionStep(session, condiscon),
      templates: state.templates,
      obtainedCredentials: state.templates.map((template) {
        // First we check whether we have an exact match.
        final matchingCred = newlyAddedCredentials.firstWhereOrNull((cred) => template.matchesCredential(cred));
        if (matchingCred != null) {
          return ChoosableDisclosureCredential.fromTemplate(
            template: template,
            credential: matchingCred,
          );
        }

        // If there is no exact match, then we look for credentials that were added in attempt to make a match.
        final templateWithoutValueConstraints = template.copyWithoutValueConstraints();
        final nonMatchingCred =
            newlyAddedCredentials.firstWhereOrNull((cred) => templateWithoutValueConstraints.matchesCredential(cred));
        if (nonMatchingCred != null) {
          return ChoosableDisclosureCredential.fromTemplate(
            template: templateWithoutValueConstraints,
            credential: nonMatchingCred,
          );
        }

        // If there is still no match, then we assume no attempt has been made to obtain this template yet.
        return null;
      }).toList(),
    );
  }

  Map<int, DisclosureDisCon> _parseDisclosureCandidates(
    ConDisCon<Attribute> rawCandidates, {
    Map<int, DisclosureDisCon>? prevCandidates,
  }) {
    return rawCandidates.asMap().map((i, rawDiscon) {
      final discon = DisCon(rawDiscon.map((con) {
        final groupedCon = groupBy(con, (Attribute attr) => attr.credentialInfo.fullId);
        return Con(groupedCon.entries.map((entry) {
          final credentialAttributes = entry.value;
          if (credentialAttributes.first.choosable) {
            return ChoosableDisclosureCredential(
              attributes: credentialAttributes,
              previouslyAdded: !_newlyAddedCredentialHashes.contains(credentialAttributes.first.credentialHash),
            );
          } else {
            return TemplateDisclosureCredential(attributes: credentialAttributes);
          }
        }));
      }));
      final selectedConIndex = discon.indexWhere(
          (con) => prevCandidates?[i]?.selectedCon.every((prevCred) => con.any((cred) => cred == prevCred)) ?? false);
      return MapEntry(
          i,
          DisclosureDisCon(
            disconIndex: i,
            selectedConIndex: selectedConIndex >= 0 ? selectedConIndex : 0,
            discon: discon,
          ));
    });
  }

  // List<DisclosurePermissionStepName> _calculatePlannedSteps(DisclosureConDisCon condiscon) {
  //   final hasPrevAddedCreds =
  //       condiscon.any((discon) => discon.selectedCon.any((cred) => cred is ChoosableDisclosureCredential));
  //   final stepNames = [
  //     DisclosurePermissionStepName.issueWizard,
  //     DisclosurePermissionStepName.previouslyAddedCredentialsOverview,
  //     DisclosurePermissionStepName.choicesOverview,
  //   ];
  //   // In an issue wizard, only the credential templates are relevant.
  //   return hasPrevAddedCreds
  //       ? stepNames
  //       : stepNames.where((name) => name != DisclosurePermissionStepName.previouslyAddedCredentialsOverview).toList();
  // }
}
