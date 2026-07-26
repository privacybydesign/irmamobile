import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/models/credential_usage.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/util/disclosure_choice_default.dart";

final _now = DateTime.utc(2026, 7, 1);

int _epochSeconds(DateTime moment) => moment.millisecondsSinceEpoch ~/ 1000;

TrustedParty _issuer() => TrustedParty(
  id: "issuer",
  name: const TranslatedValue.empty(),
  url: null,
  parent: null,
  verified: true,
);

/// A credential instance identified by [hash], issued [issuedDaysAgo] before
/// [_now] (or with no issuance date at all when null).
SelectableCredentialInstance _instance(
  String hash, {
  int? issuedDaysAgo,
  int? expiresInDays,
  bool revoked = false,
  int? batchInstanceCountRemaining,
}) => SelectableCredentialInstance(
  credentialId: "pbdf.sidn-pbdf.email",
  hash: hash,
  name: const TranslatedValue.empty(),
  issuer: _issuer(),
  format: CredentialFormat.sdjwtvc,
  attributes: const [],
  revoked: revoked,
  revocationSupported: false,
  issuanceDate: issuedDaysAgo == null
      ? null
      : _epochSeconds(_now.subtract(Duration(days: issuedDaysAgo))),
  expiryDate: expiresInDays == null
      ? null
      : _epochSeconds(_now.add(Duration(days: expiresInDays))),
  batchInstanceCountRemaining: batchInstanceCountRemaining,
);

DisclosureBundle _bundle(List<SelectableCredentialInstance> credentials) =>
    DisclosureBundle(credentials: credentials);

List<String> _hashOrder(List<DisclosureBundle>? bundles) => (bundles ?? [])
    .map((bundle) => bundle.credentials.map((c) => c.hash).join("+"))
    .toList();

CredentialUsage _usage(int count, {int usedDaysAgo = 1}) => CredentialUsage(
  count: count,
  lastUsed: _now.subtract(Duration(days: usedDaysAgo)),
);

