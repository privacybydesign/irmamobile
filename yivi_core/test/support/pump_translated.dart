import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";

/// Pumps [widget] and waits for its locale files to load.
///
/// FileTranslationLoader reads the locale JSON with real IO, and Flutter
/// decodes files over 50 KB in an isolate. Neither is driven by the test
/// framework's fake clock, so without a real delay Localizations never
/// rebuilds and the tree stays empty.
Future<void> pumpTranslated(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pump();
}
