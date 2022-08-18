import 'dart:async';

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
import 'package:irmamobile/src/screens/session/disclosure/models/choosable_disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/template_disclosure_credential.dart';
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

    final obtainCredentialsController = StreamController<String>.broadcast();
    final bloc = DisclosurePermissionBloc(
      sessionID: 42,
      repo: repo,
      onObtainCredential: (credType) => obtainCredentialsController.add(credType.fullId),
    );
    expect(bloc.state, isA<DisclosurePermissionInitial>());

    repo.dispatch(
      NewSessionEvent(sessionID: 42, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    //The first test should see the introduction
    expect(await bloc.stream.first, isA<DisclosurePermissionIntroduction>());
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    expect(issueWizardBlocState.isCompleted, false);
    expect(issueWizardBlocState.candidates.keys, [0]);
    expect(issueWizardBlocState.candidates[0]?.length, 1);
    expect(issueWizardBlocState.candidates[0]?[0].length, 1);
    expect(issueWizardBlocState.candidates[0]?[0][0].fullId, 'irma-demo.IRMATube.member');
    expect(issueWizardBlocState.candidates[0]?[0][0].attributes.length, 1);
    expect(
      issueWizardBlocState.candidates[0]?[0][0].attributes[0].attributeType.fullId,
      'irma-demo.IRMATube.member.id',
    );
    expect(issueWizardBlocState.candidates[0]?[0][0].attributes[0].value.raw, null);
    expect(issueWizardBlocState.candidates[0]?[0][0].attributes[0].choosable, false);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await obtainCredentialsController.stream.first, 'irma-demo.IRMATube.member');
    await _issueCredential(repo, mockBridge, 43, [
      {
        'irma-demo.IRMATube.member.id': TextValue.fromString('12345'),
        'irma-demo.IRMATube.member.type': TextValue.fromString('member'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, true);
    expect(issueWizardBlocState.candidates.keys, [0]);
    expect(issueWizardBlocState.candidates[0]?.length, 1);
    expect(issueWizardBlocState.candidates[0]?[0][0].fullId, 'irma-demo.IRMATube.member');

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    DisclosurePermissionChoicesOverview choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.isSignatureSession, false);
    expect(choicesOverviewBlocState.showConfirmationPopup, false);
    expect(choicesOverviewBlocState.hasAdditionalOptionalChoices, false);
    expect(choicesOverviewBlocState.optionalChoices, {});
    expect(choicesOverviewBlocState.requiredChoices.keys, [0]);
    expect(choicesOverviewBlocState.requiredChoices[0]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0], isA<ChoosableDisclosureCredential>());
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].fullId, 'irma-demo.IRMATube.member');
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].choosable, true);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].attributeType.fullId,
        'irma-demo.IRMATube.member.id');
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].value.raw, '12345');

    bloc.add(DisclosurePermissionChangeChoicePressed(disconIndex: 0));
    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    DisclosurePermissionChangeChoice changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 0);
    expect(changeChoiceBlocState.selectedConIndex, 0);
    expect(changeChoiceBlocState.choosableCons.keys, [0]);
    expect(changeChoiceBlocState.templateCons.keys, [1]);
    expect(changeChoiceBlocState.templateCons[1]?.length, 1);
    expect(changeChoiceBlocState.templateCons[1]?[0].fullId, 'irma-demo.IRMATube.member');

    // Test feature to add extra credential instance while choosing.
    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 1));
    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 0);
    expect(changeChoiceBlocState.selectedConIndex, 1);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await obtainCredentialsController.stream.first, 'irma-demo.IRMATube.member');
    await _issueCredential(repo, mockBridge, 44, [
      {
        'irma-demo.IRMATube.member.id': TextValue.fromString('67890'),
        'irma-demo.IRMATube.member.type': TextValue.fromString('member'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.selectedConIndex, 1);
    expect(changeChoiceBlocState.choosableCons.keys, [0, 1]);
    expect(changeChoiceBlocState.templateCons.keys, [2]);
    expect(changeChoiceBlocState.choosableCons[0]?[0], isA<ChoosableDisclosureCredential>());
    expect(changeChoiceBlocState.choosableCons[1]?[0], isA<ChoosableDisclosureCredential>());
    expect(changeChoiceBlocState.choosableCons[0]?[0].attributes[0].value.raw, '12345');
    expect(changeChoiceBlocState.choosableCons[1]?[0].attributes[0].value.raw, '67890');
    expect(changeChoiceBlocState.templateCons[2]?[0], isA<TemplateDisclosureCredential>());

    // Switch back to the old member attribute with value '12345'.
    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 0));
    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.selectedConIndex, 0);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, false);
    expect(choicesOverviewBlocState.requiredChoices.keys, [0]);
    expect(choicesOverviewBlocState.requiredChoices[0]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].fullId, 'irma-demo.IRMATube.member');
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].attributeType.fullId,
        'irma-demo.IRMATube.member.id');
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].value.raw, '12345');

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, true);

    // Check whether we can dismiss confirmation.
    bloc.add(DisclosurePermissionDialogDismissed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, false);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, true);

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

    final obtainCredentialsController = StreamController<String>.broadcast();
    final bloc = DisclosurePermissionBloc(
      sessionID: 43,
      repo: repo,
      onObtainCredential: (credType) => obtainCredentialsController.add(credType.fullId),
    );
    expect(bloc.state, isA<DisclosurePermissionInitial>());

    repo.dispatch(
      NewSessionEvent(sessionID: 43, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.currentStepName, DisclosurePermissionStepName.issueWizard);
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.previouslyAddedCredentialsOverview,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    // Only for address a choice needs to be made before the issue wizard can be generated.
    expect(issueWizardBlocState.candidates.keys, [0, 2]);
    expect(issueWizardBlocState.candidates[0]?.length, 2);
    expect(issueWizardBlocState.candidates[0]?[0][0].fullId, 'pbdf.pbdf.idin');
    expect(issueWizardBlocState.candidates[0]?[1][0].fullId, 'pbdf.gemeente.address');
    expect(issueWizardBlocState.selectedConIndices[0], 0);
    expect(issueWizardBlocState.candidates[2]?.length, 1);
    expect(issueWizardBlocState.candidates[2]?[0].length, 1);
    expect(issueWizardBlocState.candidates[2]?[0][0].fullId, 'pbdf.pbdf.mobilenumber');
    expect(issueWizardBlocState.selectedConIndices[2], 0);

    // Choose for pbdf.gemeente.address.
    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 1));

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.candidates.keys, [0, 2]);
    expect(issueWizardBlocState.selectedConIndices[0], 1);

    // Obtain pbdf.gemeente.address.
    bloc.add(DisclosurePermissionNextPressed());

    // Because the templates length is only 1, the credential should be obtained immediately.
    expect(await obtainCredentialsController.stream.first, 'pbdf.gemeente.address');

    await _issueCredential(repo, mockBridge, 44, [
      {
        'pbdf.gemeente.address.street': TextValue.fromString('Beukenlaan'),
        'pbdf.gemeente.address.houseNumber': TextValue.fromString('1'),
        'pbdf.gemeente.address.city': TextValue.fromString('Amsterdam'),
        'pbdf.gemeente.address.municipality': TextValue.fromString('Amsterdam'),
        'pbdf.gemeente.address.zipcode': TextValue.fromString('1000AA'),
      }
    ]);

    // Obtaining credentials should be completed and, because the length was 1,
    // we should go back the issue wizard immediately.
    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.currentDiscon?.key, 2);
    expect(issueWizardBlocState.candidates.keys, [0, 2]);
    expect(issueWizardBlocState.getSelectedCon(0)?.length, 1);
    expect(issueWizardBlocState.getSelectedCon(0)?[0].fullId, 'pbdf.gemeente.address');
    expect(issueWizardBlocState.getSelectedCon(0)?[0].attributes.length, 2);
    expect(issueWizardBlocState.currentDiscon?.value.length, 1);
    expect(issueWizardBlocState.currentDiscon?.value[0].length, 1);
    expect(issueWizardBlocState.currentDiscon?.value[0][0].fullId, 'pbdf.pbdf.mobilenumber');

    // Obtain pbdf.pbdf.mobilenumber.
    bloc.add(DisclosurePermissionNextPressed());

    // Because the templates length is only 1, the credential should be obtained immediately.
    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.mobilenumber');
    await _issueCredential(repo, mockBridge, 45, [
      {
        'pbdf.pbdf.mobilenumber.mobilenumber': TextValue.fromString('+31612345678'),
      }
    ]);

    // Obtaining credentials should be completed and, because the length was 1,
    // we should go back the issue wizard immediately.
    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, true);

    // Finish issue wizard and continue to next step.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionPreviouslyAddedCredentialsOverview>());
    DisclosurePermissionPreviouslyAddedCredentialsOverview prevAddedCredsBlocState =
        bloc.state as DisclosurePermissionPreviouslyAddedCredentialsOverview;
    expect(prevAddedCredsBlocState.currentStepName, DisclosurePermissionStepName.previouslyAddedCredentialsOverview);
    expect(
      prevAddedCredsBlocState.plannedSteps,
      contains(DisclosurePermissionStepName.previouslyAddedCredentialsOverview),
    );
    expect(prevAddedCredsBlocState.optionalChoices, {});
    expect(prevAddedCredsBlocState.requiredChoices.keys, [1]);
    expect(prevAddedCredsBlocState.requiredChoices[1]?.length, 1);
    expect(prevAddedCredsBlocState.requiredChoices[1]?[0].fullId, 'pbdf.pbdf.email');
    expect(prevAddedCredsBlocState.requiredChoices[1]?[0].attributes.length, 1);
    expect(prevAddedCredsBlocState.requiredChoices[1]?[0].attributes[0].credentialHash, 'session-42-0');
    expect(prevAddedCredsBlocState.requiredChoices[1]?[0].attributes[0].value.raw, 'test@example.com');

    // Choose for another email address.
    bloc.add(DisclosurePermissionChangeChoicePressed(disconIndex: 1));

    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    DisclosurePermissionChangeChoice changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 1);
    expect(changeChoiceBlocState.choosableCons.keys, [0]);
    expect(changeChoiceBlocState.selectedCon.length, 1);
    expect(changeChoiceBlocState.selectedConIndex, 0);
    expect(changeChoiceBlocState.selectedCon[0].fullId, 'pbdf.pbdf.email');
    expect(changeChoiceBlocState.templateCons.keys, [1]);
    expect(changeChoiceBlocState.templateCons[1]?.length, 1);
    expect(changeChoiceBlocState.templateCons[1]?[0].fullId, 'pbdf.pbdf.email');

    // Choose to add a new email address.
    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 1));

    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 1);
    expect(changeChoiceBlocState.templateCons.keys, [1]);
    expect(changeChoiceBlocState.selectedConIndex, 1);

    // Press next to obtain a new email address.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.email');
    await _issueCredential(repo, mockBridge, 46, [
      {
        'pbdf.pbdf.email.email': TextValue.fromString('test2@example.com'),
        'pbdf.pbdf.email.domain': TextValue.fromString('example.com'),
      }
    ]);

    // Check whether the newly added credential is selected.
    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 1);
    expect(changeChoiceBlocState.choosableCons.keys, [0, 1]);
    expect(changeChoiceBlocState.templateCons.keys, [2]);
    expect(changeChoiceBlocState.selectedConIndex, 1);
    expect(changeChoiceBlocState.selectedCon.length, 1);
    expect(changeChoiceBlocState.selectedCon[0].fullId, 'pbdf.pbdf.email');
    expect(changeChoiceBlocState.selectedCon[0].attributes.length, 1);
    expect(changeChoiceBlocState.selectedCon[0].attributes[0].value.raw, 'test2@example.com');

    // Confirm choice.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionPreviouslyAddedCredentialsOverview>());
    prevAddedCredsBlocState = bloc.state as DisclosurePermissionPreviouslyAddedCredentialsOverview;
    expect(prevAddedCredsBlocState.requiredChoices.keys, [1]);
    expect(prevAddedCredsBlocState.requiredChoices[1]?.length, 1);
    expect(prevAddedCredsBlocState.requiredChoices[1]?[0].fullId, 'pbdf.pbdf.email');
    expect(prevAddedCredsBlocState.requiredChoices[1]?[0].attributes.length, 1);
    expect(prevAddedCredsBlocState.requiredChoices[1]?[0].attributes[0].value.raw, 'test2@example.com');

    // Confirm previously added credential choices.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    DisclosurePermissionChoicesOverview choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.currentStepName, DisclosurePermissionStepName.choicesOverview);
    expect(choicesOverviewBlocState.plannedSteps, contains(DisclosurePermissionStepName.choicesOverview));
    expect(choicesOverviewBlocState.showConfirmationPopup, false);
    expect(choicesOverviewBlocState.optionalChoices, {});
    expect(choicesOverviewBlocState.requiredChoices.keys, [0, 1, 2]);
    expect(choicesOverviewBlocState.requiredChoices[0]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].fullId, 'pbdf.gemeente.address');
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes.length, 2);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].attributeType.fullId,
        'pbdf.gemeente.address.street');
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].value.raw, 'Beukenlaan');
    expect(choicesOverviewBlocState.requiredChoices[1]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[1]?[0].fullId, 'pbdf.pbdf.email');
    expect(choicesOverviewBlocState.requiredChoices[1]?[0].attributes[0].attributeType.fullId, 'pbdf.pbdf.email.email');
    expect(choicesOverviewBlocState.requiredChoices[1]?[0].attributes[0].value.raw, 'test2@example.com');
    expect(choicesOverviewBlocState.requiredChoices[2]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[2]?[0].fullId, 'pbdf.pbdf.mobilenumber');
    expect(
      choicesOverviewBlocState.requiredChoices[2]?[0].attributes[0].attributeType.fullId,
      'pbdf.pbdf.mobilenumber.mobilenumber',
    );
    expect(choicesOverviewBlocState.requiredChoices[2]?[0].attributes[0].value.raw, '+31612345678');

    // Check whether we can choose for another mobile number.
    bloc.add(DisclosurePermissionChangeChoicePressed(disconIndex: 2));

    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 2);
    expect(changeChoiceBlocState.choosableCons.keys, [0]);
    expect(changeChoiceBlocState.selectedCon.length, 1);
    expect(changeChoiceBlocState.selectedConIndex, 0);
    expect(changeChoiceBlocState.selectedCon[0].fullId, 'pbdf.pbdf.mobilenumber');
    expect(changeChoiceBlocState.templateCons.keys, [1]);
    expect(changeChoiceBlocState.templateCons[1]?.length, 1);
    expect(changeChoiceBlocState.templateCons[1]?[0].fullId, 'pbdf.pbdf.mobilenumber');

    // Choose to add a new mobile number.
    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 1));

    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 2);
    expect(changeChoiceBlocState.templateCons.keys, [1]);
    expect(changeChoiceBlocState.selectedConIndex, 1);

    // Press next to obtain a new mobile number.
    bloc.add(DisclosurePermissionNextPressed());

    // Because the templates length is only 1, the credential should be obtained immediately.
    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.mobilenumber');
    await _issueCredential(repo, mockBridge, 47, [
      {
        'pbdf.pbdf.mobilenumber.mobilenumber': TextValue.fromString('+31687654321'),
      }
    ]);

    // Check whether the newly added credential is selected.
    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 2);
    expect(changeChoiceBlocState.choosableCons.keys, [0, 1]);
    expect(changeChoiceBlocState.templateCons.keys, [2]);
    expect(changeChoiceBlocState.selectedConIndex, 1);
    expect(changeChoiceBlocState.selectedCon.length, 1);
    expect(changeChoiceBlocState.selectedCon[0].fullId, 'pbdf.pbdf.mobilenumber');
    expect(changeChoiceBlocState.selectedCon[0].attributes.length, 1);
    expect(changeChoiceBlocState.selectedCon[0].attributes[0].value.raw, '+31687654321');

    // Switch back choice to the old email address.
    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 0));

    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 2);
    expect(changeChoiceBlocState.selectedConIndex, 0);

    // Confirm choice.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.requiredChoices.length, 3);
    expect(choicesOverviewBlocState.requiredChoices.keys, [0, 1, 2]);
    expect(choicesOverviewBlocState.requiredChoices[2]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[2]?[0].fullId, 'pbdf.pbdf.mobilenumber');
    expect(choicesOverviewBlocState.requiredChoices[2]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[2]?[0].attributes[0].value.raw, '+31612345678');

    // Press next to trigger confirmation popup.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, true);
    expect(choicesOverviewBlocState.requiredChoices.keys, [0, 1, 2]);

    // Confirm all choices.
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

    final bloc = DisclosurePermissionBloc(
      sessionID: 43,
      repo: repo,
      onObtainCredential: (_) => {},
    );
    expect(bloc.state, isA<DisclosurePermissionInitial>());
    repo.dispatch(
      NewSessionEvent(sessionID: 43, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    DisclosurePermissionChoicesOverview choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.plannedSteps, [DisclosurePermissionStepName.choicesOverview]);
    expect(choicesOverviewBlocState.showConfirmationPopup, false);
    expect(choicesOverviewBlocState.requiredChoices.keys, [0]);
    expect(choicesOverviewBlocState.requiredChoices[0]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].fullId, 'pbdf.pbdf.email');
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes.length, 1);
    expect(
      choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].attributeType.fullId,
      'pbdf.pbdf.email.email',
    );
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].value.raw, 'test@example.com');

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, true);
    expect(choicesOverviewBlocState.requiredChoices.keys, [0]);
    expect(choicesOverviewBlocState.requiredChoices[0]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].fullId, 'pbdf.pbdf.email');
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].value.raw, 'test@example.com');

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(43).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('issuance-in-disclosure-specific-attributes', () async {
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
      [
        {
          'irma-demo.ivido.login.identifier': null,
        },
        {
          'pbdf.pbdf.mobilenumber.mobilenumber': null,
        },
      ],
    ]);

    final obtainCredentialsController = StreamController<String>.broadcast();
    final bloc = DisclosurePermissionBloc(
      sessionID: 42,
      repo: repo,
      onObtainCredential: (credType) => obtainCredentialsController.add(credType.fullId),
    );
    repo.dispatch(
      NewSessionEvent(sessionID: 42, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, false);
    expect(issueWizardBlocState.candidates.keys, [0, 1, 2]);
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    expect(issueWizardBlocState.candidates[0]?.length, 1);
    expect(issueWizardBlocState.candidates[0]?[0].length, 1);
    expect(issueWizardBlocState.candidates[0]?[0][0].fullId, 'pbdf.pbdf.email');
    expect(issueWizardBlocState.candidates[1]?.length, 1);
    expect(issueWizardBlocState.candidates[1]?[0].length, 1);
    expect(issueWizardBlocState.candidates[1]?[0][0].fullId, 'pbdf.pbdf.email');
    expect(issueWizardBlocState.candidates[2]?.length, 2);
    expect(issueWizardBlocState.selectedConIndices[2], 0);
    expect(issueWizardBlocState.candidates[2]?[0].length, 1);
    expect(issueWizardBlocState.candidates[2]?[0][0].fullId, 'irma-demo.ivido.login');
    expect(issueWizardBlocState.candidates[2]?[1].length, 1);
    expect(issueWizardBlocState.candidates[2]?[1][0].fullId, 'pbdf.pbdf.mobilenumber');

    // Start obtaining first template in the wizard.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.email');
    await _issueCredential(repo, mockBridge, 43, [
      {
        'pbdf.pbdf.email.email': TextValue.fromString('test@wrong.example.com'),
        'pbdf.pbdf.email.domain': TextValue.fromString('wrong.example.com'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionWrongCredentialsObtained>());
    final wrongCredsObtainedBlocState = bloc.state as DisclosurePermissionWrongCredentialsObtained;
    expect(wrongCredsObtainedBlocState.templates.length, 1);
    expect(wrongCredsObtainedBlocState.templates[0].fullId, 'pbdf.pbdf.email');
    expect(wrongCredsObtainedBlocState.obtainedCredentials[0].attributes.length, 1);
    expect(wrongCredsObtainedBlocState.obtainedCredentials[0].attributes[0].value.raw, 'wrong.example.com');

    bloc.add(DisclosurePermissionDialogDismissed());
    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());

    await _issueCredential(repo, mockBridge, 44, [
      {
        'pbdf.pbdf.email.email': TextValue.fromString('test@example.com'),
        'pbdf.pbdf.email.domain': TextValue.fromString('example.com'),
      }
    ]);

    // The discon with index 1 should be fulfilled too, so we should immediately go to the discon with index 2.
    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, false);
    expect(issueWizardBlocState.candidates.keys, [0, 1, 2]);
    expect(issueWizardBlocState.currentDiscon?.key, 2);
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    expect(issueWizardBlocState.candidates[0]?.length, 1);
    expect(issueWizardBlocState.candidates[0]?[0].length, 1);
    expect(issueWizardBlocState.candidates[0]?[0][0].fullId, 'pbdf.pbdf.email');
    expect(issueWizardBlocState.candidates[1]?.length, 1);
    expect(issueWizardBlocState.candidates[1]?[0].length, 1);
    expect(issueWizardBlocState.candidates[1]?[0][0].fullId, 'pbdf.pbdf.email');
    expect(issueWizardBlocState.candidates[2]?.length, 2);
    expect(issueWizardBlocState.candidates[2]?[0].length, 1);
    expect(issueWizardBlocState.candidates[2]?[0][0].fullId, 'irma-demo.ivido.login');
    expect(issueWizardBlocState.candidates[2]?[1].length, 1);
    expect(issueWizardBlocState.candidates[2]?[1][0].fullId, 'pbdf.pbdf.mobilenumber');

    // Update choice to obtain pbdf.pbdf.mobilenumber.
    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 1));
    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, false);
    expect(issueWizardBlocState.candidates.keys, [0, 1, 2]);
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    expect(issueWizardBlocState.selectedConIndices[2], 1);

    // Start obtaining pbdf.pbdf.mobilenumber.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.mobilenumber');
    await _issueCredential(repo, mockBridge, 45, [
      {
        'pbdf.pbdf.mobilenumber.mobilenumber': TextValue.fromString('+31612345678'),
      }
    ]);

    // The issue wizard should be completed now, because the second candidate contains the same credential type.
    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    expect(issueWizardBlocState.isCompleted, true);

    // Finish issue wizard.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    DisclosurePermissionChoicesOverview choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, false);
    expect(choicesOverviewBlocState.optionalChoices, {});
    expect(choicesOverviewBlocState.requiredChoices.keys, [0, 1, 2]);
    expect(choicesOverviewBlocState.requiredChoices[0]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0], isA<ChoosableDisclosureCredential>());
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].value.raw, 'example.com');
    expect(choicesOverviewBlocState.requiredChoices[1]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[1]?[0], isA<ChoosableDisclosureCredential>());
    expect(choicesOverviewBlocState.requiredChoices[1]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[1]?[0].attributes[0].value.raw, 'test@example.com');
    expect(choicesOverviewBlocState.requiredChoices[2]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[2]?[0], isA<ChoosableDisclosureCredential>());
    expect(choicesOverviewBlocState.requiredChoices[2]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[2]?[0].attributes[0].value.raw, '+31612345678');

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, true);

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

    final obtainCredentialsController = StreamController<String>.broadcast();
    final bloc = DisclosurePermissionBloc(
      sessionID: 42,
      repo: repo,
      onObtainCredential: (credType) => obtainCredentialsController.add(credType.fullId),
    );
    repo.dispatch(
      NewSessionEvent(sessionID: 42, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, false);
    expect(issueWizardBlocState.candidates.keys, [0, 1]);
    expect(issueWizardBlocState.getSelectedCon(0)?.length, 1);
    expect(issueWizardBlocState.getSelectedCon(0)?[0].fullId, 'pbdf.pbdf.surfnet-2');
    expect(issueWizardBlocState.getSelectedCon(0)?[0].attributes.length, 1);
    expect(issueWizardBlocState.getSelectedCon(0)?[0].attributes[0].attributeType.fullId, 'pbdf.pbdf.surfnet-2.id');
    expect(issueWizardBlocState.getSelectedCon(1)?.length, 1);
    expect(issueWizardBlocState.getSelectedCon(1)?[0].fullId, 'pbdf.pbdf.surfnet-2');
    expect(issueWizardBlocState.getSelectedCon(1)?[0].attributes.length, 1);
    expect(issueWizardBlocState.getSelectedCon(1)?[0].attributes[0].attributeType.fullId, 'pbdf.pbdf.surfnet-2.email');

    bloc.add(DisclosurePermissionNextPressed());

    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.surfnet-2');
    await _issueCredential(repo, mockBridge, 43, [
      {
        'pbdf.pbdf.surfnet-2.id': TextValue.fromString('12345'),
        'pbdf.pbdf.surfnet-2.email': TextValue.fromString('test@example.com'),
      }
    ]);

    // The issue wizard should be completed now, because the second candidate contains the same credential type.
    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, true);

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    DisclosurePermissionChoicesOverview choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.requiredChoices.keys, [0, 1]);

    // Try to change the choice for the first discon.
    bloc.add(DisclosurePermissionChangeChoicePressed(disconIndex: 0));

    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    DisclosurePermissionChangeChoice changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 0);
    expect(changeChoiceBlocState.selectedConIndex, 0);
    expect(changeChoiceBlocState.templateCons.keys, [1]);

    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 1));

    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 0);
    expect(changeChoiceBlocState.selectedConIndex, 1);

    bloc.add(DisclosurePermissionNextPressed());

    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.surfnet-2');
    await _issueCredential(repo, mockBridge, 44, [
      {
        'pbdf.pbdf.surfnet-2.id': TextValue.fromString('54321'),
        'pbdf.pbdf.surfnet-2.email': TextValue.fromString('test2@example.com'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionChangeChoice>());
    changeChoiceBlocState = bloc.state as DisclosurePermissionChangeChoice;
    expect(changeChoiceBlocState.disconIndex, 0);
    expect(changeChoiceBlocState.selectedConIndex, 1);
    expect(changeChoiceBlocState.selectedCon.length, 1);
    expect(changeChoiceBlocState.selectedCon[0].fullId, 'pbdf.pbdf.surfnet-2');
    expect(changeChoiceBlocState.selectedCon[0].attributes.length, 1);
    expect(changeChoiceBlocState.selectedCon[0].attributes[0].value.raw, '54321');

    // Check whether the credential we added in the issue wizard is still selected in the second discon.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, false);
    expect(choicesOverviewBlocState.optionalChoices, {});
    expect(choicesOverviewBlocState.requiredChoices.keys, [0, 1]);
    expect(choicesOverviewBlocState.requiredChoices[0]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].value.raw, '54321');
    expect(choicesOverviewBlocState.requiredChoices[1]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[1]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[1]?[0].attributes[0].value.raw, 'test@example.com');

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, true);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(42).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('optional-attributes', () async {
    await _issueCredential(repo, mockBridge, 42, [
      {
        'pbdf.pbdf.surfnet-2.id': TextValue.fromString('12345'),
        'pbdf.pbdf.surfnet-2.email': TextValue.fromString('test@example.com'),
      }
    ]);

    // Optionally, disclose your mobile number and/or email address.
    mockBridge.mockDisclosureSession(43, [
      [
        {},
        {
          'pbdf.pbdf.mobilenumber.mobilenumber': null,
        },
      ],
      [
        {},
        {
          'pbdf.pbdf.email.email': null,
        },
        {
          'pbdf.pbdf.surfnet-2.email': null,
        },
      ],
    ]);

    final obtainCredentialsController = StreamController<String>.broadcast();
    final bloc = DisclosurePermissionBloc(
      sessionID: 43,
      repo: repo,
      onObtainCredential: (credType) => obtainCredentialsController.add(credType.fullId),
    );
    repo.dispatch(
      NewSessionEvent(sessionID: 43, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    DisclosurePermissionChoicesOverview choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, false);
    expect(choicesOverviewBlocState.requiredChoices, {});
    expect(choicesOverviewBlocState.optionalChoices, {});
    expect(choicesOverviewBlocState.hasAdditionalOptionalChoices, true);

    bloc.add(DisclosurePermissionAddOptionalDataPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionAddOptionalData>());
    DisclosurePermissionAddOptionalData addOptionalDataBlocState = bloc.state as DisclosurePermissionAddOptionalData;
    expect(addOptionalDataBlocState.choosableCons.keys, [1]);
    expect(addOptionalDataBlocState.choosableCons[1]?.length, 1);
    expect(addOptionalDataBlocState.choosableCons[1]?[0].credentialHash, 'session-42-0');
    expect(addOptionalDataBlocState.templateCons.keys, [0, 2, 3]);
    expect(addOptionalDataBlocState.selectedConIndex, 1);

    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 0));
    expect(await bloc.stream.first, isA<DisclosurePermissionAddOptionalData>());
    addOptionalDataBlocState = bloc.state as DisclosurePermissionAddOptionalData;
    expect(addOptionalDataBlocState.selectedConIndex, 0);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.mobilenumber');
    await _issueCredential(repo, mockBridge, 44, [
      {
        'pbdf.pbdf.mobilenumber.mobilenumber': TextValue.fromString('+31612345678'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionAddOptionalData>());
    addOptionalDataBlocState = bloc.state as DisclosurePermissionAddOptionalData;
    expect(addOptionalDataBlocState.choosableCons.keys, [0, 2]);
    expect(addOptionalDataBlocState.choosableCons[0]?.length, 1);
    expect(addOptionalDataBlocState.choosableCons[0]?[0].credentialHash, 'session-44-0');
    expect(addOptionalDataBlocState.choosableCons[2]?.length, 1);
    expect(addOptionalDataBlocState.choosableCons[2]?[0].credentialHash, 'session-42-0');
    expect(addOptionalDataBlocState.templateCons.keys, [1, 3, 4]);
    expect(addOptionalDataBlocState.selectedConIndex, 0);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, false);
    expect(choicesOverviewBlocState.requiredChoices, {});
    expect(choicesOverviewBlocState.optionalChoices.keys, [0]);
    expect(choicesOverviewBlocState.optionalChoices[0]?.length, 1);
    expect(choicesOverviewBlocState.optionalChoices[0]?[0].fullId, 'pbdf.pbdf.mobilenumber');
    expect(choicesOverviewBlocState.optionalChoices[0]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.optionalChoices[0]?[0].attributes[0].value.raw, '+31612345678');

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, true);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(43).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('optional-attributes-mix', () async {
    await _issueCredential(repo, mockBridge, 42, [
      {
        'pbdf.pbdf.surfnet-2.id': TextValue.fromString('12345'),
        'pbdf.pbdf.surfnet-2.email': TextValue.fromString('test@example.com'),
      }
    ]);

    // Optionally, disclose your mobile number and/or email address.
    mockBridge.mockDisclosureSession(43, [
      [
        {
          'pbdf.pbdf.mobilenumber.mobilenumber': null,
        },
      ],
      [
        {},
        {
          'pbdf.pbdf.email.email': null,
        },
        {
          'pbdf.pbdf.surfnet-2.email': null,
        },
      ],
    ]);

    final obtainCredentialsController = StreamController<String>.broadcast();
    final bloc = DisclosurePermissionBloc(
      sessionID: 43,
      repo: repo,
      onObtainCredential: (credType) => obtainCredentialsController.add(credType.fullId),
    );
    repo.dispatch(
      NewSessionEvent(sessionID: 43, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.candidates.keys, [0]);
    expect(issueWizardBlocState.candidates[0]!.length, 1);
    expect(issueWizardBlocState.candidates[0]![0].length, 1);
    expect(issueWizardBlocState.candidates[0]![0][0].fullId, 'pbdf.pbdf.mobilenumber');

    bloc.add(DisclosurePermissionNextPressed());
    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.mobilenumber');
    await _issueCredential(repo, mockBridge, 44, [
      {
        'pbdf.pbdf.mobilenumber.mobilenumber': TextValue.fromString('+31612345678'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, true);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionPreviouslyAddedCredentialsOverview>());
    DisclosurePermissionPreviouslyAddedCredentialsOverview prevAddedCredsBlocState =
        bloc.state as DisclosurePermissionPreviouslyAddedCredentialsOverview;
    expect(prevAddedCredsBlocState.requiredChoices, {});
    expect(prevAddedCredsBlocState.optionalChoices, {});
    expect(prevAddedCredsBlocState.hasAdditionalOptionalChoices, true);

    bloc.add(DisclosurePermissionAddOptionalDataPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionAddOptionalData>());
    DisclosurePermissionAddOptionalData addOptionalDataBlocState = bloc.state as DisclosurePermissionAddOptionalData;
    expect(addOptionalDataBlocState.choosableCons.keys, [0]);
    expect(addOptionalDataBlocState.choosableCons[0]?.length, 1);
    expect(addOptionalDataBlocState.choosableCons[0]?[0].credentialHash, 'session-42-0');
    expect(addOptionalDataBlocState.templateCons.keys, [1, 2]);
    expect(addOptionalDataBlocState.selectedConIndex, 0);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionPreviouslyAddedCredentialsOverview>());
    prevAddedCredsBlocState = bloc.state as DisclosurePermissionPreviouslyAddedCredentialsOverview;
    expect(prevAddedCredsBlocState.requiredChoices, {});
    expect(prevAddedCredsBlocState.optionalChoices.keys, [1]);
    expect(prevAddedCredsBlocState.optionalChoices[1]?.length, 1);
    expect(prevAddedCredsBlocState.optionalChoices[1]?[0].fullId, 'pbdf.pbdf.surfnet-2');
    expect(prevAddedCredsBlocState.optionalChoices[1]?[0].attributes.length, 1);
    expect(prevAddedCredsBlocState.optionalChoices[1]?[0].attributes[0].value.raw, 'test@example.com');

    // Check whether we can remove the optional choice again.
    bloc.add(DisclosurePermissionRemoveOptionalDataPressed(disconIndex: 1));
    expect(await bloc.stream.first, isA<DisclosurePermissionPreviouslyAddedCredentialsOverview>());
    prevAddedCredsBlocState = bloc.state as DisclosurePermissionPreviouslyAddedCredentialsOverview;
    expect(prevAddedCredsBlocState.requiredChoices, {});
    expect(prevAddedCredsBlocState.optionalChoices, {});

    bloc.add(DisclosurePermissionAddOptionalDataPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionAddOptionalData>());
    addOptionalDataBlocState = bloc.state as DisclosurePermissionAddOptionalData;
    expect(addOptionalDataBlocState.selectedConIndex, 0);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionPreviouslyAddedCredentialsOverview>());
    prevAddedCredsBlocState = bloc.state as DisclosurePermissionPreviouslyAddedCredentialsOverview;
    expect(prevAddedCredsBlocState.requiredChoices, {});
    expect(prevAddedCredsBlocState.optionalChoices.keys, [1]);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    DisclosurePermissionChoicesOverview choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, false);
    expect(choicesOverviewBlocState.requiredChoices.keys, [0]);
    expect(choicesOverviewBlocState.requiredChoices[0]!.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]![0].credentialHash, 'session-44-0');
    expect(choicesOverviewBlocState.optionalChoices.keys, [1]);
    expect(choicesOverviewBlocState.optionalChoices[1]!.length, 1);
    expect(choicesOverviewBlocState.optionalChoices[1]![0].credentialHash, 'session-42-0');

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, true);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(43).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('recalculate-planned-steps', () async {
    // Ensure email credential is already present to make sure we have both a con with and without
    // previously added credentials. In this case, the planned steps should be recalculated when changing choices.
    await _issueCredential(repo, mockBridge, 42, [
      {
        'pbdf.sidn-pbdf.irma.pseudonym': TextValue.fromString('12345'),
      }
    ]);

    // Disclosure either (irma pseudonym, city and email) or (mobile number).
    mockBridge.mockDisclosureSession(43, [
      [
        {
          'pbdf.sidn-pbdf.irma.pseudonym': null,
          'pbdf.gemeente.address.city': null,
          'pbdf.pbdf.email.email': null,
        },
        {
          'pbdf.pbdf.mobilenumber.mobilenumber': null,
        },
      ],
    ]);

    final obtainCredentialsController = StreamController<String>.broadcast();
    final bloc = DisclosurePermissionBloc(
      sessionID: 43,
      repo: repo,
      onObtainCredential: (credType) => obtainCredentialsController.add(credType.fullId),
    );
    repo.dispatch(
      NewSessionEvent(sessionID: 43, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, false);
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.previouslyAddedCredentialsOverview,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    expect(issueWizardBlocState.candidates.keys, [0]);
    expect(issueWizardBlocState.candidates[0]?.length, 2);
    expect(issueWizardBlocState.candidates[0]?[0].length, 2);
    expect(issueWizardBlocState.candidates[0]?[0][0].fullId, 'pbdf.gemeente.address');
    expect(issueWizardBlocState.candidates[0]?[0][1].fullId, 'pbdf.pbdf.email');
    expect(issueWizardBlocState.selectedConIndices[0], 0);

    // Change choice to test whether the planned steps are correctly being recalculated.
    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 1));

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, false);
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    expect(issueWizardBlocState.selectedConIndices[0], 1);

    // Switch back to test whether plannedSteps changes back.
    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 0));

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, false);
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.previouslyAddedCredentialsOverview,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    expect(issueWizardBlocState.selectedConIndices[0], 0);

    bloc.add(DisclosurePermissionChoiceUpdated(conIndex: 1));
    bloc.add(DisclosurePermissionNextPressed());

    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.mobilenumber');
    await _issueCredential(repo, mockBridge, 44, [
      {
        'pbdf.pbdf.mobilenumber.mobilenumber': TextValue.fromString('+31612345678'),
      }
    ]);

    // The issue wizard should be completed now.
    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.candidates.keys, [0]);
    expect(issueWizardBlocState.candidates[0]?.length, 2);
    expect(issueWizardBlocState.candidates[0]?[0].length, 2);
    expect(issueWizardBlocState.candidates[0]?[1].length, 1);
    expect(issueWizardBlocState.isCompleted, true);

    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    DisclosurePermissionChoicesOverview choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    expect(choicesOverviewBlocState.requiredChoices.keys, [0]);
    expect(choicesOverviewBlocState.requiredChoices[0]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].credentialType.fullId, 'pbdf.pbdf.mobilenumber');
    expect(choicesOverviewBlocState.showConfirmationPopup, false);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, true);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(43).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('single-discon-complex-inner-con', () async {
    // Ensure we already have irma pseudonym.
    await _issueCredential(repo, mockBridge, 42, [
      {
        'pbdf.sidn-pbdf.irma.pseudonym': TextValue.fromString('12345'),
      }
    ]);

    // Ensure we already have surfnet id.
    await _issueCredential(repo, mockBridge, 43, [
      {
        'pbdf.pbdf.surfnet-2.id': TextValue.fromString('12345'),
        'pbdf.pbdf.surfnet-2.email': TextValue.fromString('test@example.com'),
      }
    ]);

    // Disclosure either (irma pseudonym, city and mobile number) or (surfnet id and city).
    mockBridge.mockDisclosureSession(44, [
      [
        {
          'pbdf.sidn-pbdf.irma.pseudonym': null,
          'pbdf.gemeente.address.city': null,
          'pbdf.pbdf.mobilenumber.mobilenumber': null,
        },
        {
          'pbdf.pbdf.surfnet-2.id': null,
          'pbdf.gemeente.address.city': null,
        },
      ],
    ]);

    final obtainCredentialsController = StreamController<String>.broadcast();
    final bloc = DisclosurePermissionBloc(
      sessionID: 44,
      repo: repo,
      onObtainCredential: (credType) => obtainCredentialsController.add(credType.fullId),
    );
    repo.dispatch(
      NewSessionEvent(sessionID: 44, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    DisclosurePermissionIssueWizard issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, false);
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.previouslyAddedCredentialsOverview,
      DisclosurePermissionStepName.choicesOverview,
    ]);
    expect(issueWizardBlocState.candidates.keys, [0]);
    expect(issueWizardBlocState.candidates[0]?.length, 2);
    expect(issueWizardBlocState.candidates[0]?[0].length, 2);
    expect(issueWizardBlocState.candidates[0]?[0][0].fullId, 'pbdf.gemeente.address');
    expect(issueWizardBlocState.candidates[0]?[0][1].fullId, 'pbdf.pbdf.mobilenumber');
    expect(issueWizardBlocState.candidates[0]?[1].length, 1);
    expect(issueWizardBlocState.candidates[0]?[0][0].fullId, 'pbdf.gemeente.address');
    expect(issueWizardBlocState.selectedConIndices[0], 0);

    // Press next to start obtaining all credentials.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionObtainCredentials>());
    DisclosurePermissionObtainCredentials obtainCredsBlocState = bloc.state as DisclosurePermissionObtainCredentials;
    expect(obtainCredsBlocState.templates.length, 2);
    expect(obtainCredsBlocState.templates[0].fullId, 'pbdf.gemeente.address');
    expect(obtainCredsBlocState.obtained[0], false);
    expect(obtainCredsBlocState.templates[1].fullId, 'pbdf.pbdf.mobilenumber');
    expect(obtainCredsBlocState.obtained[1], false);

    bloc.add(DisclosurePermissionNextPressed());

    expect(await obtainCredentialsController.stream.first, 'pbdf.gemeente.address');
    await _issueCredential(repo, mockBridge, 45, [
      {
        'pbdf.gemeente.address.street': TextValue.fromString('Beukenlaan'),
        'pbdf.gemeente.address.houseNumber': TextValue.fromString('1'),
        'pbdf.gemeente.address.city': TextValue.fromString('Amsterdam'),
        'pbdf.gemeente.address.municipality': TextValue.fromString('Amsterdam'),
        'pbdf.gemeente.address.zipcode': TextValue.fromString('1000AA'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionObtainCredentials>());
    obtainCredsBlocState = bloc.state as DisclosurePermissionObtainCredentials;
    expect(obtainCredsBlocState.templates.length, 2);
    expect(obtainCredsBlocState.templates[0].fullId, 'pbdf.gemeente.address');
    expect(obtainCredsBlocState.obtained[0], true);
    expect(obtainCredsBlocState.templates[1].fullId, 'pbdf.pbdf.mobilenumber');
    expect(obtainCredsBlocState.obtained[1], false);

    bloc.add(DisclosurePermissionNextPressed());

    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.mobilenumber');
    await _issueCredential(repo, mockBridge, 46, [
      {
        'pbdf.pbdf.mobilenumber.mobilenumber': TextValue.fromString('+31612345678'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionObtainCredentials>());
    obtainCredsBlocState = bloc.state as DisclosurePermissionObtainCredentials;
    expect(obtainCredsBlocState.allObtained, true);

    // Go back to IssueWizard state.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, true);
    expect(issueWizardBlocState.plannedSteps, [
      DisclosurePermissionStepName.issueWizard,
      DisclosurePermissionStepName.previouslyAddedCredentialsOverview,
      DisclosurePermissionStepName.choicesOverview,
    ]);

    // Continue to previously added credentials phase.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionPreviouslyAddedCredentialsOverview>());
    final prevAddedCredsBlocState = bloc.state as DisclosurePermissionPreviouslyAddedCredentialsOverview;
    expect(
      prevAddedCredsBlocState.plannedSteps,
      contains(DisclosurePermissionStepName.previouslyAddedCredentialsOverview),
    );
    expect(prevAddedCredsBlocState.requiredChoices.keys, [0]);
    expect(prevAddedCredsBlocState.requiredChoices[0]?.length, 1);
    expect(prevAddedCredsBlocState.requiredChoices[0]?[0].fullId, 'pbdf.sidn-pbdf.irma');
    expect(prevAddedCredsBlocState.requiredChoices[0]?[0].attributes.length, 1);
    expect(prevAddedCredsBlocState.requiredChoices[0]?[0].attributes[0].value.raw, '12345');

    // Continue to choices overview.
    bloc.add(DisclosurePermissionNextPressed());

    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    DisclosurePermissionChoicesOverview choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.requiredChoices.keys, [0]);
    expect(choicesOverviewBlocState.requiredChoices[0]?.length, 3);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].credentialType.fullId, 'pbdf.sidn-pbdf.irma');
    expect(choicesOverviewBlocState.requiredChoices[0]?[1].credentialType.fullId, 'pbdf.gemeente.address');
    expect(choicesOverviewBlocState.requiredChoices[0]?[2].credentialType.fullId, 'pbdf.pbdf.mobilenumber');
    expect(choicesOverviewBlocState.showConfirmationPopup, false);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.showConfirmationPopup, true);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionFinished>());
    await repo.getSessionState(44).firstWhere((session) => session.status == SessionStatus.success);
  });

  test('multiple-credentials-issued', () async {
    // Disclosure email address and mobile number
    mockBridge.mockDisclosureSession(42, [
      [
        {
          'pbdf.pbdf.mobilenumber.mobilenumber': null,
        },
      ],
      [
        {
          'pbdf.pbdf.surfnet-2.id': null,
        },
        {
          'pbdf.pbdf.email.email': null,
        },
      ],
    ]);

    final obtainCredentialsController = StreamController<String>.broadcast();
    final bloc = DisclosurePermissionBloc(
      sessionID: 42,
      repo: repo,
      onObtainCredential: (credType) => obtainCredentialsController.add(credType.fullId),
    );
    repo.dispatch(
      NewSessionEvent(sessionID: 42, request: SessionPointer(irmaqr: 'disclosing', u: '')),
      isBridgedEvent: true,
    );

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());

    bloc.add(DisclosurePermissionNextPressed());
    expect(await obtainCredentialsController.stream.first, 'pbdf.pbdf.mobilenumber');
    await _issueCredential(repo, mockBridge, 43, [
      {
        'pbdf.pbdf.mobilenumber.mobilenumber': TextValue.fromString('+31612345678'),
      },
      {
        'pbdf.pbdf.email.email': TextValue.fromString('test@example.com'),
        'pbdf.pbdf.email.domain': TextValue.fromString('example.com'),
      }
    ]);

    expect(await bloc.stream.first, isA<DisclosurePermissionIssueWizard>());
    final issueWizardBlocState = bloc.state as DisclosurePermissionIssueWizard;
    expect(issueWizardBlocState.isCompleted, true);

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());
    final choicesOverviewBlocState = bloc.state as DisclosurePermissionChoicesOverview;
    expect(choicesOverviewBlocState.requiredChoices.length, 2);
    expect(choicesOverviewBlocState.requiredChoices[0]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[0]?[0].attributes[0].value.raw, '+31612345678');
    expect(choicesOverviewBlocState.requiredChoices[1]?.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[1]?[0].attributes.length, 1);
    expect(choicesOverviewBlocState.requiredChoices[1]?[0].attributes[0].value.raw, 'test@example.com');

    bloc.add(DisclosurePermissionNextPressed());
    expect(await bloc.stream.first, isA<DisclosurePermissionChoicesOverview>());

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
