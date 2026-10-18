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
      expect(find.text("2 of 3"), findsOneWidget);
      expect(find.bySemanticsLabel("Step 2 of 3"), findsOneWidget);
    });

    /// The filled part of segment [i]: its colour and how much of it.
    (Color, double) segment(WidgetTester tester, int i) {
      // The top page's bar: while pages change the one under it is there too.
      final bar = find.byKey(Key("issue_sheet_progress_$i")).last;
      final fill = tester.widget<FractionallySizedBox>(
        find.descendant(of: bar, matching: find.byType(FractionallySizedBox)),
      );
      final ink = tester.widget<ColoredBox>(
        find.descendant(of: bar, matching: find.byType(ColoredBox)),
      );
      return (ink.color, fill.widthFactor!);
    }

    testWidgets("blue up to the step", (tester) async {
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
      final blue = YiviPalette.light.link;
      expect(segment(tester, 1), (blue, 1.0));
      expect(segment(tester, 2), (blue, 1.0));
      expect(segment(tester, 3).$2, 0.0);
    });

    testWidgets("done: all steps green and 'Done'", (tester) async {
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
      expect(find.text("Done"), findsOneWidget);
      expect(find.bySemanticsLabel("All steps done"), findsOneWidget);
      final green = YiviPalette.light.successText;
      for (var i = 1; i <= 3; i++) {
        expect(segment(tester, i), (green, 1.0));
      }
    });

    testWidgets("the next step's bar fills on from where the last stood", (
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
      // Half way from step 1 to step 2: the second segment is partly blue.
      final part = segment(tester, 2).$2;
      expect(part, greaterThan(0));
      expect(part, lessThan(1));
      await tester.pumpAndSettle();
      expect(segment(tester, 2).$2, 1.0);
    });
  });
}
