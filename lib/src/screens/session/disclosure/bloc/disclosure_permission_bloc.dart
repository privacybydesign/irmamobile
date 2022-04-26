import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/session/disclosure/bloc/disclosure_permission_event.dart';
import 'package:irmamobile/src/screens/session/disclosure/bloc/disclosure_permission_state.dart';
import 'package:irmamobile/src/screens/session/models/choosable_disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/models/disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/models/template_disclosure_credential.dart';

class DisclosurePermissionBloc extends Bloc<DisclosurePermissionBlocEvent, DisclosurePermissionBlocState> {
  final int sessionID;

  final IrmaRepository _repo; // Repository is hidden by design, because behaviour should be triggered via bloc events.

  late final StreamSubscription _sessionStateSubscription;

  DisclosurePermissionBloc({
    required this.sessionID,
    required IrmaRepository repo,
  })  : _repo = repo,
        super(DisclosurePermissionInitial()) {
    _sessionStateSubscription = repo.getSessionState(sessionID).asyncExpand(_mapSessionStateToBlocState).listen(emit);
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
    if (state is DisclosurePermissionIssueWizardChoices && event is DisclosurePermissionIssueWizardChoiceUpdated) {
      yield DisclosurePermissionIssueWizardChoices(
        issueWizardChoices: state.issueWizardChoices,
        issueWizardChoiceIndices: state.issueWizardChoiceIndices
            .mapIndexed((i, choiceIndex) => i == event.stepIndex ? event.choiceIndex : choiceIndex)
            .toList(),
      );
    } else if (state is DisclosurePermissionIssueWizardChoices && event is DisclosurePermissionNextPressed) {
      // We have to insert again the credential templates that contain no choice.
      final otherWizardCandidates = _parseDisclosureCandidates(session.disclosuresCandidates!)
          .where((discon) => discon.length == 1)
          .map((discon) => discon[0].whereType<TemplateDisclosureCredential>())
          .flattened;
      yield DisclosurePermissionIssueWizard(
        issueWizard: _foldIssueWizardItems([
          ...state.issueWizardChoices.mapIndexed((i, discon) => discon[state.issueWizardChoiceIndices[i]]).flattened,
          ...otherWizardCandidates,
        ]),
      );
    } else if (state is DisclosurePermissionIssueWizard && event is DisclosurePermissionNextPressed ||
        state is DisclosurePermissionConfirmChoices && event is DisclosurePermissionEditCurrentSelectionPressed) {
      if (state is DisclosurePermissionIssueWizard && !state.completed) {
        throw Exception('Issue wizard is not completed yet');
      }
      yield DisclosurePermissionChoices(
        choices: _parseDisclosureCandidates(session.disclosuresCandidates!),
        choiceIndices: session.disclosureIndices,
      );
    } else if (state is DisclosurePermissionChoices && event is DisclosurePermissionStepSelected) {
      yield DisclosurePermissionChoices(
        choices: state.choices,
        choiceIndices: state.choiceIndices,
        selectedStepIndex: event.stepIndex,
      );
    } else if (state is DisclosurePermissionChoices && event is DisclosurePermissionChoiceUpdated) {
      if (state.choices[event.stepIndex][event.choiceIndex].any((cred) => cred is TemplateDisclosureCredential)) {
        throw Exception('Cannot choose a template option');
      }
      _repo.dispatch(
        DisclosureChoiceUpdateSessionEvent(
          sessionID: sessionID,
          disconIndex: event.stepIndex,
          conIndex: event.choiceIndex,
        ),
        isBridgedEvent: true,
      );
    } else if (state is DisclosurePermissionChoices && event is DisclosurePermissionNextPressed) {
      yield DisclosurePermissionConfirmChoices(
        currentSelection: state.currentSelection,
        signedMessage: session.signedMessage,
      );
    } else if (state is DisclosurePermissionConfirmChoices && event is DisclosurePermissionNextPressed) {
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
            disclosureChoices: session.disclosureChoices!,
          ),
          isBridgedEvent: true,
        );
      }
    } else {
      throw Exception('Event ${event.runtimeType.toString()} not supported in state ${state.runtimeType.toString()}');
    }
  }

  Stream<DisclosurePermissionBlocState> _mapSessionStateToBlocState(SessionState session) async* {
    final state = this.state;
    if (session.status != SessionStatus.requestDisclosurePermission) {
      if (state is! DisclosurePermissionInitial && state is! DisclosurePermissionFinished) {
        yield DisclosurePermissionFinished();
      }
      return;
    } else if (state is DisclosurePermissionIssueWizard) {
      final credentials = _repo.credentials.values;
      final issueWizard = state.issueWizard.map((template) => template.copyWith(credentials: credentials)).toList();
      final nonMatchingCredentials = issueWizard.expand((cred) => cred.presentNonMatching).toList();
      
      yield DisclosurePermissionIssueWizard(
        issueWizard: issueWizard,
        lastNonMatchingCredential: nonMatchingCredentials.isNotEmpty ? nonMatchingCredentials.last : null,
      );
    } else {
      final parsedCandidates = _parseDisclosureCandidates(session.disclosuresCandidates!);
      if (state is DisclosurePermissionChoices) {
        yield DisclosurePermissionChoices(
          choices: parsedCandidates,
          choiceIndices: session.disclosureIndices,
        );
      } else {
        // Check whether an issue wizard is needed to bootstrap the session.
        final issueWizardCandidates = parsedCandidates
            .where((discon) => discon.every((con) => con.any((cred) => cred is TemplateDisclosureCredential)));
        if (issueWizardCandidates.isEmpty) {
          yield DisclosurePermissionChoices(
            choices: parsedCandidates,
          );
        } else {
          // In an issue wizard, only the credential templates are relevant.
          final filteredIssueWizardCandidates = ConDisCon(issueWizardCandidates
              .map((discon) => DisCon(discon.map((con) => Con(con.whereType<TemplateDisclosureCredential>())))));
          if (issueWizardCandidates.every((discon) => discon.length == 1)) {
            yield DisclosurePermissionIssueWizard(
              issueWizard: _foldIssueWizardItems(filteredIssueWizardCandidates.flattened.flattened),
            );
          } else {
            // Only include the discons in which a choice must be made.
            yield DisclosurePermissionIssueWizardChoices(
              issueWizardChoices: ConDisCon(filteredIssueWizardCandidates.where((discon) => discon.length > 1)),
            );
          }
        }
      }
    }
  }

  ConDisCon<DisclosureCredential> _parseDisclosureCandidates(ConDisCon<Attribute> candidates) =>
      ConDisCon(candidates.map((discon) => DisCon(discon.map((con) {
            final groupedCon = groupBy(con, (Attribute attr) => attr.credentialInfo.fullId);
            return Con(groupedCon.entries.map((entry) {
              final credentialAttributes = entry.value;
              if (credentialAttributes.first.choosable) {
                return ChoosableDisclosureCredential(attributes: credentialAttributes);
              } else {
                return TemplateDisclosureCredential(
                  attributes: credentialAttributes,
                  credentials: _repo.credentials.values,
                );
              }
            }));
          }))));

  /// Folds the issue wizard by merging non-contradicting template credentials.
  List<TemplateDisclosureCredential> _foldIssueWizardItems(Iterable<TemplateDisclosureCredential> unfolded) {
    final List<TemplateDisclosureCredential> folded = [];
    for (final template in unfolded) {
      bool merged = false;
      for (int i = 0; i < folded.length; i++) {
        final mergedItem = folded[i].copyAndMerge(template);
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
