import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/theme/theme.dart";

const _sessionId = 1;

TrustedParty _party(String id) => TrustedParty(
  id: id,
  name: TranslatedValue.fromString(id),
  url: null,
  parent: null,
  verified: true,
);

int _epochSeconds(DateTime moment) => moment.millisecondsSinceEpoch ~/ 1000;

/// An email credential instance issued [issuedDaysAgo] ago, expired when
/// [expired] is set.
SelectableCredentialInstance _email(
  String hash, {
  required int issuedDaysAgo,
  bool expired = false,
}) {
  final now = DateTime.now();
  return SelectableCredentialInstance(
    credentialId: "pbdf.sidn-pbdf.email",
    hash: hash,
    name: TranslatedValue.fromString("Email address"),
    issuer: _party("sidn-pbdf"),
    format: CredentialFormat.sdjwtvc,
    attributes: const [],
    revoked: false,
    revocationSupported: false,
    issuanceDate: _epochSeconds(now.subtract(Duration(days: issuedDaysAgo))),
    expiryDate: _epochSeconds(
      expired
          ? now.subtract(const Duration(days: 1))
          : now.add(const Duration(days: 365)),
    ),
  );
}

SessionState _session(List<SelectableCredentialInstance> emails) =>
    SessionState(
      id: _sessionId,
      protocol: "irma",
      type: SessionType.disclosure,
      status: SessionStatus.requestPermission,
      requestor: _party("Requestor"),
      disclosurePlan: DisclosurePlan(
        disclosureChoicesOverview: [
          DisclosurePickOne(
            optional: false,
            ownedOptions: emails
                .map((email) => DisclosureBundle(credentials: [email]))
                .toList(),
          ),
        ],
      ),
    );

Widget _testWidget({
  required SessionState session,
  required IrmaPreferences preferences,
  required ValueChanged<List<DisclosureDisconSelection>> onChoicesConfirmed,
}) {
  return ProviderScope(
    overrides: [
      preferencesProvider.overrideWithValue(preferences),
      sessionStateProvider(
        _sessionId,
      ).overrideWith((_) => Stream.value(session)),
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
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: DisclosureChoicesOverview(
          sessionState: session,
          onDismiss: () {},
          onChoicesConfirmed: onChoicesConfirmed,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<IrmaPreferences> freshPrefs() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
    return prefs;
  }

  /// Confirms the overview without opening the picker and returns the credential
  /// hashes it disclosed — i.e. the pre-selected option.
  Future<List<String>> disclosedHashes(
    WidgetTester tester, {
    required SessionState session,
    required IrmaPreferences preferences,
  }) async {
    List<DisclosureDisconSelection>? confirmed;
    await tester.pumpWidget(
      _testWidget(
        session: session,
        preferences: preferences,
        onChoicesConfirmed: (choices) => confirmed = choices,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    return (confirmed ?? [])
        .expand((choice) => choice.credentials)
        .map((credential) => credential.credentialHash)
        .toList();
  }

  testWidgets("without any usage the oldest email is pre-selected", (
    tester,
  ) async {
    final prefs = await freshPrefs();
    final session = _session([
      _email("newer", issuedDaysAgo: 2),
      _email("older", issuedDaysAgo: 40),
    ]);

    expect(
      await disclosedHashes(tester, session: session, preferences: prefs),
      ["older"],
    );
  });

  testWidgets("the most used email is pre-selected", (tester) async {
    final prefs = await freshPrefs();
    await prefs.recordCredentialUsage(["older"], now: DateTime.now());
    await prefs.recordCredentialUsage(["newer"], now: DateTime.now());
    await prefs.recordCredentialUsage(["newer"], now: DateTime.now());

    final session = _session([
      _email("newer", issuedDaysAgo: 2),
      _email("older", issuedDaysAgo: 40),
    ]);

    expect(
      await disclosedHashes(tester, session: session, preferences: prefs),
      ["newer"],
    );
  });

  testWidgets("an expired email is not pre-selected over a valid one", (
    tester,
  ) async {
    final prefs = await freshPrefs();
    // The expired one is both older and the more used, so it would win on
    // every other count.
    await prefs.recordCredentialUsage(["expired"], now: DateTime.now());
    await prefs.recordCredentialUsage(["expired"], now: DateTime.now());

    final session = _session([
      _email("expired", issuedDaysAgo: 40, expired: true),
      _email("valid", issuedDaysAgo: 2),
    ]);

    expect(
      await disclosedHashes(tester, session: session, preferences: prefs),
      ["valid"],
    );
  });
}
