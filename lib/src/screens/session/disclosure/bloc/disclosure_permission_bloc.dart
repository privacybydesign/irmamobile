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
import '../models/template_disclosure_credential.dart';

/// Bloc that specifies the flow during DisclosurePermission.
/// New states are triggered either by an event being added to the bloc, or by changes in the SessionState.
/// mapEventToState handles newly added events and _mapSessionStateToBlocState handles SessionState changes.
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
    _maybeStartIntroduction();
    _sessionStateSubscription = repo
        .getSessionState(sessionID)
        .map((session) => _mapSessionStateToBlocState(state, session))
        .where((newState) => newState != state) // To prevent the DisclosurePermissionInitial state is added twice.
        .listen(emit);
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

  void _maybeStartIntroduction() async {
    var completedIntroduction = await _repo.preferences.getCompletedDisclosurePermissionIntro().first;
    if (!completedIntroduction) add(DisclosurePermissionIntroductionStarted());
  }

  @override
  Stream<DisclosurePermissionBlocState> mapEventToState(DisclosurePermissionBlocEvent event) async* {
    final state = this.state; // To prevent the need for type casting.
    final session = _repo.getCurrentSessionState(sessionID)!;

    if (event is DisclosurePermissionIntroductionStarted) {
      yield DisclosurePermissionIntroduction();
    } else if (state is DisclosurePermissionIntroduction && event is DisclosurePermissionNextPressed) {
      yield _mapSessionStateToBlocState(state, session);
    } else if (state is DisclosurePermissionIssueWizard && event is DisclosurePermissionChoiceUpdated) {
      if (state.currentDiscon == null) throw Exception('No DisCon found that expects an update');
      if (event.conIndex < 0 || event.conIndex >= state.currentDiscon!.value.length) {
        throw Exception('Unknown conIndex ${event.conIndex} in current discon');
      }

      final selectedConIndices = state.selectedConIndices
          .map((i, selected) => MapEntry(i, i == state.currentDiscon!.key ? event.conIndex : selected));

      // When an option is changed, the list of previous added credentials that are involved in this session
      // may have changed too. Therefore, we have to recalculate the planned steps.
      yield DisclosurePermissionIssueWizard(
        plannedSteps: _calculatePlannedSteps(state.candidates, selectedConIndices, session),
        candidates: state.candidates,
        selectedConIndices: selectedConIndices,
        obtained: state.obtained,
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
        // TODO: check code duplication while constructing choices overview.
        final prevAddedChoices = {
          for (final choice in choices.entries)
            if (choice.value.any((cred) => cred.previouslyAdded))
              choice.key: Con(choice.value.where((cred) => cred.previouslyAdded))
        };
        final hasPrevAddedAdditionalChoices = choices.entries.any((entry) =>
            entry.value.isEmpty &&
            candidates[entry.key]!
                .flattened
                .any((cred) => cred is ChoosableDisclosureCredential && cred.previouslyAdded));

        if (prevAddedChoices.isEmpty && !hasPrevAddedAdditionalChoices) {
          // No previously added credentials are involved in this session, so we immediately continue to the overview.
          yield DisclosurePermissionChoicesOverview(
            plannedSteps: state.plannedSteps,
            requiredChoices: Map.fromEntries(
                choices.entries.where((entry) => candidates[entry.key]!.every((con) => con.isNotEmpty))),
            optionalChoices: Map.fromEntries(choices.entries
                .where((entry) => entry.value.isNotEmpty && candidates[entry.key]!.any((con) => con.isEmpty))),
            hasAdditionalOptionalChoices: choices.values.any((choice) => choice.isEmpty),
            signedMessage: session.isSignatureSession ?? false ? session.signedMessage : null,
          );
        } else {
          yield DisclosurePermissionPreviouslyAddedCredentialsOverview(
            plannedSteps: state.plannedSteps,
            requiredChoices: Map.fromEntries(
                prevAddedChoices.entries.where((entry) => candidates[entry.key]!.every((con) => con.isNotEmpty))),
            optionalChoices: Map.fromEntries(prevAddedChoices.entries
                .where((entry) => entry.value.isNotEmpty && candidates[entry.key]!.any((con) => con.isEmpty))),
            hasAdditionalOptionalChoices: hasPrevAddedAdditionalChoices,
          );
        }
      } else {
        yield* _obtainCredentials(state, state.getSelectedCon(state.currentDiscon!.key)!);
      }
    } else if (state is DisclosurePermissionObtainCredentials && event is DisclosurePermissionNextPressed) {
      if (state.allObtained) {
        yield state.parentState;
      } else {
        // currentIssueWizardItem cannot be null when allObtained returned false.
        onObtainCredential(state.currentIssueWizardItem!.credentialType);
      }
    } else if (state is DisclosurePermissionPreviouslyAddedCredentialsOverview &&
        event is DisclosurePermissionNextPressed) {
      final choices = Map.fromEntries(session.disclosuresCandidates!.mapIndexed((i, rawDiscon) {
        final discon = _parseCandidatesDisCon(rawDiscon);
        final choice = _findSelectedConIndex(discon, prevChoice: state.choices[i]);
        return MapEntry(i, Con(discon[choice].whereType<ChoosableDisclosureCredential>()));
      }));
      yield DisclosurePermissionChoicesOverview(
        plannedSteps: state.plannedSteps,
        requiredChoices: Map.fromEntries(
            choices.entries.where((entry) => session.disclosuresCandidates![entry.key].every((con) => con.isNotEmpty))),
        optionalChoices: Map.fromEntries(choices.entries.where(
            (entry) => entry.value.isNotEmpty && session.disclosuresCandidates![entry.key].any((con) => con.isEmpty))),
        hasAdditionalOptionalChoices: choices.values.any((choice) => choice.isEmpty),
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
        discon: DisCon(prevAddedDiscon),
        disconIndex: event.disconIndex,
        selectedConIndex: _findSelectedConIndex(discon, prevChoice: state.choices[event.disconIndex]),
      );
    } else if (state is DisclosurePermissionChoicesOverview && event is DisclosurePermissionChangeChoicePressed) {
      if (!state.choices.containsKey(event.disconIndex)) {
        throw Exception('DisCon with index ${event.disconIndex} does not exist');
      }
      final discon = _parseCandidatesDisCon(session.disclosuresCandidates![event.disconIndex]);
      yield DisclosurePermissionChangeChoice(
        parentState: state,
        discon: discon,
        disconIndex: event.disconIndex,
        selectedConIndex: _findSelectedConIndex(discon, prevChoice: state.choices[event.disconIndex]),
      );
    } else if (state is DisclosurePermissionChangeChoice && event is DisclosurePermissionChoiceUpdated) {
      if (!state.choosableCons.containsKey(event.conIndex) && !state.templateCons.containsKey(event.conIndex)) {
        throw Exception('Con with index ${event.conIndex} does not exist');
      }
      yield DisclosurePermissionChangeChoice(
        parentState: _refreshChoices(state.parentState, state.discon, state.disconIndex, event.conIndex),
        discon: state.discon,
        disconIndex: state.disconIndex,
        selectedConIndex: event.conIndex,
      );
    } else if (state is DisclosurePermissionChangeChoice && event is DisclosurePermissionNextPressed) {
      if (state.selectedCon.any((cred) => cred is TemplateDisclosureCredential)) {
        yield* _obtainCredentials(state, state.selectedCon);
      } else {
        yield state.parentState;
      }
    } else if (state is DisclosurePermissionWrongCredentialsObtained && event is DisclosurePermissionDialogDismissed) {
      yield state.parentState;
    } else if (state is DisclosurePermissionAddOptionalData && event is DisclosurePermissionChoiceUpdated) {
      if (event.conIndex < 0 || event.conIndex >= state.discon.length) {
        throw Exception('Con with index ${event.conIndex} does not exist');
      }
      yield DisclosurePermissionAddOptionalData(
        parentState: state.parentState,
        discon: state.discon,
        disconIndices: state.disconIndices,
        selectedConIndex: event.conIndex,
      );
    } else if (state is DisclosurePermissionAddOptionalData && event is DisclosurePermissionNextPressed) {
      if (state.isSelectedChoosable) {
        yield _refreshChoices(state.parentState, [state.selectedCon], state.disconIndexSelectedCon, 0);
      } else {
        yield* _obtainCredentials(state, state.selectedCon);
      }
    } else if (state is DisclosurePermissionChoices && event is DisclosurePermissionAddOptionalDataPressed) {
      yield _generateAddOptionalDataState(
        session: session,
        parentState: state,
        alreadyAddedOptionalDisconIndices: state.optionalChoices.keys,
      );
    } else if (state is DisclosurePermissionChoices && event is DisclosurePermissionRemoveOptionalDataPressed) {
      if (!state.optionalChoices.containsKey(event.disconIndex)) {
        throw Exception('Optional choice with index ${event.disconIndex} does not exist');
      }
      yield _refreshChoices(state, [state.optionalChoices[event.disconIndex]!], event.disconIndex, null);
    } else if (state is DisclosurePermissionChoicesOverview && event is DisclosurePermissionNextPressed) {
      if (!state.showConfirmationPopup) {
        yield DisclosurePermissionChoicesOverview(
          plannedSteps: state.plannedSteps,
          requiredChoices: state.requiredChoices,
          optionalChoices: state.optionalChoices,
          hasAdditionalOptionalChoices: state.hasAdditionalOptionalChoices,
          showConfirmationPopup: true,
        );
      } else {
        // Disclosure permission is finished. We have to dispatch the choices to the IrmaRepository.
        final disclosureChoices = [
          for (int i = 0; i < session.disclosuresCandidates!.length; i++)
            state.choices[i]
                    ?.expand((cred) => cred.attributes.map((attr) => AttributeIdentifier.fromAttribute(attr)))
                    .toList() ??
                []
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
    } else if (state is DisclosurePermissionChoicesOverview && event is DisclosurePermissionDialogDismissed) {
      yield DisclosurePermissionChoicesOverview(
        plannedSteps: state.plannedSteps,
        requiredChoices: state.requiredChoices,
        optionalChoices: state.optionalChoices,
        hasAdditionalOptionalChoices: state.hasAdditionalOptionalChoices,
      );
    } else {
      throw UnsupportedError(
          'Event ${event.runtimeType.toString()} not supported in state ${state.runtimeType.toString()}');
    }
  }

  DisclosurePermissionBlocState _mapSessionStateToBlocState(DisclosurePermissionBlocState state, SessionState session) {
    if (session.status != SessionStatus.requestDisclosurePermission) {
      if (state is! DisclosurePermissionInitial && state is! DisclosurePermissionFinished) {
        _repo.preferences.setCompletedDisclosurePermissionIntro(true);
        return DisclosurePermissionFinished();
      }
      return state;
    } else if (state is DisclosurePermissionIssueWizard) {
      final refreshedState = _refreshIssueWizard(state, session);
      // currentCon cannot be null when isCompleted is false.
      return refreshedState.isCompleted
          ? refreshedState
          : _validateCredentialsObtained(refreshedState.currentCon!, refreshedState);
    } else if (state is DisclosurePermissionObtainCredentials) {
      final refreshedState = _refreshObtainedCredentials(state, session);
      // In case only one credential had to be obtained, we immediately go back to the parent step.
      return refreshedState.allObtained
          ? refreshedState
          : _validateCredentialsObtained([refreshedState.currentIssueWizardItem!], refreshedState);
    } else if (state is DisclosurePermissionChangeChoice) {
      final discon = _refreshDisCon(state.disconIndex, state.discon, session);
      final selectedConIndex = _findSelectedConIndex(
        discon,
        prevDiscon: state.discon,
        prevChoice: state.selectedCon,
      );
      final refreshedState = DisclosurePermissionChangeChoice(
        parentState: _refreshChoices(state.parentState, discon, state.disconIndex, selectedConIndex),
        discon: discon,
        disconIndex: state.disconIndex,
        selectedConIndex: selectedConIndex,
      );
      return _validateCredentialsObtained(
        refreshedState.selectedCon.whereType<TemplateDisclosureCredential>(),
        refreshedState,
      );
    } else if (state is DisclosurePermissionAddOptionalData) {
      return _generateAddOptionalDataState(
        session: session,
        parentState: state.parentState,
        alreadyAddedOptionalDisconIndices: state.parentState.optionalChoices.keys,
        prevState: state,
      );
    } else if (state is DisclosurePermissionChoices) {
      // Usually, this session state change should not introduce any bloc state changes.
      // Session requests cannot change within a session and credentials cannot be deleted during the session,
      // so the current selection should still be present.
      return state;
    } else if (state is DisclosurePermissionWrongCredentialsObtained) {
      return DisclosurePermissionWrongCredentialsObtained(
        parentState: _mapSessionStateToBlocState(state.parentState, session),
        obtainedCredentials: state.obtainedCredentials,
        templates: state.templates,
      );
    } else {
      final candidates = Map.fromEntries(session.disclosuresCandidates!.mapIndexed(
        (i, rawDiscon) => MapEntry(i, _parseCandidatesDisCon(rawDiscon)),
      ));

      // Check whether an issue wizard is needed to bootstrap the session.
      final choices = candidates.map(
        (i, discon) => MapEntry(
          i,
          discon
              .firstWhereOrNull((con) => con.every((cred) => cred is ChoosableDisclosureCredential))
              ?.cast<ChoosableDisclosureCredential>(),
        ),
      );

      if (choices.values.every((choice) => choice != null)) {
        final nonNullChoices = choices.map((i, choice) => MapEntry(i, Con(choice!)));
        final requiredChoices = Map.fromEntries(
            nonNullChoices.entries.where((entry) => candidates[entry.key]!.every((con) => con.isNotEmpty)));
        final optionalChoices = Map.fromEntries(nonNullChoices.entries
            .where((entry) => entry.value.isNotEmpty && candidates[entry.key]!.any((con) => con.isEmpty)));
        return DisclosurePermissionChoicesOverview(
          plannedSteps: [DisclosurePermissionStepName.choicesOverview],
          requiredChoices: requiredChoices,
          optionalChoices: optionalChoices,
          hasAdditionalOptionalChoices: choices.keys.length > requiredChoices.length + optionalChoices.length,
          signedMessage: session.isSignatureSession ?? false ? session.signedMessage : null,
        );
      } else {
        // In an issue wizard, only the credential templates are relevant for which there is no choosable variant
        // in any other con within that discon. If an issue wizard is needed, we also include the optional discons
        // where no non-empty con is fully obtained yet. If no issue wizard is needed, then the optional discons
        // are presented in DisclosurePermissionChoicesOverview.
        final issueWizardCandidates = {
          for (final entry in candidates.entries)
            if (choices[entry.key] == null)
              entry.key: DisCon(
                entry.value.map((con) => Con(con.whereType<TemplateDisclosureCredential>())).where((con) => con.every(
                    (cred) => entry.value.flattened
                        .none((cred2) => cred2 is ChoosableDisclosureCredential && cred2.fullId == cred.fullId))),
              ),
        };
        final selectedConIndices = issueWizardCandidates.map((i, _) => MapEntry(i, 0));
        final obtained = issueWizardCandidates.map((i, _) => MapEntry(i, false));
        return DisclosurePermissionIssueWizard(
          plannedSteps: _calculatePlannedSteps(issueWizardCandidates, selectedConIndices, session),
          candidates: issueWizardCandidates,
          selectedConIndices: selectedConIndices,
          obtained: obtained,
        );
      }
    }
  }

  DisclosurePermissionIssueWizard _refreshIssueWizard(DisclosurePermissionIssueWizard prevState, SessionState session) {
    final candidates = prevState.candidates.map(
      (i, prevDiscon) => MapEntry(i, _refreshDisCon(i, prevDiscon, session)),
    );
    final obtained = prevState.candidates.map(
      (i, prevDiscon) => MapEntry(
        i,
        prevState.obtained[i]! ||
            candidates[i]!.any((con) => con.every((cred) => cred is ChoosableDisclosureCredential)),
      ),
    );
    final selectedConIndices = prevState.candidates.map(
      (i, discon) => MapEntry(
        i,
        obtained[i]!
            ? prevState.selectedConIndices[i]!
            : _findSelectedConIndex(
                discon,
                prevDiscon: prevState.currentDiscon?.value,
                prevChoice: prevState.getSelectedCon(i),
              ),
      ),
    );

    return DisclosurePermissionIssueWizard(
      plannedSteps: _calculatePlannedSteps(candidates, selectedConIndices, session),
      candidates: prevState.candidates,
      selectedConIndices: selectedConIndices,
      obtained: obtained,
    );
  }

  DisclosurePermissionBlocState _validateCredentialsObtained(
    Iterable<TemplateDisclosureCredential> templates,
    DisclosurePermissionBlocState parentState,
  ) {
    final credentials = _newlyAddedCredentialHashes
        .expand((hash) => _repo.credentials.containsKey(hash) ? [_repo.credentials[hash]!] : <Credential>[]);

    final List<TemplateDisclosureCredential> mismatchedTemplates = [];
    final List<ChoosableDisclosureCredential> obtainedCredentials = [];

    for (final template in templates) {
      // First we check whether we have an exact match.
      final matchingCred = credentials.firstWhereOrNull((cred) => template.matchesCredential(cred));
      if (matchingCred != null) {
        continue;
      }

      // If there is no exact match, then we look for credentials that were added in attempt to make a match.
      final templateWithoutValueConstraints = template.copyWithoutValueConstraints();
      final nonMatchingCred =
          credentials.firstWhereOrNull((cred) => templateWithoutValueConstraints.matchesCredential(cred));
      if (nonMatchingCred != null) {
        mismatchedTemplates.add(template);
        obtainedCredentials.add(ChoosableDisclosureCredential.fromTemplate(
          template: templateWithoutValueConstraints,
          credential: nonMatchingCred,
        ));
        // Remove credential hash from list to prevent this mismatch to be found later again.
        _newlyAddedCredentialHashes.remove(nonMatchingCred.hash);
      }
    }

    if (mismatchedTemplates.isNotEmpty) {
      return DisclosurePermissionWrongCredentialsObtained(
        parentState: parentState,
        templates: mismatchedTemplates,
        obtainedCredentials: obtainedCredentials,
      );
    }
    return parentState;
  }

  DisclosurePermissionObtainCredentials _refreshObtainedCredentials(
    DisclosurePermissionObtainCredentials prevState,
    SessionState session,
  ) {
    // Reverse list to make sure newest credentials are considered first.
    final newlyAddedCredentials = _newlyAddedCredentialHashes.reversed
        .expand((hash) => _repo.credentials.containsKey(hash) ? [_repo.credentials[hash]!] : <Credential>[]);

    final obtained = prevState.templates
        .map((template) => newlyAddedCredentials.any((cred) => template.matchesCredential(cred)))
        .toList();

    return DisclosurePermissionObtainCredentials(
      parentState: _mapSessionStateToBlocState(prevState.parentState, session),
      templates: prevState.templates,
      obtained: obtained,
    );
  }

  DisCon<DisclosureCredential> _refreshDisCon(
    int prevDisconIndex,
    DisCon<DisclosureCredential> prevDiscon,
    SessionState session,
  ) {
    final discon = _parseCandidatesDisCon(session.disclosuresCandidates![prevDisconIndex]);
    final includedCredTypeIds = prevDiscon.expand((con) => con.map((cred) => cred.fullId)).toSet();
    return DisCon(
      discon.fold([], (prev, con) {
        if (con.isEmpty || con.any((cred) => includedCredTypeIds.contains(cred.fullId))) {
          final filteredCon = Con(con.where((cred) => includedCredTypeIds.contains(cred.fullId)));
          // Make sure we don't add duplicate cons.
          if (!prev.contains(filteredCon)) return [...prev, filteredCon];
        }
        return prev;
      }),
    );
  }

  DisclosurePermissionChoices _refreshChoices(
    DisclosurePermissionChoices prevState,
    List<Con<DisclosureCredential>> discon,
    int disconIndex,
    int? selectedConIndex,
  ) {
    // The state machine should make sure the selected con only contains ChoosableDisclosureCredentials in this state.
    final requiredChoices = selectedConIndex != null
        ? prevState.requiredChoices.map((i, con) =>
            MapEntry(i, i == disconIndex ? Con(discon[selectedConIndex].cast<ChoosableDisclosureCredential>()) : con))
        : Map.of(prevState.requiredChoices);
    final optionalChoices = selectedConIndex != null
        ? prevState.optionalChoices.map((i, con) =>
            MapEntry(i, i == disconIndex ? Con(discon[selectedConIndex].cast<ChoosableDisclosureCredential>()) : con))
        : Map.of(prevState.optionalChoices);

    // Add or remove optional choices if necessary.
    if (selectedConIndex == null) {
      optionalChoices.remove(disconIndex);
    } else if (!requiredChoices.containsKey(disconIndex) && !optionalChoices.containsKey(disconIndex)) {
      optionalChoices.putIfAbsent(
        disconIndex,
        () => Con(discon[selectedConIndex].cast<ChoosableDisclosureCredential>()),
      );
    }

    if (prevState is DisclosurePermissionPreviouslyAddedCredentialsOverview) {
      return DisclosurePermissionPreviouslyAddedCredentialsOverview(
        plannedSteps: prevState.plannedSteps,
        requiredChoices: requiredChoices,
        optionalChoices: optionalChoices,
        hasAdditionalOptionalChoices: prevState.hasAdditionalOptionalChoices,
      );
    } else if (prevState is DisclosurePermissionChoicesOverview) {
      return DisclosurePermissionChoicesOverview(
        plannedSteps: prevState.plannedSteps,
        requiredChoices: requiredChoices,
        optionalChoices: optionalChoices,
        hasAdditionalOptionalChoices: prevState.hasAdditionalOptionalChoices,
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
    DisCon<DisclosureCredential>? prevDiscon,
    Con<DisclosureCredential>? prevChoice,
  }) {
    // If a new choosable option has been added, then we select the new option.
    if (prevDiscon != null) {
      final recentlyAddedCredentialHashes = _newlyAddedCredentialHashes.reversed.where((hash) =>
          prevDiscon.flattened.whereType<ChoosableDisclosureCredential>().none((cred) => cred.credentialHash == hash));
      final choice = discon.indexWhere((con) => con.any((cred) =>
          cred is ChoosableDisclosureCredential &&
          recentlyAddedCredentialHashes.any((hash) => cred.credentialHash == hash)));
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

  List<DisclosurePermissionStepName> _calculatePlannedSteps(
    Map<int, DisCon<DisclosureCredential>> candidates,
    Map<int, int> selectedConIndices,
    SessionState session,
  ) {
    final hasPrevAddedCreds = session.disclosuresCandidates!.length > candidates.length ||
        candidates.entries.any((disconEntry) =>
            session.disclosuresCandidates![disconEntry.key][selectedConIndices[disconEntry.key]!].any((candidate) =>
                candidate.credentialHash.isNotEmpty &&
                !_newlyAddedCredentialHashes.contains(candidate.credentialHash)));
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

  DisclosurePermissionAddOptionalData _generateAddOptionalDataState({
    required SessionState session,
    required DisclosurePermissionChoices parentState,
    required Iterable<int> alreadyAddedOptionalDisconIndices,
    DisclosurePermissionAddOptionalData? prevState,
  }) {
    final List<Con<DisclosureCredential>> addableCons = [];
    final List<int> addableConsDisconIndices = [];

    for (int i = 0; i < session.disclosuresCandidates!.length; i++) {
      if (!session.disclosuresCandidates![i].any((con) => con.isEmpty)) continue;
      if (alreadyAddedOptionalDisconIndices.contains(i)) continue;
      final addable = _parseCandidatesDisCon(session.disclosuresCandidates![i]).where((con) => con.isNotEmpty);

      addableCons.addAll(addable);
      addableConsDisconIndices.addAll(List.filled(addable.length, i));
    }

    if (addableCons.isEmpty) throw Exception('No optional data left to add');

    return DisclosurePermissionAddOptionalData(
      parentState: parentState,
      discon: DisCon(addableCons),
      disconIndices: addableConsDisconIndices,
      selectedConIndex: _findSelectedConIndex(
        DisCon(addableCons),
        prevDiscon: prevState?.discon,
        prevChoice: prevState?.selectedCon,
      ),
    );
  }

  Stream<DisclosurePermissionBlocState> _obtainCredentials(
    DisclosurePermissionBlocState parentState,
    Con<DisclosureCredential> selectedCon,
  ) async* {
    final selectedConTemplates = selectedCon.whereType<TemplateDisclosureCredential>().toList();
    assert(selectedConTemplates.isNotEmpty);
    // If only one credential is involved, we can open the issue url immediately.
    if (selectedConTemplates.length == 1) {
      onObtainCredential(selectedConTemplates.first.credentialType);
    } else {
      yield DisclosurePermissionObtainCredentials(
        parentState: parentState,
        templates: selectedConTemplates,
      );
    }
  }
}
