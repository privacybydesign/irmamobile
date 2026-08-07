import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";

/// The FOSS capture page is served by the passport issuer, so its URL must
/// track whichever issuer the running session points at. Pinning it to one
/// environment produces liveness transactions on a Face API the issuer does not
/// match against, which surfaces as an opaque "face verification failed".
void main() {
  group("faceCaptureUrlProvider", () {
    Uri captureUrlFor(String issuerUrl) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(passportIssuerUrlProvider.notifier).set(issuerUrl);
      return container.read(faceCaptureUrlProvider);
    }

    test("derives the capture page from the staging issuer", () {
      expect(
        captureUrlFor("https://passport-issuer.staging.yivi.app"),
        Uri.parse("https://passport-issuer.staging.yivi.app/capture"),
      );
    });

    test("follows the issuer to production", () {
      expect(
        captureUrlFor("https://passport-issuer.yivi.app"),
        Uri.parse("https://passport-issuer.yivi.app/capture"),
      );
    });

    test(
      "does not double the slash when the issuer url has a trailing one",
      () {
        expect(
          captureUrlFor("https://passport-issuer.yivi.app/"),
          Uri.parse("https://passport-issuer.yivi.app/capture"),
        );
      },
    );

    test("keeps a non-default port, as used by local issuer builds", () {
      expect(
        captureUrlFor("http://localhost:8080"),
        Uri.parse("http://localhost:8080/capture"),
      );
    });
  });
}
