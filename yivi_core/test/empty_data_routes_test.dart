import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/data/empty_data_routes.dart";
import "package:yivi_core/src/widgets/credential_card/schemaless_yivi_credential_type_card.dart";

import "support/onboarding_v2_harness.dart";

const _title = "How do you want to start?";
const _readyChip = "Your Yivi app is ready";
const _websiteTitle = "Did you come from a website on this phone?";
const _websiteText = "Go back to your browser and tap 'Open Yivi app' again.";
const _qrTitle = "Do you see a QR code on a computer?";
const _qrText = "Tap Scan QR below.";
const _oldTitle = "Obtain your personal data";

Credential _credential() => Credential(
  credentialId: "pbdf.pbdf.email",
  hash: "hash",
  name: "Email",
  issuer: TrustedParty(
    id: "pbdf",
    name: "Yivi",
    url: null,
    parent: null,
    verified: true,
  ),
  credentialInstanceIds: {},
  batchInstanceCountsRemaining: {},
  attributes: [],
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
);

class _FixedOrder extends SchemalessCredentialOrderController {
  _FixedOrder(this.items);

  final List<Credential> items;

  @override
  Future<List<Credential>> build() async => items;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;
  late IrmaRepository repo;

  setUp(() async {
    prefs = await freshPreferences();
    repo = IrmaRepository(client: RecordingBridge(), preferences: prefs);
  });

  tearDown(() => repo.close());

  group("EmptyDataRoutes", () {
    Future<void> pumpRoutes(WidgetTester tester) =>
        pumpHome(tester, repo: repo, home: const EmptyDataRoutes());

    Future<bool?> chipPending(WidgetTester tester) =>
        tester.runAsync(() => prefs.getReadyChipPending().first);

    testWidgets("shows the title and both routes", (tester) async {
      await pumpRoutes(tester);

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_websiteTitle), findsOneWidget);
      expect(find.text(_websiteText), findsOneWidget);
      expect(find.text(_qrTitle), findsOneWidget);
      expect(find.text(_qrText), findsOneWidget);
      expect(find.byIcon(Icons.smartphone_rounded), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets("is shown in Dutch", (tester) async {
      await pumpHome(
        tester,
        repo: repo,
        home: const EmptyDataRoutes(),
        locale: const Locale("nl", "NL"),
      );

      expect(find.text("Hoe wil je beginnen?"), findsOneWidget);
      expect(
        find.text("Kwam je van een website op deze telefoon?"),
        findsOneWidget,
      );
      expect(find.text("Zie je een QR-code op een computer?"), findsOneWidget);
    });

    testWidgets("has no ready chip when onboarding did not just finish", (
      tester,
    ) async {
      await pumpRoutes(tester);
      await settle(tester);

      expect(find.text(_readyChip), findsNothing);
    });

    testWidgets("shows the ready chip on the first visit only", (tester) async {
      await prefs.markReadyChipPending();
      await pumpRoutes(tester);
      await settle(tester);

      expect(find.text(_readyChip), findsOneWidget);
      expect(await chipPending(tester), isFalse);

      // Leave the tab and come back.
      await tester.pumpWidget(const SizedBox());
      await pumpRoutes(tester);
      await settle(tester);

      expect(find.text(_readyChip), findsNothing);
    });

    testWidgets("keeps the chip while the tab is rebuilt", (tester) async {
      await prefs.markReadyChipPending();
      await pumpRoutes(tester);
      await settle(tester);

      await tester.pump();
      await settle(tester);

      expect(find.text(_readyChip), findsOneWidget);
    });

    testWidgets(
      "scrolls instead of overflowing on a small, large-text screen",
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await prefs.markReadyChipPending();
        await pumpHome(
          tester,
          repo: repo,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 480),
              textScaler: TextScaler.linear(2),
            ),
            child: const EmptyDataRoutes(),
          ),
        );
        await settle(tester);

        await tester.scrollUntilVisible(find.text(_qrText), 100);

        expect(tester.takeException(), isNull);
        expect(find.text(_qrText), findsOneWidget);
      },
    );
  });

  group("DataTab", () {
    Future<void> pumpDataTab(
      WidgetTester tester, {
      List<Credential> credentials = const [],
    }) => pumpHome(
      tester,
      repo: repo,
      home: DataTab(),
      overrides: [
        schemalessCredentialsProvider.overrideWith(
          (ref) => Stream.value((credentials: credentials, problematic: [])),
        ),
        schemalessCredentialOrderControllerProvider.overrideWith(
          () => _FixedOrder(credentials),
        ),
      ],
    );

    testWidgets("flag off: keeps the pointing man", (tester) async {
      await pumpDataTab(tester);
      await settle(tester);

      expect(find.text(_oldTitle), findsOneWidget);
      expect(find.byType(EmptyDataRoutes), findsNothing);
    });

    testWidgets("flag on: shows the two routes when there is no data", (
      tester,
    ) async {
      await setOnboardingV2(prefs, on: true);
      await pumpDataTab(tester);
      await settle(tester);

      expect(find.byType(EmptyDataRoutes), findsOneWidget);
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_oldTitle), findsNothing);
    });

    testWidgets("flag on: the routes make way for the first credential", (
      tester,
    ) async {
      await setOnboardingV2(prefs, on: true);
      await pumpDataTab(tester, credentials: [_credential()]);
      await settle(tester);
      await settle(tester);

      expect(find.byType(EmptyDataRoutes), findsNothing);
      expect(find.byType(SchemalessYiviCredentialTypeCard), findsOneWidget);
    });
  });
}
