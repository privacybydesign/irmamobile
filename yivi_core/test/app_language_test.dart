import "dart:ui";

import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/app_language.dart";
import "package:yivi_core/src/data/irma_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(IrmaPreferences, AppLanguage)> setup({
    String override = "",
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    // StreamingSharedPreferences.instance is a cached singleton, so an
    // override left behind by an earlier test survives setMockInitialValues.
    // Every case states the override it wants.
    await prefs.setPreferredLanguageCode(override);
    final language = AppLanguage(prefs);
    addTearDown(language.close);
    return (prefs, language);
  }

  test("follows the device language when no override is set", () async {
    final (_, language) = await setup();
    expect(language.current, "en"); // the test binding's device locale

    language.didChangeLocales(const [Locale("de", "DE")]);
    expect(language.current, "de");
  });

  test("an in-app override wins over the device language", () async {
    final (_, language) = await setup(override: "nl");
    expect(language.current, "nl");

    language.didChangeLocales(const [Locale("de", "DE")]);
    expect(language.current, "nl");
  });

  test("changes reports a device language switch", () async {
    final (_, language) = await setup();
    final seen = <String>[];
    final sub = language.changes.listen(seen.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    language.didChangeLocales(const [Locale("de", "DE")]);
    await pumpEventQueue();

    expect(seen, ["de"]);
  });

  test("changes stays quiet while an override is pinned", () async {
    final (_, language) = await setup(override: "nl");
    final seen = <String>[];
    final sub = language.changes.listen(seen.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    language.didChangeLocales(const [Locale("de", "DE")]);
    await pumpEventQueue();

    expect(seen, isEmpty);
  });

  test("changes reports an override switch, and never repeats a value", () async {
    final (prefs, language) = await setup();
    final seen = <String>[];
    final sub = language.changes.listen(seen.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    await prefs.setPreferredLanguageCode("nl");
    await pumpEventQueue();
    // Pinning the override to the language already in effect is not a change.
    await prefs.setPreferredLanguageCode("nl");
    await pumpEventQueue();

    expect(seen, ["nl"]);
  });

  test("an override matching the device language is not a change", () async {
    final (prefs, language) = await setup();
    final seen = <String>[];
    final sub = language.changes.listen(seen.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    await prefs.setPreferredLanguageCode("en");
    await pumpEventQueue();

    expect(seen, isEmpty);
  });

  test("an empty locale list is ignored", () async {
    final (_, language) = await setup();

    language.didChangeLocales(null);
    language.didChangeLocales(const []);

    expect(language.current, "en");
  });
}
