import "package:flutter_test/flutter_test.dart";

import "../../util.dart";

/// Scrolls to and taps the "Change choice" button on the disclosure overview.
Future<void> tapChangeChoicesButton(WidgetTester tester) async {
  final changeChoiceFinder = find.text("Change choice", skipOffstage: false);
  await tester.scrollUntilVisible(changeChoiceFinder, 100);
  await tester.tapAndSettle(changeChoiceFinder);
}
