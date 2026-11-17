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
          (p) => p.setScreenshotsEnabled(true),
          "preference.screenshots_enabled",
          true,
        ),
        ("long PIN", (p) => p.setLongPin(false), "preference.long_pin", false),
        (
          "PIN visible",
          (p) => p.setPinVisible(true),
          "preference.pin_visible",
          true,
        ),
        (
          "report errors",
          (p) => p.setReportErrors(true),
          "preference.report_errors",
          true,
        ),
        (
          "accepted rooted risk",
          (p) => p.setAcceptedRootedRisk(true),
          "preference.accepted_rooted_risk",
          true,
        ),
        (
          "biometric enabled",
          (p) => p.setBiometricEnabled(true),
          "preference.biometric_enabled",
          true,
        ),
        (
          "biometric immediate",
          (p) => p.setBiometricImmediate(false),
          "preference.biometric_immediate",
          false,
        ),
        (
          "biometric prompt dismissed",
          (p) => p.setBiometricPromptDismissed(true),
          "preference.biometric_prompt_dismissed",
          true,
        ),
        (
          "preferred language",
          (p) => p.setPreferredLanguageCode("nl"),
          "preference.preferred_language_code",
          "nl",
        ),
        (
          "show name changed notification",
          (p) => p.setShowNameChangedNotification(true),
          "preference.show_name_changed_notification",
          true,
        ),
        (
          "last scheme update, in seconds",
          (p) => p.setLastSchemeUpdate(
            DateTime.fromMillisecondsSinceEpoch(1700000000000),
          ),
          "preference.last_schemeupdate",
          1700000000,
        ),
        (
          "notifications",
          (p) => p.setSerializedNotifications("[]"),
          "preference.notifications",
          "[]",
        ),
        (
          "accepted terms, the Dutch URL",
          (p) => p.markLatestTermsAsAccepted(true),
          "preference.accepted_terms_url",
          "https://example.com/nl",
        ),
        (
          "credential order",
          (p) => p.setCredentialOrder(["a", "b"]),
          "preference.credential_order",
          ["a", "b"],
        ),
        (
          "card order",
          (p) => p.setCardOrder(["x"]),
          "preference.card_order",
          ["x"],
        ),
        (
          "wallet view",
          (p) => p.setWalletView("list"),
          "preference.wallet_view",
          "list",
        ),
        (
          "card motion",
          (p) => p.setCardMotion("fly"),
          "preference.card_motion",
          "fly",
        ),
        (
          "appearance, by name",
          (p) => p.setAppearance(Appearance.dark),
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
          (p) => p.setReviewDone(true),
          "preference.review_done",
          true,
        ),
        (
          "scan tip pending",
          (p) => p.markScanTipPending(),
          "preference.scan_tip_pending",
          true,
        ),
        (
          "e-mail linked",
          (p) => p.markEmailLinked(),
          "preference.email_linked",
          true,
        ),
        (
          "e-mail banner dismissed",
          (p) => p.dismissEmailBanner(),
          "preference.email_banner_dismissed",
          true,
        ),
        (
          "e-mail banner snoozed, in milliseconds",
          (p) => p.snoozeEmailBannerUntil(
            DateTime.fromMillisecondsSinceEpoch(1700000000123),
          ),
          "preference.email_banner_snoozed_until_ms",
          1700000000123,
        ),
        (
          "local backend host",
          (p) => p.setLocalBackendHost("10.0.2.2"),
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
        ("screenshots enabled", (p) => p.getScreenshotsEnabled().first, false),
        ("long PIN", (p) => p.getLongPin().first, true),
        ("PIN visible", (p) async => p.getPinVisible(), false),
        ("report errors", (p) => p.getReportErrors().first, false),
        ("accepted rooted risk", (p) => p.getAcceptedRootedRisk().first, false),
        ("biometric enabled", (p) => p.getBiometricEnabled().first, false),
        ("biometric immediate", (p) => p.getBiometricImmediate().first, true),
        (
          "biometric prompt dismissed",
          (p) => p.getBiometricPromptDismissed().first,
          false,
        ),
        ("preferred language", (p) => p.getPreferredLanguageCode().first, ""),
        (
          "last scheme update",
          (p) => p.getLastSchemeUpdate().first,
          DateTime.fromMillisecondsSinceEpoch(0),
        ),
        ("notifications", (p) => p.getSerializedNotifications().first, ""),
        ("accepted terms", (p) => p.hasAcceptedLatestTerms().first, false),
        ("credential order", (p) async => p.getCredentialOrder(), <String>[]),
        ("card order", (p) async => p.getCardOrder(), <String>[]),
        ("wallet view", (p) async => p.getWalletViewNow(), ""),
        ("appearance", (p) => p.getAppearance().first, Appearance.system),
        ("review success count", (p) async => p.getReviewSuccessCountNow(), 0),
        ("review times asked", (p) async => p.getReviewTimesAskedNow(), 0),
        ("review last asked", (p) async => p.getReviewLastAskEpochMsNow(), 0),
        ("review done", (p) async => p.getReviewDoneNow(), false),
        ("scan tip pending", (p) => p.getScanTipPending().first, false),
        ("e-mail linked", (p) => p.getEmailLinked().first, false),
        (
          "e-mail banner dismissed",
          (p) => p.getEmailBannerDismissed().first,
          false,
        ),
        (
          "e-mail banner snoozed",
          (p) => p.getEmailBannerSnoozedUntil().first,
          DateTime.fromMillisecondsSinceEpoch(0),
        ),
        ("local backend host", (p) => p.getLocalBackendHost().first, ""),
      ];

  for (final (name, read, value) in defaults) {
    test("$name reads $value from an empty store", () async {
      expect(await read(prefs), value);
    });
  }

  test("terms accepted for the Dutch URL count, others do not", () async {
    await prefs.markLatestTermsAsAccepted(true);
    expect(await prefs.hasAcceptedLatestTerms().first, isTrue);
    await prefs.markLatestTermsAsAccepted(false);
    expect(await prefs.hasAcceptedLatestTerms().first, isFalse);
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
    expect(await migrated.getAppearance().first, Appearance.dark);
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
    await prefs.setLongPin(false);
    await prefs.setShowNameChangedNotification(true);
    await prefs.clearAll();
    expect(await _raw("preference.long_pin"), isNull);
    expect(await prefs.getShowNameChangedNotification().first, isFalse);
  });
}
