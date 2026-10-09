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

/// The data tab is a list of credential TYPES: one card per type, each opening a
/// details screen that lists every credential of that type and offers each its
/// own delete. These tests pin that split, because both ways of getting it wrong
/// have been shipped.
///
/// Keyed too coarsely (by type, everywhere) a second credential became
/// unreachable. Keyed too finely (by hash) the type list rendered one card per
/// credential -- two identical "Proof of Age" cards opening the same screen --
/// and, because the row ValueKey followed, ReorderableListView wrapped duplicate
/// keys in GlobalKeys and threw on every frame, freezing the list.
void main() {
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
  final other = _credential(
    credentialId: "org.iso.18013.5.1.mDL",
    hash: "hash-mdl",
  );

  group("deduplicateCredentialsByType", () {
    test("two credentials of one type fold into a single card", () {
      final result = deduplicateCredentialsByType([first, second]);
      expect(
        result.map((c) => c.credentialId),
        ["eu.europa.ec.av.1"],
        reason:
            "the second is reachable inside the details screen, not as a "
            "second identical card on the data tab",
      );
    });

    test("different types stay separate", () {
      expect(deduplicateCredentialsByType([first, other]), hasLength(2));
    });
  });

  group("reconcileCredentialOrder", () {
    test("keys agree with the deduplication", () {
      final deduped = deduplicateCredentialsByType([first, second]);
      final rendered = reconcileCredentialOrder(
        deduped,
        const [],
        NewItemPolicy.append,
      );

      expect(
        rendered.map((c) => c.credentialId).toSet(),
        hasLength(rendered.length),
        reason:
            "duplicate row keys crash ReorderableListView on every frame, so "
            "whatever is rendered must be uniquely keyable by credentialId",
      );
    });

    test("honours the stored order", () {
      final result = reconcileCredentialOrder(
        [other, first],
        const ["eu.europa.ec.av.1", "org.iso.18013.5.1.mDL"],
        NewItemPolicy.append,
      );
      expect(result.map((c) => c.credentialId), [
        "eu.europa.ec.av.1",
        "org.iso.18013.5.1.mDL",
      ]);
    });

    test("a type whose last credential was deleted disappears", () {
      final result = reconcileCredentialOrder(
        [other],
        const ["eu.europa.ec.av.1", "org.iso.18013.5.1.mDL"],
        NewItemPolicy.append,
      );
      expect(result.map((c) => c.credentialId), ["org.iso.18013.5.1.mDL"]);
    });
  });
}
