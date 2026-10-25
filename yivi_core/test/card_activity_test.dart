import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/screens/data/credential_detail/credential_detail_screen.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

class _FixedOrder extends SchemalessCredentialOrderController {
  _FixedOrder(this.items);
  final List<Credential> items;
  @override
  Future<List<Credential>> build() async => items;
}

final _card = testCredential(
  type: "pbdf.sidn-pbdf.email",
  hash: "email-card",
  name: "Email address",
  attributes: [stringAttr("email", "s.devries@werk.example")],
);

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

LogCredential _logged(String hash) => LogCredential(
  credentialId: "pbdf.sidn-pbdf.email",
  formats: const [CredentialFormat.idemix],
  name: "Email address",
  issuer: _party("Yivi"),
  attributes: const [],
  revoked: false,
  revocationSupported: false,
  hash: hash,
);

void main() {
  late IrmaRepository repo;
  late RecordingBridge bridge;

  setUp(() async {
    bridge = RecordingBridge()
      ..respond = (event) {
        if (event is! QueryLogsEvent) return null;
        return LogPageEvent(
          requestId: event.requestId,
          page: LogPage(
            entries: [
              LogInfo(
                id: "2",
                type: LogType.disclosure,
                time: DateTime.utc(2026, 10, 20, 12),
                issuanceLog: null,
                disclosureLog: DisclosureLog(
                  protocol: Protocol.irma,
                  credentials: [_logged("email-card")],
                  verifier: _party("Webshop"),
                ),
                signedMessageLog: null,
                removalLog: null,
              ),
              LogInfo(
                id: "1",
                type: LogType.issuance,
                time: DateTime.utc(2026, 10, 1, 12),
                issuanceLog: IssuanceLog(
                  protocol: Protocol.irma,
                  credentials: [_logged("email-card")],
                  disclosedCredentials: const [],
                  issuer: _party("Email issuer"),
                ),
                disclosureLog: null,
                signedMessageLog: null,
                removalLog: null,
              ),
            ],
          ),
        );
      };
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  testWidgets("a card lists its own activity, newest first", (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1600);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      overrides: <Override>[
        irmaRepositoryProvider.overrideWithValue(repo),
        schemalessCredentialOrderControllerProvider.overrideWith(
          () => _FixedOrder([_card]),
        ),
      ],
      home: const CredentialDetailScreen(hash: "email-card"),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // irmago is asked for this card's entries only.
    final query = bridge.dispatched.whereType<QueryLogsEvent>().last.query;
    expect(query.filter.credentialHash, "email-card");

    final shared = find.text("Shared with Webshop");
    final received = find.text("Received from Email issuer");
    expect(shared, findsOneWidget);
    expect(received, findsOneWidget);
    expect(
      tester.getTopLeft(shared).dy,
      lessThan(tester.getTopLeft(received).dy),
    );
    // The logged issuance stands in for the card's issuance date.
    expect(find.text("Added to Yivi"), findsNothing);
  });
}
