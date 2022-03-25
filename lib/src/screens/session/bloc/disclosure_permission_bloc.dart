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
import 'package:quiver/iterables.dart';
import 'package:rxdart/rxdart.dart';

import '../../../models/attributes.dart';
import '../models/abstract_disclosure_credential.dart';

class DisclosurePermissionBloc extends Bloc<DisclosurePermissionBlocEvent, DisclosurePermissionBlocState> {
  final int sessionID;
  final IrmaRepository repo;

  late StreamSubscription _sessionStateSubscription;

  final _currentChoiceStateSubject = BehaviorSubject<DisclosurePermissionChoiceState>();

  // TODO: Determine initial state async?
  DisclosurePermissionBloc({
    required this.sessionID,
    required this.repo,
  })  : assert(repo.getCurrentSessionState(sessionID)?.status == SessionStatus.requestDisclosurePermission),
        super(_determineInitialState(repo, sessionID)) {
    _sessionStateSubscription = repo.getSessionState(sessionID).asyncExpand(_mapSessionStateToBlocState).listen(emit);
    stream.whereType<DisclosurePermissionChoiceState>().pipe(_currentChoiceStateSubject);
  }

  @override
  Future<void> close() async {
    await _sessionStateSubscription.cancel();
    super.close();
  }

  static DisclosurePermissionBlocState _determineInitialState(IrmaRepository repo, int sessionID) {
    // Due to assertion in constructor we can safely use the null assertion operator here.
    final session = repo.getCurrentSessionState(sessionID)!;
    final parsedCandidates = _parseDisclosureCandidates(repo, session.disclosuresCandidates!);
    final issueWizardCandidates = parsedCandidates
        .where((discon) => discon.every((con) => con.any((cred) => cred is DisclosureCredentialTemplate)));
    if (issueWizardCandidates.isEmpty) {
      return DisclosurePermissionChoiceState(
        choices: parsedCandidates,
      );
    }
    // In an issue wizard, only the credential templates are relevant.
    final filteredIssueWizardCandidates = ConDisCon(issueWizardCandidates
        .map((discon) => DisCon(discon.map((con) => Con(con.whereType<DisclosureCredentialTemplate>())))));
    if (issueWizardCandidates.every((discon) => discon.length == 1)) {
      return DisclosurePermissionIssueWizardState(
        issueWizard: filteredIssueWizardCandidates.flattened.flattened.toList(),
      );
    } else {
      return DisclosurePermissionIssueWizardChoiceState(
        issueWizardChoices: filteredIssueWizardCandidates,
      );
    }
  }

