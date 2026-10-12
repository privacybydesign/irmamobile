import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/data_tab_sections_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";

import "helpers/data_tab_fixtures.dart";

final _held = [
  heldCredential("pbdf.sidn-pbdf.email", name: "E-mail"),
  heldCredential("irma-demo.demo.card", name: "Demo card"),
  heldCredential("pbdf.pbdf.passport", name: "Passport"),
  heldCredential("pbdf-staging.staging.card", name: "Staging card"),
  heldCredential("pbdf.shop.loyalty", name: "Loyalty card"),
  heldCredential("pbdf.sidn-pbdf.mobilenumber", name: "Mobile number"),
];

final _store = [
  storeItem("pbdf.sidn-pbdf.email", "E-mail", "Contact"),
  storeItem("pbdf.sidn-pbdf.mobilenumber", "Mobile number", "Contact"),
  storeItem("pbdf.pbdf.passport", "Passport", "Personal"),
];

/// A container for a wallet that holds [held], with the data tab sections
/// being listened to.
Future<ProviderContainer> _container({
  List<Credential>? held,
  Set<FeatureFlag> flags = const {},
  List<String> favourites = const [],
}) async {
  final credentials = held ?? _held;
  final prefs = await freshPrefs(
    order: [for (final c in credentials) c.credentialId],
  );
  await prefs.setFavouriteCredentials(favourites);

  final container = ProviderContainer(
    overrides: dataTabOverrides(
      held: credentials,
      prefs: prefs,
      store: _store,
      flags: flags,
    ),
  );
  addTearDown(container.dispose);

  // Riverpod pauses providers nothing listens to, so listen while reading.
  final loaded = Completer<void>();
  container.listen(dataTabSectionsProvider, (_, sections) {
    if (!sections.isLoading && !loaded.isCompleted) loaded.complete();
  }, fireImmediately: true);
  await loaded.future;

  return container;
}

/// The sections as `kind` or `kind:category` keys with the names of their
/// credentials.
Map<String, List<String>> _sections(ProviderContainer container) => {
  for (final section in container.read(dataTabSectionsProvider).requireValue)
    section.key: [for (final c in section.credentials) c.name],
};

void main() {
  test(
    "without flags, one section holds everything in the user's order",
    () async {
      final container = await _container();

      expect(_sections(container), {
        "ungrouped": [
          "E-mail",
          "Demo card",
          "Passport",
          "Staging card",
          "Loyalty card",
          "Mobile number",
        ],
      });
      expect(container.read(dataTabLayoutProvider), DataTabLayout.classic);
    },
  );

  test("dataTabV2 puts staging, then demo, after the rest", () async {
    final container = await _container(flags: {FeatureFlag.dataTabV2});

    expect(_sections(container), {
      "ungrouped": ["E-mail", "Passport", "Loyalty card", "Mobile number"],
      "staging": ["Staging card"],
      "demo": ["Demo card"],
    });
    expect(container.read(dataTabLayoutProvider), DataTabLayout.sourcesApart);
  });

  test("dataTabV2 leaves out sections without credentials", () async {
    final container = await _container(
      held: [_held.first],
      flags: {FeatureFlag.dataTabV2},
    );

    expect(_sections(container).keys, ["ungrouped"]);
  });

  test("dataTabCategories follows the add data screen", () async {
    final container = await _container(flags: {FeatureFlag.dataTabCategories});

    expect(_sections(container), {
      "category:Personal": ["Passport"],
      "category:Contact": ["E-mail", "Mobile number"],
      "category:": ["Loyalty card"],
      "staging": ["Staging card"],
      "demo": ["Demo card"],
    });
    expect(_sections(container).keys.toList(), [
      "category:Personal",
      "category:Contact",
      "category:",
      "staging",
      "demo",
    ]);
    expect(container.read(dataTabLayoutProvider), DataTabLayout.categories);
  });

  test("dataTabCategories wins when both flags are on", () async {
    final container = await _container(
      flags: {FeatureFlag.dataTabV2, FeatureFlag.dataTabCategories},
    );

    expect(container.read(dataTabLayoutProvider), DataTabLayout.categories);
  });

  test("pinned credentials move to the top, in the user's order", () async {
    final container = await _container(
      flags: {FeatureFlag.dataTabCategories},
      favourites: ["pbdf-staging.staging.card", "pbdf.sidn-pbdf.mobilenumber"],
    );

    expect(_sections(container), {
      "favourites": ["Staging card", "Mobile number"],
      "category:Personal": ["Passport"],
      "category:Contact": ["E-mail"],
      "category:": ["Loyalty card"],
      "demo": ["Demo card"],
    });
    expect(_sections(container).keys.first, "favourites");
  });

  test("pins are ignored while dataTabCategories is off", () async {
    final container = await _container(
      flags: {FeatureFlag.dataTabV2},
      favourites: ["pbdf.sidn-pbdf.email"],
    );

    expect(_sections(container).keys, ["ungrouped", "staging", "demo"]);
  });

  group("reorderWithin", () {
    List<String> order(ProviderContainer container) => [
      for (final c
          in container
              .read(schemalessCredentialOrderControllerProvider)
              .requireValue)
        c.name,
    ];

    test(
      "moves a credential inside its section, others keep their place",
      () async {
        final container = await _container(flags: {FeatureFlag.dataTabV2});
        final section = container
            .read(dataTabSectionsProvider)
            .requireValue
            .first;
        final controller = container.read(
          schemalessCredentialOrderControllerProvider.notifier,
        );

        // E-mail, Passport, Loyalty card, Mobile number -> Passport, Loyalty
        // card, Mobile number, E-mail.
        controller.reorderWithin(section.credentials, 0, 3);

        expect(order(container), [
          "Passport",
          "Demo card",
          "Loyalty card",
          "Staging card",
          "Mobile number",
          "E-mail",
        ]);
      },
    );

    test("moving up works the same way", () async {
      final container = await _container(flags: {FeatureFlag.dataTabV2});
      final section = container
          .read(dataTabSectionsProvider)
          .requireValue
          .first;
      final controller = container.read(
        schemalessCredentialOrderControllerProvider.notifier,
      );

      controller.reorderWithin(section.credentials, 3, 0);

      expect(order(container), [
        "Mobile number",
        "Demo card",
        "E-mail",
        "Staging card",
        "Passport",
        "Loyalty card",
      ]);
    });

    test("reorder still moves within the whole list", () async {
      final container = await _container();
      final controller = container.read(
        schemalessCredentialOrderControllerProvider.notifier,
      );

      controller.reorder(0, 2);

      expect(order(container).take(3), ["Demo card", "Passport", "E-mail"]);
    });
  });
}
