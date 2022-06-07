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
import '../models/disclosure_credential.dart';
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
        final candidates = session.disclosuresCandidates!
            .asMap()
            .map((i, rawDiscon) => MapEntry(i, _parseCandidatesDisCon(rawDiscon)));
        // Issue wizard is completed, so all credentials in the selected cons should be choosable now.
        final choices = candidates.map((i, discon) =>
            MapEntry(i, Con(discon[_findSelectedConIndex(discon)].cast<ChoosableDisclosureCredential>())));

        // Wizard is completed, so now we show the previously added credentials that are involved in this session.
        final prevAddedChoices = {
          for (final choice in choices.entries)
            if (choice.value.isEmpty || choice.value.any((cred) => cred.previouslyAdded))
              choice.key: Con(choice.value.where((cred) => cred.previouslyAdded))
        };

        if (prevAddedChoices.isEmpty) {
          // No previously added credentials are involved in this session, so we immediately continue to the overview.
          yield DisclosurePermissionChoicesOverview(
            plannedSteps: state.plannedSteps,
            choices: choices,
            isOptional: choices.map((i, _) => MapEntry(i, candidates[i]!.any((con) => con.isEmpty))),
            signedMessage: session.isSignatureSession ?? false ? session.signedMessage : null,
          );
        } else {
          yield DisclosurePermissionPreviouslyAddedCredentialsOverview(
            plannedSteps: state.plannedSteps,
            choices: prevAddedChoices,
            isOptional: prevAddedChoices.map((i, _) => MapEntry(i, candidates[i]!.any((con) => con.isEmpty))),
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
        choices: Map.fromEntries(session.disclosuresCandidates!.mapIndexed((i, rawDiscon) {
          final discon = _parseCandidatesDisCon(rawDiscon);
          final choice = _findSelectedConIndex(discon, prevChoice: state.choices[i]);
          return MapEntry(i, Con(discon[choice].whereType<ChoosableDisclosureCredential>()));
        })),
        isOptional: Map.fromEntries(session.disclosuresCandidates!.mapIndexed(
          (i, discon) => MapEntry(
            i,
            discon.any((con) => con.isEmpty),
          ),
        )),
      );
    } else if (state is DisclosurePermissionPreviouslyAddedCredentialsOverview &&
        event is DisclosurePermissionChangeChoicePressed) {
      if (!state.choices.containsKey(event.disconIndex)) {
        throw Exception('DisCon with index ${event.disconIndex} does not exist');
      }

      // Parse discon and filter it to make sure it only includes candidates with previously added credentials.
      // A con might contain a mix of previously and newly added credentials, so we have to take that into account.
      final discon = _parseCandidatesDisCon(session.disclosuresCandidates![event.disconIndex]);
      final prevAddedCredTypeIds = discon
          .expand((con) => con
              .where((cred) => cred is ChoosableDisclosureCredential && cred.previouslyAdded)
              .map((cred) => cred.fullId))
          .toSet();
      final prevAddedDiscon = [
        for (final con in discon)
          if (con.isEmpty || con.any((cred) => prevAddedCredTypeIds.contains(cred.fullId)))
            Con(con.where((cred) => prevAddedCredTypeIds.contains(cred.fullId)))
      ];

      yield DisclosurePermissionChangeChoice(
        parentState: state,
        discon: DisclosureDisCon(
          discon: DisCon(prevAddedDiscon),
          disconIndex: event.disconIndex,
        ),
      );
    } else if (state is DisclosurePermissionChoicesOverview && event is DisclosurePermissionChangeChoicePressed) {
      if (!state.choices.containsKey(event.disconIndex)) {
        throw Exception('DisCon with index ${event.disconIndex} does not exist');
      }
      yield DisclosurePermissionChangeChoice(
        parentState: state,
        discon: DisclosureDisCon(
          discon: _parseCandidatesDisCon(session.disclosuresCandidates![event.disconIndex]),
          disconIndex: event.disconIndex,
        ),
      );
    } else if (state is DisclosurePermissionChangeChoice && event is DisclosurePermissionChoiceUpdated) {
      if (!state.discon.choosableCons.containsKey(event.conIndex) &&
          !state.discon.templateCons.containsKey(event.conIndex)) {
        throw Exception('Con with index ${event.conIndex} does not exist');
      }
      final discon = state.discon.copyWith(selectedConIndex: event.conIndex);
      yield DisclosurePermissionChangeChoice(
        parentState: _refreshChoices(state.parentState, discon),
        discon: discon,
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
          choices: state.choices,
          isOptional: state.isOptional,
          showConfirmationPopup: true,
        );
      } else {
        // Disclosure permission is finished. We have to dispatch the choices to the IrmaRepository.
        final disclosureChoices = [
          for (int i = 0; i < state.choices.length; i++)
            state.choices[i]!
                .expand((cred) => cred.attributes.map((attr) => AttributeIdentifier.fromAttribute(attr)))
                .toList()
        ];
        if (session.isIssuanceSession) {
          _repo.dispatch(ContinueToIssuanceEvent(
            sessionID: sessionID,
            disclosureChoices: disclosureChoices,
          ));
        } else {
          _repo.dispatch(
            RespondPermissionEvent(
              sessionID: sessionID,
              proceed: true,
              disclosureChoices: disclosureChoices,
            ),
            isBridgedEvent: true,
          );
        }
      }
    } else if (state is DisclosurePermissionChoicesOverview && event is DisclosurePermissionConfirmationDismissed) {
      yield DisclosurePermissionChoicesOverview(
        plannedSteps: state.plannedSteps,
        choices: state.choices,
        isOptional: state.isOptional,
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
    } else if (state is DisclosurePermissionIssueWizard) {
      yield _refreshIssueWizard(state, session);
    } else if (state is DisclosurePermissionObtainCredentials) {
      final refreshedState = _refreshObtainedCredentials(state, session);
      // In case only one credential had to be obtained, we immediately go back to the parent step.
      if (refreshedState.templates.length == 1 && refreshedState.allObtainedCredentialsMatch) {
        yield refreshedState.parentState;
      } else {
        yield refreshedState;
      }
    } else if (state is DisclosurePermissionChangeChoice) {
      final discon = _refreshDisclosureDisCon(state.discon, session);
      yield DisclosurePermissionChangeChoice(
        parentState: _refreshChoices(state.parentState, discon),
        discon: discon,
      );
    } else if (state is DisclosurePermissionChoices) {
      // Usually, this session state change should not introduce any bloc state changes.
      // Session requests cannot change within a session and credentials cannot be deleted during the session,
      // so the current selection should still be present.
    } else {
      final candidates = Map.fromEntries(session.disclosuresCandidates!.mapIndexed(
        (i, rawDiscon) => MapEntry(i, DisclosureDisCon(discon: _parseCandidatesDisCon(rawDiscon), disconIndex: i)),
      ));
      // Check whether an issue wizard is needed to bootstrap the session.
      if (candidates.values.every((discon) => discon.choosableCons.isNotEmpty)) {
        yield DisclosurePermissionChoicesOverview(
          plannedSteps: [DisclosurePermissionStepName.choicesOverview],
          choices: candidates.map((i, discon) => MapEntry(i, discon.choosableCons.values.first)),
          isOptional: Map.fromEntries(session.disclosuresCandidates!.mapIndexed(
            (i, discon) => MapEntry(
              i,
              discon.any((con) => con.isEmpty),
            ),
          )),
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
                    entry.value.templateCons.values.map((con) => Con(con.whereType<TemplateDisclosureCredential>())),
                  ),
                  disconIndex: entry.key,
                )
          },
        );
      }
    }
  }

  DisclosurePermissionIssueWizard _refreshIssueWizard(DisclosurePermissionIssueWizard prevState, SessionState session) {
    final candidates = prevState.candidates.map(
      (i, prevDiscon) => MapEntry(i, _refreshDisclosureDisCon(prevDiscon, session)),
    );
    return DisclosurePermissionIssueWizard(plannedSteps: _calculatePlannedSteps(candidates), candidates: candidates);
  }

  DisclosurePermissionObtainCredentials _refreshObtainedCredentials(
    DisclosurePermissionObtainCredentials prevState,
    SessionState session,
  ) {
    // Reverse list to make sure newest credentials are considered first.
    final newlyAddedCredentials = _newlyAddedCredentialHashes.reversed
        .expand((hash) => _repo.credentials.containsKey(hash) ? [_repo.credentials[hash]!] : <Credential>[]);

    final obtainedCredentials = prevState.templates.map((template) {
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
    }).toList();

    final parentState = prevState.parentState; // To prevent the need for type casting.

    late final DisclosurePermissionBlocState refreshedParentState;
    if (parentState is DisclosurePermissionIssueWizard) {
      refreshedParentState = _refreshIssueWizard(parentState, session);
    } else if (parentState is DisclosurePermissionChangeChoice) {
      final discon = _refreshDisclosureDisCon(parentState.discon, session);
      refreshedParentState = DisclosurePermissionChangeChoice(
        parentState: _refreshChoices(parentState.parentState, discon),
        discon: _refreshDisclosureDisCon(parentState.discon, session).copyWith(
          selectedConIndex: _findSelectedConIndex(
            parentState.discon.discon,
            prevChoice: parentState.discon.selectedCon,
            recentlyAddedCredentials: obtainedCredentials.whereNotNull(),
          ),
        ),
      );
    } else {
      throw Exception('DisclosurePermissionObtainCredentials has unexpected parent: ${parentState.runtimeType}');
    }

    return DisclosurePermissionObtainCredentials(
      parentState: refreshedParentState,
      templates: prevState.templates,
      obtainedCredentials: obtainedCredentials,
    );
  }

  DisclosureDisCon _refreshDisclosureDisCon(DisclosureDisCon prevDiscon, SessionState session) {
    final discon = _parseCandidatesDisCon(session.disclosuresCandidates![prevDiscon.disconIndex]);
    final includedCredTypeIds = [...prevDiscon.choosableCons.values, ...prevDiscon.templateCons.values]
        .expand((con) => con.map((cred) => cred.fullId))
        .toSet();
    return DisclosureDisCon(
      discon: DisCon(
        discon.fold([], (prev, con) {
          if (con.isEmpty || con.any((cred) => includedCredTypeIds.contains(cred.fullId))) {
            final filteredCon = Con(con.where((cred) => includedCredTypeIds.contains(cred.fullId)));
            // Make sure we don't add duplicate cons.
            if (!prev.contains(filteredCon)) return [...prev, filteredCon];
          }
          return prev;
        }),
      ),
      disconIndex: prevDiscon.disconIndex,
      selectedConIndex: _findSelectedConIndex(
        discon,
        prevChoice: prevDiscon.selectedCon,
        recentlyAddedCredentials: discon
            .expand((con) => con.where((cred) => !prevDiscon.contains(cred)))
            .whereType<ChoosableDisclosureCredential>(),
      ),
    );
  }

  DisclosurePermissionChoices _refreshChoices(DisclosurePermissionChoices prevState, DisclosureDisCon discon) {
    final choices = prevState.choices.map((i, con) => MapEntry(
        i,
        i == discon.disconIndex && discon.choosableCons.containsKey(discon.selectedConIndex)
            ? discon.choosableCons[discon.selectedConIndex]!
            : con));
    if (prevState is DisclosurePermissionPreviouslyAddedCredentialsOverview) {
      return DisclosurePermissionPreviouslyAddedCredentialsOverview(
        plannedSteps: prevState.plannedSteps,
        choices: choices,
        isOptional: prevState.isOptional,
      );
    } else if (prevState is DisclosurePermissionChoicesOverview) {
      return DisclosurePermissionChoicesOverview(
        plannedSteps: prevState.plannedSteps,
        choices: choices,
        isOptional: prevState.isOptional,
      );
    } else {
      throw UnsupportedError('Unknown DisclosurePermissionChoices implementation: ${prevState.runtimeType}');
    }
  }

  DisCon<DisclosureCredential> _parseCandidatesDisCon(DisCon<DisclosureCandidate> rawDiscon) {
    final attrs = rawDiscon.map((con) => con.map((candidate) => Attribute.fromCandidate(
          _repo.irmaConfiguration,
          _repo.credentials,
          candidate,
        )));
    // We only include discons for which all attributes are either choosable or obtainable.
    return DisCon(attrs.where((con) => con.every((attr) => attr.choosable || attr.obtainable)).map((con) {
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
  }

  int _findSelectedConIndex(
    DisCon<DisclosureCredential> discon, {
    Con<DisclosureCredential>? prevChoice,
    Iterable<ChoosableDisclosureCredential>? recentlyAddedCredentials,
  }) {
    // If a new choosable option has been added, then we select the new option.
    if (recentlyAddedCredentials != null) {
      final choice = discon.indexWhere((con) => con.any((cred) =>
          cred is ChoosableDisclosureCredential && recentlyAddedCredentials.any((addedCred) => addedCred == cred)));
      if (choice >= 0) return choice;
    }

    // If no new option could be found, then we try to find the option that was selected previously.
    if (prevChoice != null) {
      final choice = discon.indexWhere((con) => prevChoice.every((prevCred) => con.any((cred) => cred == prevCred)));
      if (choice >= 0) return choice;
    }
    // If no con is selected yet, we simply select the first choosable option.
    // If there is no choosable option at all, we select the first option.
    final choice = discon.indexWhere((con) => con.every((cred) => cred is ChoosableDisclosureCredential));
    return choice >= 0 ? choice : 0;
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
