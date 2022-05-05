import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/session/disclosure/bloc/disclosure_permission_bloc.dart';
import 'package:irmamobile/src/screens/session/disclosure/bloc/disclosure_permission_event.dart';
import 'package:irmamobile/src/screens/session/disclosure/bloc/disclosure_permission_state.dart';
import 'package:irmamobile/src/screens/session/models/choosable_disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/models/template_disclosure_credential.dart';
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
    await repo.getCredentials().first; // Wait until AppReadyEvent has been processed.
  });
  tearDown(() async {
    await mockBridge.close();
    await repo.close();
  });

  test('issuance-in-disclosure-single-attribute', () async {
    mockBridge.mockDisclosureSession(42, [
      [
        {
          'irma-demo.IRMATube.member.id': null,
        }
      ]
    ]);

    final bloc = DisclosurePermissionBloc(sessionID: 42, repo: repo);
    expect(bloc.state, isA<DisclosurePermissionInitial>());

    repo.dispatch(
      NewSessionEvent(sessionID: 42, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.issueWizard.length, 1);
    expect(issueWizardBlocState.obtainedCredentialsMatch[0], false);
    expect(issueWizardBlocState.obtainedCredentials[0], null);
    expect(issueWizardBlocState.issueWizard[0].fullId, 'irma-demo.IRMATube.member');
    expect(issueWizardBlocState.issueWizard[0].attributes.length, 1);
    expect(issueWizardBlocState.issueWizard[0].attributes[0].attributeType.fullId, 'irma-demo.IRMATube.member.id');
    expect(issueWizardBlocState.issueWizard[0].attributes[0].value.raw, null);
    expect(issueWizardBlocState.issueWizard[0].attributes[0].choosable, false);

    await _issueCredential(repo, mockBridge, 43, [
      {
        'irma-demo.IRMATube.member.id': TextValue.fromString('12345'),
        'irma-demo.IRMATube.member.type': TextValue.fromString('member'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.issueWizard.length, 1);
    expect(issueWizardBlocState.obtainedCredentialsMatch[0], true);
    expect(issueWizardBlocState.obtainedCredentials[0]?.fullId, 'irma-demo.IRMATube.member');
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes.length, 1);
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes[0].value.raw, '12345');
    expect(issueWizardBlocState.issueWizard[0].fullId, 'irma-demo.IRMATube.member');

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    DisclosurePermissionChoices choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.selectedStepIndex, null);
    expect(choiceBlocState.choices.length, 1);
    expect(choiceBlocState.choices[0].length, 2);
    expect(choiceBlocState.choices[0][0].length, 1);
    expect(choiceBlocState.choices[0][0][0], isA<ChoosableDisclosureCredential>());
    expect(choiceBlocState.choices[0][0][0].fullId, 'irma-demo.IRMATube.member');
    expect(choiceBlocState.choices[0][0][0].attributes.length, 1);
    expect(choiceBlocState.choices[0][0][0].attributes[0].choosable, true);
    expect(choiceBlocState.choices[0][0][0].attributes[0].attributeType.fullId, 'irma-demo.IRMATube.member.id');
    expect(choiceBlocState.choices[0][0][0].attributes[0].value.raw, '12345');
    expect(choiceBlocState.choices[0][1].length, 1);
    expect(choiceBlocState.choices[0][1][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choices[0][1][0].fullId, 'irma-demo.IRMATube.member');
    expect(choiceBlocState.choices[0][1][0].attributes.length, 1);
    expect(choiceBlocState.choices[0][1][0].attributes[0].choosable, false);
    expect(choiceBlocState.choices[0][1][0].attributes[0].attributeType.fullId, 'irma-demo.IRMATube.member.id');
    expect(choiceBlocState.choices[0][1][0].attributes[0].value.raw, null);
    expect(choiceBlocState.choiceIndices, [0]);

    bloc.add(DisclosurePermissionStepSelected(stepIndex: 0));
    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.selectedStepIndex, 0);

    // Test feature to add extra credential instance while choosing.
    await _issueCredential(repo, mockBridge, 44, [
      {
        'irma-demo.IRMATube.member.id': TextValue.fromString('67890'),
        'irma-demo.IRMATube.member.type': TextValue.fromString('member'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.selectedStepIndex, 0);
    expect(choiceBlocState.choices.length, 1);
    expect(choiceBlocState.choices[0].length, 3);
    expect(choiceBlocState.choices[0][0].length, 1);
    expect(choiceBlocState.choices[0][0][0], isA<ChoosableDisclosureCredential>());
    expect(choiceBlocState.choices[0][1][0], isA<ChoosableDisclosureCredential>());
    expect(choiceBlocState.choices[0][2][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choices[0][0][0].attributes[0].value.raw, '67890');
    expect(choiceBlocState.choices[0][1][0].attributes[0].value.raw, '12345');

    bloc.add(DisclosurePermissionChoiceUpdated(stepIndex: 0, choiceIndex: 1));
    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.choiceIndices, [1]);

    bloc.add(DisclosurePermissionStepSelected(stepIndex: null));
    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.selectedStepIndex, null);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionConfirmChoices>());
    final confirmBlocState = bloc.state as DisclosurePermissionConfirmChoices;
    expect(confirmBlocState.currentSelection.length, 1);
    expect(confirmBlocState.currentSelection[0].fullId, 'irma-demo.IRMATube.member');
    expect(confirmBlocState.currentSelection[0].attributes.length, 1);
    expect(confirmBlocState.currentSelection[0].attributes[0].attributeType.fullId, 'irma-demo.IRMATube.member.id');
    expect(confirmBlocState.currentSelection[0].attributes[0].value.raw, '12345');

    // Check whether we can go back to the choice phase again.
    bloc.add(DisclosurePermissionEditCurrentSelectionPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.selectedStepIndex, null);
    expect(choiceBlocState.choiceIndices, [1]);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionConfirmChoices>());

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(42).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('issuance-in-disclosure-condiscon', () async {
    // Disclose the following:
    // - address issued by gemeente or iDIN
    // - email address issued by pbdf
    // - mobile number issued by pbdf
    // and the user already has the email address credential in its app.

    await _issueCredential(repo, mockBridge, 42, [
      {
        'pbdf.pbdf.email.email': TextValue.fromString('test@example.com'),
        'pbdf.pbdf.email.domain': TextValue.fromString('example.com'),
      }
    ]);

    mockBridge.mockDisclosureSession(43, [
      [
        {
          'pbdf.pbdf.idin.address': null,
        },
        {
          'pbdf.gemeente.address.street': null,
          'pbdf.gemeente.address.houseNumber': null,
        },
      ],
      [
        {
          'pbdf.pbdf.email.email': null,
        },
      ],
      [
        {
          'pbdf.pbdf.mobilenumber.mobilenumber': null,
        },
      ],
    ]);

    final bloc = DisclosurePermissionBloc(sessionID: 43, repo: repo);
    repo.dispatch(
      NewSessionEvent(sessionID: 43, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizardChoices>());
    DisclosurePermissionIssueWizardChoices issueWizardChoiceBlocState =
        bloc.state as DisclosurePermissionIssueWizardChoices;
    // Only for address a choice needs to be made before the issue wizard can be generated.
    expect(issueWizardChoiceBlocState.issueWizardChoices.length, 1);
    expect(issueWizardChoiceBlocState.issueWizardChoices[0].length, 2);
    expect(issueWizardChoiceBlocState.issueWizardChoices[0][0].length, 1);
    expect(issueWizardChoiceBlocState.issueWizardChoices[0][0][0].fullId, 'pbdf.pbdf.idin');
    expect(issueWizardChoiceBlocState.issueWizardChoices[0][1][0].fullId, 'pbdf.gemeente.address');
    expect(issueWizardChoiceBlocState.issueWizardChoiceIndices, [0]);

    bloc.add(DisclosurePermissionIssueWizardChoiceUpdated(stepIndex: 0, choiceIndex: 1));

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizardChoices>());
    issueWizardChoiceBlocState = bloc.state as DisclosurePermissionIssueWizardChoices;
    expect(issueWizardChoiceBlocState.issueWizardChoiceIndices, [1]);

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.allObtainedCredentialsMatch, false);
    expect(issueWizardBlocState.issueWizard.length, 2);
    expect(issueWizardBlocState.issueWizard[0].fullId, 'pbdf.gemeente.address');
    expect(issueWizardBlocState.obtainedCredentialsMatch[0], false);
    expect(issueWizardBlocState.obtainedCredentials[0], null);
    expect(issueWizardBlocState.issueWizard[1].fullId, 'pbdf.pbdf.mobilenumber');
    expect(issueWizardBlocState.obtainedCredentials[1], null);

    await _issueCredential(repo, mockBridge, 44, [
      {
        'pbdf.gemeente.address.street': TextValue.fromString('Beukenlaan'),
        'pbdf.gemeente.address.houseNumber': TextValue.fromString('1'),
        'pbdf.gemeente.address.city': TextValue.fromString('Amsterdam'),
        'pbdf.gemeente.address.municipality': TextValue.fromString('Amsterdam'),
        'pbdf.gemeente.address.zipcode': TextValue.fromString('1000AA'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.allObtainedCredentialsMatch, false);
    expect(issueWizardBlocState.issueWizard.length, 2);
    expect(issueWizardBlocState.issueWizard[0].fullId, 'pbdf.gemeente.address');
    expect(issueWizardBlocState.obtainedCredentialsMatch[0], true);
    expect(issueWizardBlocState.obtainedCredentials[0]?.fullId, 'pbdf.gemeente.address');
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes.length, 2);
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes[0].value.raw, 'Beukenlaan');
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes[1].value.raw, '1');
    expect(issueWizardBlocState.issueWizard[1].fullId, 'pbdf.pbdf.mobilenumber');
    expect(issueWizardBlocState.obtainedCredentialsMatch[1], false);
    expect(issueWizardBlocState.obtainedCredentials[1], null);

    await _issueCredential(repo, mockBridge, 45, [
      {
        'pbdf.pbdf.mobilenumber.mobilenumber': TextValue.fromString('+31612345678'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.allObtainedCredentialsMatch, true);
    expect(issueWizardBlocState.issueWizard[0].fullId, 'pbdf.gemeente.address');
    expect(issueWizardBlocState.obtainedCredentialsMatch[0], true);
    expect(issueWizardBlocState.issueWizard[1].fullId, 'pbdf.pbdf.mobilenumber');
    expect(issueWizardBlocState.obtainedCredentialsMatch[1], true);
    expect(issueWizardBlocState.obtainedCredentials[1]?.fullId, 'pbdf.pbdf.mobilenumber');
    expect(issueWizardBlocState.obtainedCredentials[1]?.attributes.length, 1);
    expect(issueWizardBlocState.obtainedCredentials[1]?.attributes[0].value.raw, '+31612345678');

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    DisclosurePermissionChoices choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.choices.length, 3);
    expect(choiceBlocState.choices[0].length, 2);
    expect(choiceBlocState.choices[0][0].length, 1);
    expect(choiceBlocState.choices[0][0][0].fullId, 'pbdf.gemeente.address');
    expect(choiceBlocState.choices[0][0][0].attributes.length, 2);
    expect(choiceBlocState.choices[0][0][0].attributes[0].attributeType.fullId, 'pbdf.gemeente.address.street');
    expect(choiceBlocState.choices[0][0][0].attributes[0].value.raw, 'Beukenlaan');
    expect(choiceBlocState.choices[0][1].length, 1);
    expect(choiceBlocState.choices[0][1][0].fullId, 'pbdf.pbdf.idin');
    expect(choiceBlocState.choices[0][1][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choices[0][1][0].attributes[0].attributeType.fullId, 'pbdf.pbdf.idin.address');
    expect(choiceBlocState.choices[0][1][0].attributes[0].value.raw, null);
    expect(choiceBlocState.choices[1].length, 2);
    expect(choiceBlocState.choices[1][0].length, 1);
    expect(choiceBlocState.choices[1][0][0].fullId, 'pbdf.pbdf.email');
    expect(choiceBlocState.choices[1][0][0].attributes[0].attributeType.fullId, 'pbdf.pbdf.email.email');
    expect(choiceBlocState.choices[1][0][0].attributes[0].value.raw, 'test@example.com');
    expect(choiceBlocState.choices[1][1].length, 1);
    expect(choiceBlocState.choices[1][1][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choices[2].length, 2);
    expect(choiceBlocState.choices[2][0].length, 1);
    expect(choiceBlocState.choices[2][0][0].fullId, 'pbdf.pbdf.mobilenumber');
    expect(choiceBlocState.choices[2][0][0].attributes[0].attributeType.fullId, 'pbdf.pbdf.mobilenumber.mobilenumber');
    expect(choiceBlocState.choices[2][0][0].attributes[0].value.raw, '+31612345678');
    expect(choiceBlocState.choices[2][1].length, 1);
    expect(choiceBlocState.choices[2][1][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choiceIndices, [0, 0, 0]);

    await _issueCredential(repo, mockBridge, 46, [
      {
        'pbdf.pbdf.mobilenumber.mobilenumber': TextValue.fromString('+31687654321'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.choices.length, 3);
    expect(choiceBlocState.choices[2].length, 3);
    expect(choiceBlocState.choices[2][0].length, 1);
    expect(choiceBlocState.choices[2][0][0].fullId, 'pbdf.pbdf.mobilenumber');
    expect(choiceBlocState.choices[2][0][0].attributes[0].attributeType.fullId, 'pbdf.pbdf.mobilenumber.mobilenumber');
    expect(choiceBlocState.choices[2][0][0].attributes[0].value.raw, '+31687654321');
    expect(choiceBlocState.choices[2][1].length, 1);
    expect(choiceBlocState.choices[2][1][0].fullId, 'pbdf.pbdf.mobilenumber');
    expect(choiceBlocState.choices[2][1][0].attributes[0].attributeType.fullId, 'pbdf.pbdf.mobilenumber.mobilenumber');
    expect(choiceBlocState.choices[2][1][0].attributes[0].value.raw, '+31612345678');
    expect(choiceBlocState.choices[2][2].length, 1);
    expect(choiceBlocState.choices[2][2][0], isA<TemplateDisclosureCredential>());

    bloc.add(DisclosurePermissionChoiceUpdated(stepIndex: 2, choiceIndex: 1));

    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.choiceIndices, [0, 0, 1]);

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionConfirmChoices>());
    final confirmBlocState = bloc.state as DisclosurePermissionConfirmChoices;
    expect(confirmBlocState.currentSelection.length, 3);
    expect(confirmBlocState.currentSelection[0].fullId, 'pbdf.gemeente.address');
    expect(confirmBlocState.currentSelection[0].attributes.length, 2);
    expect(confirmBlocState.currentSelection[0].attributes[0].value.raw, 'Beukenlaan');
    expect(confirmBlocState.currentSelection[1].fullId, 'pbdf.pbdf.email');
    expect(confirmBlocState.currentSelection[1].attributes.length, 1);
    expect(confirmBlocState.currentSelection[1].attributes[0].value.raw, 'test@example.com');
    expect(confirmBlocState.currentSelection[2].fullId, 'pbdf.pbdf.mobilenumber');
    expect(confirmBlocState.currentSelection[2].attributes.length, 1);
    expect(confirmBlocState.currentSelection[2].attributes[0].value.raw, '+31612345678');

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(43).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('discon', () async {
    await _issueCredential(repo, mockBridge, 42, [
      {
        'pbdf.pbdf.email.email': TextValue.fromString('test@example.com'),
        'pbdf.pbdf.email.domain': TextValue.fromString('example.com'),
      }
    ]);

    mockBridge.mockDisclosureSession(43, [
      [
        {
          'pbdf.pbdf.email.email': null,
        },
        {
          'pbdf.pbdf.mobilenumber.mobilenumber': null,
        },
      ],
    ]);

    final bloc = DisclosurePermissionBloc(sessionID: 43, repo: repo);
    repo.dispatch(
      NewSessionEvent(sessionID: 43, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    final choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.choices.length, 1);
    expect(choiceBlocState.choices[0].length, 3);
    expect(choiceBlocState.choices[0][0].length, 1);
    expect(choiceBlocState.choices[0][0][0].fullId, 'pbdf.pbdf.email');
    expect(choiceBlocState.choices[0][0][0].attributes.length, 1);
    expect(choiceBlocState.choices[0][0][0].attributes[0].attributeType.fullId, 'pbdf.pbdf.email.email');
    expect(choiceBlocState.choices[0][0][0].attributes[0].value.raw, 'test@example.com');
    expect(choiceBlocState.choices[0][1].length, 1);
    expect(choiceBlocState.choices[0][1][0].fullId, 'pbdf.pbdf.email');
    expect(choiceBlocState.choices[0][1][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choices[0][1][0].attributes[0].attributeType.fullId, 'pbdf.pbdf.email.email');
    expect(choiceBlocState.choices[0][1][0].attributes[0].value.raw, null);
    expect(choiceBlocState.choices[0][2].length, 1);
    expect(choiceBlocState.choices[0][2][0].fullId, 'pbdf.pbdf.mobilenumber');
    expect(choiceBlocState.choices[0][2][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choices[0][2][0].attributes[0].attributeType.fullId, 'pbdf.pbdf.mobilenumber.mobilenumber');
    expect(choiceBlocState.choices[0][2][0].attributes[0].value.raw, null);

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionConfirmChoices>());
    final confirmBlocState = bloc.state as DisclosurePermissionConfirmChoices;
    expect(confirmBlocState.currentSelection.length, 1);
    expect(confirmBlocState.currentSelection[0].fullId, 'pbdf.pbdf.email');
    expect(confirmBlocState.currentSelection[0].attributes.length, 1);
    expect(confirmBlocState.currentSelection[0].attributes[0].value.raw, 'test@example.com');

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(43).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('issuance-in-disclosure-specific-attributes', () async {
    // Spread request over multiple outer cons to test whether TemplateDisclosureCredential's copyAndMerge works.
    mockBridge.mockDisclosureSession(42, [
      [
        {
          'pbdf.pbdf.email.domain': 'example.com',
        },
      ],
      [
        {
          'pbdf.pbdf.email.email': 'test@example.com',
        },
      ],
    ]);

    final bloc = DisclosurePermissionBloc(sessionID: 42, repo: repo);
    repo.dispatch(
      NewSessionEvent(sessionID: 42, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.allObtainedCredentialsMatch, false);
    expect(issueWizardBlocState.issueWizard.length, 1);
    expect(issueWizardBlocState.issueWizard[0].fullId, 'pbdf.pbdf.email');
    expect(issueWizardBlocState.obtainedCredentialsMatch[0], false);
    expect(issueWizardBlocState.obtainedCredentials[0], null);

    await _issueCredential(repo, mockBridge, 43, [
      {
        'pbdf.pbdf.email.email': TextValue.fromString('test@wrong.example.com'),
        'pbdf.pbdf.email.domain': TextValue.fromString('wrong.example.com'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.allObtainedCredentialsMatch, false);
    expect(issueWizardBlocState.issueWizard.length, 1);
    expect(issueWizardBlocState.issueWizard[0].fullId, 'pbdf.pbdf.email');
    expect(issueWizardBlocState.obtainedCredentialsMatch[0], false);
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes.length, 2);
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes[0].value.raw, 'test@wrong.example.com');
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes[1].value.raw, 'wrong.example.com');

    await _issueCredential(repo, mockBridge, 44, [
      {
        'pbdf.pbdf.email.email': TextValue.fromString('test@example.com'),
        'pbdf.pbdf.email.domain': TextValue.fromString('example.com'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.allObtainedCredentialsMatch, true);
    expect(issueWizardBlocState.issueWizard.length, 1);
    expect(issueWizardBlocState.issueWizard[0].fullId, 'pbdf.pbdf.email');
    expect(issueWizardBlocState.obtainedCredentialsMatch[0], true);
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes.length, 2);
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes[0].value.raw, 'test@example.com');
    expect(issueWizardBlocState.obtainedCredentials[0]?.attributes[1].value.raw, 'example.com');

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    final choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.choices.length, 2);
    expect(choiceBlocState.choices[0].length, 2);
    expect(choiceBlocState.choices[0][0].length, 1);
    expect(choiceBlocState.choices[0][0][0], isA<ChoosableDisclosureCredential>());
    expect(choiceBlocState.choices[0][1].length, 1);
    expect(choiceBlocState.choices[0][1][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choices[1].length, 2);
    expect(choiceBlocState.choices[1][0].length, 1);
    expect(choiceBlocState.choices[1][0][0], isA<ChoosableDisclosureCredential>());
    expect(choiceBlocState.choices[1][1].length, 1);
    expect(choiceBlocState.choices[1][1][0], isA<TemplateDisclosureCredential>());

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionConfirmChoices>());

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(42).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('same-credential-type-in-multiple-outer-cons', () async {
    // Disclose id and email address of surfnet-2, but they don't have to come from the same credential instance.
    mockBridge.mockDisclosureSession(42, [
      [
        {
          'pbdf.pbdf.surfnet-2.id': null,
        },
      ],
      [
        {
          'pbdf.pbdf.surfnet-2.email': null,
        },
      ],
    ]);

    final bloc = DisclosurePermissionBloc(sessionID: 42, repo: repo);
    repo.dispatch(
      NewSessionEvent(sessionID: 42, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.allObtainedCredentialsMatch, false);
    expect(issueWizardBlocState.issueWizard.length, 1);
    expect(issueWizardBlocState.issueWizard[0].fullId, 'pbdf.pbdf.surfnet-2');
    expect(issueWizardBlocState.issueWizard[0].attributes.length, 2);
    expect(issueWizardBlocState.issueWizard[0].attributes[0].attributeType.fullId, 'pbdf.pbdf.surfnet-2.id');
    expect(issueWizardBlocState.issueWizard[0].attributes[1].attributeType.fullId, 'pbdf.pbdf.surfnet-2.email');
    expect(issueWizardBlocState.obtainedCredentials[0], null);

    await _issueCredential(repo, mockBridge, 43, [
      {
        'pbdf.pbdf.surfnet-2.id': TextValue.fromString('12345'),
        'pbdf.pbdf.surfnet-2.email': TextValue.fromString('test@example.com'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.allObtainedCredentialsMatch, true);

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    final choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.choices.length, 2);
    expect(choiceBlocState.choices[0].length, 2);
    expect(choiceBlocState.choices[0][0].length, 1);
    expect(choiceBlocState.choices[0][0][0], isA<ChoosableDisclosureCredential>());
    expect(choiceBlocState.choices[0][1].length, 1);
    expect(choiceBlocState.choices[0][1][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choices[1].length, 2);
    expect(choiceBlocState.choices[1][0].length, 1);
    expect(choiceBlocState.choices[1][0][0], isA<ChoosableDisclosureCredential>());
    expect(choiceBlocState.choices[1][1].length, 1);
    expect(choiceBlocState.choices[1][1][0], isA<TemplateDisclosureCredential>());

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionConfirmChoices>());

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(42).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('issuance-in-disclosure-optional-attributes', () async {
    // Disclose id and email address of surfnet-2, but they don't have to come from the same credential instance.
    mockBridge.mockDisclosureSession(42, [
      [
        {},
        {
          'pbdf.pbdf.email.email': null,
        },
        {
          'pbdf.pbdf.mobilenumber.mobilenumber': null,
        },
      ],
    ]);

    final bloc = DisclosurePermissionBloc(sessionID: 42, repo: repo);
    repo.dispatch(
      NewSessionEvent(sessionID: 42, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionChoices>());
    final choiceBlocState = bloc.state as DisclosurePermissionChoices;
    expect(choiceBlocState.choices.length, 1);
    expect(choiceBlocState.choices[0].length, 3);
    expect(choiceBlocState.choices[0][0].length, 0);
    expect(choiceBlocState.choices[0][1].length, 1);
    expect(choiceBlocState.choices[0][1][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choices[0][1][0].fullId, 'pbdf.pbdf.email');
    expect(choiceBlocState.choices[0][2].length, 1);
    expect(choiceBlocState.choices[0][2][0], isA<TemplateDisclosureCredential>());
    expect(choiceBlocState.choices[0][2][0].fullId, 'pbdf.pbdf.mobilenumber');

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionConfirmChoices>());

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
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
