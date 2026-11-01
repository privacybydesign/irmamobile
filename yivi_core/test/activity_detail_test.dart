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

TrustedParty _party(String name, {bool verified = true, String? url}) =>
    TrustedParty(
      id: name,
      name: name,
      url: url,
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
  bool verified = true,
  String? url,
  bool sharedToReceive = false,
}) {
  final credentials = [
    _credential("Email address", [
      stringAttr("email", "s.devries@werk.example"),
    ]),
  ];
  final party = _party(verifier, verified: verified, url: url);
  return LogInfo(
    type: type,
    time: DateTime.utc(2026, 10, 11, 14, 32),
    issuanceLog: type == LogType.issuance
        ? IssuanceLog(
            protocol: Protocol.irma,
            credentials: credentials,
            disclosedCredentials: sharedToReceive
                ? [
                    _credential("Mobile number", [
                      stringAttr("mobilenumber", "+31612345678"),
                    ]),
                  ]
                : const [],
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

/// The hero's line under the name: when, and whether Yivi knows the party.
String heroLine(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const Key("activity_hero_date")))
    .textSpan!
    .toPlainText();

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

  testWidgets("shared: the hero, the tile and the note, each fact once", (
    tester,
  ) async {
    await pump(tester, _log(LogType.disclosure));

    expect(find.byKey(const Key("activity_hero")), findsOneWidget);
    expect(find.text("Shared with"), findsOneWidget);
    // The name in the hero; the bar's title waits until it scrolls away.
    expect(find.text("Webshop Noord"), findsWidgets);
    // When, once, and whether Yivi knows the party, on one line.
    final time = DateTime.utc(2026, 10, 11, 14, 32).toLocal();
    expect(
      heroLine(tester),
      "${DateFormat.yMMMd("en").format(time)}, "
      "${DateFormat.jm("en").format(time)}  ·  \uFFFCKnown party",
    );
    expect(find.textContaining("ago"), findsNothing);
    // One kind of card: no section heading, the header says it.
    expect(find.text("You shared"), findsNothing);
    expect(find.byType(ActivityCredentialTile), findsOneWidget);
    expect(find.text("s.devries@werk.example"), findsOneWidget);
    expect(
      find.text("Fields that are not listed stayed on your phone."),
      findsOne,
    );
    // The tile does not open anything.
    expect(
      find.descendant(
        of: find.byType(ActivityCredentialTile),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets("a party Yivi does not know: unknown, with its website", (
    tester,
  ) async {
    await pump(
      tester,
      _log(LogType.disclosure, verified: false, url: "https://shop.example"),
    );
    expect(heroLine(tester), endsWith("\uFFFCUnknown party · shop.example"));
    expect(find.byIcon(Icons.verified_user_rounded), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key("activity_hero")),
        matching: find.byIcon(Icons.shield_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets("a party Yivi does not know, without a website: unknown", (
    tester,
  ) async {
    await pump(tester, _log(LogType.disclosure, verified: false));
    expect(heroLine(tester), endsWith("\uFFFCUnknown party"));
  });

  testWidgets("signed: the message above the data, without a footer", (
    tester,
  ) async {
    await pump(
      tester,
      _log(LogType.signature, message: "I apply for a parking permit."),
    );

    expect(find.text("Message signed for"), findsOneWidget);
    expect(find.text("You signed with"), findsNothing);
    expect(find.textContaining("Signed by you"), findsNothing);
    final message = tester.getRect(find.text("I apply for a parking permit."));
    final card = tester.getRect(find.byType(ActivityCredentialTile));
    expect(message.top, lessThan(card.top));
  });

  testWidgets("received and deleted read differently", (tester) async {
    await pump(tester, _log(LogType.issuance));
    expect(find.text("Received from"), findsOneWidget);
    expect(find.text("New"), findsOneWidget);
    // No note: the header says it.
    expect(find.byIcon(Icons.shield_outlined), findsNothing);

    await pump(tester, _log(LogType.removal));
    expect(find.text("Data deleted from"), findsOneWidget);
    expect(find.text("Deleted"), findsOneWidget);
    expect(find.text("This cannot be undone."), findsOneWidget);
  });

  testWidgets("two kinds of card: a heading for each", (tester) async {
    await pump(tester, _log(LogType.issuance, sharedToReceive: true));
    expect(find.text("You received"), findsOneWidget);
    expect(find.text("You shared to receive it"), findsOneWidget);
  });

  testWidgets("the bar shows the name, what happened and when once the name "
      "has scrolled under it", (tester) async {
    await pump(
      tester,
      _log(LogType.signature, message: List.filled(600, "word").join(" ")),
    );
    double title() => tester
        .widget<AnimatedOpacity>(find.byKey(const Key("irma_app_bar_title")))
        .opacity;
    expect(title(), 0);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(title(), 1);
    final bar = find.byKey(const Key("activity_bar_title"));
    expect(
      find.descendant(of: bar, matching: find.text("Webshop Noord")),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.textContaining("Signed · ")),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(title(), 0);
  });
}
