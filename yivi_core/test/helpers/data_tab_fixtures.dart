import "dart:async";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/favourite_credentials_provider.dart";
import "package:yivi_core/src/providers/feature_flag_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/schemaless_credential_store_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";
import "package:yivi_core/src/theme/theme.dart";

final _issuer = TrustedParty(
  id: "issuer",
  name: "Issuer",
  url: null,
  parent: null,
  verified: true,
);

final _past = DateTime(2020).millisecondsSinceEpoch ~/ 1000;
final _future =
    DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch ~/
    1000;

/// A credential the wallet holds. Valid unless [expired] or [instancesLeft]
/// says otherwise.
Credential heldCredential(
  String id, {
  String? name,
  bool expired = false,
  int? instancesLeft,
}) => Credential(
  credentialId: id,
  hash: "hash-$id-${expired ? "expired" : "valid"}-$instancesLeft",
  name: name ?? id,
  issuer: _issuer,
  credentialInstanceIds: {},
  batchInstanceCountsRemaining: {CredentialFormat.sdjwtvc: instancesLeft},
  attributes: [],
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
  expiryDate: expired ? _past : _future,
);

/// A credential as the add data screen lists it.
CredentialStoreItem storeItem(String id, String name, String? category) =>
    CredentialStoreItem(
      credential: CredentialDescriptor(
        credentialId: id,
        name: name,
        issuer: _issuer,
        category: category,
        attributes: [],
        issueURL: null,
      ),
      faq: Faq(intro: null, purpose: null, content: null, howTo: null),
    );

/// Hands the data tab the credentials in the order the user dragged them to,
/// without a repository behind it.
class FixedOrderController extends SchemalessCredentialOrderController {
  final List<Credential> _credentials;

  FixedOrderController(this._credentials);

  @override
  Future<List<Credential>> build() async => _credentials;
}

/// Pins in memory, so a widget test does not wait for the preferences.
class InMemoryFavourites extends FavouriteCredentialsController {
  final StreamController<List<String>> _changes;
  List<String> _pinned = [];

  InMemoryFavourites(super.ref, this._changes);

  @override
  Future<void> toggle(String credentialId) async {
    _pinned = _pinned.contains(credentialId)
        ? [
            for (final id in _pinned)
              if (id != credentialId) id,
          ]
        : [..._pinned, credentialId];
    _changes.add(_pinned);
  }
}

/// Preferences on an empty in-memory store.
Future<IrmaPreferences> freshPrefs() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await IrmaPreferences.fromInstance(
    mostRecentTermsUrlNl: "",
    mostRecentTermsUrlEn: "",
  );
  await prefs.clearAll();
  return prefs;
}

/// What the wallet holds, as the user dragged it: one expired credential, one
/// from staging and one from demo.
final sampleHeld = [
  heldCredential("pbdf.sidn-pbdf.email", name: "E-mail"),
  heldCredential("irma-demo.demo.card", name: "Demo card"),
  heldCredential("pbdf.pbdf.passport", name: "Passport", expired: true),
  heldCredential("pbdf-staging.staging.card", name: "Staging card"),
  heldCredential("pbdf.sidn-pbdf.mobilenumber", name: "Mobile number"),
];

final sampleStore = [
  storeItem("pbdf.sidn-pbdf.email", "E-mail", "Contact"),
  storeItem("pbdf.sidn-pbdf.mobilenumber", "Mobile number", "Contact"),
  storeItem("pbdf.pbdf.passport", "Passport", "Personal"),
];

/// [home] with [sampleHeld] in the wallet, [flags] switched on and the
/// favourites either [favourites] or, with [pinChanges], whatever it emits.
/// Pass [prefs] when the test reorders credentials, which saves the new order.
Widget dataTabApp({
  required Widget home,
  Set<FeatureFlag> flags = const {},
  List<String> favourites = const [],
  IrmaPreferences? prefs,
  StreamController<List<String>>? pinChanges,
}) {
  return ProviderScope(
    overrides: [
      for (final flag in FeatureFlag.values)
        featureFlagProvider(
          flag,
        ).overrideWith((ref) => Stream.value(flags.contains(flag))),
      schemalessCredentialOrderControllerProvider.overrideWith(
        () => FixedOrderController(sampleHeld),
      ),
      schemalessCredentialsProvider.overrideWith(
        (ref) => Stream.value((credentials: sampleHeld, problematic: const [])),
      ),
      for (final credential in sampleHeld)
        schemalessCredentialsWithIdProvider(
          credential.credentialId,
        ).overrideWith((ref) async => [credential]),
      credentialStoreProvider.overrideWith((ref) => Stream.value(sampleStore)),
      if (prefs != null) preferencesProvider.overrideWithValue(prefs),
      favouriteCredentialsProvider.overrideWith(
        (ref) => pinChanges?.stream ?? Stream.value(favourites),
      ),
      if (pinChanges != null)
        favouriteCredentialsControllerProvider.overrideWith(
          (ref) => InMemoryFavourites(ref, pinChanges),
        ),
    ],
    child: IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: const Locale("en", "US"),
            ),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: home,
      ),
    ),
  );
}
