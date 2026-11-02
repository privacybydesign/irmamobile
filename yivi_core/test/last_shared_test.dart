import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/screens/session/models/disclosure_view_model.dart";

// Which card a request starts on: the one last shared with this requestor,
// else the one last shared with anyone, else the first that can be shared.

const _future = 4102444800;

TrustedParty _party(String name, {String? id}) => TrustedParty(
  id: id ?? name,
  name: name,
  url: null,
  parent: null,
  verified: true,
);

SelectableCredentialInstance _email(String address, {bool revoked = false}) =>
    SelectableCredentialInstance(
      credentialId: "pbdf.sidn-pbdf.email",
      hash: "hash-$address",
      name: "Email address",
      issuer: _party("Yivi"),
      format: CredentialFormat.idemix,
      attributes: [
        Attribute(
          claimPath: ["email"],
          displayName: "Email address",
          value: AttributeValue(type: AttributeType.string, string: address),
        ),
      ],
      revoked: revoked,
      revocationSupported: revoked,
      expiryDate: _future,
    );

DisclosurePickOne _emails(
  List<SelectableCredentialInstance> cards, {
  bool optional = false,
}) => DisclosurePickOne(
  optional: optional,
  ownedOptions: [
    for (final c in cards) DisclosureBundle(credentials: [c]),
  ],
);

LogInfo _shared(TrustedParty who, DateTime time, {String id = ""}) => LogInfo(
  id: id,
  type: LogType.disclosure,
  time: time,
  issuanceLog: null,
  disclosureLog: DisclosureLog(
    protocol: Protocol.irma,
    credentials: const [],
    verifier: who,
  ),
  signedMessageLog: null,
  removalLog: null,
);

final _shop = _party("Webshop Noord");
final _bank = _party("Bank");
final _a = _email("a@example.com");
final _b = _email("b@example.com");
final _c = _email("c@example.com");

void main() {
  test("the card last shared with this requestor", () {
    final shares = {
      // A went to the shop; B went to the bank later.
      _a.hash: [_shared(_shop, DateTime.utc(2026, 10, 1))],
      _b.hash: [_shared(_bank, DateTime.utc(2026, 10, 20))],
    };
    final out = lastSharedBundles(
      [
        _emails([_a, _b, _c]),
      ],
      _shop,
      (hash) => shares[hash],
    );
    expect(out, {
      0: {_a.hash},
    });
  });

  test("of two shared with this requestor, the latest", () {
    final shares = {
      _a.hash: [_shared(_shop, DateTime.utc(2026, 10, 1))],
      _b.hash: [
        _shared(_bank, DateTime.utc(2026, 10, 25)),
        _shared(_shop, DateTime.utc(2026, 10, 5)),
      ],
    };
    final out = lastSharedBundles(
      [
        _emails([_a, _b]),
      ],
      _shop,
      (hash) => shares[hash],
    );
    expect(out[0], {_b.hash});
  });

  test("never with this requestor: the card last shared with anyone", () {
    final shares = {
      _a.hash: [_shared(_bank, DateTime.utc(2026, 10, 1))],
      _c.hash: [_shared(_party("School"), DateTime.utc(2026, 10, 9))],
    };
    final out = lastSharedBundles(
      [
        _emails([_a, _b, _c]),
      ],
      _shop,
      (hash) => shares[hash],
    );
    expect(out[0], {_c.hash});
  });

  test("never shared, still looking it up, or optional: no preference", () {
    expect(
      lastSharedBundles(
        [
          _emails([_a, _b]),
        ],
        _shop,
        (_) => null,
      ),
      isEmpty,
    );
    expect(
      lastSharedBundles(
        [
          _emails([_a], optional: true),
        ],
        _shop,
        (_) => [_shared(_shop, DateTime.utc(2026, 10, 1))],
      ),
      isEmpty,
    );
  });

  test("a card that cannot be shared any more is passed over", () {
    final revoked = _email("a@example.com", revoked: true);
    final shares = {
      revoked.hash: [_shared(_shop, DateTime.utc(2026, 10, 20))],
      _b.hash: [_shared(_bank, DateTime.utc(2026, 10, 1))],
    };
    final out = lastSharedBundles(
      [
        _emails([revoked, _b]),
      ],
      _shop,
      (hash) => shares[hash],
    );
    expect(out[0], {_b.hash});
  });

  test("a requestor without an id is the same party by name", () {
    final noId = _party("Gemeente Almere", id: "");
    final shares = {
      _b.hash: [
        _shared(_party("gemeente almere ", id: ""), DateTime.utc(2026, 10, 1)),
      ],
      _a.hash: [_shared(_bank, DateTime.utc(2026, 10, 20))],
    };
    final out = lastSharedBundles(
      [
        _emails([_a, _b]),
      ],
      noId,
      (hash) => shares[hash],
    );
    expect(out[0], {_b.hash});
  });

  test("selectionsFrom: what the user picked, else what was shared before", () {
    final pickOne = _emails([_a, _b, _c]);
    final before = {
      0: {_c.hash},
    };
    expect(selectionsFrom([pickOne], {}, {}, preferred: before), {0: 2});
    expect(
      selectionsFrom(
        [pickOne],
        {0: pickOne.ownedOptions![1]},
        {},
        preferred: before,
      ),
      {0: 1},
    );
    // Shared before, but not on offer now: the default.
    expect(
      selectionsFrom(
        [pickOne],
        {},
        {},
        preferred: {
          0: {"gone"},
        },
      ),
      {0: 0},
    );
  });
}
