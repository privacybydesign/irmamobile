import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";

/// The IRMA server the passport issuer hands back in `irma_server_url`. It is a
/// different service than the passport issuer itself, see the `irma_server_url`
/// key in go-passport-issuer's config.
const _stagingIrmaServer = "https://is.staging.yivi.app";
const _productionIrmaServer = "https://is.yivi.app";

DefaultPassportIssuer _issuerFor(String passportIssuerUrl) {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(passportIssuerUrlProvider.notifier).set(passportIssuerUrl);
  return container.read(passportIssuerProvider) as DefaultPassportIssuer;
}

void main() {
  group("passportIssuerProvider allowed IRMA hosts", () {
    test("accepts the IRMA server the staging passport issuer returns", () {
      final issuer = _issuerFor("https://passport-issuer.staging.yivi.app");

      expect(
        issuer.validateSessionUrl(_stagingIrmaServer).host,
        "is.staging.yivi.app",
      );
    });

    test("accepts the IRMA server the production passport issuer returns", () {
      final issuer = _issuerFor("https://passport-issuer.yivi.app");

      expect(
        issuer.validateSessionUrl(_productionIrmaServer).host,
        "is.yivi.app",
      );
    });

    test("rejects a session URL on any other host", () {
      final issuer = _issuerFor("https://passport-issuer.staging.yivi.app");

      expect(
        () => issuer.validateSessionUrl("https://attacker.example"),
        throwsException,
      );
    });

    test("rejects a session URL that is not https", () {
      final issuer = _issuerFor("https://passport-issuer.staging.yivi.app");

      expect(
        () => issuer.validateSessionUrl("http://is.staging.yivi.app"),
        throwsException,
      );
    });
  });
}
