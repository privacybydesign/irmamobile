import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/data/empty_data_routes.dart";
import "package:yivi_core/src/theme/theme.dart";
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
      expect(findSvg("ui/route_phone.svg"), findsOneWidget);
      expect(findSvg("ui/route_scan.svg"), findsOneWidget);
    });

    group("layout of the design", () {
      final theme = IrmaThemeData();

      Future<void> pumpPhone(WidgetTester tester) async {
        usePhoneScreen(tester);
        await pumpRoutes(tester);
        await settle(tester);
      }

      // The card is the rounded box around a route's title.
      Finder card(String title) => find.ancestor(
        of: find.text(title),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              (widget.decoration as BoxDecoration).borderRadius ==
                  BorderRadius.circular(12),
        ),
      );

      testWidgets("the picture is 132 px, 24 px from the top", (tester) async {
        await pumpPhone(tester);

        final picture = tester.getRect(
          findSvg("enrollment/introduction_1.svg"),
        );
        expect(picture.top, 24);
        expect(picture.height, 132);
        expect(picture.center.dx, 195);
      });

      testWidgets("the title is 24 px bold with a 32 px line", (tester) async {
        await pumpPhone(tester);

        final style = tester.widget<Text>(find.text(_title)).style!;
        expect(style.fontSize, 24);
        expect(style.fontWeight, FontWeight.w700);
        expect(style.height, 32 / 24);
        expect(style.color, theme.neutralExtraDark);
        // 10 px under the picture.
        expect(tester.getRect(find.text(_title)).top, 24 + 132 + 10);
      });

      testWidgets("the cards are 16 px from the sides and 16 px apart", (
        tester,
      ) async {
        await pumpPhone(tester);

        final first = tester.getRect(card(_websiteTitle));
        final second = tester.getRect(card(_qrTitle));
        expect(first.left, 16);
        expect(first.width, 358);
        expect(first.top, tester.getRect(find.text(_title)).bottom + 16);
        expect(second.top, first.bottom + 16);
      });

      testWidgets("a card has a 12 px radius, white and a soft shadow", (
        tester,
      ) async {
        await pumpPhone(tester);

        final decoration =
            tester.widget<DecoratedBox>(card(_qrTitle)).decoration
                as BoxDecoration;
        expect(decoration.color, theme.light);
        expect(decoration.boxShadow, hasLength(1));
        expect(decoration.boxShadow!.single.offset, const Offset(0, 1));
        expect(decoration.boxShadow!.single.blurRadius, 6);
      });

      testWidgets("a card has 14 px above, 16 px beside, a 40 px icon", (
        tester,
      ) async {
        await pumpPhone(tester);

        final box = tester.getRect(card(_qrTitle));
        final icon = tester.getRect(findSvg("ui/route_scan.svg"));
        expect(icon.size, const Size(22, 22));
        expect(icon.center.dx, box.left + 16 + 20);
        expect(icon.center.dy, box.top + 14 + 20);
        // The text starts 14 px after the icon's circle.
        expect(
          tester.getTopLeft(find.text(_qrTitle)).dx,
          box.left + 16 + 40 + 14,
        );
        expect(tester.getTopLeft(find.text(_qrTitle)).dy, box.top + 14);
      });

      testWidgets("a card says its route in 16 px bold, then 15 px", (
        tester,
      ) async {
        await pumpPhone(tester);

        final title = tester.widget<Text>(find.text(_qrTitle)).style!;
        expect(title.fontSize, 16);
        expect(title.fontWeight, FontWeight.w700);
        expect(title.height, 22 / 16);
        expect(title.color, theme.dark);
        final text = tester.widget<Text>(find.text(_qrText)).style!;
        expect(text.fontSize, 15);
        expect(text.height, 21 / 15);
        expect(text.color, theme.neutralExtraDark);
        expect(
          tester.getTopLeft(find.text(_qrText)).dy,
          tester.getRect(find.text(_qrTitle)).bottom + 2,
        );
      });

      testWidgets("the chip has a check, 14 px bold text and a 14 px radius", (
        tester,
      ) async {
        await prefs.markReadyChipPending();
        await pumpPhone(tester);

        final text = tester.widget<Text>(find.text(_readyChip)).style!;
        expect(text.fontSize, 14);
        expect(text.fontWeight, FontWeight.w700);
        expect(text.height, 20 / 14);
        expect(text.color, const Color(0xFF00602A));

        final check = tester.getRect(findSvg("ui/ready_check.svg"));
        expect(check.size, const Size(16, 16));
        // 6 px between the check and the text.
        expect(tester.getTopLeft(find.text(_readyChip)).dx, check.right + 6);

        final chip = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.text(_readyChip),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final decoration = chip.decoration as BoxDecoration;
        expect(decoration.color, theme.successSurface);
        expect(decoration.borderRadius, BorderRadius.circular(14));
      });

      testWidgets("the chip sits 10 px under the picture and above the title", (
        tester,
      ) async {
        await prefs.markReadyChipPending();
        await pumpPhone(tester);

        final picture = tester.getRect(
          findSvg("enrollment/introduction_1.svg"),
        );
        final chip = tester.getRect(
          find
              .ancestor(
                of: find.text(_readyChip),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(chip.top, picture.bottom + 10);
        expect(tester.getRect(find.text(_title)).top, chip.bottom + 10);
      });
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
      await enableOnboardingV2(prefs);
      await pumpDataTab(tester);
      await settle(tester);

      expect(find.byType(EmptyDataRoutes), findsOneWidget);
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_oldTitle), findsNothing);
    });

    testWidgets("flag on: the routes make way for the first credential", (
      tester,
    ) async {
      await enableOnboardingV2(prefs);
      await pumpDataTab(tester, credentials: [_credential()]);
      await settle(tester);
      await settle(tester);

      expect(find.byType(EmptyDataRoutes), findsNothing);
      expect(find.byType(SchemalessYiviCredentialTypeCard), findsOneWidget);
    });
  });
}
