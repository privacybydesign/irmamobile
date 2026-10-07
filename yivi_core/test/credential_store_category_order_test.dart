import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/schemaless_credential_store_provider.dart";

/// The add-data store puts the personal section first, and it recognises that
/// section by its display text: the resolved DTO carries no stable category
/// key, so `_personalCategoryNames` in the provider is a hard-coded set of the
/// resolved wording in each supported language.
///
/// That set is the fragile part, and it fails silently. If a scheme rewords one
/// of these, or starts resolving a category in a language the set does not
/// list, nothing throws — the personal section simply stops being hoisted and
/// lands wherever grouping happened to leave it. These tests are what the
/// provider's comment promises: edit the set and they fail loudly here instead
/// of quietly on a user's screen. The durable fix is a category identifier on
/// irmago's side; until then this is the guard.
CredentialStoreItem _item({required String? category, required String name}) =>
    CredentialStoreItem(
      credential: CredentialDescriptor(
        credentialId: name,
        name: name,
        issuer: TrustedParty(
          id: "test-issuer",
          name: "Test Issuer",
          url: null,
          parent: null,
          verified: true,
        ),
        category: category,
        attributes: const [],
        issueURL: null,
      ),
      faq: Faq(intro: null, purpose: null, content: null, howTo: null),
    );

Future<List<String>> _categoryOrder(List<CredentialStoreItem> items) async {
  final container = ProviderContainer.test(
    overrides: [
      credentialStoreProvider.overrideWith(
        (ref) => Stream<List<CredentialStoreItem>>.value(items),
      ),
    ],
  );

  // The listener is load-bearing, not tidiness. Every provider is auto-dispose
  // in Riverpod 3, so awaiting `.future` with nothing listening disposes the
  // provider while it is still loading and the await never completes --
  // "disposed during loading state, yet no value could be emitted", thirty
  // seconds later, which reads as a hung provider rather than a missing listen.
  container.listen(groupedCredentialStoreProvider, (_, _) {});

  final grouped = await container.read(groupedCredentialStoreProvider.future);
  return grouped.map((c) => c.category).toList();
}

void main() {
  // Exactly the wording the provider hard-codes. Adding a language to the app
  // without adding its resolved wording here is the failure this pins.
  const personalNames = {"Personal", "Persoonlijk", "Persönlich"};

  for (final personal in personalNames) {
    test("the $personal section is hoisted to the front", () async {
      // Deliberately last in the input, so passing cannot be insertion order.
      final order = await _categoryOrder([
        _item(category: "Education", name: "diploma"),
        _item(category: "Work", name: "employee"),
        _item(category: personal, name: "passport"),
      ]);

      expect(order.first, personal);
      expect(order, hasLength(3));
    });
  }

  test("every other category keeps the order it arrived in", () async {
    final order = await _categoryOrder([
      _item(category: "Work", name: "employee"),
      _item(category: "Personal", name: "passport"),
      _item(category: "Education", name: "diploma"),
    ]);

    // Personal first, then Work before Education as they were given: the
    // comparator returns 0 for two non-personal categories, so grouping order
    // survives rather than being re-sorted alphabetically.
    expect(order, ["Personal", "Work", "Education"]);
  });

  test(
    "a category outside the set is NOT hoisted, which is the known gap",
    () async {
      // "Personlig" is Danish for the same section. It is not in the set, so it
      // is treated as any other category -- the silent failure the provider's
      // comment warns about, pinned here so the cost of adding a language is
      // visible rather than discovered on a screen.
      final order = await _categoryOrder([
        _item(category: "Work", name: "employee"),
        _item(category: "Personlig", name: "passport"),
      ]);

      expect(order.first, isNot("Personlig"));
      expect(order, ["Work", "Personlig"]);
    },
  );

  test("credentials with no category group under the empty string", () async {
    final order = await _categoryOrder([
      _item(category: null, name: "uncategorised"),
      _item(category: "Personal", name: "passport"),
    ]);

    expect(order.first, "Personal");
    expect(order, contains(""));
  });
}
