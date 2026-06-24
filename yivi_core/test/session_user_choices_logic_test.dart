import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/providers/session_user_choices_provider.dart";

TrustedParty _issuer() => TrustedParty(
  id: "issuer",
  name: const TranslatedValue.empty(),
  url: null,
  parent: null,
  verified: true,
);

/// A single owned credential instance, identified by its [hash].
SelectableCredentialInstance _instance(String hash) =>
    SelectableCredentialInstance(
      credentialId: "pbdf.pbdf.email",
      hash: hash,
      name: const TranslatedValue.empty(),
      issuer: _issuer(),
      format: CredentialFormat.idemix,
      attributes: const [],
      revoked: false,
      revocationSupported: false,
    );

/// An owned option bundle containing one credential instance per [hashes].
DisclosureBundle _bundle(List<String> hashes) =>
    DisclosureBundle(credentials: hashes.map(_instance).toList());

void main() {
  group("newlyIssuedBundleToSelect", () {
    test("returns null when there are no owned options", () {
      expect(
        SessionUserChoicesNotifier.newlyIssuedBundleToSelect(
          ownedOptions: const [],
          previousHashes: const {},
        ),
        isNull,
      );
    });

    test("returns null when no owned bundle contains a new credential", () {
      final existing = _bundle(["existing-email"]);
      expect(
        SessionUserChoicesNotifier.newlyIssuedBundleToSelect(
          ownedOptions: [existing],
          previousHashes: {"existing-email"},
        ),
        isNull,
      );
    });

    test(
      "selects the newly obtained email after adding a new email address",
      () {
        // The "Share your email address" example from issue #298:
        //  - Before obtaining: only the existing email is owned.
        //  - The user picks "Add a new email address" and completes issuance.
        //  - The new email is appended to the bottom of the owned options and
        //    must become the selected option.
        final existingEmail = _bundle(["existing-email"]);
        final newEmail = _bundle(["new-email"]);

        final selected = SessionUserChoicesNotifier.newlyIssuedBundleToSelect(
          ownedOptions: [existingEmail, newEmail],
          previousHashes: {"existing-email"},
          currentSelection: existingEmail,
        );

        expect(selected, same(newEmail));
      },
    );

    test(
      "selects the bottom-most bundle when several contain new credentials",
      () {
        final old = _bundle(["old"]);
        final firstNew = _bundle(["new-a"]);
        final bottomNew = _bundle(["new-b"]);

        final selected = SessionUserChoicesNotifier.newlyIssuedBundleToSelect(
          ownedOptions: [old, firstNew, bottomNew],
          previousHashes: {"old"},
        );

        // The last (bottom-most) bundle with a new credential wins, not the
        // first one encountered.
        expect(selected, same(bottomNew));
      },
    );

    test(
      "keeps the user's current selection when it contains a new credential",
      () {
        // A credential shared across bundles should not silently switch the
        // user's existing choice if that choice already includes the new
        // credential.
        final currentWithNew = _bundle(["shared-new"]);
        final otherWithNew = _bundle(["shared-new", "extra"]);

        final selected = SessionUserChoicesNotifier.newlyIssuedBundleToSelect(
          ownedOptions: [otherWithNew, currentWithNew],
          previousHashes: const {},
          currentSelection: currentWithNew,
        );

        expect(selected, same(currentWithNew));
      },
    );
  });
}
