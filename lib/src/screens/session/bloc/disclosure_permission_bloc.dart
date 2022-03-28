import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/session/bloc/disclosure_permission_event.dart';
import 'package:irmamobile/src/screens/session/bloc/disclosure_permission_state.dart';
import 'package:irmamobile/src/screens/session/models/disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/models/disclosure_credential_template.dart';
import 'package:rxdart/rxdart.dart';

import '../../../models/attributes.dart';
import '../models/abstract_disclosure_credential.dart';

class DisclosurePermissionBloc extends Bloc<DisclosurePermissionBlocEvent, DisclosurePermissionBlocState> {
  final int sessionID;

  final IrmaRepository _repo; // Hide repository, because this bloc shadows all the repository's functionality.

  late StreamSubscription _sessionStateSubscription;

  final _currentChoiceStateSubject = BehaviorSubject<DisclosurePermissionChoiceState>();

  // TODO: Determine initial state async?
  DisclosurePermissionBloc({
    required this.sessionID,
    required IrmaRepository repo,
  })  : _repo = repo,
        super(WaitingForSessionState()) {
    _sessionStateSubscription = repo.getSessionState(sessionID).asyncExpand(_mapSessionStateToBlocState).listen(emit);
    stream.whereType<DisclosurePermissionChoiceState>().pipe(_currentChoiceStateSubject);
  }

  @override
  Future<void> close() async {
    await _sessionStateSubscription.cancel();
    super.close();
  }

  @override
  Stream<DisclosurePermissionBlocState> mapEventToState(DisclosurePermissionBlocEvent event) async* {
    final state = this.state; // To prevent the need for type casting.
    final session = _repo.getCurrentSessionState(sessionID)!;
    if (state is DisclosurePermissionIssueWizardChoiceState && event is IssueWizardChoiceEvent) {
      yield DisclosurePermissionIssueWizardChoiceState(
        issueWizardChoices: state.issueWizardChoices,
        issueWizardChoiceIndices: state.issueWizardChoiceIndices
            .mapIndexed((i, choiceIndex) => i == event.stepIndex ? event.choiceIndex : choiceIndex)
            .toList(),
      );
    } else if (state is DisclosurePermissionIssueWizardChoiceState && event is GoToNextStateEvent) {
      // We have to insert again the credential templates that contain no choice.
      final otherWizardCandidates = _parseDisclosureCandidates(session.disclosuresCandidates!)
          .where((discon) => discon.length == 1)
          .map((discon) => discon[0].whereType<DisclosureCredentialTemplate>())
          .flattened;
      yield DisclosurePermissionIssueWizardState(
        issueWizard: _foldIssueWizardItems([
          ...state.issueWizardChoices.mapIndexed((i, discon) => discon[state.issueWizardChoiceIndices[i]]).flattened,
          ...otherWizardCandidates,
        ]),
      );
    } else if (state is DisclosurePermissionIssueWizardState && event is GoToNextStateEvent) {
      if (!state.completed) throw Exception('Issue wizard is not completed yet');
      yield DisclosurePermissionChoiceState(
        choices: _parseDisclosureCandidates(_repo.getCurrentSessionState(sessionID)!.disclosuresCandidates!),
      );
    } else if (state is DisclosurePermissionChoiceState && event is DisclosureSelectStepEvent) {
      yield DisclosurePermissionChoiceState(
        choices: state.choices,
        choiceIndices: state.choiceIndices,
        selectedStepIndex: event.stepIndex,
      );
    } else if (state is DisclosurePermissionChoiceState && event is DisclosureUpdateChoiceEvent) {
      if (state.choices[event.stepIndex][event.choiceIndex].any((cred) => cred is DisclosureCredentialTemplate)) {
        throw Exception('Cannot choose a template option');
      }
      // TODO: race condition in the state?
      yield DisclosurePermissionChoiceState(
        selectedStepIndex: state.selectedStepIndex,
        choices: state.choices,
        choiceIndices: state.choiceIndices
            .mapIndexed((i, choiceIndex) => i == event.stepIndex ? event.choiceIndex : choiceIndex)
            .toList(),
      );
      _repo.dispatch(
        DisclosureChoiceUpdateSessionEvent(
          sessionID: sessionID,
          disconIndex: event.stepIndex,
          conIndex: event.choiceIndex,
        ),
        isBridgedEvent: true,
      );
    } else if (state is DisclosurePermissionChoiceState && event is GoToNextStateEvent) {
      yield DisclosurePermissionConfirmState(
        currentSelection: state.currentSelection.flattened.toList(),
      );
    } else if (state is DisclosurePermissionConfirmState && event is GoToNextStateEvent) {
      if (session.isIssuanceSession) {
        _repo.dispatch(
          ContinueToIssuanceEvent(sessionID: sessionID),
          isBridgedEvent: true,
        );
      } else {
        _repo.dispatch(
          RespondPermissionEvent(
            sessionID: sessionID,
            proceed: true,
            disclosureChoices:
                _repo.getCurrentSessionState(sessionID)!.disclosureChoices!, // TODO: Check whether this works.
          ),
          isBridgedEvent: true,
        );
      }
    } else if (state is DisclosurePermissionConfirmState && event is DisclosureChangeChoicesEvent) {
      // TODO: Sync disclosureChoices and DisclosurePermissionChoiceState.
      yield _currentChoiceStateSubject.value;
    } else {
      throw Exception('Event ${event.runtimeType.toString()} not supported in state ${state.runtimeType.toString()}');
    }
  }

