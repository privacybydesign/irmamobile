import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";

const _loadTimeout = Duration(seconds: 10);
const _pollInterval = Duration(milliseconds: 10);

/// Pumps [widget] and waits for its locale files to load.
///
/// FileTranslationLoader reads the locale JSON with real IO, and Flutter
/// decodes files over 50 KB in an isolate. Neither is driven by the test
/// framework's fake clock, so the test waits on the real clock, until
/// Localizations builds its child, for at most [_loadTimeout].
Future<void> pumpTranslated(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);

    final deadline = DateTime.now().add(_loadTimeout);
    while (!_localesLoaded(tester) && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_pollInterval);
      await tester.pump();
    }
  });
  await tester.pump();
}

// Until the delegates have loaded, Localizations builds an empty box instead
// of its child, so the Directionality it wraps its child in is missing.
bool _localesLoaded(WidgetTester tester) => tester.any(
  find.descendant(
    of: find.byType(Localizations).first,
    matching: find.byType(Directionality),
  ),
);
