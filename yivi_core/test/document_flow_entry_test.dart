import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/nfc_availability_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/schemaless_credential_store_provider.dart";
import "package:yivi_core/src/screens/add_data/schemaless_add_data_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_instruction_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/navigation.dart";
import "package:yivi_core/src/util/test_detection.dart";

import "support/pump_translated.dart";

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

CredentialStoreItem _item(String credentialId, String name) =>
    CredentialStoreItem(
      credential: CredentialDescriptor(
        credentialId: credentialId,
        name: name,
        issuer: TrustedParty(
          id: "issuer",
          name: "Issuer",
          url: null,
          parent: null,
          verified: true,
        ),
        category: "Personal",
        attributes: [],
        issueURL: "https://issuer.example/$name",
      ),
      faq: Faq(
        intro: "intro",
        purpose: "purpose",
        content: "content",
        howTo: "howto",
      ),
    );

final _store = [
  CredentialStoreCategory(
    category: "Personal",
    items: [
      _item("pbdf.pbdf.passport", "Passport"),
      _item("pbdf.pbdf.idcard", "IdCard"),
      _item("pbdf.pbdf.drivinglicence", "DrivingLicence"),
      _item("pbdf.sidn-pbdf.email", "Email"),
    ],
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  // StreamingSharedPreferences.instance is a process-wide singleton, so
  // clearAll() is what gives each test a clean store.
  setUp(() async {
    prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
  });

  // Mirrors the nesting in routing.dart: the real router builds the whole home
  // screen, which needs far more setup than this test.
  Future<void> pumpAddData(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: "/home/add_data",
      routes: [
        GoRoute(
          path: "/home",
          builder: (context, state) => const SizedBox(),
          routes: [
            GoRoute(
              path: "add_data",
              builder: (context, state) => SchemalessAddDataScreen(),
              routes: [
                GoRoute(
                  path: "details",
                  builder: (context, state) => const Text("details page"),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: "/mrz/instructions/:type",
          builder: (context, state) => DocumentInstructionScreen(
            documentType: DocumentType.values.byName(
              state.pathParameters["type"]!,
            ),
            onCancel: context.pop,
            onStart: () => context.pushPassportManualEntryScreen(),
          ),
        ),
        GoRoute(
          path: "/mrz/manual_entry/passport",
          builder: (context, state) => const Text("manual entry"),
        ),
      ],
    );

    final widget = ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        groupedCredentialStoreProvider.overrideWith(
          (ref) => Stream.value(_store),
        ),
        nfcAvailableProvider.overrideWith((ref) => Future.value(true)),
      ],
      child: IrmaRepositoryProvider(
        repository: IrmaRepository(client: _SilentBridge(), preferences: prefs),
        child: TestContext(
          child: IrmaTheme(
            builder: (_) => MaterialApp.router(
              localizationsDelegates: [
                FlutterI18nDelegate(
                  translationLoader: FileTranslationLoader(
                    basePath: "assets/locales",
                    forcedLocale: const Locale("en", "US"),
                  ),
                ),
                ...GlobalMaterialLocalizations.delegates,
              ],
              routerConfig: router,
            ),
          ),
        ),
      ),
    );

    await pumpTranslated(tester, widget);
  }

  // Preference writes and the flag stream finish on the real event loop.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> tapCredential(WidgetTester tester, String credentialId) async {
    await tester.tap(find.byKey(Key("${credentialId}_tile")));
    await settle(tester);
  }

  testWidgets("flag off: a document opens the details page", (tester) async {
    await pumpAddData(tester);
    await settle(tester);

    await tapCredential(tester, "pbdf.pbdf.passport");

    expect(find.text("details page"), findsOneWidget);
    expect(find.byType(DocumentInstructionScreen), findsNothing);
  });

  group("flag on", () {
    setUp(() => prefs.setFeatureFlag(FeatureFlag.documentFlowV2, true));

    for (final (credentialId, documentType) in [
      ("pbdf.pbdf.passport", DocumentType.passport),
      ("pbdf.pbdf.idcard", DocumentType.identityCard),
      ("pbdf.pbdf.drivinglicence", DocumentType.drivingLicence),
    ]) {
      testWidgets("$credentialId skips the details page for the instructions", (
        tester,
      ) async {
        await pumpAddData(tester);
        await settle(tester);

        await tapCredential(tester, credentialId);

        expect(find.text("details page"), findsNothing);
        final screen = tester.widget<DocumentInstructionScreen>(
          find.byType(DocumentInstructionScreen),
        );
        expect(screen.documentType, documentType);
      });
    }

    testWidgets("a credential that needs no NFC still has a details page", (
      tester,
    ) async {
      await pumpAddData(tester);
      await settle(tester);

      await tapCredential(tester, "pbdf.sidn-pbdf.email");

      expect(find.text("details page"), findsOneWidget);
      expect(find.byType(DocumentInstructionScreen), findsNothing);
    });

    testWidgets("Start continues to capture, Cancel returns to the list", (
      tester,
    ) async {
      await pumpAddData(tester);
      await settle(tester);

      await tapCredential(tester, "pbdf.pbdf.passport");
      await tester.tap(find.byKey(const Key("bottom_bar_secondary")));
      await settle(tester);
      expect(find.byType(SchemalessAddDataScreen), findsOneWidget);

      await tapCredential(tester, "pbdf.pbdf.passport");
      await tester.tap(find.byKey(const Key("bottom_bar_primary")));
      await settle(tester);
      expect(find.text("manual entry"), findsOneWidget);
    });
  });
}
