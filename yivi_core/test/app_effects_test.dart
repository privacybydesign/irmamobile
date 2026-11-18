// What the app does by itself, outside any screen: the privacy screen, the
// scheme update, the idle lock and the name change notice.
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/delete_keyshare_tokens_event.dart";
import "package:yivi_core/src/models/update_schemes_event.dart";

import "support/app_harness.dart";

void main() {
  late AppHarness app;

  setUp(() async {
    app = await AppHarness.create();
    await app.repo.preferences.showNameChangedNotification.set(false);
    // Recent, so the start does not update the schemes (test 26 sets it).
    await app.repo.preferences.lastSchemeUpdate.set(DateTime.now());
  });

  int schemeUpdates() =>
      app.bridge.dispatched.whereType<UpdateSchemesEvent>().length;

  Future<bool> locked() => app.repo.getLocked().first;

  group("25. the privacy screen follows the screenshot setting", () {
    testWidgets("screenshots off: on; then switched on: off", (tester) async {
      await app.pump(tester);
      expect(app.privacyScreenCalls, ["enablePrivacyScreen"]);

      await app.repo.preferences.screenshotsEnabled.set(true);
      await app.run(tester);
      expect(app.privacyScreenCalls, [
        "enablePrivacyScreen",
        "disablePrivacyScreen",
      ]);

      await app.repo.preferences.screenshotsEnabled.set(false);
      await app.run(tester);
      expect(app.privacyScreenCalls.last, "enablePrivacyScreen");
      await app.unmount(tester);
    });

    testWidgets("screenshots on at the start: off", (tester) async {
      await app.repo.preferences.screenshotsEnabled.set(true);
      await app.pump(tester);
      expect(app.privacyScreenCalls, ["disablePrivacyScreen"]);
      await app.unmount(tester);
    });
  });

  group("26. the schemes are updated every three hours", () {
    testWidgets("at the start, when the last update is older", (tester) async {
      await app.repo.preferences.lastSchemeUpdate.set(
        DateTime.now().subtract(const Duration(hours: 5)),
      );
      final before = DateTime.now();
      await app.pump(tester);

      expect(schemeUpdates(), 1);
      final last = app.repo.preferences.lastSchemeUpdate.value;
      expect(last.isBefore(before.subtract(const Duration(seconds: 1))), false);
      await app.unmount(tester);
    });

    testWidgets("not when the last update is recent", (tester) async {
      await app.repo.preferences.lastSchemeUpdate.set(
        DateTime.now().subtract(const Duration(hours: 1)),
      );
      await app.pump(tester);

      expect(schemeUpdates(), 0);
      await app.unmount(tester);
    });

    testWidgets("again on a return to the app", (tester) async {
      await app.pump(tester);
      expect(schemeUpdates(), 0);

      await app.repo.preferences.lastSchemeUpdate.set(
        DateTime.now().subtract(const Duration(hours: 5)),
      );
      app.background(tester);
      await app.run(tester);
      expect(schemeUpdates(), 0);
      app.foreground(tester);
      await app.run(tester);

      expect(schemeUpdates(), 1);
      await app.unmount(tester);
    });
  });

  group("27. the idle lock", () {
    /// Enrolled, at home, unlocked.
    Future<void> home(WidgetTester tester, Duration threshold) async {
      await app.pump(tester, idleLockThreshold: threshold);
      app.enrolled();
      app.schemes();
      await app.run(tester);
      app.repo.unlockAppLocally();
      await app.run(tester);
    }

    /// In the background for [away] on the real clock, the one it reads.
    Future<void> away(WidgetTester tester, Duration away) async {
      app.background(tester);
      await tester.runAsync(() => Future<void>.delayed(away));
      app.foreground(tester);
      await app.run(tester);
    }

    testWidgets("locks after longer than the threshold away", (tester) async {
      await home(tester, const Duration(milliseconds: 10));
      expect(await locked(), isFalse);

      await away(tester, const Duration(milliseconds: 50));

      expect(await locked(), isTrue);
      await app.unmount(tester);
    });

    testWidgets("not after a shorter time away", (tester) async {
      await home(tester, const Duration(hours: 1));

      await away(tester, const Duration(milliseconds: 50));

      expect(await locked(), isFalse);
      await app.unmount(tester);
    });

    testWidgets("not when unenrolled", (tester) async {
      await app.pump(tester, idleLockThreshold: Duration.zero);
      app.unenrolled();
      app.schemes();
      await app.run(tester);
      expect(await locked(), isFalse);

      await away(tester, const Duration(milliseconds: 50));

      expect(await locked(), isFalse);
      await app.unmount(tester);
    });

    testWidgets("not again when already locked", (tester) async {
      await app.pump(tester, idleLockThreshold: Duration.zero);
      app.enrolled();
      app.schemes();
      await app.run(tester);
      expect(await locked(), isTrue);
      final drops = app.bridge.dispatched
          .whereType<DeleteKeyshareTokensEvent>()
          .length;

      await away(tester, const Duration(milliseconds: 50));

      expect(
        app.bridge.dispatched.whereType<DeleteKeyshareTokensEvent>().length,
        drops,
      );
      await app.unmount(tester);
    });
  });

  testWidgets("28. once unenrolled, the name change notice is off for "
      "good", (tester) async {
    await app.repo.preferences.showNameChangedNotification.set(true);
    await app.pump(tester);
    app.unenrolled();
    app.schemes();
    await app.run(tester);

    expect(app.repo.preferences.showNameChangedNotification.value, isFalse);
    await app.unmount(tester);
  });
}
