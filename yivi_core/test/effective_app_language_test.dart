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
  });
}
