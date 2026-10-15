import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../disclosure_session/disclosure_helpers.dart";

/// Opens the Change sheet of requested item [item] on the share screen.
Future<void> tapChangeChoicesButton(WidgetTester tester, [int item = 0]) =>
    changeChoice(tester, item);

/// The index in the first key on screen that starts with [prefix], e.g.
/// `share_add_optional_` → the requested item that row adds. The order of
/// the requested items follows irmago's plan, so tests look it up.
int keyIndex(WidgetTester tester, String prefix) {
  final widgets = tester
      .widgetList(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(prefix),
          skipOffstage: false,
        ),
      )
      .toList();
  expect(widgets, isNotEmpty, reason: "a widget keyed '$prefix…'");
  final key = widgets.first.key! as ValueKey<String>;
  return int.parse(key.value.substring(prefix.length));
}

/// The "In your app" rows of the open sheet that show [text].
Finder sheetOwnedRowsWith(String text) => findSheetOwnedRowShowing(text);

/// Checks that the open Change sheet lists exactly [count] cards from the
/// app and nothing to add: OID4VCI types have no IssueURL, so irmago sends
/// no obtainable options for them.
void expectOnlyOwnedInSheet(int count) {
  expect(findSheetOwnedRows(), findsNWidgets(count));
  expect(find.text("Not in your app yet"), findsNothing);
  expect(
    find.descendant(
      of: findChoiceSheet(),
      matching: find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith("sheet_add_"),
      ),
    ),
    findsNothing,
  );
}
