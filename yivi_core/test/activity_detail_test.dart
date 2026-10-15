import "package:flutter_test/flutter_test.dart";
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

LogInfo _log(LogType type, {String message = ""}) {
  final credentials = [
    _credential("Email address", [
      stringAttr("email", "s.devries@werk.example"),
    ]),
  ];
  final verifier = _party("Webshop Noord");
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
            verifier: verifier,
          )
        : null,
    signedMessageLog: type == LogType.signature
        ? SignedMessageLog(
            protocol: Protocol.irma,
            credentials: credentials,
            verifier: verifier,
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

  testWidgets("shared: who, what and the note", (tester) async {
    await pump(tester, _log(LogType.disclosure));

    expect(find.text("Shared with"), findsOneWidget);
    expect(find.text("Webshop Noord"), findsOneWidget);
    expect(find.text("Known party"), findsOneWidget);
    expect(find.byType(ActivityCredentialTile), findsOneWidget);
    expect(find.text("s.devries@werk.example"), findsOneWidget);
    expect(find.textContaining("Only these attributes were shared"), findsOne);
  });

  testWidgets("signed: the message above the data", (tester) async {
    await pump(
      tester,
      _log(LogType.signature, message: "I apply for a parking permit."),
    );

    expect(find.text("Message signed for"), findsOneWidget);
    final message = tester.getRect(find.text("I apply for a parking permit."));
    final card = tester.getRect(find.byType(ActivityCredentialTile));
    expect(message.top, lessThan(card.top));
  });

  testWidgets("received and deleted read differently", (tester) async {
    await pump(tester, _log(LogType.issuance));
    expect(find.text("Received from"), findsOneWidget);
    expect(find.text("Received data"), findsOneWidget);

    await pump(tester, _log(LogType.removal));
    expect(find.text("Data deleted from"), findsOneWidget);
    expect(find.textContaining("cannot be recovered"), findsOneWidget);
  });
}
