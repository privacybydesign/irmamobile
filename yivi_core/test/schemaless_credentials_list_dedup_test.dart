import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";

/// A credential carrying only what the list logic reads: its docType-shaped
/// credentialId and its content hash.
Credential _credential({required String credentialId, required String hash}) =>
    Credential(
      credentialId: credentialId,
      hash: hash,
      name: credentialId,
      issuer: TrustedParty(
        id: "test-issuer",
        name: "Test Issuer",
        url: null,
        parent: null,
        verified: true,
      ),
      credentialInstanceIds: const {CredentialFormat.msoMdoc: "instance"},
      batchInstanceCountsRemaining: const {},
      attributes: const [],
      revoked: false,
      revocationSupported: false,
      issueUrl: null,
    );

void main() {
  _keysAreUnique();

  // Two Age Verification attestations. credentialId is the docType, so it is the
  // same for both; only the content hash tells them apart.
  final first = _credential(
    credentialId: "eu.europa.ec.av.1",
    hash: "hash-first",
  );
  final second = _credential(
    credentialId: "eu.europa.ec.av.1",
    hash: "hash-second",
  );

  group("deduplicateCredentialsByHash", () {
    test("keeps two credentials that share a docType", () {
      final result = deduplicateCredentialsByHash([first, second]);
      expect(
        result,
        hasLength(2),
        reason:
            "keying on credentialId hid one AV attestation: it could not be "
            "seen or deleted, yet disclosure still offered it",
      );
    });

    test("still collapses the same credential arriving twice", () {
      expect(deduplicateCredentialsByHash([first, first]), hasLength(1));
    });
  });

  group("reconcileCredentialOrder", () {
    test("keeps both same-docType credentials", () {
      final result = reconcileCredentialOrder(
        [first, second],
        const ["hash-first", "hash-second"],
        NewItemPolicy.append,
      );
      expect(result.map((c) => c.hash), ["hash-first", "hash-second"]);
    });

    test("honours the stored order", () {
      final result = reconcileCredentialOrder(
        [first, second],
        const ["hash-second", "hash-first"],
        NewItemPolicy.append,
      );
      expect(result.map((c) => c.hash), ["hash-second", "hash-first"]);
    });

    test("deleting one leaves the other visible", () {
      // What the wallet reports after one of the two batches is removed.
      final result = reconcileCredentialOrder(
        [second],
        const ["hash-first", "hash-second"],
        NewItemPolicy.append,
      );
      expect(result.map((c) => c.hash), ["hash-second"]);
    });

    test("an order stored by an older build places them by policy", () {
      // Old entries hold credentialIds, which match no hash.
      final result = reconcileCredentialOrder(
        [first, second],
        const ["eu.europa.ec.av.1"],
        NewItemPolicy.append,
      );
      expect(result, hasLength(2));
    });
  });
}

// The list widget keys each row by credential. Two credentials of one docType
// share a credentialId, and ReorderableListView wraps every child key in a
// GlobalKey, so keying on credentialId threw "Multiple widgets used the same
// GlobalKey" on every frame once the list stopped deduplicating by type. The
// list then never finished rebuilding, so deleted credentials stayed on screen.
//
// This is the property the widget's ValueKey depends on, asserted where it can
// be checked cheaply: whatever the list renders must be uniquely keyable by
// hash.
void _keysAreUnique() {
  test("rendered credentials are uniquely keyable by hash", () {
    final first = _credential(
      credentialId: "eu.europa.ec.av.1",
      hash: "hash-first",
    );
    final second = _credential(
      credentialId: "eu.europa.ec.av.1",
      hash: "hash-second",
    );

    final rendered = reconcileCredentialOrder(
      deduplicateCredentialsByHash([first, second]),
      const [],
      NewItemPolicy.append,
    );

    expect(rendered, hasLength(2));
    expect(
      rendered.map((c) => c.hash).toSet(),
      hasLength(rendered.length),
      reason: "duplicate keys crash ReorderableListView on every frame",
    );
    expect(
      rendered.map((c) => c.credentialId).toSet(),
      hasLength(1),
      reason: "and credentialId is NOT unique, which is why it cannot be the key",
    );
  });
}
