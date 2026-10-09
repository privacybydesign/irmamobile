import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/favourite_credentials_provider.dart";
import "package:yivi_core/src/providers/feature_flag_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/schemaless_credential_store_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";

import "helpers/data_tab_fixtures.dart";

ProviderContainer _container({
  Set<FeatureFlag> flags = const {},
  List<Credential> credentials = const [],
  List<CredentialStoreItem> store = const [],
  IrmaPreferences? prefs,
  Stream<List<CredentialStoreItem>>? storeStream,
}) {
  final container = ProviderContainer(
    overrides: [
      for (final flag in FeatureFlag.values)
        featureFlagProvider(
          flag,
        ).overrideWith((ref) => Stream.value(flags.contains(flag))),
      schemalessCredentialOrderControllerProvider.overrideWith(
        () => FixedOrderController(credentials),
      ),
      schemalessCredentialsProvider.overrideWith(
        (ref) =>
            Stream.value((credentials: credentials, problematic: const [])),
      ),
      credentialStoreProvider.overrideWith(
        (ref) => storeStream ?? Stream.value(store),
      ),
      if (prefs != null) preferencesProvider.overrideWithValue(prefs),
      if (prefs == null)
        favouriteCredentialsProvider.overrideWith((ref) => Stream.value([])),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// The sections as [kind or category, [credential ids]] pairs.
Future<List<List<Object>>> _sections(ProviderContainer container) async {
  // Riverpod pauses providers nothing listens to, so listen while reading.
  final subscription = container.listen(dataTabSectionsProvider, (_, _) {});
  addTearDown(subscription.close);
  // Let the stream-backed providers deliver their first values.
  await pumpEventQueue();

  return [
    for (final section in subscription.read().requireValue)
      [
        section.kind == DataTabSectionKind.category
            ? section.category
            : section.kind.name,
        [for (final c in section.credentials) c.credentialId],
      ],
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("layout", () {
    DataTabLayout layoutFor(Set<FeatureFlag> flags) =>
        _container(flags: flags).read(dataTabLayoutProvider);

    Future<DataTabLayout> settledLayout(Set<FeatureFlag> flags) async {
      final container = _container(flags: flags);
      final subscription = container.listen(dataTabLayoutProvider, (_, _) {});
      await pumpEventQueue();
      final layout = subscription.read();
      subscription.close();
      return layout;
    }

    test("is the classic list while the flags are still loading", () {
      expect(layoutFor({FeatureFlag.dataTabV2}), DataTabLayout.classic);
    });

    test("is the classic list with both flags off", () async {
      expect(await settledLayout({}), DataTabLayout.classic);
    });

    test("puts staging and demo apart with dataTabV2", () async {
      expect(
        await settledLayout({FeatureFlag.dataTabV2}),
        DataTabLayout.sourcesApart,
      );
    });

    test("groups by category with dataTabCategories", () async {
      expect(
        await settledLayout({FeatureFlag.dataTabCategories}),
        DataTabLayout.categories,
      );
    });

    test("ignores unrelated flags", () async {
      expect(
        await settledLayout({
          FeatureFlag.onboardingV2,
          FeatureFlag.emailLinking,
        }),
        DataTabLayout.classic,
      );
    });
  });

  group("dataTabV2 sections", () {
    final held = [
      heldCredential("irma-demo.demo.one"),
      heldCredential("pbdf.sidn-pbdf.email"),
      heldCredential("pbdf-staging.staging.one"),
      heldCredential("pbdf.gemeente.address"),
      heldCredential("irma-demo.demo.two"),
    ];

    test("keeps the user's order and puts staging and demo last", () async {
      final container = _container(
        flags: {FeatureFlag.dataTabV2},
        credentials: held,
      );

      expect(await _sections(container), [
        [
          "ungrouped",
          ["pbdf.sidn-pbdf.email", "pbdf.gemeente.address"],
        ],
        [
          "staging",
          ["pbdf-staging.staging.one"],
        ],
        [
          "demo",
          ["irma-demo.demo.one", "irma-demo.demo.two"],
        ],
      ]);
    });

    test("leaves out the sections without credentials", () async {
      final container = _container(
        flags: {FeatureFlag.dataTabV2},
        credentials: [heldCredential("pbdf.sidn-pbdf.email")],
      );

      expect(await _sections(container), [
        [
          "ungrouped",
          ["pbdf.sidn-pbdf.email"],
        ],
      ]);
    });

    test("is empty for the classic layout, which has no sections", () async {
      final container = _container(credentials: held);

      expect(await _sections(container), isEmpty);
    });
  });

  group("dataTabCategories sections", () {
    final store = [
      storeItem("pbdf.gemeente.address", "Address", "Personal"),
      storeItem("pbdf.sidn-pbdf.email", "E-mail", "Contact"),
      storeItem("pbdf.shop.loyalty", "Loyalty card", null),
      storeItem("pbdf.sidn-pbdf.mobilenumber", "Mobile number", "Contact"),
      storeItem("pbdf.pbdf.passport", "Passport", "Personal"),
      storeItem("pbdf.bank.iban", "IBAN", "Financial"),
    ];

    // As the user dragged them.
    final held = [
      heldCredential("pbdf.sidn-pbdf.mobilenumber"),
      heldCredential("irma-demo.demo.one"),
      heldCredential("pbdf.bank.iban"),
      heldCredential("pbdf.removed.from-scheme"),
      heldCredential("pbdf.pbdf.passport"),
      heldCredential("pbdf-staging.staging.one"),
      heldCredential("pbdf.sidn-pbdf.email"),
      heldCredential("pbdf.shop.loyalty"),
    ];

    test(
      "orders the categories as the add data screen does, each in the user's order",
      () async {
        final container = _container(
          flags: {FeatureFlag.dataTabCategories},
          credentials: held,
          store: store,
        );

        expect(await _sections(container), [
          [
            "Personal",
            ["pbdf.pbdf.passport"],
          ],
          [
            "Contact",
            ["pbdf.sidn-pbdf.mobilenumber", "pbdf.sidn-pbdf.email"],
          ],
          [
            "Financial",
            ["pbdf.bank.iban"],
          ],
          // No category, or not in the store at all.
          [
            "",
            ["pbdf.removed.from-scheme", "pbdf.shop.loyalty"],
          ],
          [
            "staging",
            ["pbdf-staging.staging.one"],
          ],
          [
            "demo",
            ["irma-demo.demo.one"],
          ],
        ]);
      },
    );

    test(
      "puts the favourites first and takes them out of their category",
      () async {
        final prefs = await freshPrefs();
        await prefs.setFavouriteCredentials([
          "pbdf.sidn-pbdf.email",
          "irma-demo.demo.one",
          "pbdf.gone.since",
        ]);
        final container = _container(
          flags: {FeatureFlag.dataTabCategories},
          credentials: held,
          store: store,
          prefs: prefs,
        );

        expect(await _sections(container), [
          [
            "favourites",
            // In the user's order, not in the order they were pinned.
            ["irma-demo.demo.one", "pbdf.sidn-pbdf.email"],
          ],
          [
            "Personal",
            ["pbdf.pbdf.passport"],
          ],
          [
            "Contact",
            ["pbdf.sidn-pbdf.mobilenumber"],
          ],
          [
            "Financial",
            ["pbdf.bank.iban"],
          ],
          [
            "",
            ["pbdf.removed.from-scheme", "pbdf.shop.loyalty"],
          ],
          [
            "staging",
            ["pbdf-staging.staging.one"],
          ],
        ]);
      },
    );

    test(
      "waits for the store instead of showing everything uncategorised",
      () async {
        final pending = StreamController<List<CredentialStoreItem>>();
        addTearDown(pending.close);
        final container = _container(
          flags: {FeatureFlag.dataTabCategories},
          credentials: held,
          storeStream: pending.stream,
        );
        final subscription = container.listen(
          dataTabSectionsProvider,
          (_, _) {},
        );
        await pumpEventQueue();

        expect(subscription.read(), isA<AsyncLoading>());

        pending.add(store);
        await pumpEventQueue();

        expect(subscription.read(), isA<AsyncData>());
      },
    );
  });

  group("expired credential types", () {
    Future<Set<String>> expiredTypes({
      required Set<FeatureFlag> flags,
      required List<Credential> credentials,
    }) async {
      final container = _container(flags: flags, credentials: credentials);
      final subscription = container.listen(
        expiredCredentialTypesProvider,
        (_, _) {},
      );
      // The flag and the credentials arrive from streams.
      await pumpEventQueue();
      final expired = subscription.read();
      subscription.close();
      return expired;
    }

    test("are none while dataTabV2 is off", () async {
      final expired = await expiredTypes(
        flags: {},
        credentials: [heldCredential("pbdf.a", expired: true)],
      );

      expect(expired, isEmpty);
    });

    test("are the types whose credentials all expired", () async {
      final expired = await expiredTypes(
        flags: {FeatureFlag.dataTabV2},
        credentials: [
          heldCredential("pbdf.expired", expired: true),
          heldCredential("pbdf.valid"),
          heldCredential("pbdf.both", expired: true),
          heldCredential("pbdf.both"),
          heldCredential("pbdf.twice", expired: true),
          heldCredential("pbdf.twice", expired: true),
        ],
      );

      expect(expired, {"pbdf.expired", "pbdf.twice"});
    });

    test("include a credential that has no instances left", () async {
      final expired = await expiredTypes(
        flags: {FeatureFlag.dataTabV2},
        credentials: [
          heldCredential("pbdf.used-up", instancesLeft: 0),
          heldCredential("pbdf.few-left", instancesLeft: 2),
        ],
      );

      expect(expired, {"pbdf.used-up"});
    });
  });

  group("reordering one section", () {
    final all = [
      for (final id in ["a", "b", "c", "d", "e"]) heldCredential("pbdf.x.$id"),
    ];
    final section = [all[1], all[3]]; // b and d, with c between them

    /// The order after the move, and the order saved once the delay is over.
    Future<({List<String> order, List<String> saved})> reorderWithin(
      int oldIndex,
      int newIndex, {
      List<Credential>? of,
    }) async {
      final prefs = await freshPrefs();
      final container = _container(
        flags: {FeatureFlag.dataTabV2},
        credentials: all,
        prefs: prefs,
      );
      final subscription = container.listen(
        schemalessCredentialOrderControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(schemalessCredentialOrderControllerProvider.future);

      container
          .read(schemalessCredentialOrderControllerProvider.notifier)
          .reorderWithin(of ?? section, oldIndex, newIndex);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      return (
        order: [
          for (final c in subscription.read().requireValue) c.credentialId,
        ],
        saved: prefs.getCredentialOrder(),
      );
    }

    test("moves a credential before its neighbour in the section", () async {
      final result = await reorderWithin(1, 0);

      expect(result.order, [
        "pbdf.x.a",
        "pbdf.x.d",
        "pbdf.x.b",
        "pbdf.x.c",
        "pbdf.x.e",
      ]);
      expect(result.saved, result.order);
    });

    test("moves a credential to the end of the section", () async {
      final result = await reorderWithin(0, 1);

      expect(result.order, [
        "pbdf.x.a",
        "pbdf.x.c",
        "pbdf.x.d",
        "pbdf.x.b",
        "pbdf.x.e",
      ]);
      expect(result.saved, result.order);
    });

    test("leaves a section of one where it is", () async {
      final result = await reorderWithin(0, 0, of: [all[2]]);

      expect(result.order, [for (final c in all) c.credentialId]);
      expect(result.saved, isEmpty);
    });
  });
}
