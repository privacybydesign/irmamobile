import "package:flutter_test/flutter_test.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_parts.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

TrustedParty _party(String name, {bool verified = true}) => TrustedParty(
  id: name,
  name: name,
  url: null,
  parent: null,
  verified: verified,
);

LogCredential _credential(String name, List<Attribute> attributes) =>
    LogCredential(
      credentialId: "pbdf.sidn-pbdf.$name",
      formats: const [CredentialFormat.idemix],
      name: name,
      issuer: _party("Yivi"),
      attributes: attributes,
      revoked: false,
      revocationSupported: false,
    );

LogInfo _log(
  LogType type, {
  String message = "",
  String verifier = "Webshop Noord",
}) {
  final credentials = [
    _credential("Email address", [
      stringAttr("email", "s.devries@werk.example"),
    ]),
  ];
  final party = _party(verifier);
  return LogInfo(
    type: type,
    time: DateTime.utc(2026, 10, 11, 14, 32),
    issuanceLog: type == LogType.issuance
        ? IssuanceLog(
            protocol: Protocol.irma,
            credentials: credentials,
            disclosedCredentials: const [],
            issuer: _party("Yivi"),
          )
        : null,
    disclosureLog: type == LogType.disclosure
        ? DisclosureLog(
            protocol: Protocol.irma,
            credentials: credentials,
            verifier: party,
          )
        : null,
    signedMessageLog: type == LogType.signature
        ? SignedMessageLog(
            protocol: Protocol.irma,
            credentials: credentials,
            verifier: party,
            message: message,
          )
        : null,
    removalLog: type == LogType.removal
        ? RemovalLog(credentials: credentials)
        : null,
  );
}

void main() {
  late IrmaRepository repo;

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  Future<void> pump(WidgetTester tester, LogInfo log) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1200);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      // The credential tiles look up the wallet for the card colours.
      overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
      home: ActivityDetailsScreen(
        args: ActivityDetailsScreenArgs(logEntry: log),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("shared: the centred header, the tile and the note", (
    tester,
  ) async {
    await pump(tester, _log(LogType.disclosure));

    expect(find.byKey(const Key("activity_party_card")), findsNothing);
    expect(find.text("Shared with"), findsOneWidget);
    expect(find.text("Webshop Noord"), findsOneWidget);
    expect(find.text("Known party"), findsOneWidget);
    // When, as a date pill and a time pill, and how long ago.
    final date = DateFormat.yMMMMEEEEd(
      "en",
    ).format(DateTime.utc(2026, 10, 11, 14, 32).toLocal());
    expect(
      find.descendant(
        of: find.byKey(const Key("activity_date_pill")),
        matching: find.text(date),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key("activity_time_pill")), findsOneWidget);
    expect(find.textContaining("ago"), findsOneWidget);
    // The pass is gone.
    expect(find.text("DATE"), findsNothing);
    expect(find.text("YOU SHARED"), findsOneWidget);
    expect(find.byType(ActivityCredentialTile), findsOneWidget);
    expect(find.text("s.devries@werk.example"), findsOneWidget);
    expect(find.textContaining("Webshop Noord got only this"), findsOne);
  });

  testWidgets("signed: the message above the data", (tester) async {
    await pump(
      tester,
      _log(LogType.signature, message: "I apply for a parking permit."),
    );

    expect(find.text("Message signed for"), findsOneWidget);
    expect(find.text("YOU SIGNED WITH"), findsOneWidget);
    final message = tester.getRect(find.text("I apply for a parking permit."));
    final card = tester.getRect(find.byType(ActivityCredentialTile));
    expect(message.top, lessThan(card.top));
  });

  testWidgets("received and deleted read differently", (tester) async {
    await pump(tester, _log(LogType.issuance));
    expect(find.text("Received from"), findsOneWidget);
    expect(find.text("YOU RECEIVED"), findsOneWidget);
    expect(find.text("New"), findsOneWidget);

    await pump(tester, _log(LogType.removal));
    expect(find.text("Data deleted from"), findsOneWidget);
    expect(find.text("YOU DELETED"), findsOneWidget);
    expect(find.text("Deleted"), findsOneWidget);
    expect(find.textContaining("cannot be recovered"), findsOneWidget);
  });

  /// Scrolls down and back in small steps; at each step the compact bar
  /// shows exactly when the whole header is above the top bar.
  Future<void> expectBarFollowsHeader(WidgetTester tester) async {
    bool barShown() => find.byType(ActivityCompactBar).evaluate().isNotEmpty;
    // The band behind the bar comes and goes with it.
    bool bandShown() =>
        find.byKey(const Key("scroll_edge_band")).evaluate().isNotEmpty;
    double headerBottom() =>
        tester.getRect(find.byType(ActivityPartyCard)).bottom;
    // No safe area in the test: the top bar ends at 60.
    const barBottom = 60.0;

    expect(barShown(), isFalse);
    var sawShown = false;
    for (final dy in [...List.filled(18, -40.0), ...List.filled(18, 40.0)]) {
      await tester.drag(find.byType(ListView), Offset(0, dy));
      await tester.pumpAndSettle();
      final gone = headerBottom() < barBottom;
      expect(barShown(), gone, reason: "header bottom ${headerBottom()}");
      expect(bandShown(), gone, reason: "header bottom ${headerBottom()}");
      sawShown |= gone;
    }
    expect(sawShown, isTrue, reason: "never scrolled the header away");
    expect(barShown(), isFalse);
  }

  testWidgets("the compact bar shows once the header has scrolled away, and "
      "hides again", (tester) async {
    await pump(
      tester,
      _log(LogType.signature, message: List.filled(600, "word").join(" ")),
    );
    await expectBarFollowsHeader(tester);
  });

  testWidgets("the band comes with the compact bar: none at the top, "
      "none on the first scroll", (tester) async {
    await pump(
      tester,
      _log(LogType.signature, message: List.filled(600, "word").join(" ")),
    );
    final band = find.byKey(const Key("scroll_edge_band"));
    expect(band, findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityCompactBar), findsNothing);
    expect(band, findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityCompactBar), findsOneWidget);
    expect(band, findsOneWidget);
  });

  testWidgets("with a name on two lines the bar waits for the whole header", (
    tester,
  ) async {
    await pump(
      tester,
      _log(
        LogType.signature,
        verifier: "Gemeentelijke Belastingsamenwerking Voorbeeldstad",
        message: List.filled(600, "word").join(" "),
      ),
    );
    final nameLines =
        tester
            .getSize(
              find.text("Gemeentelijke Belastingsamenwerking Voorbeeldstad"),
            )
            .height /
        32;
    expect(nameLines, greaterThan(1.5), reason: "the name should wrap");
    await expectBarFollowsHeader(tester);

    // The bar still says who and when.
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    final bar = find.byType(ActivityCompactBar);
    expect(
      find.descendant(
        of: bar,
        matching: find.text(
          "Gemeentelijke Belastingsamenwerking Voorbeeldstad",
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.byType(ActivityPartyLogo)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.textContaining("Signed")),
      findsOneWidget,
    );
  });
}
