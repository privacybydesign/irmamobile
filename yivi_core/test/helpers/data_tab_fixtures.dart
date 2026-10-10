import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:rxdart/rxdart.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/feature_flag_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/schemaless_credential_store_provider.dart";
import "package:yivi_core/src/theme/theme.dart";

final _issuer = TrustedParty(
  id: "issuer",
  name: "Issuer",
  url: null,
  parent: null,
  verified: true,
);

/// Expiry dates as the credentials carry them: seconds since the epoch.
final pastExpiry = DateTime(2020).millisecondsSinceEpoch ~/ 1000;
final futureExpiry =
    DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch ~/
    1000;

/// A credential the wallet holds. Valid unless [expiryDate] or [instancesLeft]
/// says otherwise.
Credential heldCredential(
  String id, {
  String? name,
  int? expiryDate,
  int? instancesLeft,
}) {
  final expiry = expiryDate ?? futureExpiry;

  return Credential(
    credentialId: id,
    hash: "hash-$id-$expiry-$instancesLeft",
    name: name ?? id,
    issuer: _issuer,
    credentialInstanceIds: {},
    batchInstanceCountsRemaining: {CredentialFormat.sdjwtvc: instancesLeft},
    attributes: [],
    revoked: false,
    revocationSupported: false,
    issueUrl: null,
    expiryDate: expiry,
  );
}

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

class _FakeRepository extends Fake implements IrmaRepository {
  final subject = BehaviorSubject<SchemalessCredentials>();

  @override
  Stream<SchemalessCredentials> getSchemalessCredentials() => subject.stream;
}

/// Preferences on an empty in-memory store, with the data tab in [order]: the
/// order the user dragged the credentials to.
Future<IrmaPreferences> freshPrefs({List<String> order = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await IrmaPreferences.fromInstance(
    mostRecentTermsUrlNl: "",
    mostRecentTermsUrlEn: "",
  );
  await prefs.clearAll();
  await prefs.setCredentialOrder(order);
  return prefs;
}

/// Provider overrides for a wallet that holds [held], with [flags] switched on
/// and the others off. [store] is what the add data screen lists.
List<Override> dataTabOverrides({
  required List<Credential> held,
  required IrmaPreferences prefs,
  List<CredentialStoreItem> store = const [],
  Set<FeatureFlag> flags = const {},
}) {
  final repository = _FakeRepository()
    ..subject.add((credentials: held, problematic: const []));

  return [
    for (final flag in FeatureFlag.values)
      featureFlagProvider(
        flag,
      ).overrideWith((ref) => Stream.value(flags.contains(flag))),
    irmaRepositoryProvider.overrideWithValue(repository),
    credentialStoreProvider.overrideWith((ref) => Stream.value(store)),
    preferencesProvider.overrideWithValue(prefs),
  ];
}

/// [home] in an app with English texts.
Widget dataTabApp({required List<Override> overrides, required Widget home}) {
  return ProviderScope(
    overrides: overrides,
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

/// Storage and the providers that wait for it finish on the real event loop,
/// not the test's fake clock. Pumps in between, as each pump builds what the
/// next wait is for.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  // A change that lands on the last pump needs one more frame to show.
  await tester.pump();
  await tester.pump();
}
