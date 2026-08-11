import "dart:ui";

import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/native_events.dart";
import "package:yivi_core/src/util/language.dart";

class _RecordingBridge extends IrmaBridge {
  final dispatched = <Event>[];

  @override
  void dispatch(Event event) => dispatched.add(event);
}

void main() {
  group("effectiveAppLanguage", () {
    test("uses the in-app override when set", () {
      expect(
        effectiveAppLanguage(
          preferredLanguageCode: "nl",
          systemLocale: const Locale("en", "US"),
        ),
        "nl",
      );
    });

    test("falls back to the system language when the override is empty", () {
      expect(
        effectiveAppLanguage(
          preferredLanguageCode: "",
          systemLocale: const Locale("de", "DE"),
        ),
        "de",
      );
    });
  });

  group("IrmaRepository locale push", () {
    TestWidgetsFlutterBinding.ensureInitialized();

    Future<(IrmaPreferences, _RecordingBridge)> setup() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      );
      final bridge = _RecordingBridge();
      final repo = IrmaRepository(client: bridge, preferences: prefs);
      addTearDown(repo.close);
      // Let the initial (skipped) effective-language emission flush before the
      // test drives a change.
      await pumpEventQueue();
      return (prefs, bridge);
    }

    test(
      "dispatches AppReadyEvent with the initial effective language",
      () async {
        final (_, bridge) = await setup();
        final appReady = bridge.dispatched.whereType<AppReadyEvent>().toList();
        expect(appReady, hasLength(1));
        expect(appReady.single.locale, isNotEmpty);
      },
    );

    test(
      "a language-override change emits one SetLocaleEvent and a log reset",
      () async {
        final (prefs, bridge) = await setup();
        final initial = bridge.dispatched
            .whereType<AppReadyEvent>()
            .single
            .locale;
        final target = initial == "nl" ? "de" : "nl";

        bridge.dispatched.clear();
        await prefs.setPreferredLanguageCode(target);
        await pumpEventQueue();

        final setLocale = bridge.dispatched
            .whereType<SetLocaleEvent>()
            .toList();
        expect(setLocale, hasLength(1));
        expect(setLocale.single.locale, target);
        // The paged activity-log cache is reset alongside the locale switch.
        expect(bridge.dispatched.whereType<LoadLogsEvent>(), hasLength(1));
      },
    );

    test(
      "no SetLocaleEvent when the effective language is unchanged",
      () async {
        final (prefs, bridge) = await setup();
        final initial = bridge.dispatched
            .whereType<AppReadyEvent>()
            .single
            .locale;
        final target = initial == "nl" ? "de" : "nl";

        await prefs.setPreferredLanguageCode(target);
        await pumpEventQueue();
        bridge.dispatched.clear();

        // Setting the override to the same value again is a no-op switch.
        await prefs.setPreferredLanguageCode(target);
        await pumpEventQueue();
        expect(bridge.dispatched.whereType<SetLocaleEvent>(), isEmpty);
      },
    );

    test(
      "a device language change reaches the bridge as a SetLocaleEvent",
      () async {
        final (prefs, bridge) = await setup();
        // StreamingSharedPreferences.instance is a cached singleton, so an
        // override set by an earlier test survives setMockInitialValues.
        // Be explicit: this case is about following the device language.
        await prefs.setPreferredLanguageCode("");
        await pumpEventQueue();
        bridge.dispatched.clear();

        // Driven through the real platform dispatcher, so the whole chain is
        // covered: binding -> AppLanguage's observer -> repository -> bridge.
        // AppLanguage's own behaviour is unit-tested in app_language_test.dart.
        final dispatcher =
            TestWidgetsFlutterBinding.instance.platformDispatcher;
        addTearDown(dispatcher.clearLocalesTestValue);
        dispatcher.localesTestValue = const [Locale("de", "DE")];
        await pumpEventQueue();

        final setLocale = bridge.dispatched
            .whereType<SetLocaleEvent>()
            .toList();
        expect(setLocale, hasLength(1));
        expect(setLocale.single.locale, "de");
      },
    );
  });
}
