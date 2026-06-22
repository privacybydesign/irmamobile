import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_selection.dart";

TrustedParty _issuer() => TrustedParty(
  id: "pbdf.sidn-pbdf",
  name: const TranslatedValue.empty(),
  url: null,
  parent: null,
  verified: true,
);

/// A single email credential instance. The [hash] is the stable identity used
/// for selection; [email] is the value that would actually be disclosed.
SelectableCredentialInstance _emailInstance({
  required String hash,
  required String email,
}) => SelectableCredentialInstance(
  credentialId: "pbdf.sidn-pbdf.email",
  hash: hash,
  name: const TranslatedValue.empty(),
  issuer: _issuer(),
  format: CredentialFormat.idemix,
  revoked: false,
  revocationSupported: false,
  attributes: [
    Attribute(
      claimPath: const ["pbdf.sidn-pbdf.email.email"],
      displayName: const TranslatedValue.empty(),
      value: AttributeValue(type: AttributeType.string, string: email),
    ),
  ],
);

DisclosureBundle _emailBundle({required String hash, required String email}) =>
    DisclosureBundle(
      credentials: [_emailInstance(hash: hash, email: email)],
    );

String _emailOf(DisclosureBundle bundle) =>
    bundle.credentials.single.attributes.single.value!.string!;

void main() {
  group("selectedBundleIndex / resolveSelectedBundle", () {
    test("resolves a selection by hash identity, not list position", () {
      final example = _emailBundle(
        hash: "h-example",
        email: "user@example.com",
      );
      final work = _emailBundle(hash: "h-work", email: "user@work.com");
      final personal = _emailBundle(
        hash: "h-personal",
        email: "user@personal.com",
      );

      final owned = [example, work, personal];

      // The user selects user@work.com, which sits at index 1.
      final selectedHashes = work.credentialHashes;
      expect(selectedBundleIndex(owned, selectedHashes), 1);
      expect(
        _emailOf(resolveSelectedBundle(owned, selectedHashes)!),
        "user@work.com",
      );
    });

    test(
      "regression #520: deleting a credential mid-session keeps the selected "
      "email pointing at the chosen credential, not the one that shifted into "
      "its slot",
      () {
        final example = _emailBundle(
          hash: "h-example",
          email: "user@example.com",
        );
        final work = _emailBundle(hash: "h-work", email: "user@work.com");
        final personal = _emailBundle(
          hash: "h-personal",
          email: "user@personal.com",
        );

        // Session starts with three email credentials; the user selects
        // user@work.com (index 1). The selection is stored by hash identity.
        final selectedHashes = work.credentialHashes;
        final ownedBefore = [example, work, personal];
        expect(selectedBundleIndex(ownedBefore, selectedHashes), 1);

        // The user deletes user@example.com mid-session. The owned list shrinks
        // and every entry below the deletion shifts up by one: index 1 is now
        // user@personal.com.
        final ownedAfter = [work, personal];
        expect(_emailOf(ownedAfter[1]), "user@personal.com");

        // A naive index-based selection would now disclose the credential that
        // shifted into slot 1 (user@personal.com) — the exact bug in #520.
        // Identity-based resolution still finds user@work.com.
        final resolved = resolveSelectedBundle(ownedAfter, selectedHashes);
        expect(resolved, isNotNull);
        expect(_emailOf(resolved!), "user@work.com");
        expect(selectedBundleIndex(ownedAfter, selectedHashes), 0);
      },
    );

    test("returns null when the selected credential was itself deleted", () {
      final work = _emailBundle(hash: "h-work", email: "user@work.com");
      final personal = _emailBundle(
        hash: "h-personal",
        email: "user@personal.com",
      );

      // The user selected user@work.com, then deleted it. It is no longer in
      // the owned list, so there is no stable match — callers fall back to a
      // default rather than silently disclosing an unrelated credential.
      final ownedAfter = [personal];
      expect(selectedBundleIndex(ownedAfter, work.credentialHashes), isNull);
      expect(resolveSelectedBundle(ownedAfter, work.credentialHashes), isNull);
    });

    test("matches on full set equality for multi-credential bundles", () {
      final bundleAB = DisclosureBundle(
        credentials: [
          _emailInstance(hash: "a", email: "a@x.com"),
          _emailInstance(hash: "b", email: "b@x.com"),
        ],
      );
      final bundleA = _emailBundle(hash: "a", email: "a@x.com");
      final owned = [bundleA, bundleAB];

      // {a, b} must match the {a, b} bundle, not the partial {a} bundle.
      expect(selectedBundleIndex(owned, {"a", "b"}), 1);
      // A subset must not match a superset bundle.
      expect(selectedBundleIndex([bundleAB], {"a"}), isNull);
    });
  });
}
