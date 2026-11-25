import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/data/keyshare_email_link_api.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/providers/contact_issuance_provider.dart";
import "package:yivi_core/src/screens/back_to_website/back_to_website_screen.dart";
import "package:yivi_core/src/screens/enrollment/biometric/enrollment_biometric_screen.dart";
import "package:yivi_core/src/screens/enrollment/choose_pin/choose_pin_screen.dart";
import "package:yivi_core/src/screens/enrollment/confirm_pin/confirm_pin_screen.dart";
import "package:yivi_core/src/screens/enrollment/terms/enrollment_terms_screen.dart";
import "package:yivi_core/src/screens/enrollment/welcome/welcome_screen.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";
import "package:yivi_core/src/widgets/buttons/pill_buttons.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

import "support/onboarding_v2_harness.dart";

/// The four sizes of the design, with the safe areas of an iPhone 17 Pro and
/// an 11" iPad.
const _sizes = {
  "phone upright": (Size(390, 844), EdgeInsets.fromLTRB(0, 62, 0, 34)),
  "phone sideways": (Size(844, 390), EdgeInsets.fromLTRB(62, 0, 62, 21)),
  "tablet upright": (Size(820, 1180), EdgeInsets.fromLTRB(0, 24, 0, 20)),
  "tablet sideways": (Size(1180, 820), EdgeInsets.fromLTRB(0, 24, 0, 20)),
};

void _device(WidgetTester tester, Size size, EdgeInsets padding) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = FakeViewPadding(
    left: padding.left,
    top: padding.top,
    right: padding.right,
    bottom: padding.bottom,
  );
  addTearDown(tester.view.reset);
}

void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  group("welcome", () {
    for (final MapEntry(key: name, value: (size, padding)) in _sizes.entries) {
      testWidgets("$name: the cards, the title, and Get started", (
        tester,
      ) async {
        _device(tester, size, padding);
        var started = 0;
        await pumpHome(
          tester,
          repo: repo,
          home: WelcomeScreen(onContinue: () => started++),
        );
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(CredentialCardArt), findsNWidgets(3));
        expect(
          find.text("Your digital identity, safe on your phone"),
          findsOneWidget,
        );
        expect(find.text("Only on your phone"), findsOneWidget);
        // The terms are the next page.
        expect(find.byKey(const Key("accept_terms_checkbox")), findsNothing);

        final start = find.byKey(const Key("enrollment_next_button"));
        expect(tester.widget<PrimaryPillButton>(start).onPressed, isNotNull);
        await tester.ensureVisible(start);
        await tester.pump();
        await tester.tap(start);
        // The cards fly out first, then it goes on.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(started, 0);
        await tester.pump(const Duration(milliseconds: 300));
        expect(started, 1);
      });
    }
  });

  group("terms", () {
    for (final MapEntry(key: name, value: (size, padding)) in _sizes.entries) {
      testWidgets("$name: the terms in short, and Continue once accepted", (
        tester,
      ) async {
        _device(tester, size, padding);
        var accepted = false;
        var continued = 0;
        await pumpHome(
          tester,
          repo: repo,
          home: StatefulBuilder(
            builder: (context, setState) => EnrollmentTermsScreen(
              isAccepted: accepted,
              onToggleAccepted: (v) => setState(() => accepted = v),
              onContinue: () => continued++,
            ),
          ),
        );
        await settle(tester);

        expect(find.text("Before you start"), findsOneWidget);
        expect(find.text("Your PIN protects your data"), findsOneWidget);
        expect(
          find.byKey(const Key("enrollment_terms_read_full")),
          findsOneWidget,
        );

        final go = find.byKey(const Key("enrollment_terms_continue"));
        expect(tester.widget<PrimaryPillButton>(go).onPressed, isNull);

        // A small phone with large text scrolls the page down to the terms.
        await tester.runAsync(
          () => Scrollable.ensureVisible(
            tester.element(find.byKey(const Key("accept_terms_checkbox"))),
            alignment: 0.5,
          ),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key("accept_terms_checkbox")));
        await tester.pump();
        expect(tester.widget<PrimaryPillButton>(go).onPressed, isNotNull);
        await tester.tap(go);
        expect(continued, 1);
      });
    }
  });

  group("PIN", () {
    testWidgets("confirming a different PIN says so and sends nothing", (
      tester,
    ) async {
      final (size, padding) = _sizes["tablet upright"]!;
      _device(tester, size, padding);
      var mismatches = 0;
      final confirmed = <String>[];
      await pumpHome(
        tester,
        repo: repo,
        home: ConfirmPinScreen(
          stepLabel: "Step 2 of 3",
          submitConfirmationPin: confirmed.add,
          onPrevious: () {},
          newPinNotifier: ValueNotifier("58193"),
          onPinMismatch: () => mismatches++,
        ),
      );
      await settle(tester);
      Future<void> type(String digits) async {
        for (final d in digits.split("")) {
          await tester.tap(find.text(d));
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 300));
      }

      await type("58194");
      expect(mismatches, 1);
      expect(confirmed, isEmpty);
    });

    for (final name in [
      "tablet sideways",
      "phone sideways",
      "tablet upright",
    ]) {
      testWidgets("$name: the keypad beside the title only when sideways", (
        tester,
      ) async {
        final (size, padding) = _sizes[name]!;
        _device(tester, size, padding);
        await pumpHome(
          tester,
          repo: repo,
          home: ChoosePinScreen(
            stepLabel: "Step 1 of 3",
            onChoosePin: (_) {},
            onPrevious: () {},
            newPinNotifier: ValueNotifier(""),
          ),
        );
        // The long-PIN preference streams in.
        await settle(tester);

        final title = tester.getRect(find.textContaining("Choose a"));
        final key = tester.getRect(find.text("1"));
        if (size.width > size.height) {
          expect(key.left, greaterThan(title.right));
        } else {
          expect(key.top, greaterThan(title.bottom));
        }
        expect(find.text("Step 1 of 3"), findsOneWidget);
      });
    }
  });

  group("Face ID", () {
    for (final MapEntry(key: name, value: (size, padding)) in _sizes.entries) {
      testWidgets("$name: Not now declines and goes on", (tester) async {
        _device(tester, size, padding);
        var done = 0;
        await pumpHome(
          tester,
          repo: repo,
          overrides: [biometricTypeProvider.overrideWith((ref) async => null)],
          home: EnrollmentBiometricScreen(onDone: () => done++),
        );
        await tester.pump();

        expect(find.text("Open Yivi with your fingerprint?"), findsOneWidget);
        await tester.tap(find.byKey(const Key("biometric_not_now")));
        await settle(tester);

        expect(done, 1);
        expect(
          await tester.runAsync(
            () => repo.preferences.biometricPromptDismissed.stream.first,
          ),
          isTrue,
        );
      });
    }
  });

  group("back to the website", () {
    for (final MapEntry(key: name, value: (size, padding)) in _sizes.entries) {
      testWidgets("$name: the steps and a close button", (tester) async {
        _device(tester, size, padding);
        await pumpHome(tester, repo: repo, home: const BackToWebsiteScreen());
        await tester.pump();

        expect(find.text("Go back to the website"), findsOneWidget);
        expect(
          find.text(
            "Switch back to your browser, to the website that asked for Yivi.",
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key("back_to_website_close")), findsOneWidget);
      });
    }
  });
}
