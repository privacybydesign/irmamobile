import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/device_lock/device_lock_required_screen.dart";
import "package:yivi_core/src/screens/device_lock/device_security.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

class _FakeDeviceSecurity implements DeviceSecurity {
  bool secure;
  int settingsOpened = 0;

  _FakeDeviceSecurity({required this.secure});

  @override
  Future<bool> isDeviceSecure() async => secure;

  @override
  Future<void> openSecuritySettings() async => settingsOpened++;
}

void main() {
  group("DeviceLockRequirement", () {
    testWidgets("requires a lock while the device has none", (tester) async {
      final requirement = DeviceLockRequirement(
        _FakeDeviceSecurity(secure: false),
      );
      addTearDown(requirement.dispose);

      expect(await requirement.lockRequired.first, isTrue);
    });

    testWidgets("does not require one on a device with a screen lock", (
      tester,
    ) async {
      final requirement = DeviceLockRequirement(
        _FakeDeviceSecurity(secure: true),
      );
      addTearDown(requirement.dispose);

      expect(await requirement.lockRequired.first, isFalse);
    });

    testWidgets("checks again when the app resumes", (tester) async {
      final security = _FakeDeviceSecurity(secure: false);
      final requirement = DeviceLockRequirement(security);
      addTearDown(requirement.dispose);
      final values = <bool>[];
      final subscription = requirement.lockRequired.listen(values.add);
      addTearDown(subscription.cancel);
      await tester.pump();
      expect(values, [true]);

      // The user sets a screen lock in the settings and comes back.
      security.secure = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(values, [true, false]);
    });

    testWidgets("can be skipped in a debug build", (tester) async {
      final requirement = DeviceLockRequirement(
        _FakeDeviceSecurity(secure: false),
      );
      addTearDown(requirement.dispose);
      final values = <bool>[];
      final subscription = requirement.lockRequired.listen(values.add);
      addTearDown(subscription.cancel);
      await tester.pump();

      requirement.skipForDebugging();
      await tester.pump();

      // Tests run with asserts on, as a debug build does.
      expect(values, [true, false]);
    });
  });

  group("DeviceLockRequiredScreen", () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      required VoidCallback onCheckAgain,
      VoidCallback? onContinueAnyway,
    }) async {
      final widget = IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: TestTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: const Locale("en", "US"),
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: DeviceLockRequiredScreen(
            onOpenSettingsPressed: () {},
            onCheckAgainPressed: onCheckAgain,
            onContinueAnywayPressed: onContinueAnyway,
          ),
        ),
      );
      // The translation loader does real IO, which the fake clock does not
      // drive (see error_reporting_check_box_semantics_test.dart).
      await tester.runAsync(() async {
        await tester.pumpWidget(widget);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
    }

    // Tests run on the host, not on Android, so the screen takes its iOS form:
    // iOS cannot open the passcode settings, so its button checks again.
    testWidgets("explains the requirement and checks again", (tester) async {
      var checks = 0;
      await pumpScreen(tester, onCheckAgain: () => checks++);

      expect(find.text("Set a screen lock"), findsOneWidget);
      expect(
        find.textContaining("Your iPhone has no passcode"),
        findsOneWidget,
      );

      await tester.tap(find.text("Check again"));
      expect(checks, 1);
    });

    testWidgets("offers to continue anyway in a debug build", (tester) async {
      var continued = 0;
      await pumpScreen(
        tester,
        onCheckAgain: () {},
        onContinueAnyway: () => continued++,
      );

      await tester.tap(find.text("Continue anyway (debug build)"));
      expect(continued, 1);
    });
  });
}
