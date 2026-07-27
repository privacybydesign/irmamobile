import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
// ignore: depend_on_referenced_packages
import "package:plugin_platform_interface/plugin_platform_interface.dart";
// ignore: depend_on_referenced_packages
import "package:url_launcher_platform_interface/link.dart";
// ignore: depend_on_referenced_packages
import "package:url_launcher_platform_interface/url_launcher_platform_interface.dart";
import "package:yivi_core/app.dart";
import "package:yivi_core/src/screens/required_update/required_update_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

import "util.dart";

// Store URLs the [RequiredUpdateScreen] launches for the update button; these
// must stay in sync with the URLs hard-coded in the screen itself.
const _playStoreUrl =
    "https://play.google.com/store/apps/details?id=org.irmacard.cardemu";
const _appStoreUrl = "https://apps.apple.com/app/id1294092994";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  // Record which URLs the screen hands to url_launcher so we can assert the
  // update button opens the correct app store. The screen launches with
  // LaunchMode.externalNonBrowserApplication, so every launch lands in
  // [externalLaunches].
  final externalLaunches = <String>[];
  UrlLauncherPlatform.instance = _RecordingUrlLauncherPlatform(
    externalLaunches: externalLaunches,
  );

  setUp(externalLaunches.clear);

  group("required-update", () {
    testWidgets("renders title, explanation and update button", (tester) async {
      await _pumpRequiredUpdateScreen(tester);

      expect(find.byType(RequiredUpdateScreen), findsOneWidget);
      expect(find.text("Update available"), findsOneWidget);
      expect(
        find.text(
          "To continue using the Yivi app, you must download the latest version.",
        ),
        findsOneWidget,
      );

      // The update button is rendered as the bottom bar's primary button.
      final updateButton = find.byKey(const Key("bottom_bar_primary"));
      expect(updateButton, findsOneWidget);
      expect(find.text("Update app"), findsOneWidget);
    });

    testWidgets("update button opens the platform app store", (tester) async {
      await _pumpRequiredUpdateScreen(tester);

      final updateButton = find.byKey(const Key("bottom_bar_primary"));
      await tester.tapAndSettle(updateButton);

      // Android points at the Play Store, iOS at the App Store. The test
      // itself only runs on those two platforms in CI.
      final expectedUrl = Platform.isAndroid ? _playStoreUrl : _appStoreUrl;
      expect(externalLaunches, [expectedUrl]);
    });
  });
}

/// Renders [RequiredUpdateScreen] on its own, wrapped in the same theme and
/// localization scaffolding the real app uses, forced to English so the
/// asserted copy is deterministic.
Future<void> _pumpRequiredUpdateScreen(WidgetTester tester) async {
  await tester.pumpWidgetAndSettle(
    IrmaTheme(
      builder: (context) => MaterialApp(
        theme: IrmaTheme.of(context).themeData,
        localizationsDelegates: AppState.defaultLocalizationsDelegates(),
        supportedLocales: AppState.defaultSupportedLocales(),
        locale: const Locale("en", "US"),
        home: const RequiredUpdateScreen(),
      ),
    ),
  );
}

/// Records the URLs passed to url_launcher so a test can assert which store
/// the update button opened. Mirrors the recording stand-in used by the
/// disclosure-session integration tests.
class _RecordingUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  _RecordingUrlLauncherPlatform({required this.externalLaunches});

  final List<String> externalLaunches;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    externalLaunches.add(url);
    return true;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    externalLaunches.add(url);
    return true;
  }

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => true;
}
