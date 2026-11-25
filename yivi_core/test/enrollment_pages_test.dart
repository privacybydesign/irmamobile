import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/back_to_website/back_to_website_screen.dart";
import "package:yivi_core/src/screens/enrollment/biometric/enrollment_biometric_screen.dart";
import "package:yivi_core/src/screens/enrollment/done/enrollment_done_page.dart";
import "package:yivi_core/src/screens/enrollment/error_reports/enrollment_error_reports_screen.dart";
import "package:yivi_core/src/screens/enrollment/pin/enrollment_pin_page.dart";
import "package:yivi_core/src/screens/enrollment/terms/enrollment_terms_screen.dart";
import "package:yivi_core/src/screens/enrollment/welcome/welcome_screen.dart";
import "package:yivi_core/src/screens/enrollment/widgets/enrollment_actions.dart";
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
      testWidgets("$name: both documents, and Accept and continue", (
        tester,
      ) async {
        _device(tester, size, padding);
        var accepted = 0;
        await pumpHome(
          tester,
          repo: repo,
          home: EnrollmentTermsScreen(
            actions: EnrollmentStepActions(
              primary: "Accept and continue",
              primaryKey: const Key("enrollment_terms_continue"),
              onPrimary: () => accepted++,
            ),
          ),
        );
        await settle(tester);

        expect(find.text("Before you start"), findsOneWidget);
        expect(find.byKey(const Key("enrollment_terms_open")), findsOneWidget);
        expect(
          find.byKey(const Key("enrollment_privacy_open")),
          findsOneWidget,
        );
        expect(find.byKey(const Key("enrollment_terms_agree")), findsOneWidget);
        // No checkbox: the tap on the button is the agreement.
        expect(find.byType(Checkbox), findsNothing);

        final go = find.byKey(const Key("enrollment_terms_continue"));
        await tester.ensureVisible(go);
        await tester.pump();
        await tester.tap(go);
        expect(accepted, 1);
      });
    }

    for (final (row, sheet) in [
      ("enrollment_terms_open", "legal_sheet_terms"),
      ("enrollment_privacy_open", "legal_sheet_privacy"),
    ]) {
      testWidgets("$row opens the document in short, and the full text", (
        tester,
      ) async {
        final (size, padding) = _sizes["phone upright"]!;
        _device(tester, size, padding);
        await pumpHome(
          tester,
          repo: repo,
          home: EnrollmentTermsScreen(
            actions: EnrollmentStepActions(primary: "Go", onPrimary: () {}),
          ),
        );
        await settle(tester);

        await tester.tap(find.byKey(Key(row)));
        await settle(tester);
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byKey(Key(sheet)), findsOneWidget);
        expect(find.text("In short"), findsOneWidget);
        expect(find.byKey(const Key("enrollment_sheet_hero")), findsOneWidget);
        expect(find.byKey(const Key("legal_sheet_read_full")), findsOneWidget);
      });
    }
  });

  group("error reports", () {
    for (final MapEntry(key: name, value: (size, padding)) in _sizes.entries) {
      testWidgets("$name: Don't share and Share reports side by side", (
        tester,
      ) async {
        _device(tester, size, padding);
        final answers = <bool>[];
        await pumpHome(
          tester,
          repo: repo,
          home: EnrollmentErrorReportsScreen(
            actions: EnrollmentStepActions(
              primary: "Share reports",
              primaryKey: const Key("error_reports_share"),
              onPrimary: () => answers.add(true),
              secondary: "Don't share",
              secondaryKey: const Key("error_reports_dont_share"),
              onSecondary: () => answers.add(false),
            ),
          ),
        );
        await settle(tester);

        expect(find.text("Help improve Yivi?"), findsOneWidget);
        final share = find.byKey(const Key("error_reports_share"));
        final dontShare = find.byKey(const Key("error_reports_dont_share"));
        await tester.ensureVisible(share);
        await tester.pump();
        expect(
          tester.getCenter(dontShare).dx,
          lessThan(tester.getCenter(share).dx),
        );
        expect(
          tester.getCenter(dontShare).dy,
          moreOrLessEquals(tester.getCenter(share).dy),
        );
        await tester.tap(dontShare);
        await tester.tap(share);
        expect(answers, [false, true]);
      });
    }
  });

  testWidgets("Help improve Yivi? shows what is sent on the page", (
    tester,
  ) async {
    final (size, padding) = _sizes["phone upright"]!;
    _device(tester, size, padding);
    await pumpHome(
      tester,
      repo: repo,
      home: EnrollmentErrorReportsScreen(
        actions: EnrollmentStepActions(primary: "Share", onPrimary: () {}),
      ),
    );
    await settle(tester);
    expect(find.byKey(const Key("error_reports_points")), findsOneWidget);
    expect(find.text("When something goes wrong"), findsOneWidget);
    expect(find.text("Now and then, its status"), findsOneWidget);
    expect(find.text("Never your data"), findsOneWidget);
    expect(find.text("What is sent?"), findsNothing);
  });

  group("PIN", () {
    /// The PIN page as the enrollment has it: choose, then the same again.
    Future<(List<String>, ValueGetter<String?>)> pumpPinPage(
      WidgetTester tester, {
      bool short = true,
    }) async {
      final confirmed = <String>[];
      String? chosen;
      await pumpHome(
        tester,
        repo: repo,
        home: StatefulBuilder(
          builder: (context, setState) => EnrollmentPinPage(
            chosen: chosen,
            onChosen: (pin) => setState(() => chosen = pin),
            onConfirmed: confirmed.add,
            onMismatch: () => setState(() => chosen = null),
          ),
        ),
      );
      // The long-PIN preference streams in; a long PIN is the default.
      await settle(tester);
      if (short) {
        await tester.tap(find.text("Prefer a shorter PIN?"));
        await settle(tester);
      }
      return (confirmed, () => chosen);
    }

    Future<void> type(WidgetTester tester, String digits) async {
      for (final d in digits.split("")) {
        await tester.tap(find.byKey(Key("number_pad_key_$d")));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets("the chosen PIN moves up, grey, and the same again confirms", (
      tester,
    ) async {
      final (size, padding) = _sizes["phone upright"]!;
      _device(tester, size, padding);
      final (confirmed, chosen) = await pumpPinPage(tester);

      await type(tester, "58193");
      await settle(tester);
      expect(chosen(), "58193");
      expect(find.byKey(const Key("pin_chosen_row")), findsOneWidget);
      expect(find.text("Enter the same PIN again"), findsOneWidget);

      await type(tester, "58193");
      expect(confirmed, ["58193"]);
    });

    testWidgets("a different PIN says so in place, then choosing starts over", (
      tester,
    ) async {
      final (size, padding) = _sizes["phone upright"]!;
      _device(tester, size, padding);
      final (confirmed, chosen) = await pumpPinPage(tester);

      await type(tester, "58193");
      await settle(tester);
      await type(tester, "58194");
      expect(find.byKey(const Key("pin_again_error")), findsOneWidget);
      expect(confirmed, isEmpty);
      expect(chosen(), "58193");

      await tester.pump(const Duration(milliseconds: 1500));
      await settle(tester);
      expect(chosen(), isNull);
      expect(find.byKey(const Key("pin_chosen_row")), findsNothing);
      expect(find.text("Choose a 5-digit PIN"), findsOneWidget);
    });

    testWidgets("a PIN that is possibly not secure waits for the arrow", (
      tester,
    ) async {
      final (size, padding) = _sizes["phone upright"]!;
      _device(tester, size, padding);
      final (_, chosen) = await pumpPinPage(tester);

      await type(tester, "12345");
      await settle(tester);
      expect(chosen(), isNull);
      expect(
        find.textContaining("This PIN is possibly not secure."),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key("pin_next")));
      await settle(tester);
      expect(chosen(), "12345");
      expect(find.byKey(const Key("pin_chosen_row")), findsOneWidget);
    });

    testWidgets("a long PIN goes on by the arrow, its second entry by itself", (
      tester,
    ) async {
      final (size, padding) = _sizes["phone upright"]!;
      _device(tester, size, padding);
      final (confirmed, chosen) = await pumpPinPage(tester, short: false);

      await type(tester, "582917");
      expect(find.text("At least 6 digits"), findsOneWidget);
      expect(chosen(), isNull);
      await tester.tap(find.byKey(const Key("pin_next")));
      await settle(tester);
      expect(chosen(), "582917");
      expect(find.byKey(const Key("pin_chosen_row")), findsOneWidget);
      // As many empty slots as the chosen PIN, before the first digit.
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(ValueKey("pin_dot_$i")), findsOneWidget);
      }
      expect(find.byKey(const ValueKey("pin_dot_6")), findsNothing);

      // Full, it is checked.
      await type(tester, "582917");
      expect(confirmed, ["582917"]);
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
        await pumpPinPage(tester);

        final title = tester.getRect(find.textContaining("Choose a"));
        final key = tester.getRect(find.text("1"));
        if (size.width > size.height) {
          expect(key.left, greaterThan(title.right));
        } else {
          expect(key.top, greaterThan(title.bottom));
        }
      });
    }
  });

  group("done", () {
    for (final ready in [false, true]) {
      testWidgets("ready ${ready ? "from the start" : "later"}: setting up, "
          "then You're all set", (tester) async {
        final (size, padding) = _sizes["phone upright"]!;
        _device(tester, size, padding);
        var isReady = ready;
        var shown = false;
        late StateSetter set;
        await pumpHome(
          tester,
          repo: repo,
          home: StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return shown
                  ? EnrollmentDonePage(ready: isReady)
                  : const SizedBox();
            },
          ),
        );
        // Shown after the harness has loaded, as it comes after a step.
        set(() => shown = true);
        await tester.pump();
        expect(find.text("Setting up your app"), findsOneWidget);
        if (!ready) {
          await tester.pump(const Duration(seconds: 2));
          expect(find.text("Setting up your app"), findsOneWidget);
          set(() => isReady = true);
        }
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text("You’re all set"), findsOneWidget);
        expect(
          find.text("Your app is ready, and protected with your PIN."),
          findsOneWidget,
        );
      });
    }
  });

  group("Face ID", () {
    for (final MapEntry(key: name, value: (size, padding)) in _sizes.entries) {
      testWidgets("$name: Not now and Use, side by side", (tester) async {
        _device(tester, size, padding);
        final answers = <bool>[];
        await pumpHome(
          tester,
          repo: repo,
          overrides: [biometricTypeProvider.overrideWith((ref) async => null)],
          home: EnrollmentBiometricScreen(
            actions: EnrollmentStepActions(
              primary: "Use fingerprint",
              primaryKey: const Key("biometric_enable"),
              onPrimary: () => answers.add(true),
              secondary: "Not now",
              secondaryKey: const Key("biometric_not_now"),
              onSecondary: () => answers.add(false),
            ),
          ),
        );
        await tester.pump();

        expect(find.text("Open Yivi with your fingerprint?"), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key("biometric_not_now")));
        await tester.pump();
        await tester.tap(find.byKey(const Key("biometric_not_now")));
        expect(answers, [false]);
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
