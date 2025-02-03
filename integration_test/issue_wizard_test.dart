import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/issue_wizard_success_screen.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/wizard_scaffold.dart';
import 'package:irmamobile/src/widgets/collapsible.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';
import 'package:irmamobile/src/widgets/irma_markdown.dart';
import 'package:irmamobile/src/widgets/irma_stepper.dart';
import 'package:irmamobile/src/widgets/requestor_header.dart';
import 'package:irmamobile/src/widgets/session_progress_indicator.dart';

import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('issue-wizard', (() {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('issue-wizard', (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      await irmaBinding.repository.startTestIssueWizard(
        'irma-demo-requestors.ivido.demo-client',
      );

      // This takes quite some time
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Expect the issue wizard
      expect(find.byType(WizardScaffold), findsOneWidget);

      // Expect to find the header
      final headerFinder = find.byType(IssueWizardRequestorHeader);
      expect(headerFinder, findsOneWidget);

      // Expect the header with the right text
      expect(
        find.descendant(
          of: headerFinder,
          matching: find.text('Ivido PHE'),
        ),
        findsOneWidget,
      );

      // Expect the right background color from Ivido
      final headerWidget = headerFinder.evaluate().first.widget as IssueWizardRequestorHeader;
      expect(headerWidget.backgroundColor, const Color(0xffe7dffe));

      // Test the questions and answers
      final qAndAs = {
        'Which data are added?':
            'You retrieve your personal data. You need this data to show who you are. That way only you can log in on your account.',
        'Where do you get the data?':
            'You retrieve your personal data from the dutch personal records database ("Basis Registratie Personen", BRP). You log in with DigiD at the municipality of Nijmegen. Even if you live in another city. Nijmegen offers this service for everyone with a DigiD.',
        'How does it work?':
            'Your login data are stored only in your IRMA app on your phone. To log in at Ivido you show who you are with your IRMA app.',
        'What is Ivido?':
            'Ivido is a Personal Health Environment (PHE, dutch: PHO). In Ivido you can store everything about your healt. You choose yourself with who you share this data. You use IRMA to register and log in at Ivido.',
      };

      // There should be a collapsible card for every expected q and a item.
      final collapsiblesFinder = find.byType(Collapsible);
      expect(collapsiblesFinder, findsNWidgets(qAndAs.length));

      for (var i = 0; i < qAndAs.entries.length; i++) {
        final qAndAEntry = qAndAs.entries.elementAt(i);
        final question = qAndAEntry.key;
        final answer = qAndAEntry.value;

        // Find the specific collapsible which we are checking this iteration.
        final collapsibleFinder = collapsiblesFinder.at(i);
        expect(collapsibleFinder, findsOneWidget);

        // Somehow there are two scrollables on the screen, we need to target the last one when scrolling.
        final lastScrollableFinder = find.byType(Scrollable).last;

        await tester.scrollUntilVisible(
          collapsibleFinder,
          100,
          scrollable: lastScrollableFinder,
        );

        // Expect the question text to be present on this collapsible
        final questionFinder = find.descendant(
          of: collapsibleFinder,
          matching: find.text(question).hitTestable(),
        );
        expect(questionFinder, findsOneWidget);

        // Unfold answer.
        await tester.tapAndSettle(questionFinder);

        // The collapsible should have IrmaMarkdown as content
        final markDownFinder = find.descendant(
          of: collapsibleFinder,
          matching: find.byType(IrmaMarkdown),
        );
        expect(markDownFinder, findsOneWidget);

        // Because markdown is hard to test we compare the expected markdown with the markdown in the widget
        // Note: This does not check the actual text on the screen!
        final markdownWidget = markDownFinder.evaluate().first.widget as IrmaMarkdown;
        expect(markdownWidget.data, answer);

        // Fold answer again.
        await tester.tapAndSettle(questionFinder);
      }

      // Go to the actual issue wizard
      await tester.tapAndSettle(find.text('Add'));

      // Check the progress indicator
      final progressIndicatorFinder = find.byType(SessionProgressIndicator);
      expect(
        find.descendant(
          of: progressIndicatorFinder,
          matching: find.text('Step 1 of 2'),
        ),
        findsOneWidget,
      );

      // Expect stepper with two cards
      final stepperFinder = find.byType(IrmaStepper);
      expect(stepperFinder, findsOneWidget);

      final stepperCardsFinder = find.descendant(
        of: stepperFinder,
        matching: find.byType(IrmaCard),
      );
      expect(stepperCardsFinder, findsNWidgets(2));

      // Expect the right content on the first card
      expect(
        tester.getAllText(stepperCardsFinder.first),
        [
          'Demo Personal data',
          'Retrieve your personal data from the dutch personal records database ("Basis Registratie Personen", BRP). You do this with DigiD. You need this information to show who you are.',
        ],
      );

      // Expect the right content on the second card
      expect(
        tester.getAllText(stepperCardsFinder.at(1)),
        [
          'Demo Ivido Login',
          'Retrieve your Ivido login pass. This way you can log at Ivido in easily and safely.',
        ],
      );

      // Retrieve the demo personal data
      await issueMunicipalityPersonalData(
        tester,
        irmaBinding,
        continueOnSecondDevice: false,
      );

      // Check the progress indicator again
      expect(
        find.descendant(
          of: progressIndicatorFinder,
          matching: find.text('Step 2 of 2'),
        ),
        findsOneWidget,
      );

      // Issue the Ivido login card.
      await issueDemoIvidoLogin(
        tester,
        irmaBinding,
        continueOnSecondDevice: false,
      );

      // Press OK and complete the issue wizard
      await tester.tapAndSettle(find.text('OK'));

      // Expect success screen
      final successScreenFinder = find.byType(IssueWizardSuccessScreen);
      expect(successScreenFinder, findsOneWidget);

      // Expect the correct text on the success screen
      expect(find.text('Done!'), findsOneWidget);
      // The english content text is in dutch too for this demo issue wizard
      expect(find.text('Je kunt nu inloggen bij Ivido.'), findsOneWidget);

      await tester.tapAndSettle(find.text('OK'));
      expect(find.byType(WizardScaffold), findsNothing);
    });
  }));
}
