import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/providers/email_issuance_provider.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/providers/local_backends_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  setUp(() async {
    prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
  });

  // The preferences stream their values, so the providers read the host only
  // once the event queue has run.
  Future<ProviderContainer> loadedContainer() async {
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.listen(localBackendsProvider, (_, _) {});
    await pumpEventQueue();
    return container;
  }

  String emailIssuerHost(ProviderContainer container) =>
      (container.read(emailIssuerApiProvider) as DefaultEmailIssuerApi).host;

  String emailLinkUrl(ProviderContainer container) =>
      (container.read(keyshareEmailLinkApiProvider)
              as DefaultKeyshareEmailLinkApi)
          .url;

  test("without a host the app uses the real backends", () async {
    final container = await loadedContainer();

    expect(container.read(localBackendsProvider), isNull);
    expect(emailIssuerHost(container), container.read(emailIssuerUrlProvider));
    expect(emailLinkUrl(container), isEmpty);
  });

  test("with a host the e-mail calls go to its fixed ports", () async {
    await prefs.setLocalBackendHost("localhost");
    final container = await loadedContainer();

    expect(emailIssuerHost(container), "http://localhost:8080");
    expect(emailLinkUrl(container), "http://localhost:8081/email/link");
  });

  test("the scheme's issuer url does not override a local host", () async {
    await prefs.setLocalBackendHost("192.168.1.20");
    final container = await loadedContainer();

    container
        .read(emailIssuerUrlProvider.notifier)
        .set("https://email-issuer.yivi.app");

    expect(emailIssuerHost(container), "http://192.168.1.20:8080");
  });

  test("a blank host counts as off", () async {
    await prefs.setLocalBackendHost("  ");
    final container = await loadedContainer();

    expect(container.read(localBackendsProvider), isNull);
  });
}
