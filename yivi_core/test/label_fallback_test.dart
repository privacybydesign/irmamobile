import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_change_page.dart";
import "package:yivi_core/src/widgets/buttons/pill_buttons.dart";

import "support/test_app.dart";

/// A label that names a card falls back to a generic one when it does not
/// fit on one line; screen readers hear the full label either way.
void main() {
  const full = "Demo E-mailadres toevoegen";
  const short = "Toevoegen";

  Future<void> pumpAt(WidgetTester tester, double width, Widget child) =>
      pumpTestApp(
        tester,
        Center(
          child: SizedBox(width: width, child: child),
        ),
        size: const Size(1200, 800),
      );

  group("PrimaryPillButton", () {
    Widget button() =>
        PrimaryPillButton(label: full, shortLabel: short, onPressed: () {});

    testWidgets("keeps the full label when it fits", (tester) async {
      await pumpAt(tester, 1100, button());
      expect(find.text(full), findsOneWidget);
      expect(find.text(short), findsNothing);
    });

    testWidgets("falls back when it does not fit", (tester) async {
      await pumpAt(tester, 300, button());
      expect(find.text(short), findsOneWidget);
      expect(find.text(full), findsNothing);
      expect(find.bySemanticsLabel(full), findsOneWidget);
    });

    testWidgets("without a short label: the full one", (tester) async {
      await pumpAt(
        tester,
        300,
        PrimaryPillButton(label: full, onPressed: () {}),
      );
      expect(find.text(full), findsOneWidget);
    });
  });

  group("ChangeLinkRow", () {
    Widget link() => ChangeLinkRow(
      label: full,
      shortLabel: short,
      disc: Icons.add_rounded,
      onTap: () {},
    );

    testWidgets("keeps the full label when it fits", (tester) async {
      await pumpAt(tester, 1100, link());
      expect(find.text(full), findsOneWidget);
    });

    testWidgets("falls back when it does not fit", (tester) async {
      await pumpAt(tester, 300, link());
      expect(find.text(short), findsOneWidget);
      expect(find.bySemanticsLabel(full), findsOneWidget);
    });
  });
}
