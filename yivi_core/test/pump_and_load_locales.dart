import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";

/// Pumps [widget] and waits for its locale files to load.
///
/// `AssetBundle.loadString` decodes files over 50 KiB in an isolate, and
/// `FileTranslationLoader` reads the locale JSON with real IO. The fake clock
/// drives neither, so without `runAsync` and a real delay the tree stays empty.
Future<void> pumpAndLoadLocales(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}
