import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<IrmaPreferences> freshPrefs() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "https://yivi.app/terms_and_conditions_v3/",
      mostRecentTermsUrlEn: "https://yivi.app/en/terms_and_conditions_v3/",
    );
    await prefs.clearAll();
    return prefs;
  }

  test("no consent is on record before the terms are accepted", () async {
    final prefs = await freshPrefs();

    expect(prefs.acceptedTermsUrl, isNull);
    expect(prefs.acceptedTermsAt, isNull);
  });

  test("accepting the terms records which version was accepted and "
      "when", () async {
    final prefs = await freshPrefs();
    final before = DateTime.now();

    await prefs.markLatestTermsAsAccepted(true);

    expect(prefs.acceptedTermsUrl, "https://yivi.app/terms_and_conditions_v3/");
    final acceptedAt = prefs.acceptedTermsAt!;
    expect(
      acceptedAt.isBefore(before.subtract(const Duration(seconds: 1))),
      isFalse,
    );
    expect(acceptedAt.isAfter(DateTime.now()), isFalse);
    expect(await prefs.hasAcceptedLatestTerms().first, isTrue);
  });

  test("withdrawing the acceptance removes the record", () async {
    final prefs = await freshPrefs();
    await prefs.markLatestTermsAsAccepted(true);

    await prefs.markLatestTermsAsAccepted(false);

    expect(prefs.acceptedTermsUrl, isNull);
    expect(prefs.acceptedTermsAt, isNull);
    expect(await prefs.hasAcceptedLatestTerms().first, isFalse);
  });
}
