import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/schemaless_credential_store_provider.dart";

CredentialStoreItem _item(String id, String name, String? category) =>
    CredentialStoreItem(
      credential: CredentialDescriptor(
        credentialId: id,
        name: name,
        issuer: TrustedParty(
          id: "issuer",
          name: "Issuer",
          url: null,
          parent: null,
          verified: true,
        ),
        category: category,
        attributes: [],
        issueURL: null,
      ),
      faq: Faq(intro: null, purpose: null, content: null, howTo: null),
    );

/// The store as irmago sends it, grouped and sorted by the provider, as
/// [category, [item ids]] pairs; the staging and demo sections read "staging"
/// and "demo".
Future<List<List<Object>>> _sections(List<CredentialStoreItem> store) async {
  final container = ProviderContainer(
    overrides: [
      credentialStoreProvider.overrideWith((ref) => Stream.value(store)),
    ],
  );
  addTearDown(container.dispose);

  // Riverpod pauses providers nothing listens to, so listen while reading.
  final subscription = container.listen(
    groupedCredentialStoreProvider.future,
    (_, _) {},
  );
  final sections = await subscription.read();

  return [
    for (final section in sections)
      [
        section.source == CredentialStoreSource.production
            ? section.category
            : section.source.name,
        [for (final item in section.items) item.credential.credentialId],
      ],
  ];
}

final _store = [
  _item("pbdf.gemeente.address", "Address", "Personal"),
  _item("pbdf.shop.loyalty", "Loyalty card", null),
  _item("pbdf.sidn-pbdf.mobilenumber", "Mobile number", "Contact"),
  _item("pbdf.pbdf.passport", "Passport", "Personal"),
  _item("pbdf.sidn-pbdf.email", "e-mail", "Contact"),
  _item("pbdf.pbdf.idcard", "ID card", "Personal"),
  _item("pbdf.edu.diploma", "Diploma", "Education"),
  _item("pbdf.pbdf.drivinglicence", "Driving licence", "Personal"),
];

const _expected = [
  [
    "Personal",
    [
      "pbdf.gemeente.address",
      "pbdf.pbdf.drivinglicence",
      "pbdf.pbdf.idcard",
      "pbdf.pbdf.passport",
    ],
  ],
  [
    "Contact",
    ["pbdf.sidn-pbdf.email", "pbdf.sidn-pbdf.mobilenumber"],
  ],
  [
    "Education",
    ["pbdf.edu.diploma"],
  ],
  [
    "",
    ["pbdf.shop.loyalty"],
  ],
];

void main() {
  test(
    "sorts personal first, then categories and names alphabetically",
    () async {
      expect(await _sections(_store), _expected);
    },
  );

  test("gives the same order whatever order irmago sends", () async {
    // irmago iterates a Go map, so every start can hand over another order.
    for (final store in [
      _store.reversed.toList(),
      [..._store.skip(3), ..._store.take(3)],
      [..._store]..sort(
        (a, b) =>
            b.credential.credentialId.compareTo(a.credential.credentialId),
      ),
    ]) {
      expect(await _sections(store), _expected);
    }
  });

  test(
    "puts the staging scheme's credentials in one list at the bottom",
    () async {
      final sections = await _sections([
        ..._store,
        _item("pbdf-staging.pbdf.passport", "Passport", "Personal"),
        _item("pbdf-staging.sidn-pbdf.email", "e-mail", "Contact"),
        _item("pbdf-staging.pbdf.idcard", "ID card", "Personal"),
      ]);
      expect(sections, [
        ..._expected,
        [
          "staging",
          [
            "pbdf-staging.sidn-pbdf.email",
            "pbdf-staging.pbdf.idcard",
            "pbdf-staging.pbdf.passport",
          ],
        ],
      ]);
    },
  );

  test("puts demo credentials in a list of their own below staging", () async {
    // The attribute index's three environments: pbdf, pbdf-staging, irma-demo.
    final sections = await _sections([
      _item("irma-demo.gemeente.address", "Address", "Personal"),
      ..._store,
      _item("irma-demo.MijnOverheid.ageLower", "Age", "Personal"),
      _item("pbdf-staging.pbdf.passport", "Passport", "Personal"),
    ]);
    expect(sections, [
      ..._expected,
      [
        "staging",
        ["pbdf-staging.pbdf.passport"],
      ],
      [
        "demo",
        ["irma-demo.gemeente.address", "irma-demo.MijnOverheid.ageLower"],
      ],
    ]);
  });

  for (final personal in ["Personal", "Persoonlijk", "Persönlich"]) {
    test('puts the personal section first in "$personal"', () async {
      final sections = await _sections([
        _item("pbdf.edu.diploma", "Diploma", "Aardrijkskunde"),
        _item("pbdf.pbdf.passport", "Passport", personal),
      ]);
      expect(sections.first.first, personal);
    });
  }

  test("keeps credentials with the same name in a fixed order", () async {
    final store = [
      _item("b.email", "Email", "Contact"),
      _item("a.email", "Email", "Contact"),
    ];
    expect(await _sections(store), [
      [
        "Contact",
        ["a.email", "b.email"],
      ],
    ]);
    expect(await _sections(store.reversed.toList()), [
      [
        "Contact",
        ["a.email", "b.email"],
      ],
    ]);
  });
}
