import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/screens/session/widgets/issue_sheet_progress.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/theme/yivi_palette.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";
import "package:yivi_core/src/widgets/glass/pill_buttons.dart";
import "package:yivi_core/src/widgets/glass/sheet_action_row.dart";

import "helpers/test_translation_loader.dart";
import "support/pump_translated.dart";

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: TestTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("en", "US"),
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

final _shop = TrustedParty(
  id: "webshop",
  name: "Webshop Noord",
  url: null,
  parent: null,
  verified: true,
);

void main() {
  group("SheetActionRow", () {
    // A phone held upright: sideways the row puts its button at the right
    // (see the landscape tests).
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
    });
    tearDown(
      () => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        ..resetPhysicalSize()
        ..resetDevicePixelRatio(),
    );

    testWidgets("two buttons are equally wide and equally tall", (
      tester,
    ) async {
      var cancelled = 0, added = 0;
      await pumpTranslated(
        tester,
        _wrap(
          SheetActionRow(
            secondaryLabel: "Cancel",
            onSecondary: () => cancelled++,
            primaryLabel: "Add",
            onPrimary: () => added++,
          ),
        ),
      );
      final secondary = tester.getSize(find.byType(PillButton));
      final primary = tester.getSize(find.byType(FancyPillButton));
      expect(secondary.width, primary.width);
      expect(secondary.height, SheetActionRow.height);
      expect(primary.height, SheetActionRow.height);

      await tester.tap(find.byType(PillButton));
      await tester.tap(find.byType(FancyPillButton));
      expect((cancelled, added), (1, 1));
    });

    testWidgets("a label that wraps makes both taller, not one", (
      tester,
    ) async {
      await pumpTranslated(
        tester,
        _wrap(
          SheetActionRow(
            secondaryLabel: "Cancel",
            onSecondary: () {},
            primaryLabel: "Add Personal data to my Yivi-app",
            onPrimary: () {},
          ),
        ),
      );
      final secondary = tester.getSize(find.byType(PillButton));
      final primary = tester.getSize(find.byType(FancyPillButton));
      expect(primary.height, greaterThan(SheetActionRow.height));
      expect(secondary.height, primary.height);
    });

    testWidgets("a single button takes the whole width", (tester) async {
      await pumpTranslated(
        tester,
        _wrap(SheetActionRow(primaryLabel: "Back", onPrimary: () {})),
      );
      // 400 wide test screen, 16 padding on both sides.
      expect(
        tester.getSize(find.byType(FancyPillButton)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio - 32,
      );
    });
  });

  group("IssueSheetProgress", () {
    // A phone held upright (sideways, who it is for goes under the bar's
    // title: see the first test).
    setUp(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
    });
    tearDown(
      () => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        ..resetPhysicalSize()
        ..resetDevicePixelRatio(),
    );

    testWidgets(
      "sideways: the line, and who it is for once (under the title)",
      (tester) async {
        tester.view.physicalSize = const Size(874, 402);
        await pumpTranslated(
          tester,
          _wrap(
            Column(
              children: [
                IssueSheetProgress(
                  subject: IssueSheetSubject.request(_shop),
                  step: 2,
                  total: 4,
                ),
                IssueSheetRequestorLine(
                  subject: IssueSheetSubject.request(_shop),
                ),
              ],
            ),
          ),
        );
        // No count to read; screen readers hear it.
        expect(find.text("2 of 4"), findsNothing);
        expect(
          tester
              .getSize(find.byKey(const Key("issue_sheet_progress_line")))
              .height,
          3,
        );
        expect(find.bySemanticsLabel("Step 2 of 4"), findsOneWidget);
        // Who it is for: once, the line for under the bar's title.
        expect(find.text("For Webshop Noord"), findsOneWidget);
      },
    );

    testWidgets("says who it is for and which step", (tester) async {
      await pumpTranslated(
        tester,
        _wrap(
          IssueSheetProgress(
            subject: IssueSheetSubject.request(_shop),
            step: 2,
          ),
        ),
      );
      expect(find.text("For Webshop Noord"), findsOneWidget);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 2, 3))),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel("Step 2 of 3"), findsOneWidget);
    });

    /// The filled part of the line: its colour and how much of it.
    (Color, double) line(WidgetTester tester) {
      // The top page's bar: while pages change the one under it is there too.
      final bar = find.byKey(const Key("issue_sheet_progress_line")).last;
      final fill = tester.widget<FractionallySizedBox>(
        find.descendant(of: bar, matching: find.byType(FractionallySizedBox)),
      );
      final ink = tester.widget<ColoredBox>(
        find.descendant(of: bar, matching: find.byType(ColoredBox)).last,
      );
      return (ink.color, fill.widthFactor!);
    }

    testWidgets("green up to the step during a request", (tester) async {
      await pumpTranslated(
        tester,
        _wrap(
          IssueSheetProgress(
            subject: IssueSheetSubject.request(_shop),
            step: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final (ink, part) = line(tester);
      expect(ink, YiviPalette.light.successText);
      expect(part, closeTo(2 / 3, 0.001));
    });

    testWidgets("done: the whole line green", (tester) async {
      await pumpTranslated(
        tester,
        _wrap(
          IssueSheetProgress(
            subject: IssueSheetSubject.request(_shop),
            step: 3,
            done: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Done"), findsNothing);
      expect(find.bySemanticsLabel("All steps done"), findsOneWidget);
      expect(line(tester), (YiviPalette.light.successText, 1.0));
    });

    testWidgets("the next step's line fills on from where the last stood", (
      tester,
    ) async {
      late StateSetter setStep;
      var step = 1;
      await pumpTranslated(
        tester,
        _wrap(
          SizedBox(
            height: 300,
            child: StatefulBuilder(
              builder: (context, setState) {
                setStep = setState;
                return GlassSheetPages(
                  onBack: () {},
                  pages: [
                    for (var s = 1; s <= step; s++)
                      GlassSheetPage(
                        key: ValueKey(s),
                        title: "Step $s",
                        pinned: IssueSheetProgress(
                          subject: IssueSheetSubject.request(_shop),
                          step: s,
                        ),
                        child: const SizedBox(height: 40),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      setStep(() => step = 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Half way from step 1 to step 2.
      final part = line(tester).$2;
      expect(part, greaterThan(1 / 3));
      expect(part, lessThan(2 / 3));
      await tester.pumpAndSettle();
      expect(line(tester).$2, closeTo(2 / 3, 0.001));
    });
  });
}
