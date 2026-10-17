import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/screens/session/widgets/issue_sheet_progress.dart";
import "package:yivi_core/src/theme/theme.dart";
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
        _wrap(IssueSheetProgress(subject: IssueSheetSubject.request(_shop), step: 2)),
      );
      expect(find.text("For Webshop Noord"), findsOneWidget);
      expect(find.text("2 of 3"), findsOneWidget);
      expect(find.bySemanticsLabel("Step 2 of 3"), findsOneWidget);
    });

    testWidgets("done: all steps green and 'Done'", (tester) async {
      await pumpTranslated(
        tester,
        _wrap(IssueSheetProgress(subject: IssueSheetSubject.request(_shop), step: 3, done: true)),
      );
      expect(find.text("Done"), findsOneWidget);
      expect(find.bySemanticsLabel("All steps done"), findsOneWidget);
      final colors = [
        for (var i = 1; i <= 3; i++)
          ((tester
                      .widget<AnimatedContainer>(
                        find.byKey(Key("issue_sheet_progress_$i")),
                      )
                      .decoration!
                  as BoxDecoration)
              .color),
      ];
      expect(colors.toSet(), hasLength(1));
    });
  });
}
