import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/session/bloc/disclosure_permission_bloc.dart';
import 'package:irmamobile/src/screens/session/bloc/disclosure_permission_event.dart';
import 'package:irmamobile/src/screens/session/bloc/disclosure_permission_state.dart';
import 'package:irmamobile/src/screens/session/models/disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/models/disclosure_credential_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late IrmaRepository repo;
  late IrmaMockBridge mockBridge;

  setUp(() async {
    mockBridge = IrmaMockBridge();
    SharedPreferences.setMockInitialValues({});
    repo = IrmaRepository(
      client: mockBridge,
      preferences: await IrmaPreferences.fromInstance(),
    );
  });
  tearDown(() async {
    await mockBridge.close();
    await repo.close();
  });

  test('simple-issuance-in-disclosure', () async {
    mockBridge.mockDisclosureSession(42, [
      [
        {'irma-demo.IRMATube.member.id': null}
      ]
    ]);

    final bloc = DisclosurePermissionBloc(sessionID: 42, repo: repo);
    expect(bloc.state, isA<WaitingForSessionState>());

    repo.dispatch(
      NewSessionEvent(sessionID: 42, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizardState>());
    DisclosurePermissionIssueWizardState issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizardState;
    expect(issueWizardBlocState.issueWizard.length, 1);
    expect(issueWizardBlocState.issueWizard[0].obtained, false);
    expect(issueWizardBlocState.issueWizard[0].presentMatching, []);
    expect(issueWizardBlocState.issueWizard[0].presentNonMatching, []);
    expect(issueWizardBlocState.issueWizard[0].fullId, 'irma-demo.IRMATube.member');
    expect(issueWizardBlocState.issueWizard[0].attributes.length, 1);
    expect(issueWizardBlocState.issueWizard[0].attributes[0].attributeType.fullId, 'irma-demo.IRMATube.member.id');
    expect(issueWizardBlocState.issueWizard[0].attributes[0].value.raw, null);
    expect(issueWizardBlocState.issueWizard[0].attributes[0].choosable, false);

    // TODO: Check false issuance

    await _issueCredential(repo, mockBridge, 43, [
      {
        'irma-demo.IRMATube.member.id': TextValue.fromString('12345'),
        'irma-demo.IRMATube.member.type': TextValue.fromString('member'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizardState>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizardState;
    expect(issueWizardBlocState.issueWizard.length, 1);
    expect(issueWizardBlocState.issueWizard[0].obtained, true);
    expect(issueWizardBlocState.issueWizard[0].presentMatching.length, 1);
    expect(issueWizardBlocState.issueWizard[0].presentMatching[0].fullId, 'irma-demo.IRMATube.member');
    expect(issueWizardBlocState.issueWizard[0].presentMatching[0].attributes.length, 1);
    expect(issueWizardBlocState.issueWizard[0].presentMatching[0].attributes[0].value.raw, '12345');
    expect(issueWizardBlocState.issueWizard[0].presentNonMatching, []);
    expect(issueWizardBlocState.issueWizard[0].fullId, 'irma-demo.IRMATube.member');

    bloc.add(GoToNextStateEvent());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoiceState>());
    DisclosurePermissionChoiceState choiceBlocState = bloc.state as DisclosurePermissionChoiceState;
    expect(choiceBlocState.selectedStepIndex, null);
    expect(choiceBlocState.choices.length, 1);
    expect(choiceBlocState.choices[0].length, 2);
    expect(choiceBlocState.choices[0][0].length, 1);
    expect(choiceBlocState.choices[0][0][0], isA<DisclosureCredential>());
    expect(choiceBlocState.choices[0][0][0].fullId, 'irma-demo.IRMATube.member');
    expect(choiceBlocState.choices[0][0][0].attributes.length, 1);
    expect(choiceBlocState.choices[0][0][0].attributes[0].choosable, true);
    expect(choiceBlocState.choices[0][0][0].attributes[0].attributeType.fullId, 'irma-demo.IRMATube.member.id');
    expect(choiceBlocState.choices[0][0][0].attributes[0].value.raw, '12345');
    expect(choiceBlocState.choices[0][1].length, 1);
    expect(choiceBlocState.choices[0][1][0], isA<DisclosureCredentialTemplate>());
    expect(choiceBlocState.choices[0][1][0].fullId, 'irma-demo.IRMATube.member');
    expect(choiceBlocState.choices[0][1][0].attributes.length, 1);
    expect(choiceBlocState.choices[0][1][0].attributes[0].choosable, false);
    expect(choiceBlocState.choices[0][1][0].attributes[0].attributeType.fullId, 'irma-demo.IRMATube.member.id');
    expect(choiceBlocState.choices[0][1][0].attributes[0].value.raw, null);
    expect(choiceBlocState.choiceIndices, [0]);

    bloc.add(DisclosureSelectStepEvent(stepIndex: 0));
    expect(await bloc.stream.first, isA<DisclosurePermissionChoiceState>());
    choiceBlocState = bloc.state as DisclosurePermissionChoiceState;
    expect(choiceBlocState.selectedStepIndex, 0);

    // Test feature to add extra credential instance while choosing.
    await _issueCredential(repo, mockBridge, 44, [
      {
        'irma-demo.IRMATube.member.id': TextValue.fromString('67890'),
        'irma-demo.IRMATube.member.type': TextValue.fromString('member'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionChoiceState>());
    choiceBlocState = bloc.state as DisclosurePermissionChoiceState;
    expect(choiceBlocState.selectedStepIndex, null);
    expect(choiceBlocState.choices.length, 1);
    expect(choiceBlocState.choices[0].length, 3);
    expect(choiceBlocState.choices[0][0].length, 1);
    expect(choiceBlocState.choices[0][0][0], isA<DisclosureCredential>());
    expect(choiceBlocState.choices[0][1][0], isA<DisclosureCredential>());
    expect(choiceBlocState.choices[0][2][0], isA<DisclosureCredentialTemplate>());
    expect(choiceBlocState.choices[0][0][0].attributes[0].value.raw, '67890');
    expect(choiceBlocState.choices[0][1][0].attributes[0].value.raw, '12345');

    bloc.add(DisclosureUpdateChoiceEvent(stepIndex: 0, choiceIndex: 1));
    expect(await bloc.stream.first, isA<DisclosurePermissionChoiceState>());
    choiceBlocState = bloc.state as DisclosurePermissionChoiceState;
    expect(choiceBlocState.choiceIndices, [1]);

    // Wait for state renewal caused by the dispatched DisclosureChoiceUpdateSessionEvent.
    // TODO: Check whether we can prevent this superfluous state change.
    expect(await bloc.stream.first, isA<DisclosurePermissionChoiceState>());

    bloc.add(DisclosureSelectStepEvent(stepIndex: null));
    expect(await bloc.stream.first, isA<DisclosurePermissionChoiceState>());
    choiceBlocState = bloc.state as DisclosurePermissionChoiceState;
    expect(choiceBlocState.selectedStepIndex, null);

    bloc.add(GoToNextStateEvent());
    expect(await bloc.stream.first, isA<DisclosurePermissionConfirmState>());
    final confirmBlocState = bloc.state as DisclosurePermissionConfirmState;
    expect(confirmBlocState.currentSelection.length, 1);
    expect(confirmBlocState.currentSelection[0].fullId, 'irma-demo.IRMATube.member');
    expect(confirmBlocState.currentSelection[0].attributes.length, 1);
    expect(confirmBlocState.currentSelection[0].attributes[0].attributeType.fullId, 'irma-demo.IRMATube.member.id');
    expect(confirmBlocState.currentSelection[0].attributes[0].value.raw, '12345');

    // Check whether we can go back to the choice phase again.
    bloc.add(DisclosureChangeChoicesEvent());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoiceState>());
    choiceBlocState = bloc.state as DisclosurePermissionChoiceState;
    expect(choiceBlocState.selectedStepIndex, null);
    expect(choiceBlocState.choiceIndices, [1]);

    bloc.add(GoToNextStateEvent());
    expect(await bloc.stream.first, isA<DisclosurePermissionConfirmState>());

    bloc.add(GoToNextStateEvent());
    await repo.getSessionState(42).firstWhere((session) => session.status == SessionStatus.success);
  });
}

Future<void> _issueCredential(
  IrmaRepository repo,
  IrmaMockBridge mockBridge,
  int sessionID,
  List<Map<String, TextValue>> credentials,
) async {
  mockBridge.mockIssuanceSession(sessionID, credentials);

  repo.dispatch(
    NewSessionEvent(sessionID: sessionID, request: SessionPointer(irmaqr: 'issuing', u: '')),
    isBridgedEvent: true,
  );
  await repo
      .getSessionState(sessionID)
      .firstWhere((session) => session.status == SessionStatus.requestIssuancePermission);

  repo.dispatch(
    RespondPermissionEvent(sessionID: sessionID, proceed: true, disclosureChoices: [[]]),
    isBridgedEvent: true,
  );
  await repo.getSessionState(sessionID).firstWhere((session) => session.status == SessionStatus.success);
}