void main() {
  group("owned options are listed chronologically", () {
    test("oldest issued option comes first", () {
      final pickOne = DisclosurePickOne(
        optional: false,
        ownedOptions: [
          _bundle([_instance("newest", issuedDaysAgo: 1)]),
          _bundle([_instance("oldest", issuedDaysAgo: 30)]),
          _bundle([_instance("middle", issuedDaysAgo: 10)]),
        ],
      );

      expect(_hashOrder(pickOne.ownedOptions), ["oldest", "middle", "newest"]);
    });

    test("options without an issuance date sort last, keeping their order", () {
      final pickOne = DisclosurePickOne(
        optional: false,
        ownedOptions: [
          _bundle([_instance("undated-first")]),
          _bundle([_instance("dated", issuedDaysAgo: 5)]),
          _bundle([_instance("undated-second")]),
        ],
      );

      expect(_hashOrder(pickOne.ownedOptions), [
        "dated",
        "undated-first",
        "undated-second",
      ]);
    });

    test("multi-credential options are dated by their oldest credential", () {
      final pickOne = DisclosurePickOne(
        optional: false,
        ownedOptions: [
          _bundle([
            _instance("a", issuedDaysAgo: 8),
            _instance("b", issuedDaysAgo: 2),
          ]),
          _bundle([
            _instance("c", issuedDaysAgo: 20),
            _instance("d", issuedDaysAgo: 1),
          ]),
        ],
      );

      expect(_hashOrder(pickOne.ownedOptions), ["c+d", "a+b"]);
    });

    test("options sharing an oldest credential are split by their newest", () {
      final shared = _instance("shared", issuedDaysAgo: 30);
      final pickOne = DisclosurePickOne(
        optional: false,
        ownedOptions: [
          _bundle([shared, _instance("later", issuedDaysAgo: 2)]),
          _bundle([shared, _instance("earlier", issuedDaysAgo: 9)]),
        ],
      );

      expect(_hashOrder(pickOne.ownedOptions), [
        "shared+earlier",
        "shared+later",
      ]);
    });

    test("an already chronological list is left untouched", () {
      final pickOne = DisclosurePickOne(
        optional: false,
        ownedOptions: [
          _bundle([_instance("first", issuedDaysAgo: 20)]),
          _bundle([_instance("second", issuedDaysAgo: 10)]),
        ],
      );

      expect(_hashOrder(pickOne.ownedOptions), ["first", "second"]);
    });

    test("null owned options stay null", () {
      expect(DisclosurePickOne(optional: false).ownedOptions, isNull);
    });
  });

  group("defaultDisclosureBundleIndex", () {
    test("selects the only option", () {
      final options = [
        _bundle([_instance("only", issuedDaysAgo: 1)]),
      ];

      expect(
        defaultDisclosureBundleIndex(options, usage: const {}, now: _now),
        0,
      );
    });

    test("prefers a valid option over an expired one", () {
      final options = DisclosureBundle.sortedByIssuance([
        _bundle([_instance("expired", issuedDaysAgo: 30, expiresInDays: -1)]),
        _bundle([_instance("valid", issuedDaysAgo: 2, expiresInDays: 30)]),
      ])!;

      // The expired one is still listed first: ordering is chronological.
      expect(_hashOrder(options), ["expired", "valid"]);
      expect(
        defaultDisclosureBundleIndex(options, usage: const {}, now: _now),
        1,
      );
    });

    test("prefers a valid option over a revoked one", () {
      final options = [
        _bundle([_instance("revoked", issuedDaysAgo: 30, revoked: true)]),
        _bundle([_instance("valid", issuedDaysAgo: 2)]),
      ];

      expect(
        defaultDisclosureBundleIndex(options, usage: const {}, now: _now),
        1,
      );
    });

    test("prefers a valid option over one out of batch instances", () {
      final options = [
        _bundle([
          _instance("empty", issuedDaysAgo: 30, batchInstanceCountRemaining: 0),
        ]),
        _bundle([_instance("valid", issuedDaysAgo: 2)]),
      ];

      expect(
        defaultDisclosureBundleIndex(options, usage: const {}, now: _now),
        1,
      );
    });

    test("selects the most used of the valid options", () {
      final options = [
        _bundle([_instance("seldom", issuedDaysAgo: 30)]),
        _bundle([_instance("often", issuedDaysAgo: 10)]),
        _bundle([_instance("sometimes", issuedDaysAgo: 2)]),
      ];

      expect(
        defaultDisclosureBundleIndex(
          options,
          usage: {
            "seldom": _usage(1),
            "often": _usage(7),
            "sometimes": _usage(3),
          },
          now: _now,
        ),
        1,
      );
    });

    test("a more used but expired option does not win", () {
      final options = [
        _bundle([_instance("expired", issuedDaysAgo: 30, expiresInDays: -1)]),
        _bundle([_instance("valid", issuedDaysAgo: 2)]),
      ];

      expect(
        defaultDisclosureBundleIndex(
          options,
          usage: {"expired": _usage(20), "valid": _usage(1)},
          now: _now,
        ),
        1,
      );
    });

    test("equally used options are split by which was used most recently", () {
      final options = [
        _bundle([_instance("stale", issuedDaysAgo: 30)]),
        _bundle([_instance("recent", issuedDaysAgo: 10)]),
      ];

      expect(
        defaultDisclosureBundleIndex(
          options,
          usage: {
            "stale": _usage(4, usedDaysAgo: 40),
            "recent": _usage(4, usedDaysAgo: 1),
          },
          now: _now,
        ),
        1,
      );
    });

    test("with no usage at all the chronologically first option wins", () {
      final options = [
        _bundle([_instance("oldest", issuedDaysAgo: 30)]),
        _bundle([_instance("newest", issuedDaysAgo: 1)]),
      ];

      expect(
        defaultDisclosureBundleIndex(options, usage: const {}, now: _now),
        0,
      );
    });

    test("a multi-credential option counts as used as its least used part", () {
      final options = [
        _bundle([
          _instance("pair-a", issuedDaysAgo: 30),
          _instance("pair-b", issuedDaysAgo: 30),
        ]),
        _bundle([_instance("single", issuedDaysAgo: 10)]),
      ];

      expect(
        defaultDisclosureBundleIndex(
          options,
          usage: {
            // pair-b was disclosed on its own too, but the pair itself only
            // twice, so the single credential is the more used option.
            "pair-a": _usage(2),
            "pair-b": _usage(9),
            "single": _usage(4),
          },
          now: _now,
        ),
        1,
      );
    });

    test("falls back to the first option when none can be disclosed", () {
      final options = [
        _bundle([_instance("expired", issuedDaysAgo: 30, expiresInDays: -1)]),
        _bundle([_instance("revoked", issuedDaysAgo: 2, revoked: true)]),
      ];

      expect(
        defaultDisclosureBundleIndex(
          options,
          usage: {"revoked": _usage(9)},
          now: _now,
        ),
        0,
      );
    });

    test("no options at all yields 0", () {
      expect(
        defaultDisclosureBundleIndex(const [], usage: const {}, now: _now),
        0,
      );
    });
  });
}
