import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
// ignore: depend_on_referenced_packages
import "package:plugin_platform_interface/plugin_platform_interface.dart";
// ignore: depend_on_referenced_packages
import "package:url_launcher_platform_interface/link.dart";
// ignore: depend_on_referenced_packages
import "package:url_launcher_platform_interface/url_launcher_platform_interface.dart";

import "../irma_binding.dart";
import "special_scenarios/attribute_order.dart";
import "special_scenarios/calling_session.dart";
import "special_scenarios/combined_disclosure_issuance.dart";
import "special_scenarios/decline_disclosure.dart";
import "special_scenarios/nullables.dart";
import "special_scenarios/random_blind.dart";
import "special_scenarios/return_url_https_external.dart";
import "special_scenarios/return_url_https_inapp.dart";
import "special_scenarios/revocation.dart";
import "special_scenarios/signing.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  // Spies for the URL-launcher / in-app-browser plumbing. Swap the real
  // url_launcher platform for a recording stand-in, and intercept the
  // Android in-app-browser MethodChannel. Both buckets get cleared in setUp.
  final externalLaunches = <String>[];
  final inAppLaunches = <String>[];

  UrlLauncherPlatform.instance = _RecordingUrlLauncherPlatform(
    externalLaunches: externalLaunches,
    inAppLaunches: inAppLaunches,
  );
  TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel("irma.app/iiab"),
        (call) async {
          if (call.method == "open_browser") {
            inAppLaunches.add(call.arguments as String);
          }
          return null;
        },
      );

  group("disclosure-session", () {
    setUp(() async {
      await irmaBinding.setUp();
      externalLaunches.clear();
      inAppLaunches.clear();
    });
    tearDown(() async => await irmaBinding.tearDown());

    group("special-scenarios", () {
      // Session with an optional attribute that cannot be null
      testWidgets("nullables", (tester) => nullablesTest(tester, irmaBinding));

      // Disclosure session and signing a message
      testWidgets("signing", (tester) => signingTest(tester, irmaBinding));

      // Issuance and disclosure in one session
      testWidgets(
        "combined-disclosure-issuance-session",
        (tester) => combinedDisclosureIssuanceSessionTest(tester, irmaBinding),
      );

      // Entering a session with a revoked credential
      testWidgets(
        "revocation",
        (tester) => revocationTest(tester, irmaBinding),
      );

      // Address from municipality with different attribute order
      testWidgets(
        "attribute-order",
        (tester) => attributeOrderTest(tester, irmaBinding),
      );

      // Disclosing stempas credential which is an unobtainable credential (no IssueURL) and contains a random blind attribute.
      testWidgets(
        "random-blind",
        (tester) => randomBlindTest(tester, irmaBinding),
      );

      // Decline disclosure at the last moment
      testWidgets(
        "decline-disclosure",
        (tester) => declineDisclosure(tester, irmaBinding),
      );

      // tel: clientReturnUrl → CallInfoScreen
      testWidgets(
        "calling-session",
        (tester) => callingSessionTest(tester, irmaBinding),
      );

      // https clientReturnUrl → openURLExternally + pop
      testWidgets(
        "return-url-https-external",
        (tester) => returnUrlHttpsExternalTest(
          tester,
          irmaBinding,
          externalLaunches: externalLaunches,
          inAppLaunches: inAppLaunches,
        ),
      );

      // https?inapp=true clientReturnUrl → in-app browser
      testWidgets(
        "return-url-https-inapp",
        (tester) => returnUrlHttpsInAppTest(
          tester,
          irmaBinding,
          externalLaunches: externalLaunches,
          inAppLaunches: inAppLaunches,
        ),
      );
    });
  });
}

/// Records calls from `url_launcher` so tests can assert which return URL
/// was opened, and through which channel. `mode: .externalApplication` (used
/// by `openURLExternally`) lands in [externalLaunches]; `mode: .inAppWebView`
/// or `.inAppBrowserView` (used by iOS `openURLinAppBrowser`) lands in
/// [inAppLaunches]. The Android in-app browser path goes through the
/// `irma.app/iiab` MethodChannel mocked separately in [main].
class _RecordingUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  _RecordingUrlLauncherPlatform({
    required this.externalLaunches,
    required this.inAppLaunches,
  });

  final List<String> externalLaunches;
  final List<String> inAppLaunches;

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
    (useWebView ? inAppLaunches : externalLaunches).add(url);
    return true;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    final mode = options.mode;
    final isInApp =
        mode == PreferredLaunchMode.inAppWebView ||
        mode == PreferredLaunchMode.inAppBrowserView;
    (isInApp ? inAppLaunches : externalLaunches).add(url);
    return true;
  }

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => true;
}
