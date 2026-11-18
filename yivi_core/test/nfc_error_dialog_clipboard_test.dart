import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/nfc_error_dialog.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

// The sensitive NFC logs hold chip data and the MRZ-derived inputs for the
// chip's access keys. The dialog may show them, but must never put them on the
// clipboard, where other apps can read them.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const logs = "APDU trace without personal data";
  const sensitiveLogs = "MRZ document number NL1234567 and chip data";

  late List<String> copied;

  setUp(() {
    copied = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == "Clipboard.setData") {
            copied.add((call.arguments as Map)["text"] as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pumpDialog(WidgetTester tester) async {
    final widget = IrmaTheme(
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
          body: NfcErrorDialog(logs: logs, sensitiveLogs: sensitiveLogs),
        ),
      ),
    );

    // See error_reporting_check_box_semantics_test.dart: the translation
    // loader does real IO, which the fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  final copyButton = find.widgetWithIcon(IconButton, Icons.copy);

  testWidgets("copies the non-sensitive logs", (tester) async {
    await pumpDialog(tester);

    await tester.tap(copyButton);
    await tester.pump();

    expect(copied, [logs]);
  });

  testWidgets("does not copy while the sensitive logs are shown", (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text(sensitiveLogs), findsOneWidget);

    expect(tester.widget<IconButton>(copyButton).onPressed, isNull);
    await tester.tap(copyButton, warnIfMissed: false);
    await tester.pump();

    expect(copied, isEmpty);
  });
}
