import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/disclosure_credential.dart';
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
import '../models/disclosure_con.dart';
import '../models/disclosure_con_dis_con.dart';
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
 *    |      | NextPressed       |__^ ChoiceUpdated                (c)  ----------------         NextPressed (h)
 *    |      |------------------------------------------------------>  | SubIssueWizard | <---------------
 *    |      |                                                          ----------------                  |
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
 * c). if the issue wizard is not completed yet. A sub issue wizard is started for the first incompleted discon.
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
  final Locale? locale;

  final IrmaRepository _repo; // Repository is hidden by design, because behaviour should be triggered via bloc events.

  late final StreamSubscription _sessionStateSubscription;
  late final StreamSubscription _sessionEventSubscription;

  final List<String> _newlyAddedCredentialHashes;

  DisclosurePermissionBloc({
    required this.sessionID,
    required this.locale,
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
      final updatedCondiscon = DisclosureConDisCon(
        state.condiscon
            .map(
              (discon) => discon.disconIndex == state.currentDisconIndex
                  ? discon.copyWith(selectedConIndex: event.conIndex)
                  : discon,
            )
            .toList(),
      );
      // When an option is changed, the list of previous added credentials that are involved in this session
      // may have changed too. Therefore, we have to recalculate the planned steps.
      yield DisclosurePermissionIssueWizard(
        plannedSteps: _calculatePlannedSteps(updatedCondiscon),
        condiscon: updatedCondiscon,
      );
    } else if (state is DisclosurePermissionIssueWizard && event is DisclosurePermissionNextPressed) {
      if (state.isCompleted) {
        // Wizard is completed, so now we show the previously added credentials that are involved in this session.
        final condiscon = _parseDisclosureCandidates(session.disclosuresCandidates!);
        final prevAddedDiscons = condiscon.map((discon) {
          for (final wizardDiscon in state.condiscon) {
            // In case we already handled this discon in the issue wizard, then we only show previously present data
            // for the condiscon that also contain the newly obtained credentials from the issue wizard.
            if (wizardDiscon.disconIndex == discon.disconIndex) {
              final prevAddedDiscons = DisclosureDisCon(
                discon: wizardDiscon
                    .expand((wizardCon) => wizardCon.conIndices.map((i) {
                          final con = discon[i];
                          if (con == null) return null;
                          // Filter out all credentials that were obtained during the issue wizard.
                          final filteredCon =
                              con.where((cred) => wizardCon.any((wizardCred) => wizardCred.fullId == cred.fullId));
                          return filteredCon.isNotEmpty
                              ? DisclosureCon(con: Con(filteredCon), conIndices: con.conIndices)
                              : null;
                        }).whereNotNull())
                    .toList(),
                disconIndex: discon.disconIndex,
              );
              return prevAddedDiscons.isNotEmpty ? prevAddedDiscons : null;
            }
          }
          return discon;
        }).whereNotNull();
        if (prevAddedDiscons.isEmpty) {
          // No previously added credentials are involved in this session, so we immediately continue to the overview.
          yield DisclosurePermissionChoicesOverview(
            plannedSteps: state.plannedSteps,
            condiscon: condiscon,
            signedMessage: session.isSignatureSession ?? false ? session.signedMessage : null,
          );
        } else {
          yield DisclosurePermissionPreviouslyAddedCredentialsOverview(
            plannedSteps: state.plannedSteps,
            condiscon: DisclosureConDisCon(prevAddedDiscons.toList()),
          );
        }
      } else {
        // If only one credential is involved, we can open the issue url immediately.
        if (state.currentDiscon!.selectedCon.length == 1) {
          _repo.openIssueURL(locale, state.currentDiscon!.selectedCon.first.credentialType.fullId);
        }
        yield DisclosurePermissionSubIssueWizard(
          parentState: state,
          issueWizard: state.currentDiscon!.selectedCon.whereType<TemplateDisclosureCredential>().toList(),
        );
      }
    } else if (state is DisclosurePermissionSubIssueWizard && event is DisclosurePermissionNextPressed) {
      if (state.allObtainedCredentialsMatch) {
        final parentState = state.parentState; // To prevent the need for type casting.
        if (parentState is DisclosurePermissionPreviouslyAddedCredentialsOverview) {
          yield DisclosurePermissionPreviouslyAddedCredentialsOverview(
            plannedSteps: parentState.plannedSteps,
            condiscon: _parseDisclosureCandidates(
              session.disclosuresCandidates!,
              onlyInclude: parentState.condiscon.includedCredentialTypes,
            ),
          );
        } else if (parentState is DisclosurePermissionChoicesOverview) {
          yield DisclosurePermissionChoicesOverview(
            plannedSteps: parentState.plannedSteps,
            condiscon: _parseDisclosureCandidates(session.disclosuresCandidates!),
          );
        } else {
          throw Exception('DisclosurePermissionSubIssueWizard has unexpected parent: ${state.parentState.runtimeType}');
        }
      } else {
        _repo.openIssueURL(locale, state.currentIssueWizardItem!.fullId);
      }
    } else if (state is DisclosurePermissionPreviouslyAddedCredentialsOverview &&
        event is DisclosurePermissionNextPressed) {
      yield DisclosurePermissionChoicesOverview(
        plannedSteps: state.plannedSteps,
        condiscon: _parseDisclosureCandidates(session.disclosuresCandidates!),
      );
    } else if (state is DisclosurePermissionStep && event is DisclosurePermissionChangeChoicePressed) {
      if (state is DisclosurePermissionIssueWizard) {
        throw UnsupportedError('No separate state exists for changing choices during issue wizards');
      }
      final discon = state.condiscon[event.disconIndex];
      if (discon == null) {
        throw Exception('DisclosureDisCon with index ${event.disconIndex} does not exist');
      }
      yield DisclosurePermissionChangeChoice(parentState: state, discon: discon);
    } else if (state is DisclosurePermissionChangeChoice && event is DisclosurePermissionChoiceUpdated) {
      final con = state.discon[(event.conIndex)];
      if (con == null) throw Exception('Con with index ${event.conIndex} does not exist');
      if (con.needsToBeObtained) throw Exception('Cannot choose a template con');

      final parentState = state.parentState; // To prevent the need for type casting.
      late final DisclosurePermissionStep updatedParentState;
      if (parentState is DisclosurePermissionPreviouslyAddedCredentialsOverview) {
        updatedParentState = DisclosurePermissionPreviouslyAddedCredentialsOverview(
          plannedSteps: parentState.plannedSteps,
          condiscon: DisclosureConDisCon(
            parentState.condiscon
                .map((discon) => discon.disconIndex == state.discon.disconIndex ? state.discon : discon)
                .toList(),
          ),
        );
      } else if (parentState is DisclosurePermissionChoicesOverview) {
        updatedParentState = DisclosurePermissionChoicesOverview(
          plannedSteps: parentState.plannedSteps,
          condiscon: DisclosureConDisCon(
            parentState.condiscon
                .map((discon) => discon.disconIndex == state.discon.disconIndex ? state.discon : discon)
                .toList(),
          ),
        );
      } else {
        throw UnsupportedError('Transition from DisclosurePermissionChangeChoice to ${state.parentState.runtimeType}');
      }

      yield DisclosurePermissionChangeChoice(
        parentState: updatedParentState,
        discon: updatedParentState.condiscon[state.discon.disconIndex]!,
      );
    } else if (state is DisclosurePermissionChangeChoice && event is DisclosurePermissionNextPressed) {
      if (state.discon.selectedCon.needsToBeObtained) {
        // If only one credential is involved, we can open the issue url immediately.
        if (state.discon.selectedCon.length == 1) {
          _repo.openIssueURL(locale, state.discon.selectedCon.first.credentialType.fullId);
        }
        yield DisclosurePermissionSubIssueWizard(
          parentState: state,
          issueWizard: state.discon.selectedCon.whereType<TemplateDisclosureCredential>().toList(),
        );
      } else {
        yield state.parentState;
      }
    } else if (state is DisclosurePermissionChoicesOverview && event is DisclosurePermissionNextPressed) {
      if (!state.showConfirmationPopup) {
        yield DisclosurePermissionChoicesOverview(
          plannedSteps: state.plannedSteps,
          condiscon: state.condiscon,
          showConfirmationPopup: true,
        );
      } else if (session.isIssuanceSession) {
        _repo.dispatch(
          ContinueToIssuanceEvent(sessionID: sessionID),
          isBridgedEvent: true,
        );
      } else {
        _repo.dispatch(
          RespondPermissionEvent(
            sessionID: sessionID,
            proceed: true,
            disclosureChoices: Con(state.condiscon.map((discon) => Con(discon.selectedCon
                .expand((cred) => cred.attributes.map((attr) => AttributeIdentifier.fromAttribute(attr)))))),
          ),
          isBridgedEvent: true,
        );
      }
    } else if (state is DisclosurePermissionChoicesOverview && event is DisclosurePermissionConfirmationDismissed) {
      yield DisclosurePermissionChoicesOverview(
        plannedSteps: state.plannedSteps,
        condiscon: state.condiscon,
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
    } else if (state is DisclosurePermissionSubIssueWizard) {
      final refreshedWizard = _refreshSubIssueWizard(session, state);
      // In case the sub wizard only contains one item, we immediately go back to the parent step.
      if (refreshedWizard.issueWizard.length == 1 && refreshedWizard.allObtainedCredentialsMatch) {
        yield refreshedWizard.parentState;
      } else {
        yield refreshedWizard;
      }
    } else if (state is DisclosurePermissionChangeChoice) {
      final refreshedStep = _refreshDisclosurePermissionStep(session, state.parentState);
      yield DisclosurePermissionChangeChoice(
        parentState: refreshedStep,
        discon: refreshedStep.condiscon[state.discon.disconIndex]!,
      );
    } else {
      // Check whether an issue wizard is needed to bootstrap the session.
      final condiscon = _parseDisclosureCandidates(session.disclosuresCandidates!);
      if (condiscon.every((discon) => discon.choosableCons.isNotEmpty)) {
        yield DisclosurePermissionChoicesOverview(
          plannedSteps: [DisclosurePermissionStepName.choicesOverview],
          condiscon: condiscon,
          signedMessage: session.isSignatureSession ?? false ? session.signedMessage : null,
        );
      } else {
        // In an issue wizard, only the credential templates are relevant. If an issue wizard is needed,
        // we also include the optional discons where no non-empty con is fully obtained yet. If no issue wizard
        // is needed, then the optional discons are presented in DisclosurePermissionChoicesOverview.
        yield DisclosurePermissionIssueWizard(
          plannedSteps: _calculatePlannedSteps(condiscon),
          condiscon: _parseDisclosureCandidates(
            session.disclosuresCandidates!,
            onlyInclude: condiscon
                .where((discon) => discon.choosableCons.where((con) => con.isNotEmpty).isEmpty)
                .expand((discon) => discon
                    .expand((con) => con.whereType<TemplateDisclosureCredential>().map((cred) => cred.credentialType)))
                .toSet(),
          ),
        );
      }
    }
  }

  DisclosurePermissionStep _refreshDisclosurePermissionStep(SessionState session, DisclosurePermissionStep state) {
    if (state is DisclosurePermissionIssueWizard) {
      // We assume that in the initial disclosure candidates all credential types involved in this session are
      // being mentioned. This allows us to build upon the previously generated issue wizard.
      return DisclosurePermissionIssueWizard(
        plannedSteps: state.plannedSteps,
        condiscon: _parseDisclosureCandidates(
          session.disclosuresCandidates!,
          onlyInclude: state.condiscon.includedCredentialTypes,
        ),
      );
    } else if (state is DisclosurePermissionPreviouslyAddedCredentialsOverview) {
      return DisclosurePermissionPreviouslyAddedCredentialsOverview(
        plannedSteps: state.plannedSteps,
        condiscon: _parseDisclosureCandidates(
          session.disclosuresCandidates!,
          onlyInclude: state.condiscon.includedCredentialTypes,
        ),
      );
    } else if (state is DisclosurePermissionChoicesOverview) {
      return DisclosurePermissionChoicesOverview(
        plannedSteps: state.plannedSteps,
        condiscon: _parseDisclosureCandidates(session.disclosuresCandidates!),
        signedMessage: state.signedMessage,
        showConfirmationPopup: state.showConfirmationPopup,
      );
    } else {
      throw UnsupportedError('unknown step ${state.runtimeType}');
    }
  }

  DisclosurePermissionSubIssueWizard _refreshSubIssueWizard(
    SessionState session,
    DisclosurePermissionSubIssueWizard state,
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
      throw Exception('DisclosurePermissionSubIssueWizard has unexpected parent: ${parentState.runtimeType}');
    }

    return DisclosurePermissionSubIssueWizard(
      parentState: _refreshDisclosurePermissionStep(session, condiscon),
      issueWizard: state.issueWizard,
      obtainedCredentials: state.issueWizard.map((template) {
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

  DisclosureConDisCon _parseDisclosureCandidates(
    ConDisCon<Attribute> candidates, {
    Set<CredentialType> onlyInclude = const {},
  }) {
    final onlyIncludeIds = onlyInclude.map((ct) => ct.fullId).toSet();
    final rawCondiscon = candidates.map((discon) => DisCon(discon.map((con) {
          final groupedCon = groupBy(con, (Attribute attr) => attr.credentialInfo.fullId);
          return Con(groupedCon.entries.map((entry) {
            final credentialAttributes = entry.value;
            if (credentialAttributes.first.choosable) {
              return ChoosableDisclosureCredential(attributes: credentialAttributes);
            } else {
              return TemplateDisclosureCredential(attributes: credentialAttributes);
            }
          }));
        })));
    return DisclosureConDisCon(rawCondiscon.mapIndexed((i, discon) {
      final cons = discon.mapIndexed((j, con) {
        final filteredCon = Con(con.where((cred) => onlyIncludeIds.contains(cred.fullId)));
        return filteredCon.isNotEmpty ? DisclosureCon<DisclosureCredential>(con: filteredCon, conIndices: {j}) : null;
      }).whereNotNull();

      // Filter duplicate cons.
      final List<DisclosureCon> filteredCons = cons.fold([], (prev, con) {
        for (int i = 0; i < prev.length; i++) {
          final merged = prev[i].copyAndMerge(con);
          if (merged != null) {
            prev[i] = merged;
            return prev;
          }
        }
        return [...prev, con];
      });

      return DisclosureDisCon(discon: filteredCons, disconIndex: i);
    }).toList());
  }

  List<DisclosurePermissionStepName> _calculatePlannedSteps(DisclosureConDisCon condiscon) {
    final hasPrevAddedCreds =
        condiscon.any((discon) => discon.selectedCon.any((cred) => cred is ChoosableDisclosureCredential));
    final stepNames = [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.previouslyAddedCredentialsOverview,
      DisclosurePermissionStepName.choicesOverview,
    ];
    // In an issue wizard, only the credential templates are relevant.
    return hasPrevAddedCreds
        ? stepNames
        : stepNames.where((name) => name != DisclosurePermissionStepName.previouslyAddedCredentialsOverview).toList();
  }
}
