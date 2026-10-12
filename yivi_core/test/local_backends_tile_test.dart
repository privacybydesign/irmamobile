import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/debug/widgets/local_backends_tile.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  setUp(() async {
    prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
  });

  Future<void> pumpTile(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: Scaffold(body: LocalBackendsTile())),
      ),
    );
    await tester.pump();
  }

  // Reading the stream inside the fake clock never finishes.
  Future<String?> storedHost(WidgetTester tester) =>
      tester.runAsync(() => prefs.getLocalBackendHost().first);

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key("local_backends_tile")));
    await tester.pumpAndSettle();
  }

  testWidgets("Save stores the trimmed host and closes the dialog", (
    tester,
  ) async {
    await pumpTile(tester);
    await openDialog(tester);

    await tester.enterText(
      find.byKey(const Key("local_backend_host_field")),
      " 192.168.1.20 ",
    );
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await storedHost(tester), "192.168.1.20");
    expect(find.textContaining("http://192.168.1.20:8080"), findsOneWidget);
  });

  testWidgets("Off clears the host", (tester) async {
    await prefs.setLocalBackendHost("localhost");
    await pumpTile(tester);
    await openDialog(tester);

    final field = tester.widget<TextField>(
      find.byKey(const Key("local_backend_host_field")),
    );
    expect(field.controller?.text, "localhost");

    await tester.tap(find.text("Off"));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await storedHost(tester), isEmpty);
    expect(find.text("Off"), findsOneWidget);
  });

  testWidgets("dismissing the dialog keeps the host", (tester) async {
    await prefs.setLocalBackendHost("localhost");
    await pumpTile(tester);
    await openDialog(tester);

    await tester.enterText(
      find.byKey(const Key("local_backend_host_field")),
      "other",
    );
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(await storedHost(tester), "localhost");
  });
}