  @override
  Stream<DisclosurePermissionBlocState> mapEventToState(DisclosurePermissionBlocEvent event) async* {
    final state = this.state; // To prevent the need for type casting.
    if (state is DisclosurePermissionIssueWizardChoiceState && event is IssueWizardChoiceEvent) {
      yield DisclosurePermissionIssueWizardChoiceState(
        issueWizardChoices: state.issueWizardChoices,
        issueWizardChoiceIndices: state.issueWizardChoiceIndices
            .mapIndexed((i, choiceIndex) => i == event.stepIndex ? event.choiceIndex : choiceIndex)
            .toList(),
      );
    } else if (state is DisclosurePermissionIssueWizardChoiceState && event is GoToNextStateEvent) {
      yield DisclosurePermissionIssueWizardState(
        issueWizard: state.issueWizardChoices
            .mapIndexed((i, discon) => discon[state.issueWizardChoiceIndices[i]])
            .flattened
            .toList(),
      );
    } else if (state is DisclosurePermissionIssueWizardState && event is GoToNextStateEvent) {
      yield DisclosurePermissionChoiceState(
        choices: _parseDisclosureCandidates(repo, repo.getCurrentSessionState(sessionID)!.disclosuresCandidates!),
      );
    } else if (state is DisclosurePermissionChoiceState && event is DisclosureViewAllChoicesEvent) {
      yield DisclosurePermissionChoiceState(
        choices: state.choices,
        choiceIndices: state.choiceIndices,
        selectedStepIndex: event.stepIndex,
      );
    } else if (state is DisclosurePermissionChoiceState && event is DisclosureUpdateChoiceEvent) {
      // TODO: throw exception if an template is chosen, or remove templates from choices.
      yield DisclosurePermissionChoiceState(
        selectedStepIndex: state.selectedStepIndex,
        choices: state.choices,
        choiceIndices: state.choiceIndices
            .mapIndexed((i, choiceIndex) => i == event.stepIndex ? event.choiceIndex : choiceIndex)
            .toList(),
      );
      repo.dispatch(
        DisclosureChoiceUpdateSessionEvent(
          sessionID: sessionID,
          disconIndex: event.stepIndex,
          conIndex: event.choiceIndex,
        ),
        isBridgedEvent: true,
      );
    } else if (state is DisclosurePermissionChoiceState && event is DisclosureConfirmChoiceEvent) {
      // selectedStepIndex should be set to null again.
      yield DisclosurePermissionChoiceState(
        choices: state.choices,
        choiceIndices: state.choiceIndices,
      );
    } else if (state is DisclosurePermissionChoiceState && event is GoToNextStateEvent) {
      yield DisclosurePermissionConfirmState(
        currentSelection: state.currentSelection.flattened.toList(),
      );
    } else if (state is DisclosurePermissionConfirmState && event is GoToNextStateEvent) {
      repo.dispatch(
        RespondPermissionEvent(
          sessionID: sessionID,
          proceed: true,
          disclosureChoices:
              repo.getCurrentSessionState(sessionID)!.disclosureChoices!, // TODO: Check whether this works.
        ),
        isBridgedEvent: true,
      );
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
      return;
    }

    final parsedCandidates = _parseDisclosureCandidates(repo, session.disclosuresCandidates!);
    if (state is DisclosurePermissionIssueWizardState) {
      yield DisclosurePermissionIssueWizardState(
        issueWizard: state.issueWizard.map((template) => _refreshCredentialTemplate(repo, template)).toList(),
      );
    } else if (state is DisclosurePermissionChoiceState) {
      yield DisclosurePermissionChoiceState(
        choices: parsedCandidates,
        choiceIndices: state.choiceIndices, // TODO: Check whether this works.
      );
    } else {
      // If the session state changes in another bloc state than expected, we have to restart from the beginning
      // to make sure we don't skip a stage. This should normally not happen.
      yield _determineInitialState(repo, sessionID);
    }
  }

  static ConDisCon<AbstractDisclosureCredential> _parseDisclosureCandidates(
          IrmaRepository repo, ConDisCon<Attribute> candidates) =>
      ConDisCon(candidates.map((discon) => DisCon(discon.map((con) {
            final groupedCon = groupBy(con, (Attribute attr) => attr.credentialInfo.fullId);
            return Con(groupedCon.entries.map((entry) {
              final credentialAttributes = entry.value;
              if (credentialAttributes.first.choosable) {
                return DisclosureCredential(attributes: credentialAttributes);
              } else {
                return _refreshCredentialTemplate(
                  repo,
                  DisclosureCredentialTemplate(
                    attributes: credentialAttributes,
                  ),
                );
              }
            }));
          }))));

  static DisclosureCredentialTemplate _refreshCredentialTemplate(
      IrmaRepository repo, DisclosureCredentialTemplate template) {
    final presentCreds = repo.getCurrentCredentials().values.where((cred) => cred.info.fullId == template.fullId);
    final Map<bool, List<DisclosureCredential>> mapped = groupBy(
        // Only include the attributes that are included in the template.
        presentCreds.map((cred) => DisclosureCredential(
            attributes: cred.attributeList
                .where((attr1) =>
                    template.attributes.any((attr2) => attr1.attributeType.fullId == attr2.attributeType.fullId))
                .toList())),
        // Group based on whether the credentials match the template or not.
        // The attribute lists have an equal length and order due to the filtering above and guarantees from irmago.
        (cred) => zip([template.attributes, cred.attributes])
            .every((entry) => entry[0].value.raw == null || entry[0].value.raw == entry[1].value.raw));
    return DisclosureCredentialTemplate(
      attributes: template.attributes,
      presentMatching: mapped[true] ?? [],
      presentNonMatching: mapped[false] ?? [],
    );
  }
}
