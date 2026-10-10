import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/theme/theme.dart";

const testSessionId = 1;

TrustedParty testParty(String name, {bool verified = true}) => TrustedParty(
  id: name,
  name: name,
  url: null,
  parent: null,
  verified: verified,
);

CredentialDescriptor testDescriptor(
  String id, {
  String? issueURL = "https://issuer",
}) => CredentialDescriptor(
  credentialId: id,
  name: "Cred $id",
  issuer: testParty("Issuer"),
  category: null,
  attributes: const [],
  issueURL: issueURL,
);

IssuanceStep testStep(List<List<CredentialDescriptor>> options) => IssuanceStep(
  options: [for (final o in options) IssuanceBundle(credentials: o)],
);

SelectableCredentialInstance _instance(String id) =>
    SelectableCredentialInstance(
      credentialId: id,
      hash: "hash-$id",
      name: "Cred $id",
      issuer: testParty("Issuer"),
      format: CredentialFormat.idemix,
      attributes: const [],
      revoked: false,
      revocationSupported: false,
    );

Credential testCredential(String id) => Credential(
  credentialId: id,
  hash: "hash-$id",
  name: "Cred $id",
  issuer: testParty("Issuer"),
  credentialInstanceIds: const {},
  batchInstanceCountsRemaining: const {},
  attributes: const [],
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
);

/// A disclosure session of "Test Verifier" waiting for permission, with
/// [steps] still to obtain except for the [issued] credentials. With
/// [withChoices] it also has the overview irmago adds once nothing is missing,
/// and [wrongCredential] is the credential irmago reports as not matching.
SessionState testSession({
  required List<IssuanceStep> steps,
  Set<String> issued = const {},
  Credential? wrongCredential,
  bool withChoices = false,
  SessionType type = SessionType.disclosure,
  bool verified = true,
}) => SessionState(
  id: testSessionId,
  protocol: "irma",
  type: type,
  status: SessionStatus.requestPermission,
  requestor: testParty("Test Verifier", verified: verified),
  disclosurePlan: DisclosurePlan(
    issueDuringDisclosure: IssueDuringDisclosure(
      steps: steps,
      issuedCredentialIds: {for (final id in issued) id: null},
      wrongCredentialIssued: wrongCredential,
    ),
    disclosureChoicesOverview: withChoices
        ? [
            for (final step in steps)
              DisclosurePickOne(
                optional: false,
                ownedOptions: [
                  DisclosureBundle(
                    credentials: [
                      for (final c in step.options.first.credentials)
                        _instance(c.credentialId),
                    ],
                  ),
                ],
              ),
          ]
        : null,
  ),
);

class _TestBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}

  void emit(Event event) => addEvent(event);
}

/// A Dutch app around a router, with a repository whose sessions the test
/// controls through [emit].
class MissingDataHarness {
  final _TestBridge _bridge;
  final ProviderContainer container;

  MissingDataHarness._(this._bridge, this.container);

  static Future<MissingDataHarness> pump(
    WidgetTester tester,
    GoRouter router, {
    bool flagOn = true,
  }) async {
    final bridge = _TestBridge();

    late final IrmaPreferences prefs;
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      );
      await prefs.clearAll();
      await prefs.setCompletedDisclosurePermissionIntro(true);
      await prefs.setFeatureFlag(FeatureFlag.missingDataChecklist, flagOn);
    });

    final repo = IrmaRepository(client: bridge, preferences: prefs);
    addTearDown(repo.close);

    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        irmaRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: IrmaTheme(
            builder: (_) => MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: [
                FlutterI18nDelegate(
                  translationLoader: FileTranslationLoader(
                    basePath: "assets/locales",
                    forcedLocale: const Locale("nl"),
                  ),
                ),
                ...GlobalMaterialLocalizations.delegates,
              ],
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    return MissingDataHarness._(bridge, container);
  }

  Future<void> emit(WidgetTester tester, SessionState session) async {
    _bridge.emit(SessionStateEvent(sessionState: session));
    await tester.pump();
    await tester.pump();
  }
}
