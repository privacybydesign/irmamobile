import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/enrollment/accept_terms/accept_terms_screen.dart";
import "package:yivi_core/src/screens/enrollment/introduction/introduction_screen.dart";
import "package:yivi_core/src/screens/enrollment/introduction/models/introduction_entry.dart";
import "package:yivi_core/src/screens/enrollment/provide_email/email_sent_screen.dart";
import "package:yivi_core/src/screens/enrollment/provide_email/provide_email_screen.dart";
import "package:yivi_core/src/screens/splash_screen/splash_screen.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";
import "package:yivi_core/src/widgets/glass/pill_buttons.dart";

import "support/onboarding_v2_harness.dart";

void main() {
  late IrmaRepository repo;

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  group("introduction", () {
    testWidgets("the first step fans out example cards", (tester) async {
      phone(tester);
      await pumpHome(
        tester,
        repo: repo,
        home: IntroductionScreen(
          currentStepIndex: 0,
          entry: IntroductionEntry.returning,
          onContinue: () {},
          onPrevious: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CredentialCardArt), findsNWidgets(3));
      expect(
        find.text("Yivi is an app for your digital identity"),
        findsOneWidget,
      );
      expect(find.byKey(const Key("enrollment_next_button")), findsOneWidget);
      expect(find.byKey(const Key("enrollment_previous_button")), findsNothing);
    });

    testWidgets("the second step shows what is shared", (tester) async {
      phone(tester);
      var previous = 0;
      await pumpHome(
        tester,
        repo: repo,
        home: IntroductionScreen(
          currentStepIndex: 1,
          onContinue: () {},
          onPrevious: () => previous++,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("YOU SHARE ONLY"), findsOneWidget);
      expect(find.text("Over 18"), findsOneWidget);
      await tester.tap(find.byKey(const Key("enrollment_previous_button")));
      expect(previous, 1);
    });
  });

  testWidgets("terms: Next waits for the terms to be accepted", (tester) async {
    phone(tester);
    var accepted = false;
    await pumpHome(
      tester,
      repo: repo,
      home: StatefulBuilder(
        builder: (context, setState) => AcceptTermsScreen(
          isAccepted: accepted,
          onToggleAccepted: (value) => setState(() => accepted = value),
          onContinue: () {},
          onPrevious: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    FancyPillButton next() => tester.widget<FancyPillButton>(
      find.byKey(const Key("enrollment_next_button")),
    );
    expect(find.text("Our values"), findsOneWidget);
    expect(next().onPressed, isNull);

    await tester.tap(find.byKey(const Key("accept_terms_checkbox")));
    await tester.pumpAndSettle();
    expect(next().onPressed, isNotNull);
  });

  testWidgets("e-mail: an invalid address is called out", (tester) async {
    phone(tester);
    String? provided;
    await pumpHome(
      tester,
      repo: repo,
      home: ProvideEmailScreen(
        onEmailProvided: (email) => provided = email,
        onEmailSkipped: () {},
        onPrevious: () {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key("email_input_field")),
      "sanne@",
    );
    await tester.pump();
    expect(find.text("Invalid e-mail address"), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key("email_input_field")),
      "sanne@devries.example",
    );
    await tester.pump();
    expect(find.text("Invalid e-mail address"), findsNothing);
    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    expect(provided, "sanne@devries.example");
  });

  testWidgets("e-mail sent: shows the address and the sender", (tester) async {
    phone(tester);
    await pumpHome(
      tester,
      repo: repo,
      home: EmailSentScreen(email: "sanne@devries.example", onContinue: () {}),
    );
    await tester.pumpAndSettle();

    expect(find.text("sanne@devries.example"), findsOneWidget);
    expect(find.textContaining("noreply@mail.yivi.app"), findsOneWidget);
  });

  testWidgets("splash: the logo and the slogan", (tester) async {
    phone(tester);
    await pumpHome(tester, repo: repo, home: const SplashScreen());
    await tester.pumpAndSettle();
    expect(find.text("Everyone deserves privacy"), findsOneWidget);
  });

  // Overflows throw in widget tests, so pumping is the check.
  for (final size in const [Size(320, 568), Size(568, 320), Size(560, 820)]) {
    testWidgets("introduction and terms fit $size", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      for (var step = 0; step < 3; step++) {
        await pumpHome(
          tester,
          repo: repo,
          home: IntroductionScreen(
            currentStepIndex: step,
            onContinue: () {},
            onPrevious: () {},
          ),
        );
        await tester.pumpAndSettle();
      }
      await pumpHome(
        tester,
        repo: repo,
        home: AcceptTermsScreen(
          isAccepted: false,
          onToggleAccepted: (_) {},
          onContinue: () {},
          onPrevious: () {},
        ),
      );
      await tester.pumpAndSettle();
    });
  }
}
