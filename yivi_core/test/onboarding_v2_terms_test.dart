import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/enrollment/accept_terms/accept_terms_screen.dart";
import "package:yivi_core/src/screens/enrollment/accept_terms/widgets/error_reporting_check_box.dart";
import "package:yivi_core/src/screens/enrollment/accept_terms/widgets/terms_check_box.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";

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
      await enableOnboardingV2(prefs);
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
      await enableOnboardingV2(prefs);
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

    testWidgets("flag on: bold asterisk, label 12 px after the box", (
      tester,
    ) async {
      await enableOnboardingV2(prefs);
      await pumpTerms(tester);
      await settle(tester);

      final style = tester.widget<Text>(find.text("*")).style!;
      expect(style.fontWeight, FontWeight.bold);
      expect(tester.getSize(find.byType(Checkbox)), const Size(24, 24));
      // The box is 22 px in a 24 px slot, so the slot ends 12 px - 1 px
      // before the asterisk.
      expect(tester.getTopLeft(find.text("*")).dx, 24 + 10);
    });

    testWidgets("flag on: the box has a grey 2 px border once scaled", (
      tester,
    ) async {
      await enableOnboardingV2(prefs);
      await pumpTerms(tester);
      await settle(tester);

      final side = WidgetStateProperty.resolveAs<BorderSide?>(
        tester.widget<Checkbox>(termsCheckbox).side,
        <WidgetState>{},
      )!;
      expect(side.width * 22 / 18, closeTo(2, 0.001));
      expect(side.color, IrmaThemeData().neutralDark);
    });

    testWidgets("flag off: asterisk-free row keeps the Material checkbox", (
      tester,
    ) async {
      await pumpTerms(tester);

      expect(tester.getSize(find.byType(Checkbox)), const Size(48, 48));
    });

    testWidgets("flag on: required is spoken in Dutch", (tester) async {
      final handle = tester.ensureSemantics();
      await enableOnboardingV2(prefs);
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
      await enableOnboardingV2(prefs);
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
      const oldTitle = "Error and app status reporting";
      const title = shareErrors;
      const phone = Size(400, 800);

      Future<void> openSheet(WidgetTester tester) async {
        await tester.tapOnText(find.textRange.ofSubstring(shareErrors));
        await tester.pumpAndSettle();
      }

      double leftOf(WidgetTester tester, Finder finder) =>
          tester.getTopLeft(finder).dx;

      final oldExplanation = find.textContaining("By enabling error reporting");
      final explanation = find.textContaining(
        "By sending the error messages to us automatically",
      );

      testWidgets("flag off: the old sheet, 16 px from the side", (
        tester,
      ) async {
        usePhoneScreen(tester, size: phone);
        await pumpErrorReporting(tester);

        await openSheet(tester);

        expect(leftOf(tester, find.text(oldTitle)), 16);
        expect(leftOf(tester, oldExplanation), 16);
      });

      testWidgets("flag on: title and text 24 px from the side", (
        tester,
      ) async {
        usePhoneScreen(tester, size: phone);
        await enableOnboardingV2(prefs);
        await pumpErrorReporting(tester);
        await settle(tester);

        await openSheet(tester);

        expect(leftOf(tester, find.text(title)), 24);
        expect(leftOf(tester, explanation), 24);
        expect(tester.getTopRight(explanation).dx, 400 - 24);
        expect(find.text(oldTitle), findsNothing);
      });

      testWidgets("flag on: the title is 18 px bold, text 16 px", (
        tester,
      ) async {
        usePhoneScreen(tester, size: phone);
        await enableOnboardingV2(prefs);
        await pumpErrorReporting(tester);
        await settle(tester);

        await openSheet(tester);

        final titleStyle = tester.widget<Text>(find.text(title)).style!;
        expect(titleStyle.fontSize, 18);
        expect(titleStyle.fontWeight, FontWeight.w700);
        expect(titleStyle.height, 26 / 18);
        // Three lines of 26 px.
        expect(tester.getSize(find.text(title)).height, 3 * 26);
        expect(tester.getSize(explanation).height, greaterThan(24 * 3));
        expect(tester.widget<Text>(explanation).style?.fontSize, isNull);
      });

      testWidgets("flag on: a white sheet with a 16 px corner and a handle", (
        tester,
      ) async {
        usePhoneScreen(tester, size: phone);
        await enableOnboardingV2(prefs);
        await pumpErrorReporting(tester);
        await settle(tester);

        await openSheet(tester);

        final sheet = tester
            .widgetList<DecoratedBox>(
              find.ancestor(
                of: find.text(title),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((box) => box.decoration)
            .whereType<BoxDecoration>()
            .firstWhere((decoration) => decoration.borderRadius != null);
        expect(sheet.color, IrmaThemeData().light);
        expect(
          sheet.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(16)),
        );

        final handle = find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == 40,
        );
        expect(tester.getSize(handle), const Size(40, 4));
        expect(tester.getCenter(handle).dx, 200);
      });

      testWidgets("flag on: the barrier is black at 45 percent", (
        tester,
      ) async {
        usePhoneScreen(tester, size: phone);
        await enableOnboardingV2(prefs);
        await pumpErrorReporting(tester);
        await settle(tester);

        await openSheet(tester);

        final barrier = tester.widget<ModalBarrier>(
          find.byType(ModalBarrier).last,
        );
        expect(barrier.color!.a, closeTo(0.45, 0.001));
        expect(barrier.color!.withValues(alpha: 1), Colors.black);
      });

      testWidgets("flag on: the close button is on the title's line", (
        tester,
      ) async {
        usePhoneScreen(tester, size: phone);
        await enableOnboardingV2(prefs);
        await pumpErrorReporting(tester);
        await settle(tester);

        await openSheet(tester);

        final titleBox = tester.getRect(find.text(title));
        final closeBox = tester.getRect(find.bySemanticsLabel("Close"));
        expect(closeBox.size, const Size(44, 44));
        expect(closeBox.left, greaterThan(titleBox.left));
        expect(closeBox.top, lessThan(titleBox.bottom));
        expect(closeBox.bottom, greaterThan(titleBox.top));
        // It reaches 12 px into the side padding.
        expect(closeBox.right, 400 - 24 + 12);
        expect(find.byType(IrmaCloseButton), findsNothing);
      });

      testWidgets("flag on: the close button closes the sheet", (tester) async {
        usePhoneScreen(tester, size: phone);
        await enableOnboardingV2(prefs);
        await pumpErrorReporting(tester);
        await settle(tester);
        await openSheet(tester);

        await tester.tap(find.bySemanticsLabel("Close"));
        await tester.pumpAndSettle();

        expect(find.text(title), findsNothing);
      });

      testWidgets("flag on: the Dutch sheet has the words of the design", (
        tester,
      ) async {
        usePhoneScreen(tester, size: phone);
        await enableOnboardingV2(prefs);
        await pumpHome(
          tester,
          repo: repo,
          home: ErrorReportingCheckBox(),
          locale: const Locale("nl", "NL"),
        );
        await settle(tester);

        await tester.tapOnText(
          find.textRange.ofSubstring("Foutmeldingen en app status delen"),
        );
        await tester.pumpAndSettle();

        expect(find.text("Foutmeldingen en app status delen"), findsOneWidget);
        expect(
          find.text(
            "Door de foutmeldingen automatisch naar ons door te sturen kunnen we problemen sneller verhelpen. Ook stuurt de app periodiek een melding of alles nog goed werkt. Natuurlijk doen we dat allemaal zonder toegang te hebben tot je persoonlijke gegevens of transacties.",
          ),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel("Sluiten"), findsOneWidget);
      });
    });
  });

  group("AcceptTermsScreen", () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      Locale locale = const Locale("nl", "NL"),
    }) async {
      usePhoneScreen(tester);
      await pumpHome(
        tester,
        repo: repo,
        locale: locale,
        home: AcceptTermsScreen(
          isAccepted: false,
          onToggleAccepted: (_) {},
          onContinue: () {},
          onPrevious: () {},
        ),
      );
      await settle(tester);
    }

    final previous = find.byKey(const Key("enrollment_previous_button"));
    final next = find.byKey(const Key("enrollment_next_button"));
    final firstPoint = find.text(
      "Jij bepaalt wat je opslaat, wat je deelt en met wie.",
    );

    testWidgets("flag on: title and text 12 px apart, as in the design", (
      tester,
    ) async {
      await enableOnboardingV2(prefs);
      await pumpScreen(tester);

      final title = tester.getRect(find.text("Onze waarden"));
      expect(title.left, 24);
      expect(title.top, 48);
      expect(
        tester.getTopLeft(find.textContaining("Met Yivi pak jij")).dy,
        title.bottom + 12,
      );
    });

    testWidgets("flag off: title and text stay 24 px apart", (tester) async {
      await pumpScreen(tester);

      final title = tester.getRect(find.text("Onze waarden"));
      expect(
        tester.getTopLeft(find.textContaining("Met Yivi pak jij")).dy,
        title.bottom + 24,
      );
    });

    testWidgets("flag on: points start 58 px in with a 22 px check", (
      tester,
    ) async {
      await enableOnboardingV2(prefs);
      await pumpScreen(tester);

      expect(tester.getTopLeft(firstPoint).dx, 58);
      final checks = findSvg("ui/onboarding_check.svg");
      expect(checks, findsNWidgets(3));
      expect(tester.getSize(checks.first), const Size(22, 22));
      expect(tester.getTopLeft(checks.first).dx, 24);

      final style = tester.widget<Text>(firstPoint).style!;
      expect(style.fontWeight, FontWeight.w600);
      expect(style.color, IrmaThemeData().dark);
    });

    testWidgets("flag on: points are 16 px apart", (tester) async {
      await enableOnboardingV2(prefs);
      await pumpScreen(tester);

      final points = tester
          .widgetList<Text>(find.byType(Text))
          .where((text) => text.style?.fontWeight == FontWeight.w600);
      expect(points, hasLength(3));
      final rects = [
        for (final point in points) tester.getRect(find.byWidget(point)),
      ];
      expect(rects[1].top - rects[0].bottom, 16);
      expect(rects[2].top - rects[1].bottom, 16);
    });

    testWidgets("flag on: the points say what the design says in nl", (
      tester,
    ) async {
      await enableOnboardingV2(prefs);
      await pumpScreen(tester);

      expect(firstPoint, findsOneWidget);
      expect(
        find.text("Jouw gegevens staan alleen op je mobiel, wel zo veilig."),
        findsOneWidget,
      );
      expect(find.text("Niemand kijkt mee, ook Yivi niet!"), findsOneWidget);
    });

    testWidgets("flag on: the points say the same in en", (tester) async {
      await enableOnboardingV2(prefs);
      await pumpScreen(tester, locale: const Locale("en", "US"));

      expect(
        find.text("You decide what you store, what you share and with whom."),
        findsOneWidget,
      );
      expect(
        find.text("Your data is only on your phone, which is safer."),
        findsOneWidget,
      );
      expect(
        find.text("Nobody is watching along, not even Yivi!"),
        findsOneWidget,
      );
    });

    testWidgets("flag on: the points say the same in de", (tester) async {
      await enableOnboardingV2(prefs);
      await pumpScreen(tester, locale: const Locale("de", "DE"));

      expect(
        find.text(
          "Sie entscheiden, was Sie speichern, was Sie teilen und mit wem.",
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          "Ihre Daten befinden sich nur auf Ihrem Telefon, das ist sicherer.",
        ),
        findsOneWidget,
      );
    });

    testWidgets("flag off: the points keep the old copy", (tester) async {
      await pumpScreen(tester, locale: const Locale("en", "US"));

      expect(
        find.text("You decide what data you store, and what you share."),
        findsOneWidget,
      );
    });

    testWidgets("flag on: the labels are 16 px apart, 8 px above the bar", (
      tester,
    ) async {
      await enableOnboardingV2(prefs);
      await pumpScreen(tester);

      expect(tester.getCenter(termsCheckbox).dx, 24 + 12);
      expect(tester.getCenter(errorCheckbox).dx, 24 + 12);
      expect(tester.getSize(termsCheckbox), const Size(24, 24));

      final bar = tester.getRect(next);
      expect(
        tester
            .getBottomLeft(find.textContaining("met Yivi", findRichText: true))
            .dy,
        bar.top - 16 - 8,
      );
      expect(
        tester.getCenter(errorCheckbox).dy - tester.getCenter(termsCheckbox).dy,
        greaterThan(24 + 16),
      );
    });

    testWidgets("flag on: two 48 px buttons share the width", (tester) async {
      await enableOnboardingV2(prefs);
      await pumpScreen(tester);

      final back = tester.getRect(previous);
      final forward = tester.getRect(next);
      expect(back, const Rect.fromLTWH(24, 764, 163, 48));
      expect(forward, const Rect.fromLTWH(203, 764, 163, 48));
    });

    testWidgets("flag on: the outline is 1 px", (tester) async {
      await enableOnboardingV2(prefs);
      await pumpScreen(tester);

      expect(tester.widget<YiviThemedButton>(previous).outlineWidth, 1);
    });

    testWidgets("flag off: the buttons keep their size and gap", (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(tester.getSize(previous).height, 50);
      expect(tester.getRect(next).left - tester.getRect(previous).right, 8);
      expect(tester.widget<YiviThemedButton>(previous).outlineWidth, 1.7);
    });
  });
}
