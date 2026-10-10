import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/enrollment/accept_terms/widgets/error_reporting_check_box.dart";
import "package:yivi_core/src/screens/enrollment/accept_terms/widgets/terms_check_box.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

import "support/onboarding_v2_harness.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;
  late IrmaRepository repo;

  setUp(() async {
    prefs = await freshPreferences();
    repo = IrmaRepository(client: RecordingBridge(), preferences: prefs);
  });

  tearDown(() => repo.close());

  final termsCheckbox = find.byKey(const Key("accept_terms_checkbox"));
  final errorCheckbox = find.byKey(const Key("error_reporting_checkbox"));

  group("terms checkbox", () {
    Future<void> pumpTerms(
      WidgetTester tester, {
      Locale locale = const Locale("en", "US"),
    }) => pumpHome(
      tester,
      repo: repo,
      locale: locale,
      home: TermsCheckBox(isAccepted: false, onToggleAccepted: (_) {}),
    );

    testWidgets("flag off: no asterisk, label unchanged", (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTerms(tester);

      expect(find.text("*"), findsNothing);
      expect(
        tester.getSemantics(termsCheckbox).label,
        "Yes, I accept the terms and conditions",
      );

      handle.dispose();
    });

    testWidgets("flag on: red asterisk before the label", (tester) async {
      await setOnboardingV2(prefs, on: true);
      await pumpTerms(tester);
      await settle(tester);

      final asterisk = find.text("*");
      expect(asterisk, findsOneWidget);
      expect(tester.widget<Text>(asterisk).style!.color, IrmaThemeData().error);
      expect(
        tester.getTopLeft(asterisk).dx,
        lessThan(tester.getTopLeft(find.textContaining("Yes, I accept")).dx),
      );
    });

    testWidgets("flag on: a screen reader hears that it is required", (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setOnboardingV2(prefs, on: true);
      await pumpTerms(tester);
      await settle(tester);

      expect(
        tester.getSemantics(termsCheckbox).label,
        "Yes, I accept the terms and conditions, required",
      );
      // The asterisk is decoration: it must not be read as "asterisk".
      expect(find.semantics.byLabel("*"), findsNothing);

      handle.dispose();
    });

    testWidgets("flag on: required is spoken in Dutch", (tester) async {
      final handle = tester.ensureSemantics();
      await setOnboardingV2(prefs, on: true);
      await pumpTerms(tester, locale: const Locale("nl", "NL"));
      await settle(tester);

      expect(
        tester.getSemantics(termsCheckbox).label,
        "Ja, ik ga akkoord met de algemene voorwaarden, verplicht",
      );

      handle.dispose();
    });
  });

  group("error reporting checkbox", () {
    const shareErrors = "Share error messages and app status";

    Future<void> pumpErrorReporting(WidgetTester tester) =>
        pumpHome(tester, repo: repo, home: ErrorReportingCheckBox());

    testWidgets("flag off: keeps the bold Optional prefix", (tester) async {
      final handle = tester.ensureSemantics();
      await pumpErrorReporting(tester);

      expect(find.textContaining("Optional", findRichText: true), findsOne);
      expect(
        tester.getSemantics(errorCheckbox).label,
        "Optional: $shareErrors with Yivi",
      );

      handle.dispose();
    });

    testWidgets("flag on: no Optional prefix, seen or heard", (tester) async {
      final handle = tester.ensureSemantics();
      await setOnboardingV2(prefs, on: true);
      await pumpErrorReporting(tester);
      await settle(tester);

      expect(find.textContaining("Optional", findRichText: true), findsNothing);
      expect(
        tester.getSemantics(errorCheckbox).label,
        "$shareErrors with Yivi",
      );

      handle.dispose();
    });

    group("info sheet", () {
      const title = "Error and app status reporting";

      // Phone width: on the default test surface the sheet is capped at its
      // maximum width and centered, which hides the padding.
      void usePhoneScreen(WidgetTester tester) {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
      }

      Future<void> openSheet(WidgetTester tester) async {
        await tester.tapOnText(find.textRange.ofSubstring(shareErrors));
        await tester.pumpAndSettle();
      }

      double leftOf(WidgetTester tester, Finder finder) =>
          tester.getTopLeft(finder).dx;

      final explanation = find.textContaining("By enabling error reporting");

      testWidgets("flag off: 16 px from the side", (tester) async {
        usePhoneScreen(tester);
        await pumpErrorReporting(tester);

        await openSheet(tester);

        expect(leftOf(tester, find.text(title)), 16);
        expect(leftOf(tester, explanation), 16);
      });

      testWidgets("flag on: 24 px from the side", (tester) async {
        usePhoneScreen(tester);
        await setOnboardingV2(prefs, on: true);
        await pumpErrorReporting(tester);
        await settle(tester);

        await openSheet(tester);

        expect(leftOf(tester, find.text(title)), 24);
        expect(leftOf(tester, explanation), 24);
        expect(tester.getTopRight(explanation).dx, 400 - 24);
      });

      testWidgets("flag on: the close button is on the title's line", (
        tester,
      ) async {
        usePhoneScreen(tester);
        await setOnboardingV2(prefs, on: true);
        await pumpErrorReporting(tester);
        await settle(tester);

        await openSheet(tester);

        final titleBox = tester.getRect(find.text(title));
        final closeBox = tester.getRect(find.byType(IrmaCloseButton));
        expect(closeBox.left, greaterThan(titleBox.left));
        expect(closeBox.top, lessThan(titleBox.bottom));
        expect(closeBox.bottom, greaterThan(titleBox.top));
      });
    });
  });
}
