import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/screens/activity/activity_entry.dart";

import "helpers/credential_factory.dart";

TrustedParty _party(String name, {bool verified = true, String? url}) =>
    TrustedParty(
      id: name,
      name: name,
      url: url,
      parent: null,
      verified: verified,
    );

LogCredential _credential(String name, {String issuer = "Yivi"}) =>
    LogCredential(
      credentialId: "pbdf.sidn-pbdf.$name",
      formats: const [CredentialFormat.idemix],
      name: name,
      issuer: _party(issuer),
      attributes: [stringAttr(name, "value")],
      revoked: false,
      revocationSupported: false,
    );

final _time = DateTime.utc(2026, 10, 11, 14, 32);

LogInfo _log(
  LogType type, {
  IssuanceLog? issuance,
  DisclosureLog? disclosure,
  SignedMessageLog? signature,
  RemovalLog? removal,
}) => LogInfo(
  type: type,
  time: _time,
  issuanceLog: issuance,
  disclosureLog: disclosure,
  signedMessageLog: signature,
  removalLog: removal,
);

void main() {
  test("a disclosure: the verifier, its host and one shared section", () {
    final entry = ActivityEntry.fromLog(
      _log(
        LogType.disclosure,
        disclosure: DisclosureLog(
          protocol: Protocol.irma,
          credentials: [_credential("email"), _credential("age")],
          verifier: _party(
            "Webshop Noord",
            url: "https://www.webshopnoord.nl/login",
          ),
        ),
      ),
    );
    expect(entry.kind, ActivityKind.shared);
    expect(entry.party.name, "Webshop Noord");
    expect(entry.party.verified, isTrue);
    expect(entry.party.host, "webshopnoord.nl");
    expect(entry.sections.map((s) => s.role), [ActivityRole.shared]);
    expect(entry.cards.map((c) => c.credential.name), ["email", "age"]);
    expect(entry.cards.every((c) => c.disclosure), isTrue);
  });

  test("an issuance: received first, then what was shared to receive it", () {
    final entry = ActivityEntry.fromLog(
      _log(
        LogType.issuance,
        issuance: IssuanceLog(
          protocol: Protocol.irma,
          credentials: [_credential("student")],
          disclosedCredentials: [_credential("personal")],
          issuer: _party("Universiteit Lagewaard"),
        ),
      ),
    );
    expect(entry.kind, ActivityKind.received);
    expect(entry.sections.map((s) => s.role), [
      ActivityRole.received,
      ActivityRole.sharedToReceive,
    ]);
    expect(entry.cards.first.disclosure, isFalse);
    expect(entry.cards.last.disclosure, isTrue);
  });

  test("an issuance without an issuer takes the card's issuer", () {
    final entry = ActivityEntry.fromLog(
      _log(
        LogType.issuance,
        issuance: IssuanceLog(
          protocol: Protocol.irma,
          credentials: [_credential("email", issuer: "Privacy by Design")],
          disclosedCredentials: const [],
        ),
      ),
    );
    expect(entry.party.name, "Privacy by Design");
    expect(entry.party.verified, isFalse);
    expect(entry.sections.single.role, ActivityRole.received);
  });

  test("a signature keeps its message", () {
    final entry = ActivityEntry.fromLog(
      _log(
        LogType.signature,
        signature: SignedMessageLog(
          protocol: Protocol.irma,
          credentials: [_credential("personal")],
          verifier: _party("Gemeente"),
          message: "I agree",
        ),
      ),
    );
    expect(entry.kind, ActivityKind.signed);
    expect(entry.message, "I agree");
    expect(entry.sections.single.role, ActivityRole.signedWith);
  });

  test("a removal has no party: the card's issuer, never verified", () {
    final entry = ActivityEntry.fromLog(
      _log(
        LogType.removal,
        removal: RemovalLog(
          credentials: [_credential("mobile", issuer: "Privacy by Design")],
        ),
      ),
    );
    expect(entry.kind, ActivityKind.deleted);
    expect(entry.party.name, "Privacy by Design");
    expect(entry.party.verified, isFalse);
    expect(entry.cards.single.deleted, isTrue);
    expect(entry.cards.single.disclosure, isFalse);
  });

  test("a disclosure of nothing has no sections", () {
    final entry = ActivityEntry.fromLog(
      _log(
        LogType.disclosure,
        disclosure: DisclosureLog(
          protocol: Protocol.irma,
          credentials: const [],
          verifier: _party("Webshop Noord"),
        ),
      ),
    );
    expect(entry.sections, isEmpty);
    expect(entry.cards, isEmpty);
  });

  test("the key and hero tags stay the same for the same entry", () {
    LogInfo log() => _log(
      LogType.removal,
      removal: RemovalLog(credentials: [_credential("mobile")]),
    );
    final a = ActivityEntry.fromLog(log());
    final b = ActivityEntry.fromLog(log());
    expect(a.key, b.key);
    expect(a.heroTag(0), b.heroTag(0));
    expect(a.heroTag(0), isNot(a.heroTag(1)));
  });
}
