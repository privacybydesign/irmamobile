import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../disclosure_helpers.dart";

// Checks on the rows of the open Change sheet, for the filled-app and
// special scenarios.

/// The "In your app" row of the open sheet that shows [text].
Finder sheetOwnedRowWith(String text) => findSheetOwnedRowShowing(text);

/// Whether the "In your app" [row] is the selected one (its radio).
bool sheetRowSelected(WidgetTester tester, Finder row) {
  // One card and nothing else to pick: no radio, it is the one in use.
  final radios = find.descendant(
    of: row,
    matching: find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.selected != null,
    ),
    matchRoot: true,
  );
  if (radios.evaluate().isEmpty) {
    return findSheetOwnedRows().evaluate().length == 1;
  }
  final semantics = tester
      .widgetList<Semantics>(
        find.descendant(
          of: row,
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.selected != null,
          ),
          matchRoot: true,
        ),
      )
      .first;
  return semantics.properties.selected!;
}

/// Checks the open sheet: the "In your app" rows showing [owned] (in order,
/// the [selected] one picked) and, when given, exactly the "Not in your app
/// yet" rows for [addable] credential ids.
void expectSheet(
  WidgetTester tester, {
  required List<String> owned,
  String? selected,
  List<String>? addable,
}) {
  expect(findChoiceSheet(), findsOneWidget);
  expect(findSheetOwnedRows(), findsNWidgets(owned.length));
  for (final text in owned) {
    final row = sheetOwnedRowWith(text);
    expect(row, findsOneWidget, reason: "sheet row with '$text'");
    if (selected != null) {
      expect(
        sheetRowSelected(tester, row),
        text == selected,
        reason: "row '$text' selected",
      );
    }
  }
  if (addable == null) return;
  // One add link ("＋ Add another card") can add several types.
  for (final id in addable) {
    expect(findSheetAddRow(id), findsOneWidget, reason: "add row for $id");
  }
  final offered = {
    for (final e
        in find
            .descendant(
              of: findChoiceSheet(),
              matching: find.byWidgetPredicate(
                (w) =>
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.startsWith("sheet_add_"),
              ),
            )
            .evaluate())
      ...(e.widget.key! as ValueKey<String>).value.substring(10).split("+"),
  };
  expect(offered, unorderedEquals(addable));
}
