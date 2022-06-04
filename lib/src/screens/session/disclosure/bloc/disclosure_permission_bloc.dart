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
 * i). if the previous state was IssueWizard. This action is triggered automatically if the list of credentials that
 *     should be obtained only contains one credential and the attempt to obtain it succeeds at once.
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
      if (!state.currentDiscon!.templateCons.containsKey(event.conIndex)) {
        throw Exception('Unknown conIndex ${event.conIndex} in discon with index ${state.currentDiscon!.disconIndex}');
      }
      final updatedCandidates = state.candidates.map(
        (i, discon) => MapEntry(
          i,
          discon.disconIndex == state.currentDiscon!.disconIndex
              ? discon.copyWith(selectedConIndex: event.conIndex)
              : discon,
        ),
      );
      // When an option is changed, the list of previous added credentials that are involved in this session
      // may have changed too. Therefore, we have to recalculate the planned steps.
      final stepNames = [
        DisclosurePermissionStepName.issueWizard,
        DisclosurePermissionStepName.previouslyAddedCredentialsOverview,
        DisclosurePermissionStepName.choicesOverview,
      ];
      yield DisclosurePermissionIssueWizard(
        plannedSteps: session.disclosuresCandidates!.length > updatedCandidates.length ||
                updatedCandidates.entries.any((disconEntry) => session.disclosuresCandidates![disconEntry.key]
                        [disconEntry.value.selectedConIndex]
                    .any((attr) => attr.credentialHash?.isNotEmpty ?? false))
            ? stepNames
            : (stepNames..remove(DisclosurePermissionStepName.previouslyAddedCredentialsOverview)),
        candidates: updatedCandidates,
      );
    } else if (state is DisclosurePermissionIssueWizard && event is DisclosurePermissionNextPressed) {
      if (state.isCompleted) {
        // Wizard is completed, so now we show the previously added credentials that are involved in this session.
        // We also add the templates to obtain new instances of the previously added credential types.
        final candidates = _parseDisclosureCandidates(session.disclosuresCandidates!, prevCandidates: state.candidates);
        final previouslyAddedCredTypes = candidates.values
            .expand((discon) => discon.choosableCons.values
                .expand((con) => con.where((cred) => cred.previouslyAdded).map((cred) => cred.fullId)))
            .toSet();
        final prevAddedDiscons = {
          for (final entry in candidates.entries)
            if (entry.value.choosableCons.values.any((con) => con.any((cred) => cred.previouslyAdded)))
              entry.key: DisclosureDisCon(
                disconIndex: entry.key,
                selectedConIndex: entry.value.selectedConIndex,
                discon: DisCon(
                  [
                    ...entry.value.choosableCons.values.map((con) => Con(con.where((cred) => cred.previouslyAdded))),
                    ...entry.value.templateCons.values.map((con) => Con(con
                        .whereType<TemplateDisclosureCredential>()
                        .where((cred) => previouslyAddedCredTypes.contains(cred.fullId))))
                  ].fold([], (prev, con) => prev.contains(con) ? prev : [...prev, con]), // Filter out duplicates.
                ),
              ),
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
      } else {
        // Disclosure permission is finished. We have to dispatch the choices to the IrmaRepository.
        final choices = [
          for (int i = 0; i < state.candidates.length; i++)
            state.candidates[i]!.selectedCon
                .expand((cred) => cred.attributes.map((attr) => AttributeIdentifier.fromAttribute(attr)))
                .toList()
        ];
        if (session.isIssuanceSession) {
          _repo.dispatch(ContinueToIssuanceEvent(
            sessionID: sessionID,
            disclosureChoices: choices,
          ));
        } else {
          _repo.dispatch(
            RespondPermissionEvent(
              sessionID: sessionID,
              proceed: true,
              disclosureChoices: choices,
            ),
            isBridgedEvent: true,
          );
        }
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
      final refreshedState = _refreshObtainedCredentials(session, state);
      // In case only one credential had to be obtained, we immediately go back to the parent step.
      if (refreshedState.templates.length == 1 && refreshedState.allObtainedCredentialsMatch) {
        yield refreshedState.parentState;
      } else {
        yield refreshedState;
      }
    } else if (state is DisclosurePermissionChangeChoice) {
      final refreshedStep = _refreshDisclosurePermissionStep(
        session,
        state.parentState,
        selectedDisconIndex: state.discon.disconIndex,
      );
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
        yield DisclosurePermissionIssueWizard(
          plannedSteps: _calculatePlannedSteps(candidates),
          candidates: {
            for (final entry in candidates.entries)
              if (entry.value.choosableCons.isEmpty)
                entry.key: DisclosureDisCon(
                  discon: DisCon(
                      entry.value.templateCons.values.map((con) => Con(con.whereType<TemplateDisclosureCredential>()))),
                  disconIndex: entry.key,
                )
          },
        );
      }
    }
  }

  DisclosurePermissionStep _refreshDisclosurePermissionStep(
    SessionState session,
    DisclosurePermissionStep state, {
    int? selectedDisconIndex,
  }) {
    final parsedCandidates = _parseDisclosureCandidates(
      session.disclosuresCandidates!,
      prevCandidates: state.candidates,
      selectedDisconIndex: selectedDisconIndex,
    );
    if (state is DisclosurePermissionIssueWizard) {
      // We assume that in the initial disclosure candidates all credential types involved in this session are
      // being mentioned. This allows us to build upon the previously generated issue wizard.
      return DisclosurePermissionIssueWizard(
        plannedSteps: state.plannedSteps,
        candidates: parsedCandidates..removeWhere((i, _) => !state.candidates.containsKey(i)),
      );
    } else if (state is DisclosurePermissionPreviouslyAddedCredentialsOverview) {
      return DisclosurePermissionPreviouslyAddedCredentialsOverview(
        plannedSteps: state.plannedSteps,
        candidates: parsedCandidates..removeWhere((i, _) => !state.candidates.containsKey(i)),
      );
    } else if (state is DisclosurePermissionChoicesOverview) {
      return DisclosurePermissionChoicesOverview(
        plannedSteps: state.plannedSteps,
        candidates: parsedCandidates,
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
    late final DisclosurePermissionBlocState refreshedParentState;
    if (parentState is DisclosurePermissionStep) {
      refreshedParentState = _refreshDisclosurePermissionStep(session, parentState);
    } else if (parentState is DisclosurePermissionChangeChoice) {
      final refreshedStep = _refreshDisclosurePermissionStep(
        session,
        parentState.parentState,
        selectedDisconIndex: parentState.discon.disconIndex,
      );
      refreshedParentState = DisclosurePermissionChangeChoice(
        parentState: refreshedStep,
        discon: refreshedStep.candidates[parentState.discon.disconIndex]!,
      );
    } else {
      throw Exception('DisclosurePermissionObtainCredentials has unexpected parent: ${parentState.runtimeType}');
    }

    return DisclosurePermissionObtainCredentials(
      parentState: refreshedParentState,
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
    ConDisCon<DisclosureCandidate> rawCandidates, {
    Map<int, DisclosureDisCon>? prevCandidates,
    int? selectedDisconIndex,
  }) {
    final parsedCandidates = ConDisCon.fromRaw<DisclosureCandidate, Attribute>(
      rawCandidates,
      (disclosureCandidate) => Attribute.fromCandidate(
        _repo.irmaConfiguration,
        _repo.credentials,
        disclosureCandidate,
      ),
    );

    return parsedCandidates.asMap().map((i, rawDiscon) {
      // We only include discons for which all attributes are either choosable or obtainable.
      final discon = DisCon(rawDiscon.where((con) => con.every((attr) => attr.choosable || attr.obtainable)).map((con) {
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

      int selectedConIndex = -1;
      if (prevCandidates != null && prevCandidates.containsKey(i)) {
        // If a new choosable option has been added, then we select the new option.
        // If one discon is selected in particular, we only change it there.
        if (selectedDisconIndex == null || selectedDisconIndex == i) {
          final prevCredHashes =
              prevCandidates[i]!.choosableCons.values.expand((con) => con.map((cred) => cred.credentialHash)).toSet();
          selectedConIndex = discon.indexWhere((con) => con
              .any((cred) => cred is ChoosableDisclosureCredential && !prevCredHashes.contains(cred.credentialHash)));
        }

        // If no new option could be found, then we try to find the option that was selected previously.
        if (selectedConIndex < 0) {
          selectedConIndex = discon.indexWhere(
              (con) => prevCandidates[i]!.selectedCon.every((prevCred) => con.any((cred) => cred == prevCred)));
        }
      }
      // If no con is selected yet, we simply select the first option.
      if (selectedConIndex < 0) {
        selectedConIndex = 0;
      }
      return MapEntry(
          i,
          DisclosureDisCon(
            disconIndex: i,
            selectedConIndex: selectedConIndex,
            discon: discon,
          ));
    });
  }

  List<DisclosurePermissionStepName> _calculatePlannedSteps(Map<int, DisclosureDisCon> candidates) {
    final hasPrevAddedCreds =
        candidates.values.any((discon) => discon.selectedCon.any((cred) => cred is ChoosableDisclosureCredential));
    final stepNames = [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.previouslyAddedCredentialsOverview,
      DisclosurePermissionStepName.choicesOverview,
    ];
    // In an issue wizard, only the credential templates are relevant.
    return hasPrevAddedCreds
        ? stepNames
        : (stepNames..remove(DisclosurePermissionStepName.previouslyAddedCredentialsOverview));
  }
}
