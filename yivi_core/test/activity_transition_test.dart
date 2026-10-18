import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_parts.dart";
import "package:yivi_core/src/screens/data/wallet/wallet_transition.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

LogCredential _credential(String name) => LogCredential(
  credentialId: "pbdf.sidn-pbdf.$name",
  formats: const [CredentialFormat.idemix],
  name: name,
  issuer: _party("Yivi"),
  attributes: [stringAttr(name, "$name value")],
  revoked: false,
  revocationSupported: false,
);

LogInfo _disclosure(String verifier, int day, List<String> cards) => LogInfo(
  type: LogType.disclosure,
  time: DateTime.utc(2026, 10, day, 12),
  issuanceLog: null,
  disclosureLog: DisclosureLog(
    protocol: Protocol.irma,
    credentials: [for (final c in cards) _credential(c)],
    verifier: _party(verifier),
  ),
  signedMessageLog: null,
  removalLog: null,
);

final _logs = [
  _disclosure("Above", 12, ["email"]),
  _disclosure("Tapped", 11, ["email", "age", "mobile", "iban"]),
  _disclosure("Below", 10, ["age"]),
];

void main() {
  late IrmaRepository repo;

  setUp(() async {
    WalletTransition.openKey.value = null;
    WalletTransition.closing = false;
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  Future<GoRouter> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final router = await pumpRoutes(
      tester,
      repo: repo,
      overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
      initialLocation: "/home",
      routes: [
        GoRoute(
          path: "/home",
          pageBuilder: (context, state) => MaterialPage(
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 120, 16, 0),
                children: [
                  for (final log in _logs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ActivityCard(logEntry: log),
                    ),
                ],
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: "activity_details",
              pageBuilder: (context, state) => WalletDetailPage(
                child: ActivityDetailsScreen(
                  args: ActivityDetailsScreenArgs(
                    logEntry: state.extra as LogInfo,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder row(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(ActivityCard));

  testWidgets("rows above go up, rows below go down, the cards fly into "
      "their tiles", (tester) async {
    await pump(tester);
    // Measured inside the row: its own box is the transform that moves it.
    final above = tester.getTopLeft(find.text("Above"));
    final below = tester.getTopLeft(find.text("Below"));

    await tester.tap(row("Tapped"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getTopLeft(find.text("Above")).dy, lessThan(above.dy));
    expect(tester.getTopLeft(find.text("Below")).dy, greaterThan(below.dy));

    await tester.pumpAndSettle();
    expect(find.byType(ActivityDetailsScreen), findsOneWidget);
    // One tile per card; the four arts landed in them, not in the pile.
    expect(find.byType(ActivityCredentialTile), findsNWidgets(4));
    final tileArt = find.descendant(
      of: find.byType(ActivityCredentialTile).first,
      matching: find.byType(ActivityCardHero),
    );
    expect(tester.getSize(tileArt).width, closeTo(58, 0.5));
  });

  testWidgets("a long pull closes; the cards drop back into the pile", (
    tester,
  ) async {
    final router = await pump(tester);
    final pile = tester.getTopLeft(
      find.descendant(
        of: row("Tapped"),
        matching: find.byType(ActivityCardStack),
      ),
    );
    await tester.tap(row("Tapped"));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(ListView).last,
      const Offset(0, 260),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ActivityDetailsScreen), findsNothing);
    expect(router.routerDelegate.currentConfiguration.uri.path, "/home");
    expect(
      tester.getTopLeft(
        find.descendant(
          of: row("Tapped"),
          matching: find.byType(ActivityCardStack),
        ),
      ),
      pile,
    );
    expect(WalletTransition.openKey.value, isNull);
  });

  testWidgets("each pile carries the party's logo, its first letter when "
      "there is no image", (tester) async {
    await pump(tester);
    for (final name in ["Above", "Tapped", "Below"]) {
      final pile = find.descendant(
        of: row(name),
        matching: find.byType(ActivityCardStack),
      );
      final logo = find.descendant(
        of: pile,
        matching: find.byType(ActivityPartyLogo),
      );
      expect(logo, findsOneWidget);
      expect(
        find.descendant(of: logo, matching: find.text(name[0])),
        findsOneWidget,
      );
      // On the corner, over the cards.
      final pileRect = tester.getRect(pile);
      final logoRect = tester.getRect(logo);
      expect(logoRect.right, greaterThan(pileRect.right));
      expect(logoRect.bottom, greaterThan(pileRect.bottom));
    }
  });

  testWidgets("a short pull springs back", (tester) async {
    await pump(tester);
    await tester.tap(row("Tapped"));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(ListView).last,
      const Offset(0, 60),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ActivityDetailsScreen), findsOneWidget);
  });

  testWidgets("Done closes", (tester) async {
    await pump(tester);
    await tester.tap(row("Tapped"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("activity_detail_done")));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityDetailsScreen), findsNothing);
  });
}
