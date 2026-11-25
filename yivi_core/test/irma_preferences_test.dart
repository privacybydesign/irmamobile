import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:streaming_shared_preferences/streaming_shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";

import "support/onboarding_v2_harness.dart";

/// What is in the store under [key], read past every cache.
Future<Object?> _raw(String key) async {
  final store = await SharedPreferences.getInstance();
  await store.reload();
  return store.get(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IrmaPreferences prefs;

  setUp(() async => prefs = await freshPreferences());

  // Each preference: a write through the API, its key, and what the store
  // holds after it. The keys and stored types must never change: an update
  // would lose what users stored.
  final writes =
      <(String, Future<void> Function(IrmaPreferences), String, Object)>[
        (
          "screenshots enabled",
          (p) => p.screenshotsEnabled.set(true),
          "preference.screenshots_enabled",
          true,
        ),
        ("long PIN", (p) => p.longPin.set(false), "preference.long_pin", false),
        (
          "PIN visible",
          (p) => p.pinVisible.set(true),
          "preference.pin_visible",
          true,
        ),
        (
          "report errors",
          (p) => p.reportErrors.set(true),
          "preference.report_errors",
          true,
        ),
        (
          "accepted rooted risk",
          (p) => p.acceptedRootedRisk.set(true),
          "preference.accepted_rooted_risk",
          true,
        ),
        (
          "biometric enabled",
          (p) => p.biometricEnabled.set(true),
          "preference.biometric_enabled",
          true,
        ),
        (
          "biometric immediate",
          (p) => p.biometricImmediate.set(false),
          "preference.biometric_immediate",
          false,
        ),
        (
          "biometric prompt dismissed",
          (p) => p.biometricPromptDismissed.set(true),
          "preference.biometric_prompt_dismissed",
          true,
        ),
        (
          "preferred language",
          (p) => p.preferredLanguageCode.set("nl"),
          "preference.preferred_language_code",
          "nl",
        ),
        (
          "show name changed notification",
          (p) => p.showNameChangedNotification.set(true),
          "preference.show_name_changed_notification",
          true,
        ),
        (
          "last scheme update, in seconds",
          (p) => p.lastSchemeUpdate.set(
            DateTime.fromMillisecondsSinceEpoch(1700000000000),
          ),
          "preference.last_schemeupdate",
          1700000000,
        ),
        (
          "notifications",
          (p) => p.serializedNotifications.set("[]"),
          "preference.notifications",
          "[]",
        ),
        (
          "accepted terms, the Dutch URL",
          (p) => p.acceptedLatestTerms.set(true),
          "preference.accepted_terms_url",
          "https://example.com/nl",
        ),
        (
          "credential order",
          (p) => p.credentialOrder.set(["a", "b"]),
          "preference.credential_order",
          ["a", "b"],
        ),
        (
          "card order",
          (p) => p.cardOrder.set(["x"]),
          "preference.card_order",
          ["x"],
        ),
        (
          "wallet view",
          (p) => p.walletView.set("list"),
          "preference.wallet_view",
          "list",
        ),
        (
          "card motion",
          (p) => p.cardMotion.set("fly"),
          "preference.card_motion",
          "fly",
        ),
        (
          "appearance, by name",
          (p) => p.appearance.set(Appearance.dark),
          "preference.appearance",
          "dark",
        ),
        (
          "review success count",
          (p) => p.incrementReviewSuccessCount(),
          "preference.review_success_count",
          1,
        ),
        (
          "review asked",
          (p) => p.recordReviewAsked(nowEpochMs: 1234),
          "preference.review_times_asked",
          1,
        ),
        (
          "review last asked, in milliseconds",
          (p) => p.recordReviewAsked(nowEpochMs: 1234),
          "preference.review_last_ask_epoch_ms",
          1234,
        ),
        (
          "review done",
          (p) => p.reviewDone.set(true),
          "preference.review_done",
          true,
        ),
        (
          "e-mail linked",
          (p) => p.emailLinked.set(true),
          "preference.email_linked",
          true,
        ),
        (
          "secure offer shown",
          (p) => p.secureOfferShown.set(true),
          "preference.secure_offer_shown",
          true,
        ),
        (
          "local backend host",
          (p) => p.localBackendHost.set("10.0.2.2"),
          "preference.local_backend_host",
          "10.0.2.2",
        ),
      ];

  for (final (name, write, key, stored) in writes) {
    test("$name is stored under $key", () async {
      await write(prefs);
      expect(await _raw(key), stored);
    });
  }

  // What an empty store reads as.
  final defaults =
      <(String, Future<Object?> Function(IrmaPreferences), Object)>[
        (
          "screenshots enabled",
          (p) => p.screenshotsEnabled.stream.first,
          false,
        ),
        ("long PIN", (p) => p.longPin.stream.first, true),
        ("PIN visible", (p) async => p.pinVisible.value, false),
        ("report errors", (p) => p.reportErrors.stream.first, false),
        (
          "accepted rooted risk",
          (p) => p.acceptedRootedRisk.stream.first,
          false,
        ),
        ("biometric enabled", (p) => p.biometricEnabled.stream.first, false),
        ("biometric immediate", (p) => p.biometricImmediate.stream.first, true),
        (
          "biometric prompt dismissed",
          (p) => p.biometricPromptDismissed.stream.first,
          false,
        ),
        ("preferred language", (p) => p.preferredLanguageCode.stream.first, ""),
        (
          "last scheme update",
          (p) => p.lastSchemeUpdate.stream.first,
          DateTime.fromMillisecondsSinceEpoch(0),
        ),
        ("notifications", (p) => p.serializedNotifications.stream.first, ""),
        ("accepted terms", (p) => p.acceptedLatestTerms.stream.first, false),
        ("credential order", (p) async => p.credentialOrder.value, <String>[]),
        ("card order", (p) async => p.cardOrder.value, <String>[]),
        ("wallet view", (p) async => p.walletView.value, ""),
        ("appearance", (p) => p.appearance.stream.first, Appearance.system),
        ("review success count", (p) async => p.reviewSuccessCount.value, 0),
        ("review times asked", (p) async => p.reviewTimesAsked.value, 0),
        ("review last asked", (p) async => p.reviewLastAskEpochMs.value, 0),
        ("review done", (p) async => p.reviewDone.value, false),
        ("e-mail linked", (p) => p.emailLinked.stream.first, false),
        ("secure offer shown", (p) => p.secureOfferShown.stream.first, false),
        ("local backend host", (p) => p.localBackendHost.stream.first, ""),
      ];

  for (final (name, read, value) in defaults) {
    test("$name reads $value from an empty store", () async {
      expect(await read(prefs), value);
    });
  }

  test("terms accepted for the Dutch URL count, others do not", () async {
    await prefs.acceptedLatestTerms.set(true);
    expect(await prefs.acceptedLatestTerms.stream.first, isTrue);
    await prefs.acceptedLatestTerms.set(false);
    expect(await prefs.acceptedLatestTerms.stream.first, isFalse);
    expect(await _raw("preference.accepted_terms_url"), "no-terms-accepted");
  });

  test("the old dark mode preview makes the appearance dark", () async {
    final store = await StreamingSharedPreferences.instance;
    await store.setBool("preference.dark_mode_preview", true);
    final migrated = IrmaPreferences(
      store,
      mostRecentTermsUrlNl: "nl",
      mostRecentTermsUrlEn: "en",
    );
    expect(await migrated.appearance.stream.first, Appearance.dark);
  });

  test("retired keys are removed when the preferences open", () async {
    final store = await StreamingSharedPreferences.instance;
    await store.setBool("preference.devmode_visible", true);
    await store.setBool("preference.show_disclosure_dialog", true);
    IrmaPreferences(
      store,
      mostRecentTermsUrlNl: "nl",
      mostRecentTermsUrlEn: "en",
    );
    await Future<void>.delayed(Duration.zero);
    expect(await _raw("preference.devmode_visible"), isNull);
    expect(await _raw("preference.show_disclosure_dialog"), isNull);
  });

  test("clearAll empties the store but keeps the name notice off", () async {
    await prefs.longPin.set(false);
    await prefs.showNameChangedNotification.set(true);
    await prefs.clearAll();
    expect(await _raw("preference.long_pin"), isNull);
    expect(await prefs.showNameChangedNotification.stream.first, isFalse);
  });
}