  Stream<DisclosurePermissionBlocState> _mapSessionStateToBlocState(SessionState session) async* {
    final state = this.state;
    if (session.status != SessionStatus.requestDisclosurePermission) {
      // TODO: Shouldn't we indicate a permission has been finished?
      return;
    } else if (state is DisclosurePermissionIssueWizardState) {
      final credentials = _repo.getCurrentCredentials().values;
      yield DisclosurePermissionIssueWizardState(
        issueWizard: state.issueWizard.map((template) => template.refresh(credentials)).toList(),
      );
    } else {
      final parsedCandidates = _parseDisclosureCandidates(session.disclosuresCandidates!);
      if (state is DisclosurePermissionChoiceState) {
        yield DisclosurePermissionChoiceState(
          choices: parsedCandidates,
          choiceIndices: state.choiceIndices, // TODO: Check whether this works.
        );
      } else {
        // Check whether an issue wizard is needed to bootstrap the session.
        final issueWizardCandidates = parsedCandidates
            .where((discon) => discon.every((con) => con.any((cred) => cred is DisclosureCredentialTemplate)));
        if (issueWizardCandidates.isEmpty) {
          yield DisclosurePermissionChoiceState(
            choices: parsedCandidates,
          );
        } else {
          // In an issue wizard, only the credential templates are relevant.
          final filteredIssueWizardCandidates = ConDisCon(issueWizardCandidates
              .map((discon) => DisCon(discon.map((con) => Con(con.whereType<DisclosureCredentialTemplate>())))));
          if (issueWizardCandidates.every((discon) => discon.length == 1)) {
            yield DisclosurePermissionIssueWizardState(
              issueWizard: _foldIssueWizardItems(filteredIssueWizardCandidates.flattened.flattened),
            );
          } else {
            // Only include the discons in which a choice must be made.
            yield DisclosurePermissionIssueWizardChoiceState(
              issueWizardChoices: ConDisCon(filteredIssueWizardCandidates.where((discon) => discon.length > 1)),
            );
          }
        }
      }
    }
  }

  ConDisCon<AbstractDisclosureCredential> _parseDisclosureCandidates(ConDisCon<Attribute> candidates) =>
      ConDisCon(candidates.map((discon) => DisCon(discon.map((con) {
            final groupedCon = groupBy(con, (Attribute attr) => attr.credentialInfo.fullId);
            return Con(groupedCon.entries.map((entry) {
              final credentialAttributes = entry.value;
              if (credentialAttributes.first.choosable) {
                return DisclosureCredential(attributes: credentialAttributes);
              } else {
                return DisclosureCredentialTemplate(
                  attributes: credentialAttributes,
                  credentials: _repo.getCurrentCredentials().values,
                );
              }
            }));
          }))));

  /// Folds the issue wizard by merging non-contradicting credential templates.
  List<DisclosureCredentialTemplate> _foldIssueWizardItems(Iterable<DisclosureCredentialTemplate> unfolded) {
    final List<DisclosureCredentialTemplate> folded = [];
    for (final template in unfolded) {
      bool merged = false;
      for (int i = 0; i < folded.length; i++) {
        final mergedItem = folded[i].merge(template);
        if (mergedItem != null) {
          folded[i] = mergedItem;
          merged = true;
          break;
        }
      }
      if (!merged) folded.add(template);
    }
    return folded;
  }
}
